<# =====================================================================
  파일: scripts/g5/apply-patches.ps1
  목적: manifest 기반 패치를 DryRun/Apply로 실행하고
        콘솔·JSONL 로그를 남기는 표준 운용 스크립트
  사용법(로컬):
    # DryRun (종료코드 11)
    pwsh -NoProfile -File scripts/g5/apply-patches.ps1 -DryRun `
      -Root . -Manifest patches/manifest.json `
      -OutText .ak-out.txt -OutJson logs/ak7.jsonl

    # Apply (종료코드 0)
    pwsh -NoProfile -File scripts/g5/apply-patches.ps1 `
      -Root . -Manifest patches/manifest.json `
      -OutText .ak-out.txt -OutJson logs/ak7.jsonl

  CI(GitHub Actions) 자동 보호:
    - CI에서는 .ak-out.txt에 직접 쓰지 않음(콘솔만 출력).
      => 워크플로의 Tee-Object가 파일을 "단독"으로 잡음 → 잠금 충돌 제거.
    - 별도 설정 불필요. (AK_TEE=1 있으면 동일하게 우선 적용)

  종료코드:
    0  = Apply 성공
    11 = DryRun 정상 종료
    1  = 일반 오류

  연관 파일:
    - .github/workflows/ak-apply.yml (이 스크립트를 호출)
    - patches/manifest.json         (패치 정의)
    - logs/ak7.jsonl                (JSON Lines; 분석/보관)

  테스트:
    1) CI에서 재실행 → .ak-out.txt 잠금 오류가 사라져야 함.
    2) 로컬 단독 실행 시 .ak-out.txt/ak7.jsonl 생성 확인.
===================================================================== #>

param(
  [string]$Root = ".",
  [string]$Manifest = "patches/manifest.json",
  [string]$OutText = ".ak-out.txt",
  [string]$OutJson = "logs/ak7.jsonl",
  [switch]$DryRun,
  [switch]$Quiet
)

# ===== 런타임 가드 =====
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'Ansi'

# CI 여부 및 OutText 비활성화 플래그(자체 방어)
$IsCI = ($env:GITHUB_ACTIONS -eq 'true')
# 아래 조건 중 하나라도 true면 OutText 파일 기록 금지:
#  - AK_TEE=1 (워크플로가 Tee-Object로 파일 전담)
#  - CI(GitHub Actions)에서 실행
#  - 대상 파일명이 .ak-out.txt (충돌 위험 높은 표준 파일)
$DisableOutText = ($env:AK_TEE -eq '1') -or $IsCI -or ($OutText -match '\.ak-out\.txt$')

# CI 힌트(있으면 로그에 싣기)
$TARGET_CMD = $env:TARGET_CMD
$TARGET_REF = $env:TARGET_REF

# ===== 안전 Append 유틸(파일공유 허용 + 재시도) =====
function Append-SafeLine {
  param([string]$Path, [string]$Line)

  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  $enc = [System.Text.UTF8Encoding]::new($false)  # UTF-8 (BOM 없음)
  for ($i=0; $i -lt 20; $i++) {
    try {
      # 공유 모드: ReadWrite → 동시 읽기/쓰기 허용
      $fs = [System.IO.File]::Open($Path,
        [System.IO.FileMode]::Append,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::ReadWrite)
      $sw = [System.IO.StreamWriter]::new($fs, $enc)
      $sw.WriteLine($Line)
      $sw.Dispose(); $fs.Dispose()
      return
    } catch {
      Start-Sleep -Milliseconds (50 * [Math]::Min($i+1,10))
      if ($i -eq 19) { throw }
    }
  }
}

# ===== 로깅 =====
function Write-Text([string]$s) {
  if (-not $Quiet) { Write-Host $s }
  # ⚠️ 충돌 방지: CI / AK_TEE=1 / .ak-out.txt 지정 시 파일 기록 금지
  if ($DisableOutText) { return }
  Append-SafeLine -Path $OutText -Line $s
}

function Write-JsonLog {
  param(
    [string]$Event,
    [string]$Message,
    [int]$ExitCode = 0,
    [hashtable]$Data
  )
  $obj = [pscustomobject]@{
    ts       = (Get-Date -AsUtc -Format o)
    event    = $Event
    message  = $Message
    exitCode = $ExitCode
    data     = $Data
  }
  $line = $obj | ConvertTo-Json -Compress
  # JSONL은 동시 사용률 낮고 충돌 리스크 낮음 → 계속 파일로 남김
  Append-SafeLine -Path $OutJson -Line $line
  if (-not $Quiet) { Write-Host $line }
}

