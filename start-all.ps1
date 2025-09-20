# APPLY IN SHELL
#requires -Version 7.0
param([string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",[int]$ApiPort=8787,[int]$WebPort=8080)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$env:CONFIRM_APPLY='true'
Start-Process -WindowStyle Minimized -FilePath "$Root\scripts\github\run-github-summary.ps1" -ArgumentList @('-Root',"$Root",'-Owner','dh1293-hub','-Repo','kobong-orchestrator','-Port',"$ApiPort",'-ConfirmApply','-SkipTokenCheck')
Start-Process -WindowStyle Minimized -FilePath "$Root\web\serve-web.ps1" -ArgumentList @('-Port',"$WebPort",'-Root',"$Root\web")
Start-Process "http://127.0.0.1:$WebPort/"
