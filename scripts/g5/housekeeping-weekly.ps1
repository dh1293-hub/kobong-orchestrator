#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [int]$RotateMaxLines = 5000,
  [int]$RotateMaxSizeMB = 10
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# Resolve repo root (git → CWD → param)
$RepoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }

function Normalize-Path([string]$p) {
  $n=[IO.Path]::GetFullPath($p) -replace '/','\'
  if ($n[-1] -ne '\') { return $n } else { return $n.TrimEnd('\') }
}
$RepoRoot = Normalize-Path $RepoRoot

function Assert-InRepo([string]$Path) {
  $full = Normalize-Path (Resolve-Path -LiteralPath $Path).Path
  $root = (Normalize-Path $RepoRoot)
  $rootWithSep = $root + '\'
  if ($full.Length -lt $rootWithSep.Length -or -not $full.StartsWith($rootWithSep,[StringComparison]::OrdinalIgnoreCase)) {
    throw "Path not inside repo root: $full (RepoRoot=$root)"
  }
}

$trace=[guid]::NewGuid().ToString()
$sw=[Diagnostics.Stopwatch]::StartNew()
$LockFile = Join-Path $RepoRoot '.gpt5.lock'

try {
  if (Test-Path $LockFile) { throw 'CONFLICT: .gpt5.lock exists.' }
  "locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

  # 1) 회전: logs/apply-log.jsonl
  & pwsh -File (Join-Path $RepoRoot 'scripts/g5/rotate-apply-log.ps1') `
      -Root $RepoRoot -MaxLines $RotateMaxLines -MaxSizeMB $RotateMaxSizeMB @(@{ }[0]) 2>$null | Out-Null

  # 2) 조용한 브랜치 정리(있으면)
  $prune = Join-Path $RepoRoot 'scripts/g5/branch-prune-quiet.ps1'
  if (Test-Path $prune) {
    & pwsh -File $prune -Root $RepoRoot @(@{ }[0]) 2>$null | Out-Null
  }

  # 3) 로그로 기록 남기기
  $log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
  Assert-InRepo $log
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level='INFO'; traceId=$trace
    module='housekeeping-weekly'; action='run'; inputHash=''
    outcome=($(if($ConfirmApply){'APPLY'}else{'PREVIEW'})); durationMs=0; errorCode=''
    message="rotate=$RotateMaxLines/$RotateMaxSizeMB; prune=optional"
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}
finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}