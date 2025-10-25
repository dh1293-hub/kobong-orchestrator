# Run-OrchMon-5193.ps1  (백그라운드 기동 + 로그 + PID)
param()
$ErrorActionPreference='Stop'
$AppDir = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\containers\orch-shells'
$Node   = 'D:\tools\node18\node.exe'
$Logs   = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\logs'
$Pid    = Join-Path $Logs 'orchmon-host.pid'
$log   = Join-Path $Logs ('orchmon_' + (Get-Date -Format yyyyMMdd) + '.log')

Set-Location $AppDir
# 중복 인스턴스 정리
if(Test-Path $Pid){ Get-Content $Pid | % { try{ Stop-Process -Id [int]$_ -Force -ErrorAction SilentlyContinue }catch{} }; Remove-Item $Pid -Force -ErrorAction SilentlyContinue }

# 기동
$p = Start-Process -FilePath $Node -ArgumentList 'server.js' -WorkingDirectory $AppDir -WindowStyle Hidden -PassThru 
        -RedirectStandardOutput $log -RedirectStandardError $log
$p.Id | Out-File -Encoding ascii -FilePath $Pid -Force
