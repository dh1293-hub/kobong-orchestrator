# APPLY IN SHELL
#requires -Version 7.0
param([string]$Repo="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",[switch]$ConfirmApply)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'; $PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function AtomicWrite([string]$Path,[string]$Content){
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  $ts=(Get-Date -Format 'yyyyMMdd-HHmmss'); $tmp="$Path.tmp"; $bak="$Path.bak-$ts"
  if (Test-Path $Path) { Copy-Item $Path $bak -Force }
  [IO.File]::WriteAllText($tmp,$Content,[Text.UTF8Encoding]::new($false)); Move-Item -Force $tmp $Path
}

# 1) Workflow 교체(명령+인자 파싱)
$wf = @'
name: ak-commands
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
permissions:
  contents: write
  pull-requests: write
  checks: write
  statuses: write
  issues: write
concurrency:
  group: ak-${{ github.event.pull_request.number || github.event.issue.number }}
  cancel-in-progress: true
jobs:
  run-ak:
    if: contains(github.event.comment.body, '/ak ')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Parse command and args
        id: parse
        shell: bash
        run: |
          BODY="${{ github.event.comment.body }}"
          # command (첫 단어)
          cmd=$(echo "$BODY" | sed -n 's/.*\/ak[[:space:]]\+\([a-z0-9-]\+\).*/\1/p')
          # rest args (명령 뒤 전체)
          rest=$(echo "$BODY" | sed -n 's/.*\/ak[[:space:]]\+[a-z0-9-]\+\s*\(.*\)$/\1/p')
          echo "cmd=$cmd"  >> $GITHUB_OUTPUT
          echo "arg=$rest" >> $GITHUB_OUTPUT
      - name: Dispatch (PS7)
        shell: pwsh
        run: |
          pwsh -NoLogo -NoProfile -File AUTO-Kobong/scripts/g5/ak-dispatch.ps1 `
            -Command "${{ steps.parse.outputs.cmd }}" `
            -Sha "${{ github.sha }}" `
            -Pr "${{ github.event.issue.number || github.event.pull_request.number }}" `
            -Arg "${{ steps.parse.outputs.arg }}"
'@

# 2) pre-commit 훅 (AK-LIVE 남으면 커밋 차단)
$hookPs1 = @'
#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ext = '\.(ts|tsx|js|jsx|py|java|md|ya?ml|json|ps1)$'
$exclude = @('node_modules','dist','build','coverage','.git','.venv','venv','out','target','bin','obj')

# 스테이지 파일
$files = git diff --cached --name-only --diff-filter=ACM 2>$null
if (-not $files) { exit 0 }
$bad=@()
foreach($f in $files){
  if ($exclude | Where-Object { $f -match "^(?:$_)/" }) { continue }
  if ($f -notmatch $ext) { continue }
  if (-not (Test-Path $f)) { continue }
  try {
    $t = Get-Content -Raw -Path $f -Encoding UTF8 -ErrorAction Stop
    if ($t -and $t.IndexOf('AK-LIVE-BEGIN',[System.StringComparison]::Ordinal) -ge 0) { $bad += $f }
  } catch { continue }
}
if ($bad.Count -gt 0) {
  Write-Host ""
  Write-Host "⛔ 커밋 중단: 코드 안에 AK-LIVE 블록이 남아 있습니다." -ForegroundColor Red
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
  Write-Host "→ 배포/머지 전에 AK-LIVE 블록을 제거한 뒤 다시 커밋하세요."
  exit 1
}
exit 0
'@

$hookSh = @'
#!/bin/sh
# Git hook: pre-commit → PS7 검사
exec pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$PWD/.githooks/pre-commit.ps1"
'@
$hookCmd = @'
@echo off
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%CD%\.githooks\pre-commit.ps1"
exit /b %ERRORLEVEL%
'@

# 적용(원자 교체)
$wfPath    = Join-Path $Repo ".github\workflows\ak-commands.yml"
$psHookDir = Join-Path $Repo ".githooks"
$psHook    = Join-Path $psHookDir "pre-commit.ps1"
$gitHook   = Join-Path $Repo ".git\hooks\pre-commit"
$gitHookCmd= Join-Path $Repo ".git\hooks\pre-commit.cmd"

if (-not $ConfirmApply){
  Write-Host "[PLAN] Would write:"
  Write-Host " - $wfPath"
  Write-Host " - $psHook"
  Write-Host " - $gitHook"
  Write-Host " - $gitHookCmd"
  exit 0
}

AtomicWrite -Path $wfPath     -Content $wf
New-Item -ItemType Directory -Force -Path $psHookDir | Out-Null
AtomicWrite -Path $psHook     -Content $hookPs1
AtomicWrite -Path $gitHook    -Content $hookSh
AtomicWrite -Path $gitHookCmd -Content $hookCmd
Write-Host "[APPLIED] workflow + pre-commit hook installed."
