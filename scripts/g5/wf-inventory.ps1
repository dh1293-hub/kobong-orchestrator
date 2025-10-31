# 파일: scripts/g5/wf-inventory.ps1
# 목적: 레포의 .github/workflows/*.yml 전수 수집 → _inventory/workflows.csv|json 생성
# 동작:
#   (A) 체크아웃된 워크스페이스에서 로컬 우선 스캔
#   (B) 로컬이 비어있으면 zipball로 폴백(브랜치/태그명 사용 권장; SHA는 404 가능)
# 사용:
#   pwsh -NoProfile -File scripts/g5/wf-inventory.ps1 -Repo dh1293-hub/kobong-orchestrator -Ref main
# 보안:
#   - GH_TOKEN 있으면 API 헤더로 사용(레이트리밋 완화)
#   - User-Agent / X-GitHub-Api-Version 명시
# 산출: _inventory/workflows.csv, _inventory/workflows.json
# 규칙: #주석(친절한) / 멱등 / 실패 시 원인(로컬 비어있음+zipball 실패) 명확히 출력

param(
  [string]$Repo = "dh1293-hub/kobong-orchestrator",
  [string]$Ref  = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$RepoRoot = (Get-Location).Path
$Out = Join-Path $RepoRoot '_inventory'
New-Item -ItemType Directory -Force -Path $Out | Out-Null

function Write-Info($msg){ Write-Host $msg -ForegroundColor Cyan }

# === A) Local scan ============================================================
function Get-WfFilesFromLocal {
  $dir = Join-Path $RepoRoot '.github/workflows'
  if (Test-Path $dir) {
    Write-Info "로컬 스캔: $dir"
    return Get-ChildItem $dir -File -Include *.yml,*.yaml -ErrorAction SilentlyContinue
  }
  return @()
}

# 공통 헤더
$Headers = @{
  'User-Agent'           = 'wf-inventory/1.3'
  'X-GitHub-Api-Version' = '2022-11-28'
}
if ($env:GH_TOKEN) { $Headers['Authorization'] = "Bearer $env:GH_TOKEN" }

# 임시 경로
$tmp = Join-Path (${env:RUNNER_TEMP} ?? ${env:TEMP}) "wfscan"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
New-Item $tmp -ItemType Directory | Out-Null

# === B) Contents API (가볍고 안정적인 2단계) ==================================
function Get-WfFilesFromContents {
  $api = "https://api.github.com/repos/$Repo/contents/.github/workflows?ref=$Ref"
  Write-Info "Contents API 시도: $api"
  try {
    $resp = Invoke-WebRequest -Uri $api -Headers $Headers -ErrorAction Stop
    $items = $resp.Content | ConvertFrom-Json
  } catch {
    Write-Warning "Contents API 실패: $($_.Exception.Message)"
    return @()
  }
  if (-not $items) { return @() }

  $dir = Join-Path $tmp 'contents'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $acc = @()
  foreach ($it in $items) {
    if ($it.type -eq 'file' -and ($it.name -like '*.yml' -or $it.name -like '*.yaml')) {
      $dst = Join-Path $dir $it.name
      try {
        Invoke-WebRequest -Uri $it.download_url -OutFile $dst -Headers $Headers -ErrorAction Stop
        $acc += Get-Item $dst
      } catch {
        Write-Warning "파일 다운로드 실패: $($it.name) - $($_.Exception.Message)"
      }
    }
  }
  return $acc
}

# === C) Zipball (마지막 폴백) =================================================
function Get-WfFilesFromZipball {
  $zip = Join-Path $tmp 'src.zip'
  $unz = Join-Path $tmp 'unz'
  New-Item $unz -ItemType Directory -Force | Out-Null

  $zipUrl = "https://api.github.com/repos/$Repo/zipball/$Ref"
  Write-Info "Zipball 시도: $zipUrl"
  try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -Headers $Headers -ErrorAction Stop
  } catch {
    Write-Warning "zipball 다운로드 실패(ref=$Ref): $($_.Exception.Message)"
    return @()
  }

  try {
    Expand-Archive -Path $zip -DestinationPath $unz -Force
  } catch {
    Write-Warning "압축 해제 실패: $($_.Exception.Message)"
    return @()
  }

  if (-not (Test-Path $unz)) { Write-Warning "unz 경로가 없음"; return @() }
  $top = Get-ChildItem -Path $unz -Directory | Select-Object -First 1
  if (-not $top) { Write-Warning "zipball 최상위 폴더 탐지 실패"; return @() }

  $wfRoot = Join-Path $top.FullName '.github/workflows'
  if (Test-Path $wfRoot) {
    Write-Info "zipball 스캔: $wfRoot"
    return Get-ChildItem -Path $wfRoot -Recurse -File -Include *.yml,*.yaml
  }
  Write-Warning "zipball에 .github/workflows 폴더 없음"
  return @()
}

# 1) Local
$files = @( Get-WfFilesFromLocal )

# 2) Contents API
if (-not $files -or $files.Count -eq 0) { $files = @( Get-WfFilesFromContents ) }

# 3) Zipball
if (-not $files -or $files.Count -eq 0) {
  Write-Host "로컬+Contents API 실패 → zipball 폴백(ref=$Ref)"
  $files = @( Get-WfFilesFromZipball )
}

if (-not $files -or $files.Count -eq 0) {
  throw "워크플로 파일을 찾지 못했습니다(Local/Contents/Zipball 모두 실패). Repo=$Repo Ref=$Ref"
}

# 4) 라이트 파싱 & 저장
$rows = foreach($f in $files){
  $t = Get-Content -LiteralPath $f.FullName -Raw
  $name = ([regex]::Match($t,'(?m)^\s*name:\s*(.+)$').Groups[1].Value).Trim()
  $perm = ([regex]::Match($t,'(?m)^\s*permissions:\s*(.+)$').Groups[1].Value).Trim()
  $conc = ([regex]::Match($t,'(?m)^\s*concurrency:\s*(.+)$').Groups[1].Value).Trim()
  $has = @{
    dispatch = $t -match '(^|\n)\s*workflow_dispatch\s*:'
    pr       = $t -match '(^|\n)\s*(pull_request|pull_request_target)\s*:'
    push     = $t -match '(^|\n)\s*push\s*:'
    issuecmt = $t -match '(^|\n)\s*issue_comment\s*:'
    release  = $t -match '(^|\n)\s*release\s*:'
    schedule = $t -match '(^|\n)\s*schedule\s*:'
  }
  [pscustomobject]@{
    path = ($f.FullName -replace [regex]::Escape($RepoRoot), '').TrimStart('\','/')
    name = if($name){$name}else{[IO.Path]::GetFileNameWithoutExtension($f.Name)}
    permissions = if($perm){$perm}else{'(default)'}
    concurrency = $conc
    has_workflow_dispatch = $has.dispatch
    has_pull_request      = $has.pr
    has_push              = $has.push
    has_issue_comment     = $has.issuecmt
    has_release           = $has.release
    has_schedule          = $has.schedule
    updated_utc           = (Get-Item $f.FullName).LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
  }
}

$csv  = Join-Path $Out 'workflows.csv'
$json = Join-Path $Out 'workflows.json'
$rows | Sort-Object path | Export-Csv -NoTypeInformation -Path $csv
$rows | ConvertTo-Json -Depth 4 | Set-Content -Path $json
Write-Host "[OK] inventory → $csv , $json"
