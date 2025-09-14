#requires -Version 7.0
<#
 G5/HOTLIST — 최근 윈도우에서 에러를 정규화/집계하여 상위 N개만 출력
 콘솔-only 핸드오프용 (파일 첨부 불요)
#>
param(
  [int]$SinceMinutes = 120,
  [int]$Top = 5,
  [switch]$OneLine
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Jsonl    = Join-Path $RepoRoot 'logs\apply-log.jsonl'

function Short([string]$s,[int]$n=120){
  if ([string]::IsNullOrWhiteSpace($s)) { return '' }
  $t = ($s -replace '\s+',' ').Trim()
  if ($t.Length -le $n) { return $t }
  return $t.Substring(0,$n) + '…'
}
function SafeJson([string]$line){ try { $line | ConvertFrom-Json } catch { $null } }
function TryIso([string]$s){ try { [datetime]::Parse($s) } catch { $null } }
function Norm([string]$s){
  if ($null -eq $s) { return '' }
  $x = ($s -replace '\s+',' ')         # 공백 정규화
  $x = ($x -replace '(?i)\bline\s*\d+\b','line N') # 라인번호 무시
  $x = ($x -replace '(?i)\b\d{4}-\d{2}-\d{2}T?\d{2}:\d{2}:\d{2}\S*','<ts>') # 타임스탬프 무시
  $x.Trim()
}

$cut = (Get-Date).AddMinutes(-$SinceMinutes)
$errs = @()
if (Test-Path $Jsonl) {
  foreach($line in (Get-Content -Path $Jsonl)) {
    $o = SafeJson $line
    if ($null -eq $o) { continue }
    $t = $null; if ($o.PSObject.Properties['timestamp']) { $t = TryIso $o.timestamp }
    if ($t -and $t -lt $cut) { continue }
    $lvl = ([string]$o.level).ToUpperInvariant()
    $out = ([string]$o.outcome).ToUpperInvariant()
    if ($lvl -match 'ERROR' -or $out -match 'FAIL') {
      $errs += $o
    }
  }
}

# 버스트 억제: 너무 많으면 최근 1000건만
if ($errs.Count -gt 1000) { $errs = $errs | Select-Object -Last 1000 }

# 시그니처 = [코드]|정규화된메시지
$bucket = @{}
foreach($e in $errs){
  $code = ''; $msg = ''
  if ($e.PSObject.Properties['error'])   { $code = [string]$e.error }
  if ($e.PSObject.Properties['message']) { $msg  = [string]$e.message }
  $sig = ("[{0}] {1}" -f ($code.ToUpperInvariant()), (Norm $msg))
  if ($bucket.ContainsKey($sig)) { $bucket[$sig]++ } else { $bucket[$sig]=1 }
}

# 상위 Top
$top = $bucket.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top

if ($OneLine) {
  $pairs = @()
  foreach($it in $top){ $pairs += ("{0} (x{1})" -f (Short $it.Key 60), $it.Value) }
  if (-not $pairs) { Write-Host "G5HOT v1 | none" }
  else { Write-Host ("G5HOT v1 | " + ([string]::Join(' | ', $pairs))) }
} else {
  Write-Host "== G5/HOTLIST v1 ==" -ForegroundColor Magenta
  if (-not $top) { Write-Host "(no errors in window)"; exit 0 }
  $i=1
  foreach($it in $top){
    Write-Host ("{0}. {1}  —  x{2}" -f $i, (Short $it.Key 200), $it.Value)
    $i++
  }
  Write-Host "Tip: 필요 시  stderr 20줄 →  pwsh -File `"$($PSScriptRoot)\next-stderr.ps1`""
}