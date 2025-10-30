# 파일: scripts/g5/ak-dispatch.ps1
# 목적:
#   AK 디스패처. GitHub Actions에서 수동(workflow_dispatch) 호출로
#   /ak scan | /ak test | /ak rewrite | /ak fix | /ak help 를 실행.
#   - scan   : .github/workflows/*.yml 에서 흔한 오류 패턴을 탐지(읽기 전용)
#   - test   : scan과 동일하되 경고도 실패로 간주(엄격 모드)
#   - rewrite: 안전한 멱등 자동 수선(… 제거, 잘못된 top-level 대시 교정 등)
#   - fix    : rewrite 후 재스캔, 남은 문제 있으면 실패
# 산출물:
#   - 콘솔 요약 + 상세 목록
#   - _deploy/logs/ak-dispatch-YYYYMMDD_HHMMSS.log (실행 로그)
#   - KLC 1행 로그: KLC|ak-dispatch|cmd=...|ok=..|warn=..|fail=..|sha=...|run=...|attempt=...
# 연관:
#   - .github/workflows/ak-dispatch.yml (이 스크립트를 호출)
#   - .github/workflows/*.yml (점검/수정 대상)
# 사용:
#   pwsh -NoProfile -File scripts/g5/ak-dispatch.ps1 -Command "/ak scan"  [-Pr 579] [-Sha <sha>]
#   pwsh -NoProfile -File scripts/g5/ak-dispatch.ps1 -Command "/ak rewrite"
# 테스트:
#   - 로컬에서 실행해 $LASTEXITCODE로 성공/실패 확인
#   - 의도적으로 .yml에 '...' 한 줄을 넣어 재현 가능

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Command,
  [string]$Pr,
  [string]$Sha
)

$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'

# 로그 준비
$logRoot = Join-Path -Path (Resolve-Path '.').Path -ChildPath '_deploy/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$ts     = Get-Date -Format 'yyyyMMdd_HHmmss'
$log    = Join-Path $logRoot "ak-dispatch-$ts.log"

# 단순 로거 (콘솔+파일)
function Write-Log {
  param([string]$Message)
  $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Message
  Write-Host $line
  Add-Content -Path $log -Value $line
}
Write-Log "== ak-dispatch start: Command='$Command' Pr='$Pr' Sha='$Sha'"

# 결과 집계
$issues = New-Object System.Collections.Generic.List[psobject]
function Add-Issue { param([string]$File,[string]$Rule,[string]$Level,[string]$Message,[int]$Line=0)
  $issues.Add([pscustomobject]@{File=$File; Rule=$Rule; Level=$Level; Message=$Message; Line=$Line})
}

# 스캔 타깃 가져오기
function Get-WorkflowFiles {
  if (-not (Test-Path '.github/workflows')) { return @() }
  Get-ChildItem '.github/workflows' -Recurse -Include *.yml,*.yaml -File
}

# 규칙 1: 단독 '...' 또는 유니코드 '…' 라인 금지
function Rule-Ellipsis {
  param([string[]]$Lines,[string]$Path)
  for ($i=0; $i -lt $Lines.Count; $i++) {
    $t = $Lines[$i].Trim()
    if ($t -eq '...' -or $t -eq '…') {
      Add-Issue -File $Path -Rule 'ellipsis-line' -Level 'FAIL' -Message "Standalone ellipsis line" -Line ($i+1)
    }
  }
}

# 규칙 2: 최상위에서 '- permissions:' / '- concurrency:' 사용 금지
function Rule-TopDashKeys {
  param([string[]]$Lines,[string]$Path)
  for ($i=0; $i -lt $Lines.Count; $i++) {
    $m = [regex]::Match($Lines[$i], '^[ ]*-[ ]*(permissions|concurrency)\s*:')
    if ($m.Success -and ($Lines[$i] -notmatch '^\s{2,}')) {
      Add-Issue -File $Path -Rule 'top-level-dash' -Level 'FAIL' -Message "Top-level key must not start with '- '" -Line ($i+1)
    }
  }
}

# 규칙 3: step 블록(- name:)에 uses/run 둘 다 없는 경우
function Rule-StepNeedsUsesOrRun {
  param([string[]]$Lines,[string]$Path)
  # 매우 단순한 상태기계 (들여쓰기 기반 휴리스틱)
  $idx = 0
  while ($idx -lt $Lines.Count) {
    if ($Lines[$idx] -match '^\s*-\s*name\s*:\s*(.+)') {
      $start = $idx; $name = $Matches[1].Trim()
      $idx++
      $hasUses = $false; $hasRun=$false
      while ($idx -lt $Lines.Count -and ($Lines[$idx] -notmatch '^\s*-\s*name\s*:')) {
        if ($Lines[$idx] -match '^\s*uses\s*:') { $hasUses = $true }
        if ($Lines[$idx] -match '^\s*run\s*:')  { $hasRun  = $true }
        # step 끝 휴리스틱: 빈 줄 여러 개/다음 job/top-level 키를 만나면 중단
        if ($Lines[$idx] -match '^[a-zA-Z_]+\s*:') { break }
        $idx++
      }
      if (-not ($hasUses -or $hasRun)) {
        Add-Issue -File $Path -Rule 'step-missing-uses-or-run' -Level 'FAIL' -Message "Step has no 'uses' or 'run' (name=$name)" -Line ($start+1)
      }
    } else {
      $idx++
    }
  }
}

