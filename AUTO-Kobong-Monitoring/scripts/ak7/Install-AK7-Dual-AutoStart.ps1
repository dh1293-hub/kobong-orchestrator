param(
  [switch]$Install,
  [switch]$Remove,
  [switch]$Now,
  [ValidateSet('Mock','Dev','Both','UI')][string]$Run='Both'
)

# === 상수/경로 ===
$Repo     = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring'
$SrvDir   = Join-Path $Repo 'containers\ak7-shells'
$ServerJs = Join-Path $SrvDir 'server-ak7.js'
$WebHtml  = Join-Path $Repo 'webui\AUTO-Kobong-Monitoring-Han.html'
$Logs     = Join-Path $Repo 'logs'

$PORT_DEV  = 5181
$PORT_MOCK = 5191
$AK7_BASE  = '/api/ak7'

$Health_DEV  = "http://localhost:$PORT_DEV/health"
$Health_MOCK = "http://localhost:$PORT_MOCK/health"
$Api_DEV     = "http://localhost:$PORT_DEV$AK7_BASE"
$Api_MOCK    = "http://localhost:$PORT_MOCK$AK7_BASE"

$TaskMock = 'AK7_MOCK_5191_Server'
$TaskDev  = 'AK7_DEV_5181_Server'
$TaskUI   = 'AK7_UI_AutoOpen'

# === 유틸 ===
New-Item -ItemType Directory -Force -Path $Logs | Out-Null
function Log($m){
  ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) |
    Tee-Object -FilePath (Join-Path $Logs 'dual-autostart.log') -Append | Out-Null
}

function Get-NodePath{
  foreach($p in @('D:\tools\node18\node.exe', (Join-Path $env:ProgramFiles 'nodejs\node.exe'), 'node')){
    $cmd = Get-Command $p -ErrorAction SilentlyContinue
    if($cmd){ return $cmd.Source }
  }
  return $null
}

function Test-PortUsed([int]$Port){
  (Get-NetTCPConnection -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $Port -and $_.State -in 'Listen','Established' }).Count -gt 0
}

function Stop-ByPort([int]$Port){
  (Get-NetTCPConnection -ErrorAction SilentlyContinue |
    Where-Object LocalPort -eq $Port |
    Select-Object -ExpandProperty OwningProcess -Unique) | ForEach-Object {
      try{ Stop-Process -Id $_ -Force }catch{}
    }
}

function Wait-HttpOK($Url, [int]$TimeoutSec=60){
  $t0 = Get-Date
  do{
    try{
      $r = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5
      if($r.StatusCode -ge 200 -and $r.StatusCode -lt 300){ return $true }
    }catch{}
    Start-Sleep -Milliseconds 800
  }while((Get-Date)-$t0 -lt [TimeSpan]::FromSeconds($TimeoutSec))
  return $false
}

function Open-Default($Url){ Start-Process cmd "/c start `"$Url`"" }

function Ensure-Firewall{
  foreach($p in @($PORT_MOCK,$PORT_DEV)){
    $name = ('Allow_AK7_{0}' -f $p)
    if(-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)){
      New-NetFirewallRule -DisplayName $name -Direction Inbound -Action Allow -Protocol TCP -LocalPort $p | Out-Null
      Log ('Firewall rule added: {0}' -f $name)
    }
  }
}

# === 인스턴스 실행 ===
function Run-Instance([int]$Port, [string]$Mode){
  if(!(Test-Path $ServerJs)){ Log ('server-ak7.js not found: {0}' -f $ServerJs); return }
  $node = Get-NodePath
  if(!$node){ Log 'Node not found'; return }

  if(Test-PortUsed $Port){ Log ('Port {0} in use → killing' -f $Port); Stop-ByPort $Port }

  Push-Location $SrvDir
  try{
    $env:PORT = "$Port"
    $env:MODE = $Mode
    $baseName = ('ak7_{0}_{1}' -f $Port, $Mode.ToLower())
    $logOut = Join-Path $Logs ('{0}.log' -f $baseName)
    $logErr = Join-Path $Logs ('{0}.err.log' -f $baseName)

    Log ('RUN → node {0} (PORT={1}, MODE={2})' -f $ServerJs, $Port, $Mode)
    Start-Process -FilePath $node -ArgumentList @("$ServerJs") -WorkingDirectory $SrvDir -WindowStyle Hidden `
      -RedirectStandardOutput $logOut -RedirectStandardError $logErr
  }finally{
    Pop-Location
  }

  $health = "http://localhost:$Port/health"
  if(Wait-HttpOK $health 30){ Log ('HEALTH OK ({0})' -f $health) } else { Log ('HEALTH TIMEOUT ({0})' -f $health) }
}

