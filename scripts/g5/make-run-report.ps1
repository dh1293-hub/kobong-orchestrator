#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot = (Resolve-Path ($Root ?? (Get-Location))).Path
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline
$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
try {
  $OutDir  = Join-Path $RepoRoot 'webui\public\data'
  $OutFile = Join-Path $OutDir  'gh-monitor.json'
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

  function Test-Http($url,[int]$timeout=3){
    try {
      $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head -TimeoutSec $timeout -ErrorAction Stop
      [pscustomobject]@{ url=$url; ok=$true; status=$resp.StatusCode; when=(Get-Date).ToString('o') }
    } catch {
      [pscustomobject]@{ url=$url; ok=$false; status=($_.Exception.Message); when=(Get-Date).ToString('o') }
    }
  }

  $urls = @('http://localhost:5173/','http://localhost:5173/metrics')
  $http = $urls | ForEach-Object { Test-Http $_ }

  $ports = 5173,5174
  $tcp = foreach($p in $ports){
    try {
      $c = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction Stop
      foreach($row in $c){
        $pid=$row.OwningProcess
        $pn=(Get-Process -Id $pid -ErrorAction SilentlyContinue).ProcessName
        [pscustomobject]@{ port=$p; state='Listening'; pid=$pid; proc=$pn }
      }
    } catch {
      [pscustomobject]@{ port=$p; state='NotListening'; pid=$null; proc=$null }
    }
  }

  $tn='MyTask_Interactive_v2'
  $ti=Get-ScheduledTaskInfo -TaskName $tn -ErrorAction SilentlyContinue
  $tsk= if($ti){ [pscustomobject]@{ name=$tn; lastRun="$($ti.LastRunTime)"; result=$ti.LastTaskResult } } else { [pscustomobject]@{ name=$tn; lastRun=$null; result=$null } }

  $out=[pscustomobject]@{
    timestamp=(Get-Date).ToString('o')
    repo=$RepoRoot
    http=$http
    tcp=$tcp
    task=$tsk
  }

  $json = $out | ConvertTo-Json -Depth 6

  if (-not $ConfirmApply) {
    "[PREVIEW] Would write → $OutFile" | Write-Output
    $json | Write-Output
    exit 0
  }

  $ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
  $tmp = "$OutFile.tmp"
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  if (Test-Path $OutFile) { Copy-Item $OutFile "$OutFile.bak-$ts" -Force }
  [System.IO.File]::WriteAllText($tmp, $json, $utf8)
  Move-Item -LiteralPath $tmp -Destination $OutFile -Force
  "[OK] wrote → $OutFile" | Write-Output

  $rec=@{timestamp=(Get-Date).ToString('o');level='INFO';traceId=$trace;module='make-run-report';action='write-gh-monitor.json';inputHash='';outcome='SUCCESS';durationMs=$sw.ElapsedMilliseconds;errorCode='';message=$OutFile} | ConvertTo-Json -Compress
  $applyLog = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $applyLog) | Out-Null
  Add-Content -Path $applyLog -Value $rec
}
catch {
  $rec=@{timestamp=(Get-Date).ToString('o');level='ERROR';traceId=$trace;module='make-run-report';action='write-gh-monitor.json';inputHash='';outcome='FAILURE';durationMs=$sw.ElapsedMilliseconds;errorCode=$_.Exception.Message;message=$_.ScriptStackTrace} | ConvertTo-Json -Compress
  $applyLog = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $applyLog) | Out-Null
  Add-Content -Path $applyLog -Value $rec
  throw
}
finally {
  Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
}