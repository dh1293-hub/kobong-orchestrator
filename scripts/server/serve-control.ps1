#requires -Version 7.0
param(
  [ValidateSet("status","start","stop","restart","logs","enable","disable","smoke","export-openapi","clean-logs","watch")]
  [string]$Action="status",
  [int]$Port=8000,
  [string]$BindHost="127.0.0.1",
  [int]$RetentionDays=14
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

# Paths
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath) # scripts/server → repo
$ServerRoot = Join-Path $RepoRoot 'server'
$ScriptsDir = Join-Path $RepoRoot 'scripts\server'
$LogsDir    = Join-Path $RepoRoot 'logs\serve'
$Launcher   = Join-Path $ScriptsDir 'guard-launcher.ps1'
$RunProd    = Join-Path $ScriptsDir 'run-prod.ps1'
$Guard      = Join-Path $ScriptsDir 'serve-guard.ps1'
$Smoke      = Join-Path $ScriptsDir 'health-smoke.ps1'
$Export     = Join-Path $ScriptsDir 'export-openapi.ps1'
$PwshExe    = Join-Path $PSHOME 'pwsh.exe'
$RunKey     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RunName    = 'KO-ServeGuard'
$StartupDir = [Environment]::GetFolderPath('Startup')
$StartupLnk = Join-Path $StartupDir "$RunName.lnk"

function BaseUrl(){ return "http://$BindHost`:$Port" }
function IsUp(){
  try{ $r=Invoke-RestMethod -Uri "$(BaseUrl)/livez" -TimeoutSec 2; return ($r.status -eq 'ok') } catch { return $false }
}

switch ($Action) {
  'status' {
    $alive = IsUp
    if ($alive) {
      Write-Host ("[OK] up → {0}/livez" -f (BaseUrl)) -ForegroundColor Green
    } else {
      try {
        $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop
        Write-Host ("[LISTEN] pid={0} (port {1}) but livez not OK" -f ($conn|Select -First 1 -Expand OwningProcess), $Port) -ForegroundColor Yellow
      } catch {
        Write-Host ("[DOWN] nothing listening on {0}" -f (BaseUrl)) -ForegroundColor Red
      }
    }
  }
  'start' {
    Start-Process -FilePath $PwshExe -ArgumentList ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Root "{1}" -Port {2} -BindHost "{3}"' -f $Launcher,$RepoRoot,$Port,$BindHost) -WorkingDirectory $RepoRoot -WindowStyle Hidden | Out-Null
    for($i=0;$i -lt 30;$i++){ if(IsUp){break}; Start-Sleep 1 }
    & $PSCommandPath -Action status -Port $Port -BindHost $BindHost
  }
  'stop' {
    try {
      Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
        Select-Object -Unique OwningProcess |
        ForEach-Object { try { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } catch {} }
      Write-Host "[STOP] listeners on port $Port terminated." -ForegroundColor Yellow
    } catch {
      Write-Host "[STOP] nothing to stop (port $Port idle)." -ForegroundColor Yellow
    }
  }
  'restart' {
    & $PSCommandPath -Action stop    -Port $Port -BindHost $BindHost
    & $PSCommandPath -Action start   -Port $Port -BindHost $BindHost
    & $PSCommandPath -Action status  -Port $Port -BindHost $BindHost
  }
  'logs' {
    $last = Get-ChildItem -Path $LogsDir -Filter 'prod-*.out.log' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $last) { Write-Host "[LOGS] no prod-*.out.log yet."; break }
    Write-Host "[TAIL] $($last.FullName) (Ctrl+C to exit)"
    Get-Content -Path $last.FullName -Wait -Encoding utf8
  }
  'enable' {
    New-Item -Path $RunKey -Force | Out-Null
    $argStr = ('-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}" -Root "{1}" -Port {2} -BindHost "{3}"' -f $Launcher,$RepoRoot,$Port,$BindHost)
    Set-ItemProperty -Path $RunKey -Name $RunName -Value ('"{0}" {1}' -f $PwshExe, $argStr) -Type String
    Write-Host "[ENABLE] HKCU\\Run entry set → $RunName" -ForegroundColor Green
  }
  'disable' {
    if (Test-Path $RunKey) { try { Remove-ItemProperty -Path $RunKey -Name $RunName -ErrorAction SilentlyContinue } catch {} }
    if (Test-Path $StartupLnk) { try { Remove-Item -LiteralPath $StartupLnk -Force } catch {} }
    Write-Host "[DISABLE] autorun entries removed." -ForegroundColor Yellow
  }
  'smoke' {
    if (Test-Path $Smoke) {
      & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Smoke -Base (BaseUrl) | Write-Host
    } else {
      try {
        $h = Invoke-RestMethod -Uri "$(BaseUrl)/healthz"
        $p = Invoke-RestMethod -Uri "$(BaseUrl)/api/v1/ping"
        $e = Invoke-RestMethod -Uri "$(BaseUrl)/api/v1/echo" -Method POST -ContentType 'application/json' -Body (@{text='hello';meta=@{a=1}}|ConvertTo-Json -Compress)
        $s = Invoke-RestMethod -Uri "$(BaseUrl)/api/v1/sum"  -Method POST -ContentType 'application/json' -Body (@{numbers=@(1,2,3.5)}|ConvertTo-Json -Compress)
        $h,$p,$e,$s | ForEach-Object { $_ | ConvertTo-Json -Compress | Write-Host }
      } catch { Write-Host "[SMOKE] failed: $($_.Exception.Message)" -ForegroundColor Red }
    }
  }
  'export-openapi' {
    $Artifacts = Join-Path $RepoRoot 'artifacts'
    New-Item -ItemType Directory -Force -Path $Artifacts | Out-Null
    if (Test-Path $Export) {
      & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Export -OutDir $Artifacts | Write-Host
    } else {
      Write-Host "[WARN] export-openapi.ps1 not found" -ForegroundColor Yellow
    }
  }
  'clean-logs' {
    $cut=(Get-Date).AddDays(-[math]::Abs($RetentionDays))
    Get-ChildItem -Path $LogsDir -File | Where-Object { $_.LastWriteTime -lt $cut } | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "[CLEAN] removed logs older than $RetentionDays days." -ForegroundColor Yellow
  }
}

# --- watch action (g5) ---
try {
  if ($Action -eq 'watch') {
    $watch = Join-Path $PSScriptRoot 'serve-watch.ps1'
    if (-not (Test-Path $watch)) { Write-Error "missing $watch"; exit 13 }
    & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $watch -Port $Port -BindHost $BindHost
    exit $LASTEXITCODE
  }
} catch {
  Write-Error -Message $_.Exception.Message
  exit 13
}

