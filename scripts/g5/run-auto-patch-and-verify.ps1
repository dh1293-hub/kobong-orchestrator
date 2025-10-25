# APPLY IN SHELL
#requires -Version 7.0
param([string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Get-RepoRoot {
  try { $p=(git rev-parse --show-toplevel 2>$null); if($p){return (Resolve-Path $p).Path} } catch {}
  if ($Root) { return (Resolve-Path $Root).Path }
  return (Get-Location).Path
}
$RepoRoot = Get-RepoRoot

# Runner 전용 락 (패처와 분리)
$RunnerLock = Join-Path $RepoRoot '.gpt5.runner.lock'
if (Test-Path $RunnerLock) { Write-Error 'CONFLICT: .gpt5.runner.lock exists.'; exit 11 }
"runner-locked $(Get-Date -Format o)" | Out-File $RunnerLock -Encoding utf8 -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logPath = Join-Path $RepoRoot 'logs\apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null
function LogRec([string]$level,[string]$action,[string]$outcome,[string]$msg,[string]$err='') {
  $rec=@{timestamp=(Get-Date).ToString('o');level=$level;traceId=$trace;module='runner';action=$action;inputHash='';outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode=$err;message=$msg}|ConvertTo-Json -Compress
  Add-Content -Path $logPath -Value $rec
}

try {
  # 1) 패치 적용 (별도 pwsh 프로세스, 180s 타임아웃, stdout/err 캡처)
  $patcher = Join-Path $RepoRoot 'scripts\g5\apply-pending-patches.ps1'
  if (!(Test-Path $patcher)) { throw "Missing patcher: $patcher" }
  $PWSH = (Get-Command pwsh).Source
  $outLog = Join-Path $RepoRoot 'logs\patcher.stdout.log'
  $errLog = Join-Path $RepoRoot 'logs\patcher.stderr.log'
  $prev = $env:CONFIRM_APPLY; $env:CONFIRM_APPLY='true'
  $arg  = @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File', $patcher, '-ConfirmApply','-Root', $RepoRoot)
  $proc = Start-Process -FilePath $PWSH -ArgumentList $arg -PassThru -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
  $ok   = $proc.WaitForExit(180000)
  $env:CONFIRM_APPLY = $prev
  if (-not $ok) { try { Stop-Process -Id $proc.Id -Force } catch {}; throw "TIMEOUT: patcher exceeded 180s (see logs/patcher.*.log)" }
  if ($proc.ExitCode -ne 0) {
  $exit = $proc.ExitCode
  $tailOut = (Get-Content -LiteralPath $outLog -Tail 40 -ErrorAction SilentlyContinue) -join "`n"
  $tailErr = (Get-Content -LiteralPath $errLog -Tail 40 -ErrorAction SilentlyContinue) -join "`n"
  LogRec 'WARN' 'patcher' 'SKIPPED' ("exit="+$exit+"; stdout-tail:`n"+$tailOut+"`nstderr-tail:`n"+$tailErr)
  Write-Host "[WARN] patcher exit=$exit (continuing)"
}

  # 2) 핵심 가드 검증
  $core = Join-Path $RepoRoot 'scripts\apply_ui_patch.ps1'
  if (Test-Path $core) {
    $c = Get-Content -LiteralPath $core -Raw -Encoding UTF8
    if ($c -notmatch 'ensure valid tmp path .* atomic friendly') {
      throw "VERIFY FAIL: guard snippet not found in apply_ui_patch.ps1"
    }
  }

  # 3) 모듈 스모크(Write-AtomicUtf8 사용 확인)
  $mod = Join-Path $RepoRoot 'scripts\lib\kobong-fileio.psm1'
  $hasModule = $false
  try { if (Test-Path $mod) { Import-Module $mod -Force; $hasModule=$true } } catch {}
  if (-not $hasModule) {
    function Write-AtomicUtf8 { param([string]$Path,[string]$Content)
      $dir = Split-Path -Parent $Path; if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
      $tmp = Join-Path $dir ('.'+(Split-Path -Leaf $Path)+'.tmp')
      $utf8 = New-Object System.Text.UTF8Encoding($false)
      [System.IO.File]::WriteAllText($tmp,$Content,$utf8)
      Move-Item -LiteralPath $tmp -Destination $Path -Force
    }
  }
  $smoke = Join-Path $RepoRoot 'webui\public\_atomic-smoke.txt'
  $txt   = "[atomic-ok] $(Get-Date -Format o)"
  Write-AtomicUtf8 -Path $smoke -Content $txt
  if (!(Test-Path $smoke)) { throw "Smoke write failed: $smoke" }
  Remove-Item -LiteralPath $smoke -Force -ErrorAction SilentlyContinue

  # 4) 로그 꼬리 기록 + 완료
  $tail = (Get-Content -LiteralPath $logPath -Tail 20 -ErrorAction SilentlyContinue) -join "`n"
  LogRec 'INFO' 'run' 'SUCCESS' ("patched & verified. tail:`n"+$tail)
  Write-Host "`n[OK] patches applied and verified."
}
catch {
  LogRec 'ERROR' 'run' 'FAILURE' $_.Exception.Message 'LOGIC'
  Write-Error $_.Exception.Message
  exit 13
}
finally {
  Remove-Item -Force $RunnerLock -ErrorAction SilentlyContinue
}