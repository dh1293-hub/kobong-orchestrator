<# =================================================================================================
[파일] scripts/g5/apply-patches.ps1
[목적] 패치(또는 수정 작업) 적용 파이프라인의 공용 실행 스크립트
[핵심] 콘솔·JSONL 위주 로깅. AK_TEE=1 환경에서는 .ak-out.txt에 직접 쓰지 않음(충돌 방지).
[연관] .github/workflows/ak-apply.yml, logs/ak7.jsonl, patches/manifest.json (선택)
[사용법]
  pwsh -NoProfile -File scripts/g5/apply-patches.ps1 `
      -Root . `
      -Manifest patches/manifest.json `
      -OutText .ak-out.txt -OutJson logs/ak7.jsonl `
      -DryRun:$true

[옵션]
  -Root       : 작업 기준 폴더(기본 '.')
  -Manifest   : 패치 선언 JSON 경로(없어도 동작; 있으면 루프 실행)
  -OutText    : 텍스트 로그(로컬에서만 직접 Append, Actions에선 AK_TEE=1이므로 미사용)
  -OutJson    : JSONL 로그(항상 안전 Append)
  -DryRun     : 시뮬레이션 모드(파일 변경 없이 흐름·검증)
  -Quiet      : 콘솔 최소화

[테스트]
  1) 로컬(단독 파일 기록)
     pwsh -NoProfile -File scripts/g5/apply-patches.ps1 -DryRun -Root .
     ▶ .ak-out.txt, logs/ak7.jsonl 둘 다 생성/Append

  2) GitHub Actions 흉내(파이프+Tee 동시 기록)
     $env:AK_TEE='1'
     & pwsh -NoProfile -File scripts/g5/apply-patches.ps1 -DryRun `
        -OutText .ak-out.txt -OutJson logs/ak7.jsonl 2>&1 |
        Tee-Object -FilePath .ak-out.txt -Append
     ▶ .ak-out.txt는 Tee가 단독으로 쓰므로 충돌 無

[주의]
  - 파일 동시 기록 충돌 방지: .ak-out.txt는 "한 주체만" 쓴다(워크플로우의 Tee-Object).
  - JSONL은 Append-SafeLine(파일 공유 허용+재시도)로 안전 기록.
================================================================================================= #>

[CmdletBinding()]
param(
  [string]$Root = ".",
  [string]$Manifest = "patches/manifest.json",
  [string]$OutText = ".ak-out.txt",
  [string]$OutJson = "logs/ak7.jsonl",
  [switch]$DryRun,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

# ===== 내부 유틸: 안전 Append(파일 공유 허용 + 재시도) =========================================
function Append-SafeLine {
  param([string]$Path, [string]$Line)
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  $enc = [System.Text.UTF8Encoding]::new($false)  # UTF-8 (BOM 없음)
  for ($i=0; $i -lt 20; $i++) {
    try {
      $fs = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Append,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::ReadWrite)        # ← 동시 읽기/쓰기 허용
      $sw = [System.IO.StreamWriter]::new($fs, $enc)
      $sw.WriteLine($Line)
      $sw.Dispose(); $fs.Dispose()
      return
    } catch {
      Start-Sleep -Milliseconds (50 * [Math]::Min($i+1, 10))
      if ($i -eq 19) { throw }
    }
  }
}

# ===== 로깅: 콘솔 + (조건부) 텍스트 + JSONL ======================================================
function Write-Text([string]$s) {
  if (-not $Quiet) { Write-Host $s }
  # Actions에서 Tee-Object가 .ak-out.txt를 전담하도록 위임(AK_TEE=1일 때 직접 파일 쓰기 금지)
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

# ===== 메인 ======================================================================================
$start = Get-Date
$ctx = @{
  TARGET_REF = $env:TARGET_REF
  TARGET_CMD = $env:TARGET_CMD
  DryRun     = [bool]$DryRun
  Root       = (Resolve-Path -LiteralPath $Root).Path
  Manifest   = $Manifest
}

try {
  Write-Text     "== apply-patches.ps1 start (DryRun=$DryRun) =="
  Write-JsonLog  -Event "ak-apply:start" -Message "Start" -Data $ctx

  Set-Location -LiteralPath $Root

  # 1) Manifest 로딩(있으면)
  $manifestObj = $null
  if (Test-Path -LiteralPath $Manifest) {
    try {
      $json = Get-Content -LiteralPath $Manifest -Raw -Encoding UTF8
      $manifestObj = $json | ConvertFrom-Json -ErrorAction Stop
      Write-Text "Loaded manifest: $Manifest"
    } catch {
      throw "Manifest parse failed: $Manifest `n$($_.Exception.Message)"
    }
  } else {
    Write-Text "Manifest not found: $Manifest (skip patch loop)"
  }

  # 2) 패치 루프(예시 구현: 실제 규칙은 프로젝트 구성에 맞게 확장)
  $applied = 0
  if ($manifestObj -and $manifestObj.patches) {
    foreach ($p in $manifestObj.patches) {
      $name = $p.name
      $type = $p.type
      Write-Text "-> Patch: $name (type=$type)"

      switch ($type) {
        'copy' {
          $src = $p.src; $dst = $p.dst
          if ($DryRun) {
            Write-Text "   DRYRUN copy $src -> $dst"
          } else {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
            Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
            Write-Text "   copied $src -> $dst"
          }
          $applied++
        }
        'replaceText' {
          $file = $p.file; $find = $p.find; $repl = $p.replace
          if ($DryRun) {
            Write-Text "   DRYRUN replace in $file : '$find' -> '$repl'"
          } else {
            $t = Get-Content -LiteralPath $file -Raw -Encoding UTF8
            $t2 = $t -replace [regex]::Escape($find), [System.Text.RegularExpressions.Regex]::Escape($repl).Replace('\','\\')
            Set-Content -LiteralPath $file -Value $t2 -Encoding UTF8
            Write-Text "   replaced in $file"
          }
          $applied++
        }
        default {
          Write-Text "   skip: unknown type '$type'"
        }
      }
    }
  }

  $elapsed = (Get-Date) - $start
  Write-Text    "== apply-patches.ps1 end (applied=$applied, elapsed=$($elapsed.ToString())) =="
  Write-JsonLog -Event "ak-apply:done" -Message "Done" -ExitCode 0 -Data @{applied=$applied; elapsed="$elapsed"}
  exit 0
}
catch {
  $msg = $_.Exception.Message
  Write-Text    "ERROR: $msg"
  Write-JsonLog -Event "ak-apply:error" -Message $msg -ExitCode 1 -Data @{trace="$_"}
  exit 1
}
