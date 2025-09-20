#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-HasProp([object]$o, [string]$name){
  return $null -ne $o -and $o.PSObject -and $o.PSObject.Properties.Match($name).Count -gt 0
}
function Read-JsonLines([string]$path){
  if(-not (Test-Path $path)){ return @() }
  $out=@()
  Get-Content -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_.Trim()
    if(-not $line){ return }
    try{
      $obj = $line | ConvertFrom-Json -ErrorAction Stop
      if($obj){ $out += $obj }
    }catch{ } # JSON 한 줄이 아닐 수 있음 → 무시
  }
  return $out
}

$repo = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator'

# 후보 로그들(존재하는 것만 사용) + 최신 *.log 몇 개
$candidates = @(
  Join-Path $repo '_gpt5.apply.log'),
  Join-Path $repo 'apply.log',
  Join-Path $repo 'scripts\g5\g5-apply.log'
) | Where-Object { $_ -and (Test-Path $_) }

if(-not $candidates){
  $candidates = Get-ChildItem $repo -Recurse -Filter *.log -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object { $_.FullName }
}

$entries = @()
foreach($f in $candidates){ $entries += Read-JsonLines $f }

# outcome 있는 항목만 집계
$withOutcome = $entries | Where-Object { Test-HasProp $_ 'outcome' }

$successSet = @('APPLIED','SUCCESS','done')
$failSet    = @('FAILED','ERROR')

$stats = [pscustomobject]@{
  Files       = $candidates
  Total       = $withOutcome.Count
  Success     = (@($withOutcome | Where-Object { $_.outcome -in $successSet })).Count
  Failed      = (@($withOutcome | Where-Object { $_.outcome -in $failSet    })).Count
  NotApplied  = (@($withOutcome | Where-Object { $_.outcome -eq 'NOT_APPLIED' })).Count
}

Write-Host "== APPLY LOG SUMMARY ==" -ForegroundColor Cyan
$stats | Format-List

Write-Host "`n== RECENT ENTRIES ==" -ForegroundColor Cyan
$entries |
  Sort-Object { if(Test-HasProp $_ 'timestamp'){[datetime]$_.timestamp}else{[datetime]'1970-01-01'} } -Descending |
  Select-Object -First 30 |
  Select-Object timestamp, level, module, action, outcome, message |
  Format-Table -AutoSize
