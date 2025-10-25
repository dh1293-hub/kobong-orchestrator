# Install-AK7-AutoStart.ps1
[CmdletBinding()]param([switch]$Install,[switch]$Remove,[switch]$Now,[ValidateSet('Server','UI')][string]$Run)

$ROOT = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring'
$SrvDir= Join-Path $ROOT 'containers\ak7-shells'
$ServerJs = Join-Path $SrvDir 'server.js'
$WebHtml  = Join-Path $ROOT 'webui\Orchestrator-Monitoring-Su.html'
$LogsDir  = Join-Path $ROOT 'logs'; New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

$Port=5191
$Health = "http://localhost:$Port/health"
$ApiInfo= "http://localhost:$Port/api/ak7"
$TaskSrv= 'AK7_Server_AutoStart'
$TaskUI = 'AK7_UI_AutoOpen'
$Self   = $MyInvocation.MyCommand.Path

function W($m){ ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$m) | Tee-Object -FilePath (Join-Path $LogsDir 'autostart_ak7.log') -Append | Out-Null }
function Node(){ $c=@('D:\tools\node18\node.exe',(Join-Path $env:ProgramFiles 'nodejs\node.exe'),'node'); foreach($p in $c){$g=Get-Command $p -ErrorAction SilentlyContinue; if($g){return $g.Source}} return $null }
function WaitOK($u,[int]$t=60){ $t0=Get-Date; do{ try{$r=Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri $u; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 300){return $true}}catch{} Start-Sleep -Milliseconds 700 } while((Get-Date)-$t0 -lt (New-TimeSpan -Seconds $t)); return $false }

function Run-Server{
  W "RUN SERVER :$Port"
  if(!(Test-Path $ServerJs)){ W "NO server.js"; return }
  $node=Node; if(!$node){ W "NO node.exe"; return }
  $env:PORT="$Port"; $env:MODE="MOCK"
  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$node; $psi.Arguments="`"$ServerJs`""; $psi.WorkingDirectory=$SrvDir; $psi.CreateNoWindow=$true; $psi.UseShellExecute=$false
  $p=[System.Diagnostics.Process]::Start($psi); W "PID=$($p.Id)"
  if(WaitOK $Health 90){ W "HEALTH OK $Health"; try{ $s=Invoke-WebRequest -UseBasicParsing $ApiInfo -TimeoutSec 5 | % Content; W "API $s" }catch{ W "API FAIL: $($_.Exception.Message)" } } else { W "HEALTH TIMEOUT $Health" }
}
function Run-UI{
  W "OPEN UI"; $url='file:///' + ($WebHtml -replace '\\','/')
  if(WaitOK $Health 60){ W "OK health, opening" } else { W "open anyway" }
  Start-Process cmd "/c start `"$Health`""; Start-Process cmd "/c start `"$ApiInfo`""; Start-Process cmd "/c start `"$url`""
}

function Install-Tasks{
  W "Install tasks"
  $actS=New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-NoProfile -File `"$Self`" -Run Server"
  $trgS=New-ScheduledTaskTrigger -AtStartup
  $priS=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
  $setS=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew
  try{ if(Get-ScheduledTask -TaskName $TaskSrv -ErrorAction SilentlyContinue){ Unregister-ScheduledTask -TaskName $TaskSrv -Confirm:$false }
       Register-ScheduledTask -TaskName $TaskSrv -Action $actS -Trigger $trgS -Principal $priS -Settings $setS | Out-Null
       W "Installed ${TaskSrv}" }catch{ W "Install ${TaskSrv} FAIL: $($_.Exception.Message)" }

  $me=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $actU=New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-NoProfile -File `"$Self`" -Run UI"
  $trgU=New-ScheduledTaskTrigger -AtLogOn
  $priU=New-ScheduledTaskPrincipal -UserId $me -RunLevel Highest
  $setU=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew
  try{ if(Get-ScheduledTask -TaskName $TaskUI -ErrorAction SilentlyContinue){ Unregister-ScheduledTask -TaskName $TaskUI -Confirm:$false }
       Register-ScheduledTask -TaskName $TaskUI -Action $actU -Trigger $trgU -Principal $priU -Settings $setU | Out-Null
       W "Installed ${TaskUI}" }catch{ W "Install ${TaskUI} FAIL: $($_.Exception.Message)" }
}

function Remove-Tasks{ foreach($t in @($TaskSrv,$TaskUI)){ try{ Unregister-ScheduledTask -TaskName $t -Confirm:$false }catch{} } }

if($Install){ Install-Tasks }
if($Remove){ Remove-Tasks }
switch($Run){ 'Server'{Run-Server}; 'UI'{Run-UI} }
if($Install -and $Now){ Run-Server; Start-Sleep 2; Run-UI }
if(-not $Install -and -not $Remove -and -not $Run){
  "Usage: -Install [-Now] | -Remove | -Run Server|UI"
}
