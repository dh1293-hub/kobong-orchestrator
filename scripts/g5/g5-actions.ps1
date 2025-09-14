#requires -Version 7.0
param([switch]$OneLine,[int]$SinceMinutes=240,[int]$Top=3)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot {
  param([string]$Fallback)
  $here = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($here)) {
    try { $here = Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue } catch {}
  }
  if ([string]::IsNullOrWhiteSpace($here)) { $here = (Get-Location).Path }
  $top = $null
  try { $top = (git -C $here rev-parse --show-toplevel 2>$null) } catch {}
  if ([string]::IsNullOrWhiteSpace($top)) {
    try { $top = (Resolve-Path (Join-Path $here '..\..')).Path } catch {}
  }
  if ([string]::IsNullOrWhiteSpace($top)) { $top = $Fallback }
  return $top
}

$RepoRoot = Get-RepoRoot $env:KOBONG_REPO_ROOT
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { $RepoRoot = (Get-Location).Path }

$Jsonl = Join-Path $RepoRoot 'logs\apply-log.jsonl'

function Short([string]$s,[int]$n=160){
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $t = ($s -replace '\s+',' ').Trim()
  if ($t.Length -le $n) { return $t } else { return $t.Substring(0,$n) + '…' }
}
function Norm([string]$s){
  if ($null -eq $s) { return '' }
  $t = $s.ToLowerInvariant()
  $t = $t -replace '(?i)\b[a-z]:\\[^\s\|\r\n:]+' , '<path>'
  $t = $t -replace '(?i)<path>:\d+', '<path>:<n>'
  $t = $t -replace '(?i)\bline\s*\|\s*\d+','line|<n>'
  $t = $t -replace '(?i)line\s+\d+','line <n>'
  $t = $t -replace '위치\s*줄:\s*\d+','위치 줄:<n>'
  $t = $t -replace '문자:\s*\d+','문자:<n>'
  $t = $t -replace '\b[0-9a-f]{8,}\b','<hex>'
  $t = $t -replace '\d{4}-\d{2}-\d{2}[t\s]\d{2}:\d{2}:\d{2}(\.\d+)?(z|[+\-]\d{2}:\d{2})?','<ts>'
  $t = $t -replace '\s+',' '
  $t.Trim()
}
function TryParseIso([string]$s){ try { [datetime]::Parse($s) } catch { $null } }
function FirstProp([object]$o,[string[]]$names){
  foreach($n in $names){ if ($o -and $o.PSObject.Properties[$n]) { $v=$o.$n; if ($null -ne $v -and (''+$v)) { return (''+$v) } } }
  ''
}

# 최근 로그 수집
$cut = (Get-Date).AddMinutes(-$SinceMinutes)
$recs=@()
if (Test-Path $Jsonl) {
  foreach($line in (Get-Content -Path $Jsonl)){
    $o=$null; try { $o=$line|ConvertFrom-Json } catch { $o=$null }
    if ($null -eq $o) { continue }
    $tt = if ($o.PSObject.Properties['timestamp']) { TryParseIso (''+$o.timestamp) } else { $null }
    if ($tt -and $tt -lt $cut) { continue }
    $recs+= $o
  }
}

# 에러 버킷팅
$bucket=@{}; $lastErr=$null
foreach($r in $recs){
  $lv = (FirstProp $r @('level')).ToUpperInvariant()
  $oc = (FirstProp $r @('outcome')).ToUpperInvariant()
  $isErr = ($lv -like '*ERROR*') -or ($oc -like '*FAIL*')
  if (-not $isErr) { continue }
  $lastErr = $r
  $code = FirstProp $r @('error','errorCode','category','code'); if (-not $code) { $code = $lv -like '*ERROR*' ? 'ERROR' : 'FAILURE' }
  $msg  = FirstProp $r @('message','msg','detail','errorMessage','exception')
  $sig  = Norm $msg
  $key="$code :: $sig"
  if (-not $bucket.ContainsKey($key)) { $bucket[$key]=[pscustomobject]@{code=$code; sig=$sig; n=0; sample=$msg} }
  $bucket[$key].n = [int]$bucket[$key].n + 1
  if ($msg) { $bucket[$key].sample = $msg }
}

$topList = ($bucket.Values | Sort-Object -Property n -Descending | Select-Object -First $Top)

# 권고 액션
function Recommend([string]$code,[string]$sig){
  $sig = ($sig ?? '').ToLowerInvariant()
  switch -Regex ($code) {
    'PRECONDITION' {
      if ($sig -like '*uncommitted changes*' -or $sig -like '*commit/stash*') {
        return 'git 상태 정리: git status → git add -A; git commit -m ''wip''  (또는) git stash -u'
      }
      '사전조건 점검: 입력/경로/권한 확인'
    }
    'LOGIC' {
      if ($sig -like '*cannot call method on a null*' -or $sig -like '*null*메서드*호출*') {
        return 'NPE 가드: if ($x) {...} else { Write-Host "[ERR] $x is null" }'
      }
      '로직 점검: 변수/속성 존재 여부 확인 및 null-check 추가'
    }
    'ERROR' { '에러 코드·환경 점검: PS7 사용, 경로 따옴표, $LASTEXITCODE 접근 전 초기화' }
    default { '일반 점검: 최신 stderr 20줄 확인 → scripts/g5/next-stderr.ps1' }
  }
}

# 출력
$repo = Split-Path $RepoRoot -Leaf
$sha='unknown'; try { $sh=(git -C $RepoRoot rev-parse --short HEAD 2>$null); if ($sh){ $sha=$sh.Trim() } } catch {}
$now=(Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')

if ($OneLine) {
  if ($topList.Count -eq 0) { Write-Host ("G5RECO v1 | repo={0}@{1} | time={2} | ok=no-errors" -f $repo,$sha,$now); exit 0 }
  $t=$topList[0]
  $tip = Recommend $t.code $t.sig
  Write-Host ("G5RECO v1 | repo={0}@{1} | time={2} | cause=[{3}] {4} | do={5}" -f $repo,$sha,$now,$t.code,(Short $t.sample 100), (Short $tip 110))
  exit 0
}

Write-Host "== G5/RECO v1 ==" -ForegroundColor Magenta
if ($topList.Count -eq 0) { Write-Host ("{0}@{1} :: 최근 {2}분 에러 없음" -f $repo,$sha,$SinceMinutes); exit 0 }
$k=1
foreach($t in $topList){
  $tip = Recommend $t.code $t.sig
  Write-Host ("[{0}] [{1}] x{2} :: {3}" -f $k,$t.code,[int]$t.n,(Short $t.sample 140)) -ForegroundColor DarkYellow
  Write-Host ("    → {0}" -f $tip)
  $k++
}