<# =====================================================================
  파일: scripts/g5/apply-patches.ps1
  목적: 패치(manifest 기반)를 DryRun/Apply로 실행하고,
        콘솔·텍스트·JSONL 로그를 남기는 "표준 운용" 스크립트
  사용법(로컬):
    # DryRun (표준 종료코드 11)
    pwsh -NoProfile -File scripts/g5/apply-patches.ps1 -DryRun `
      -Root . -Manifest patches/manifest.json `
      -OutText .ak-out.txt -OutJson logs/ak7.jsonl

    # Apply
    pwsh -NoProfile -File scripts/g5/apply-patches.ps1 `
      -Root . -Manifest patches/manifest.json `
      -OutText .ak-out.txt -OutJson logs/ak7.jsonl

  CI(GitHub Actions) 연동 규칙:
    - 워크플로에서 .ak-out.txt는 Tee-Object가 "단독"으로 쓰도록 함.
    - 이를 위해 이 스크립트는 AK_TEE=1 이면 OutText 파일 쓰기를 생략(콘솔만 출력).
    - JSONL(logs/ak7.jsonl)은 항상 안전한 Append로 남김(분석/보관용).

  종료코드:
    0  = 성공(Apply 또는 DryRun에서 오류 없음 + DryRun이 아님)
    11 = DryRun 정상 종료
    1  = 일반 오류(예외 발생 등)

  연관 파일:
    - .github/workflows/ak-apply.yml  (이 스크립트를 호출)
    - patches/manifest.json           (패치 정의; 없으면 스킵)
    - logs/ak7.jsonl                  (JSON Lines; 운영/분석용)

  테스트:
    1) DryRun과 Apply 모두 실행해 종료코드 확인
    2) .ak-out.txt, logs/ak7.jsonl 내용 확인
    3) 잠금 충돌 재현 불가 확인(Tee-Object와 Out-File 동시쓰기 제거)
===================================================================== #>

param(
  [string]$Root = ".",
  [string]$Manifest = "patches/manifest.json",
  [string]$OutText = ".ak-out.txt",
  [string]$OutJson = "logs/ak7.jsonl",
  [switch]$DryRun,
  [switch]$Quiet
)

# ===== 내부 설정/상태 =====
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'Ansi'

# CI에서 전달될 수 있는 힌트(없어도 무방)
$TARGET_CMD = $env:TARGET_CMD
$TARGET_REF = $env:TARGET_REF

# ===== 공용 유틸: 안전 Append (파일공유 허용 + 재시도) =====
function Append-SafeLine {
  param([string]$Path, [string]$Line)

  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  $enc = [System.Text.UTF8Encoding]::new($false)  # UTF-8 (BOM 없음)
  for ($i=0; $i -lt 20; $i++) {
    try {
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
  # CI에서는 .ak-out.txt 파일을 Tee-Object가 전담한다.
  # 따라서 AK_TEE=1 이면 파일 쓰기 스킵 → 잠금 충돌 제거.
  if ($env:AK_TEE -eq '1') { return }
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
  Write-Text  "== apply-patches.ps1 start (DryRun=$DryRun) =="
  Write-JsonLog -Event 'start' -Message 'apply-patches start' -Data @{
    root = (Resolve-Path $Root).Path
    manifest = $Manifest
    target_cmd = $TARGET_CMD
    target_ref = $TARGET_REF
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
