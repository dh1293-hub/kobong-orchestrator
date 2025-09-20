#requires -Version 7.0
param([int]$Port=8000,[string]$BindHost='127.0.0.1',[string]$TaskName='KO-ServeGuard',[string]$RunName='KO-ServeGuard')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$RepoRoot=Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$PwshExe=Join-Path $PSHOME 'pwsh.exe'
$Scripts =Join-Path $RepoRoot 'scripts\server'
$Launcher=Join-Path $Scripts 'guard-launcher.ps1'

# stop listeners
try {
  Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
    Select-Object -Unique OwningProcess |
    ForEach-Object { try { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } catch {} }
  Write-Host "[STOP] port $Port listeners terminated." -ForegroundColor Yellow
} catch { Write-Host "[STOP] none" -ForegroundColor Yellow }

# disable autorun (HKCU Run / Startup shortcut)
$RunKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
try { if (Test-Path $RunKey) { Remove-ItemProperty -Path $RunKey -Name $RunName -ErrorAction SilentlyContinue } } catch {}
$StartupDir=[Environment]::GetFolderPath('Startup')
$Lnk=Join-Path $StartupDir "$RunName.lnk"
if (Test-Path $Lnk) { try { Remove-Item -LiteralPath $Lnk -Force } catch {} }

# unregister scheduled task if any (best-effort)
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  try { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null } catch {}
}

# clean pid markers
$Logs=Join-Path $RepoRoot 'logs\serve'
Remove-Item -LiteralPath (Join-Path $Logs 'last-prod.pid') -Force -ErrorAction SilentlyContinue

# verify down
$base="http://$BindHost`:$Port"
$alive=$false
try{ $r=Invoke-RestMethod -Uri "$base/livez" -TimeoutSec 2; $alive=($r.status -eq 'ok') } catch {}
if (-not $alive) { Write-Host "ALL GREEN ✅ — disabled & stopped (port=$Port)" -ForegroundColor Green }
else { Write-Host "PARTIAL ⚠️ — still alive at $base/livez (manual check)" -ForegroundColor Yellow }