function Run-UI{
  Open-Default $Health_MOCK
  Open-Default $Api_MOCK
  $u = 'file:///' + ($WebHtml -replace '\\','/')
  Open-Default $u
  Log ('UI open → {0}' -f $u)
}

# === 태스크 설치/제거 ===
function Install-Tasks{
  Ensure-Firewall
  $self = $PSCommandPath

  # MOCK @ Startup (SYSTEM)
  $act1 = New-ScheduledTaskAction  -Execute 'pwsh.exe' -Argument ('-NoProfile -File "'+$self+'" -Run Mock -Now')
  $trg1 = New-ScheduledTaskTrigger -AtStartup
  $pri1 = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
  $set1 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew
  try{
    if(Get-ScheduledTask -TaskName $TaskMock -ErrorAction SilentlyContinue){ Unregister-ScheduledTask -TaskName $TaskMock -Confirm:$false | Out-Null }
    Register-ScheduledTask -TaskName $TaskMock -Action $act1 -Trigger $trg1 -Principal $pri1 -Settings $set1 | Out-Null
    Log ('Installed: {0}' -f $TaskMock)
  }catch{
    Log ('Install fail {0}: {1}' -f $TaskMock, $_.Exception.Message)
  }

  # DEV @ Startup (SYSTEM)
  $act2 = New-ScheduledTaskAction  -Execute 'pwsh.exe' -Argument ('-NoProfile -File "'+$self+'" -Run Dev -Now')
  $trg2 = New-ScheduledTaskTrigger -AtStartup
  $pri2 = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
  $set2 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew
  try{
    if(Get-ScheduledTask -TaskName $TaskDev -ErrorAction SilentlyContinue){ Unregister-ScheduledTask -TaskName $TaskDev -Confirm:$false | Out-Null }
    Register-ScheduledTask -TaskName $TaskDev -Action $act2 -Trigger $trg2 -Principal $pri2 -Settings $set2 | Out-Null
    Log ('Installed: {0}' -f $TaskDev)
  }catch{
    Log ('Install fail {0}: {1}' -f $TaskDev, $_.Exception.Message)
  }

  # UI @ Logon (현재 사용자)
  $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $act3 = New-ScheduledTaskAction  -Execute 'pwsh.exe' -Argument ('-NoProfile -File "'+$self+'" -Run UI -Now')
  $trg3 = New-ScheduledTaskTrigger -AtLogOn
  $pri3 = New-ScheduledTaskPrincipal -UserId $me -RunLevel Highest
  $set3 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew
  try{
    if(Get-ScheduledTask -TaskName $TaskUI -ErrorAction SilentlyContinue){ Unregister-ScheduledTask -TaskName $TaskUI -Confirm:$false | Out-Null }
    Register-ScheduledTask -TaskName $TaskUI -Action $act3 -Trigger $trg3 -Principal $pri3 -Settings $set3 | Out-Null
    Log ('Installed: {0}' -f $TaskUI)
  }catch{
    Log ('Install fail {0}: {1}' -f $TaskUI, $_.Exception.Message)
  }
}

function Remove-Tasks{
  foreach($t in @($TaskMock,$TaskDev,$TaskUI)){
    try{ Unregister-ScheduledTask -TaskName $t -Confirm:$false | Out-Null; Log ('Removed: {0}' -f $t) }catch{}
  }
}

# === 엔트리 ===
if($Install){ Install-Tasks }
if($Remove){ Remove-Tasks }

switch($Run){
  'Mock' { Run-Instance -Port $PORT_MOCK -Mode 'MOCK' }
  'Dev'  { Run-Instance -Port $PORT_DEV  -Mode 'DEV'  }
  'Both' { Run-Instance -Port $PORT_MOCK -Mode 'MOCK'; Run-Instance -Port $PORT_DEV -Mode 'DEV' }
  'UI'   { Run-UI }
}

if($Now -and $Run -eq 'Both'){ Run-UI }
