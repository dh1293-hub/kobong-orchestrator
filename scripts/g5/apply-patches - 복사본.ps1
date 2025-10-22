#requires -Version 7.0
<#
  apply-patches.ps1 — 안정판(전자동)
  - 질문/옵션 없이 실행 → DRYRUN 내부검사 → 바로 APPLY
  - UI 파일 3종(AK7/GHMON/ORCHMON) 에 '센티넬+2줄 주입' 멱등 적용
  - 포트/프리픽스 고정: AK7 5181/5191, GHMON 5182/5199, ORCHMON 5183/5193
  - URS: .bak 스냅샷 + GOOD 슬롯(최신 파일 good-slot1 복사)
  - KLC v1.3 최소 1행 로그(traceId/durationMs/exitCode/anchorHash)
#>

[CmdletBinding()]
param(
  # DEV(기본) 또는 MOCK — 질문 없이 자동 적용
  [ValidateSet('DEV','MOCK')] [string] $Mode = 'DEV'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

function New-TraceId { ([guid]::NewGuid().ToString('N')).Substring(0,16) }
$traceId = New-TraceId
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 0) 루트/로그 디렉터리
$RepoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$RepoRoot = (Resolve-Path $RepoRoot).Path
$LogsDir = Join-Path $RepoRoot ".kobong\logs\ak"
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

# 1) 모듈 매트릭스(포트/프리픽스/브릿지명)
$Matrix = @(
  @{ Name='AK7';     Api='/api/ak7';     Dev=5181; Mock=5191; UiGlob='AUTO-Kobong-Monitoring\webui\*.html'; Bridge='ak7-bridge.js' },
  @{ Name='GHMON';   Api='/api/ghmon';   Dev=5182; Mock=5199; UiGlob='GitHub-Monitoring\webui\*.html';   Bridge='GitHub-Mon-bridge.js' },
  @{ Name='ORCHMON'; Api='/api/orchmon'; Dev=5183; Mock=5193; UiGlob='Orchestrator-Monitoring\webui\*.html'; Bridge='orchmon-bridge.js' }
)

$Changes = New-Object System.Collections.Generic.List[hashtable]

# 2) 각 UI HTML에 '센티넬+2줄' 멱등 주입/업데이트
foreach ($m in $Matrix) {
  $pattern = Join-Path $RepoRoot $m.UiGlob
  $files = Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    $html = Get-Content -Raw -Path $f.FullName
    $port = if ($Mode -eq 'DEV') { $m.Dev } else { $m.Mock }
    $base = "http://localhost:{0}{1}" -f $port, $m.Api

    # 브릿지 파일은 같은 webui 폴더 안에서 탐색해 상대경로로 연결
    $bridgePath = Join-Path $f.DirectoryName $m.Bridge
    $bridgeSrc  = if (Test-Path $bridgePath) { [IO.Path]::GetFileName($bridgePath) } else { $m.Bridge }

    # 모듈 소문자 키로 센티넬 고정
    $sentKey = $m.Name.ToLowerInvariant()
    $sentinel = "<!-- __G5_{0}_perma: do not remove -->" -f $sentKey
    $inject1  = "<script>window.{0}_MODE=""{1}"";window.{0}_BASE=""{2}"";</script>" -f $m.Name, $Mode, $base
    $inject2  = "<script src=""{0}"" defer></script>" -f $bridgeSrc

    $needWrite = $false
    $new = $html

    if ($html -notmatch [regex]::Escape($sentinel)) {
      if ($html -notmatch '</body>') { throw "No </body> tag in $($f.FullName)" }
      # DRYRUN 판단 완료 → APPLY (백업 후)
      Copy-Item $f.FullName "$($f.FullName).bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
      $new = $html -replace '</body>', ($sentinel + "`r`n" + $inject1 + "`r`n" + $inject2 + "`r`n</body>")
      $needWrite = $true
      $Changes.Add(@{file=$f.FullName; action='inject'; mode=$Mode; base=$base})
    }
    else {
      # 이미 센티넬 있음: BASE/MODE만 최신화
      $tmp = [regex]::Replace($new, "window\.$($m.Name)_MODE=""(DEV|MOCK)""", "window.$($m.Name)_MODE=""$Mode""")
      $tmp = [regex]::Replace($tmp,  "window\.$($m.Name)_BASE=""[^""]+""",    "window.$($m.Name)_BASE=""$base""")
      if ($tmp -ne $new) {
        Copy-Item $f.FullName "$($f.FullName).bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        $new = $tmp; $needWrite = $true
        $Changes.Add(@{file=$f.FullName; action='update'; mode=$Mode; base=$base})
      }
      # 브릿지 라인이 없다면 추가
      if ($new -notmatch [regex]::Escape($inject2)) {
        $new = $new -replace '</body>', ($inject2 + "`r`n</body>")
        $needWrite = $true
        $Changes.Add(@{file=$f.FullName; action='bridge-add'; mode=$Mode; base=$base})
      }
    }

    if ($needWrite) { Set-Content -Path $f.FullName -Value $new -NoNewline }
  }
}

# 3) GOOD 슬롯(최신본 복제) — 간단 회전(슬롯1만 유지)
$goodRoot = Join-Path $RepoRoot ".rollbacks\webui"
New-Item -ItemType Directory -Force -Path $goodRoot | Out-Null
foreach ($c in $Changes) {
  $leaf = (Split-Path $c.file -Leaf)
  Copy-Item $c.file (Join-Path $goodRoot "$leaf.good-slot1") -Force
}

# 4) KLC v1.3 로그 1행
$sw.Stop()
$canon = ($Changes | ConvertTo-Json -Depth 6)
$sha = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($canon))).ToLower()
$exit = if ($Changes.Count -gt 0) { 0 } else { 13 }  # 0=성공, 13=SKIP

$log = [ordered]@{
  version='1.3'
  timestamp=(Get-Date).ToString('o')
  traceId=$traceId
  message='apply-patches auto'
  outcome= if ($Changes.Count -gt 0) { 'SUCCESS' } else { 'SKIP' }
  hash=$sha; prevHash=''; hashAlgo='sha256'; canonAlgo='json.v1'
  env=$Mode; mode='APPLY'; service='apply-patches.ps1'
  exitCode=$exit; durationMs=[int]$sw.Elapsed.TotalMilliseconds; anchorHash=$sha
}
$logFile = Join-Path $LogsDir "run-$([DateTimeOffset]::Now.ToUnixTimeMilliseconds()).log"
$log | ConvertTo-Json -Depth 5 | Out-File -FilePath $logFile

Write-Host ("[apply-patches] exit={0}, changed={1}, log={2}" -f $exit, $Changes.Count, $logFile)
exit $exit
