param(
  [Parameter(Mandatory=$true)][string] $Code,
  [Parameter(Mandatory=$true)][scriptblock] $Run,
  [string] $CategoryHint
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-GitSummary {
  try {
    $root = git rev-parse --show-toplevel 2>$null
    if (-not $root) { return @{ summary='not-a-git-repo'; changed=@() } }
    $lines = @(git status --porcelain 2>$null)
    if ($lines.Count -eq 0) { return @{ summary='clean'; changed=@() } }
    return @{ summary=('modified(' + $lines.Count + ')'); changed=$lines }
  } catch {
    return @{ summary='git-error'; changed=@() }
  }
}

function Get-NextBatchId {
  $date = (Get-Date).ToString('yyyyMMdd')
  $dir  = Join-Path $env:HAN_GPT5_ROOT 'logs/error-reports'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $existing = Get-ChildItem -Path $dir -Filter "$date-*.txt" -File | ForEach-Object {
    if ($_.BaseName -match '^\d{8}-(\d{2})$') { [int]$Matches[1] } else { $null }
  } | Where-Object { $_ -ne $null }
  $n = 1 + ($(if ($existing){ ($existing | Measure-Object -Maximum).Maximum } else { 0 }))
  return ('{0}-{1:00}' -f $date, $n)
}

function Append-JsonLog {
  param([Parameter(Mandatory=$true)][hashtable]$obj)
  try {
    $line = ($obj | ConvertTo-Json -Depth 6 -Compress)
    $log  = Join-Path $env:HAN_GPT5_ROOT 'logs/apply-log.jsonl'
    New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
    Add-Content -Path $log -Value $line
  } catch {
    # ignore logging errors
  }
}

# ?? ?ㅽ뻾 & 罹≪쿂 ??????????????????????????????????????????????????????????????
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$buffer = New-Object System.Collections.ArrayList
$success = $true
$err = $null
try {
  & $Run *>&1 | Tee-Object -Variable teeOut | ForEach-Object { [void]$buffer.Add($_); $_ } | Out-Host
} catch {
  $success = $false
  $err = $_
}
$sw.Stop()

if ($success) {
  Append-JsonLog @{
    timestamp=(Get-Date).ToString('o'); level='INFO'; module='gpt5-wrap'; action=$Code;
    outcome='SUCCESS'; durationMs=$sw.ElapsedMilliseconds; message=''
  }
  return
}

# ?? ?ㅽ뙣 由ы룷???묒꽦 ?????????????????????????????????????????????????????????
$batchId = Get-NextBatchId
$wd = (Get-Location).Path
$git = Get-GitSummary
$lines = ($buffer | ForEach-Object { $_ | Out-String }) -split "(`r`n|`n)"
$excerpt = ($lines | Select-Object -Last 30) -join "`r`n"
$msg = if ($err) { $err.Exception.Message } else { 'Unknown error' }
$cat = if ($CategoryHint) { $CategoryHint }
       elseif ($msg -match 'PRECONDITION') { 'PRECONDITION' }
       elseif ($msg -match 'CONFLICT|\.gpt5\.lock') { 'CONFLICT' }
       elseif ($msg -match 'timed out|timeout|network') { 'TRANSIENT' }
       else { 'LOGIC' }

$report = @"
[Batch Id]: $batchId
[Code]: $Code
[Outcome]: FAILED
[Category]: $cat
[Message]: $msg
[Excerpt]:
$excerpt
[WorkingDir]: $wd
[git status]: $($git.summary)
[Changed Files]: $(if ($git.changed.Count -gt 0) { ($git.changed -join '; ') } else { '(none)' })
"@

$path = Join-Path $env:HAN_GPT5_ROOT ("logs/error-reports/{0}.txt" -f $batchId)
New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null

# ?뚯씪 ???(UTF-8 no BOM)
try {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $report, $enc)
} catch {
  # ignore file write errors
}

# ?대┰蹂대뱶 ???(?섍꼍???곕씪 ?ㅽ뙣 媛??
try { Set-Clipboard -Value $report } catch { }

Append-JsonLog @{
  timestamp=(Get-Date).ToString('o'); level='ERROR'; module='gpt5-wrap'; action=$Code;
  outcome='FAILURE'; durationMs=$sw.ElapsedMilliseconds; errorCode=$msg; message=''
}

Write-Host ("`nERROR REPORT generated: " + $path + " (copied to clipboard if available)") -ForegroundColor Redexit 1