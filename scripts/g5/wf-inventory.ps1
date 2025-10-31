# 파일: scripts/g5/wf-inventory.ps1
# 목적: .github/workflows/*.yml 전수 수집 → _inventory/workflows.csv|json 생성
# 동작: (A) 로컬 워크스페이스 우선 스캔 → (B) 없으면 zipball로 폴백(ref=브랜치/태그 권장)
# 보안: GH_TOKEN이 있으면 API 헤더 사용(User-Agent/Api-Version 명시), 읽기 전용
# 출력: _inventory/workflows.csv, _inventory/workflows.json

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

function Get-WfFilesFromLocal {
  $dir = Join-Path $RepoRoot '.github/workflows'
  if(Test-Path $dir){
    Get-ChildItem $dir -File -Include *.yml,*.yaml -ErrorAction SilentlyContinue
  }
}

# zipball 폴백(핫픽스: 폴더 선생성, 예외 처리, 루트/.github/workflows만 수집)
function Get-WfFilesFromZipball {
  $tmp = Join-Path (${env:RUNNER_TEMP} ?? ${env:TEMP}) "wfscan"
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  New-Item $tmp -ItemType Directory | Out-Null

  $zip = Join-Path $tmp 'src.zip'
  $unz = Join-Path $tmp 'unz'
  New-Item $unz -ItemType Directory -Force | Out-Null

  $h = @{
    'User-Agent'           = 'wf-inventory/1.2'
    'X-GitHub-Api-Version' = '2022-11-28'
  }
  if($env:GH_TOKEN){ $h['Authorization'] = "Bearer $env:GH_TOKEN" }

  $zipUrl = "https://api.github.com/repos/$Repo/zipball/$Ref"
  try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -Headers $h -ErrorAction Stop
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

  if (-not (Test-Path $unz)) { return @() }
  $top = Get-ChildItem -Path $unz | Where-Object PSIsContainer | Select-Object -First 1
  if (-not $top) { return @() }

  $wfRoot = Join-Path $top.FullName '.github/workflows'
  if (Test-Path $wfRoot) {
    Get-ChildItem -Path $wfRoot -Recurse -File -Include *.yml,*.yaml
  } else {
    @()
  }
}

# 1) 로컬 우선
$files = @( Get-WfFilesFromLocal )
if(-not $files -or $files.Count -eq 0){
  Write-Host "로컬에 .github/workflows 없음 → zipball 폴백(ref=$Ref)"
  $files = @( Get-WfFilesFromZipball )
  if(-not $files -or $files.Count -eq 0){
    throw "워크플로 파일을 찾지 못했습니다(로컬/zipball 모두 실패)."
  }
}

# 2) 라이트 파싱
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

# 3) 저장(멱등)
$csv  = Join-Path $Out 'workflows.csv'
$json = Join-Path $Out 'workflows.json'
$rows | Sort-Object path | Export-Csv -NoTypeInformation -Path $csv
$rows | ConvertTo-Json -Depth 4 | Set-Content -Path $json
Write-Host "[OK] inventory → $csv , $json"