# ===== 보조 유틸 =====
function Read-Json([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $txt = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
  if ([string]::IsNullOrWhiteSpace($txt)) { return $null }
  return $txt | ConvertFrom-Json -ErrorAction Stop
}

function Ensure-Dir([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return }
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

# ===== 패치 실행기(샘플 오퍼레이션 4종) =====
function Apply-Op {
  param(
    [hashtable]$op,
    [switch]$DryRun
  )
  $type = $op.type
  switch ($type) {
    'touch' {
      $p = Join-Path $Root $op.path
      if ($DryRun) {
        Write-Text "DRYRUN: touch $($op.path)"
      } else {
        Ensure-Dir (Split-Path -Parent $p)
        if (-not (Test-Path -LiteralPath $p)) {
          Set-Content -LiteralPath $p -Value '' -Encoding UTF8
        }
        Write-Text "touch OK: $($op.path)"
      }
    }

    'writeFile' {
      $p = Join-Path $Root $op.path
      $content = [string]$op.content
      if ($DryRun) {
        Write-Text "DRYRUN: writeFile $($op.path) (len=$($content.Length))"
      } else {
        Ensure-Dir (Split-Path -Parent $p)
        Set-Content -LiteralPath $p -Value $content -Encoding UTF8
        Write-Text "writeFile OK: $($op.path)"
      }
    }

    'copy' {
      $src = Join-Path $Root $op.from
      $dst = Join-Path $Root $op.to
      if ($DryRun) {
        Write-Text "DRYRUN: copy $($op.from) -> $($op.to)"
      } else {
        Ensure-Dir (Split-Path -Parent $dst)
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Text "copy OK: $($op.from) -> $($op.to)"
      }
    }

    'replaceText' {
      $p = Join-Path $Root $op.path
      $find = [string]$op.find
      $repl = [string]$op.replace
      $raw  = Get-Content -LiteralPath $p -Raw -Encoding UTF8
      $new  = $raw -replace [regex]::Escape($find), [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $repl }
      if ($DryRun) {
        $changed = [int]($raw -ne $new)
        Write-Text "DRYRUN: replaceText $($op.path) changed=$changed"
      } else {
        Set-Content -LiteralPath $p -Value $new -Encoding UTF8
        Write-Text "replaceText OK: $($op.path)"
      }
    }

    default {
      throw "지원하지 않는 op.type: $type"
    }
  }
}

# ===== 메인 =====
try {
  Write-Text  "== apply-patches.ps1 start (DryRun=$DryRun; CI=$IsCI; AK_TEE=$($env:AK_TEE)) =="
  Write-JsonLog -Event 'start' -Message 'apply-patches start' -Data @{
    root = (Resolve-Path $Root).Path
    manifest = $Manifest
    target_cmd = $TARGET_CMD
    target_ref = $TARGET_REF
    ci = $IsCI
  }

  $mf = Read-Json -Path (Join-Path $Root $Manifest)
  if ($null -eq $mf) {
    Write-Text "manifest not found or empty → skip"
  } else {
    $ops = @()
    if ($mf.PSObject.Properties.Name -contains 'ops') {
      $ops = $mf.ops
    } elseif ($mf -is [System.Collections.IEnumerable]) {
      $ops = $mf
    }
    if ($ops.Count -eq 0) {
      Write-Text "manifest has no ops → nothing to do"
    } else {
      foreach ($op in $ops) {
        Apply-Op -op $op -DryRun:$DryRun
      }
    }
  }

  if ($DryRun) {
    Write-Text   "== DryRun end =="
    Write-JsonLog -Event 'end' -Message 'dryrun ok' -ExitCode 11
    exit 11
  } else {
    Write-Text   "== Apply end =="
    Write-JsonLog -Event 'end' -Message 'apply ok' -ExitCode 0
    exit 0
  }
}
catch {
  $msg = $_.Exception.Message
  Write-Text   "ERROR: $msg"
  Write-JsonLog -Event 'error' -Message $msg -ExitCode 1 -Data @{ stack = "$($_.ScriptStackTrace)" }
  exit 1
}
