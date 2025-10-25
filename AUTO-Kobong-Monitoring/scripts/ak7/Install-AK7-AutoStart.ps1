param([switch]$Install,[switch]$Remove,[ValidateSet('Server','UI')][string]$Run,[switch]$Now)
$RepoRoot = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring'
$SrvDir   = Join-Path $RepoRoot 'containers\ak7-shells'
$ServerJs = Join-Path $SrvDir 'server-ak7.js'
$WebHtml  = Join-Path $RepoRoot 'webui\AUTO-Kobong-Monitoring-Han.html'
$LogsDir  = Join-Path $RepoRoot 'logs'
$Port     = 5191
$Health   = 'http://localhost:5191/health'
$ApiInfo  = 'http://localhost:5191/api/ak7'
$TaskSrv  = 'AK7_Server_AutoStart'
$TaskUI   = 'AK7_UI_AutoOpen'
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null
function Write-Log($m){ ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$m) | Tee-Object -FilePath (Join-Path $LogsDir 'autostart.log') -Append | Out-Null }
function Get-NodePath{ foreach($p in @('D:\tools\node18\node.exe',(Join-Path $env:ProgramFiles 'nodejs\node.exe'),'node')){ if(Get-Command $p -ErrorAction SilentlyContinue){ return (Get-Command $p).Source } } }
function Test-PortUsed($Port){ (Get-NetTCPConnection -ErrorAction SilentlyContinue | ? { $_.LocalPort -eq $Port -and $_.State -in 'Listen','Established' }).Count -gt 0 }
function Stop-ByPort($Port){ (Get-NetTCPConnection -ErrorAction SilentlyContinue | ? LocalPort -eq $Port | Select -Exp OwningProcess -Unique) | % { try{ Stop-Process -Id $_ -Force }catch{} } }
function Wait-HttpOK($Url,[int]$TimeoutSec=90){ $t0=Get-Date; do{ try{ $r=Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 5; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 300){ return $true } }catch{} Start-Sleep -Milliseconds 800 } while((Get-Date)-$t0 -lt [TimeSpan]::FromSeconds($TimeoutSec)); $false }
function Open-Default($Url){ Start-Process cmd '/c start "$Url"' }
function Run-Server{ Write-Log '=== AK7 SERVER RUN ==='; if(!(Test-Path $ServerJs)){ Write-Log ('server not found: ' + $ServerJs); return }; $node=Get-NodePath; if(!$node){ Write-Log 'Node not found'; return }; if(Test-PortUsed $Port){ Stop-ByPort $Port }
  Push-Location $SrvDir; try{ $env:PORT='5191'; $env:MODE='MOCK'; & $node $ServerJs | Out-Null; Write-Log ('Started → ' + $Health) }catch{ Write-Log $_.Exception.Message } finally{ Pop-Location }
  if(Wait-HttpOK $Health 60){ Write-Log 'HEALTH OK'; try{ $s=Invoke-WebRequest -UseBasicParsing $ApiInfo -TimeoutSec 5 | % Content; Write-Log ('API INFO: ' + $s) }catch{ Write-Log ('API fail: ' + $_.Exception.Message) } } else { Write-Log 'HEALTH TIMEOUT' } }
function Run-UI{ if(!(Test-Path $WebHtml)){ Write-Log ('HTML not found: ' + $WebHtml); return }; if(Wait-HttpOK $Health 30){ Write-Log 'Open UI'; } else { Write-Log 'Open UI (server not ready)'; }
  Open-Default $Health; Open-Default $ApiInfo; $u='file:///'+($WebHtml -replace '\\','/'); Open-Default $u }
function Install-Tasks{
  $Self = $PSCommandPath
  $actSrv = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument ('-NoProfile -File "' + $Self + '" -Run Server')
  $trgSrv = New-ScheduledTaskTrigger -AtStartup
  $priSrv = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
  $setSrv = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew
  try{ if(Get-ScheduledTask -TaskName $TaskSrv -ErrorAction SilentlyContinue){ Unregister-ScheduledTask -TaskName $TaskSrv -Confirm:$false | Out-Null }
       Register-ScheduledTask -TaskName $TaskSrv -Action $actSrv -Trigger $trgSrv -Principal $priSrv -Settings $setSrv | Out-Null
       Write-Log ('Installed: ' + $TaskSrv) } catch { Write-Log ('Install fail ' + $TaskSrv + ': ' + $_.Exception.Message) }
  $me=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
  $actUI = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument ('-NoProfile -File "' + $Self + '" -Run UI')
  $trgUI = New-ScheduledTaskTrigger -AtLogOn
  $priUI = New-ScheduledTaskPrincipal -UserId $me -RunLevel Highest
  $setUI = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopOnIdleEnd -MultipleInstances IgnoreNew
  try{ if(Get-ScheduledTask -TaskName $TaskUI -ErrorAction SilentlyContinue){ Unregister-ScheduledTask -TaskName $TaskUI -Confirm:$false | Out-Null }
       Register-ScheduledTask -TaskName $TaskUI -Action $actUI -Trigger $trgUI -Principal $priUI -Settings $setUI | Out-Null
       Write-Log ('Installed: ' + $TaskUI) } catch { Write-Log ('Install fail ' + $TaskUI + ': ' + $_.Exception.Message) } }
if($Install){ Install-Tasks }
if($Remove){ foreach($t in @($TaskSrv,$TaskUI)){ try{ Unregister-ScheduledTask -TaskName $t -Confirm:$false | Out-Null }catch{} } }
switch($Run){ 'Server'{ Run-Server } 'UI'{ Run-UI } }
if($Install -and $Now){ Run-Server; Start-Sleep -s 2; Run-UI }