# 안전 수선(rewrite) — 멱등/보수적
function Apply-Rewrite {
  param([string]$Path)
  $orig = Get-Content -Path $Path -Raw
  $lines = $orig -split "`r?`n", 0

  $changed = $false
  $out = New-Object System.Collections.Generic.List[string]

  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    # 1) 단독 ellipsis 제거
    if ($line.Trim() -in @('...', '…')) { $changed = $true; continue }

    # 2) top-level '- permissions:' / '- concurrency:' 교정
    if ($line -match '^[ ]*-[ ]*(permissions|concurrency)\s*:\s*$' -and ($line -notmatch '^\s{2,}')) {
      $fixed = $line -replace '^[ ]*-[ ]*', ''
      $out.Add($fixed); $changed = $true; continue
    }

    $out.Add($line)
  }

  # 3) step(- name:)에 uses/run 모두 없으면 경고 주석 삽입(자동 수정 대신 표시)
  $lines2 = $out
  $out = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines2.Count; $i++) {
    $line = $lines2[$i]
    $out.Add($line)
    if ($line -match '^\s*-\s*name\s*:\s*(.+)') {
      $j = $i+1; $hasUses=$false; $hasRun=$false
      while ($j -lt $lines2.Count -and ($lines2[$j] -notmatch '^\s*-\s*name\s*:')) {
        if ($lines2[$j] -match '^\s*uses\s*:') { $hasUses=$true }
        if ($lines2[$j] -match '^\s*run\s*:')  { $hasRun=$true  }
        if ($lines2[$j] -match '^[a-zA-Z_]+\s*:') { break }
        $j++
      }
      if (-not ($hasUses -or $hasRun)) {
        $out.Add("  # TODO: step has no 'uses' or 'run' (auto-note by ak-dispatch)")
        $changed = $true
      }
    }
  }

  if ($changed) {
    $bak = "$Path.bak"
    Set-Content -Path $bak -Value $orig -Encoding UTF8
    Set-Content -Path $Path -Value ($out -join "`n") -Encoding UTF8
  }
  return $changed
}

# 스캔 실행
function Invoke-Scan {
  $files = Get-WorkflowFiles
  if (-not $files) { Write-Log "No workflow files found."; return }

  foreach ($f in $files) {
    $lines = Get-Content -Path $f.FullName
    Rule-Ellipsis -Lines $lines -Path $f.FullName
    Rule-TopDashKeys -Lines $lines -Path $f.FullName
    Rule-StepNeedsUsesOrRun -Lines $lines -Path $f.FullName
  }
}

# 결과 출력/종료코드
function Finish-And-Exit {
  param([string]$Cmd,[switch]$StrictMode)

  $ok   = 0
  $warn = ($issues | ? Level -eq 'WARN').Count
  $fail = ($issues | ? Level -eq 'FAIL').Count
  $tot  = $issues.Count

  if ($tot -gt 0) {
    Write-Host ""
    Write-Host "== Issues ($tot) ======================================================"
    $issues | Sort-Object File, Line | Format-Table File, Line, Level, Rule, Message -AutoSize | Out-String | Write-Host
  } else {
    Write-Log "No issues found."
  }

  # KLC 1행
  $sha = if ($Sha) { $Sha } elseif ($env:GITHUB_SHA) { $env:GITHUB_SHA } else { '' }
  $run = $env:GITHUB_RUN_ID
  $att = $env:GITHUB_RUN_ATTEMPT
  $klc = "KLC|ak-dispatch|cmd={0}|ok={1}|warn={2}|fail={3}|sha={4}|run={5}|attempt={6}" -f $Cmd,$ok,$warn,$fail,$sha,$run,$att
  Write-Host $klc
  Add-Content -Path $log -Value $klc

  if ($fail -gt 0) { exit 1 }
  if ($StrictMode.IsPresent -and $warn -gt 0) { exit 1 }
  exit 0
}

# 메인
switch ($Command.Trim().ToLower()) {
  '/ak help' {
    @"
AK Dispatch Help
  /ak scan     : 워크플로 YAML 검사(읽기 전용)
  /ak test     : scan과 동일하되 경고도 실패 처리(엄격)
  /ak rewrite  : 안전한 멱등 자동 수선(… 제거, 잘못된 '- permissions|concurrency:' 교정, step 경고 주석)
  /ak fix      : rewrite 후 재스캔, 남은 문제 있으면 실패
"@ | Write-Host
    exit 0
  }

  '/ak scan' {
    Write-Log "SCAN: begin"
    Invoke-Scan
    Write-Log "SCAN: end"
    Finish-And-Exit -Cmd 'scan'
  }

  '/ak test' {
    Write-Log "TEST: begin (strict)"
    Invoke-Scan
    Write-Log "TEST: end"
    Finish-And-Exit -Cmd 'test' -StrictMode
  }

  '/ak rewrite' {
    Write-Log "REWRITE: begin"
    $files = Get-WorkflowFiles
    $changedTotal = 0
    foreach ($f in $files) {
      $changed = Apply-Rewrite -Path $f.FullName
      if ($changed) {
        $changedTotal++
        Write-Log ("Rewrote: {0}" -f $f.FullName)
      }
    }
    # rewrite 후 경고/실패 다시 산출을 위해 스캔
    Invoke-Scan
    Write-Log ("REWRITE: end (files changed={0})" -f $changedTotal)
    Finish-And-Exit -Cmd 'rewrite'
  }

  '/ak fix' {
    Write-Log "FIX: begin"
    $files = Get-WorkflowFiles
    $changedTotal = 0
    foreach ($f in $files) {
      $changed = Apply-Rewrite -Path $f.FullName
      if ($changed) {
        $changedTotal++
        Write-Log ("Rewrote: {0}" -f $f.FullName)
      }
    }
    Invoke-Scan
    Write-Log ("FIX: end (files changed={0})" -f $changedTotal)
    Finish-And-Exit -Cmd 'fix' -StrictMode    # fix는 엄격 모드로 실패 판단
  }

  default {
    Write-Error "Unknown command: $Command  (use /ak help)"
    exit 2
  }
}
