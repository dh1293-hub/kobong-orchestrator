# --- onboard-monitors.ps1 : 모듈 3종을 안전하게 GitHub 온보딩 + 통일 보호조치 적용 ---
[CmdletBinding(SupportsShouldProcess)]
param(
  # 푸시/PR 자동 생성 여부
  [switch]$NoPush,
  [switch]$NoPR,
  [switch]$NoAutoMerge,
  # 온보딩 후 로컬 보호(ACL+R/O) 적용
  [switch]$ApplyProtection = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
  try {
    $top = (git rev-parse --show-toplevel).Trim()
    if ($top) { return $top }
  } catch {}
  return (Resolve-Path "$PSScriptRoot\..\..").Path
}

$Root = Get-RepoRoot
Set-Location $Root

# --- 1) 기본 경로/대상 ---
$Modules = @(
  "Orchestrator-Monitoring",
  "GitHub-Monitoring",
  "AUTO-Kobong-Monitoring"
)
$Containers = @(
  "containers\orch-shells",
  "containers\ghmon",
  "containers\ak7"
)

# --- 2) .gitignore / .gitattributes 멱등 반영 ---
function Ensure-Lines($Path, [string[]]$Wanted) {
  $cur = if (Test-Path $Path) { Get-Content $Path -Raw } else { "" }
  $out = New-Object System.Collections.Generic.List[string]
  if ($cur) { $out.Add($cur.TrimEnd()) }
  foreach ($ln in $Wanted) {
    if ($cur -notmatch [regex]::Escape($ln)) { $out.Add($ln) }
  }
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  ($out -join "`r`n") | Set-Content $Path -Encoding UTF8
}

Ensure-Lines -Path ".gitignore" -Wanted @(
  "# === auto by onboard-monitors ===",
  "_deploy/",
  "automation_logs/",
  "logs/",
  "*.log","*.bak","*.tmp",
  "node_modules/","dist/","build/","out/","*.map",
  ".env",".env.*","*.pem","*.pfx","*.key","*.crt","*.cer","*credentials*.json",
  "*.sqlite","*.db","*.db-shm","*.db-wal",
  "*.zip","*.7z","*.tar","*.tar.gz",
  "containers/**/data/","containers/**/volumes/","containers/**/secrets/"
)

Ensure-Lines -Path ".gitattributes" -Wanted @(
  "# === auto by onboard-monitors ===",
  "*.ps1 text eol=crlf",
  "*.psm1 text eol=crlf",
  "*.bat text eol=crlf",
  "*.cmd text eol=crlf",
  "*.sh  text eol=lf",
  "*.yml text eol=lf",
  "*.yaml text eol=lf",
  "*.html text eol=lf",
  "*.js text eol=lf"
)

# --- 3) 컨테이너 컨텍스트 .dockerignore 멱등 반영 ---
$dockerIgnore = @(
".git",".gitignore","_deploy","logs","automation_logs",
"node_modules","*.env","*.pem","*.pfx","*.key","*.crt","*.zip","*.7z"
) -join "`r`n"

foreach($c in $Containers){
  $p = Join-Path $Root $c
  if(Test-Path $p){
    $t = Join-Path $p ".dockerignore"
    Set-Content $t $dockerIgnore -Encoding UTF8
  }
}

# --- 4) messages-wiring.js 기본 파일(없을 때만) ---
$WiringTemplate = @"
;/* __G5_BRIDGE_CONFIG_v1__ (generated; do not edit HTML) */
(function (w) {
  const defaults = {
    GHMON_BASE:   "http://localhost:5181",
    AK7_BASE:     "http://localhost:5182",
    ORCHMON_BASE: "http://localhost:5183"
  };
  w.__G5_ENDPOINTS = Object.assign({}, defaults, w.__G5_ENDPOINTS || {});
})(window);
"@
foreach($m in $Modules){
  $webui = Join-Path $Root "$m\webui"
  if(Test-Path $webui){
    $js = Join-Path $webui "messages-wiring.js"
    if(-not (Test-Path $js)){
      New-Item -ItemType Directory -Force -Path $webui | Out-Null
      Set-Content $js $WiringTemplate -Encoding UTF8
    }
  }
}

# --- 5) 스테이징 목록 구성(코드/정의만) ---

# 포함 루트(상대 경로 기준)
$IncludeRoots = @(
  'Orchestrator-Monitoring',
  'GitHub-Monitoring',
  'AUTO-Kobong-Monitoring',
  'scripts\g5',
  'deploy',
  'containers'
)

# 제외 패턴(정규식)
$Exclude = @(
  '\\logs\\','\\automation_logs\\','\\_deploy\\',
  '\.env($|\.|\\)','\.pem$','\.pfx$','\.key$','\.crt$','\.cer$',
  '\.sqlite$','\.db$','\.db-shm$','\.db-wal$',
  '\.zip$','\.7z$','\.tar$','\.tar\.gz$'
)

function Test-Included([IO.FileInfo]$f, [string]$root) {
  # $root(저장소 루트)를 기준으로 상대 경로 계산 후, IncludeRoots 중 하나로 시작하면 포함
  $rel = $f.FullName.Substring($root.Length).TrimStart('\','/')
  foreach ($r in $IncludeRoots) {
    if ($rel -like ($r.TrimStart('\','/') + '\*')) { return $true }
  }
  return $false
}

function Test-Excluded([IO.FileInfo]$f, [string[]]$patterns) {
  foreach ($p in $patterns) { if ($f.FullName -match $p) { return $true } }
  return $false
}

$files = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  (Test-Included $_ $Root) -and (-not (Test-Excluded $_ $Exclude))
}

if (-not $files) {
  Write-Warning "스테이징할 파일이 없습니다."
  exit 0
}

# 안전 확인용 로그
Write-Host "Will stage $($files.Count) file(s)..." -ForegroundColor Cyan


# --- 6) 브랜치/커밋/푸시/PR ---
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$branch = "g5/onboard-monitors-$ts"
git fetch --all --prune | Out-Null
git switch -c $branch

# add by path list (경로에 공백/한글 대응)
$pathsFile = Join-Path $env:TEMP "g5_paths_$ts.txt"
$files | Select-Object -ExpandProperty FullName | Set-Content $pathsFile -Encoding UTF8
git add --pathspec-from-file="$pathsFile"

git status --porcelain=v1
git commit -m "feat(monitors): onboard Orchestrator/GitHub/AUTO-Kobong modules (code-only, no logs/secrets)" || `
  Write-Host "변경 없음(커밋 생략)" -ForegroundColor Yellow

if(-not $NoPush){
  git push -u origin $branch
  if(-not $NoPR){
    gh pr create --base main --head $branch `
      -t "feat: onboard monitors (safe, code-only)" `
      -b "코드/정의만 온보딩: _deploy, logs, secrets 제외. CI/guards 유지."
    if(-not $NoAutoMerge){
      try { gh pr merge --squash --auto $branch } catch { gh pr merge --squash $branch }
    }
  }
}

# --- 7) 통일 보호조치(로컬) — 첨부 참조 정책 일반화 ---
function Protect-Tree([string]$Dir){
  if(-not (Test-Path $Dir)) { return }
  Write-Host "[PROTECT] $Dir" -ForegroundColor Green
  # 7.1 핵심 HTML 읽기전용(실수 방지)
  Get-ChildItem -Path $Dir -Recurse -File -Include *.html -ErrorAction SilentlyContinue |
    ForEach-Object { attrib +R $_.FullName 2>$null }
  # 7.2 ACL: 상속 제거 → Admin/SYSTEM=F, 현재 사용자=Modify, Users=RX
  & icacls $Dir /inheritance:r /T | Out-Null
  & icacls $Dir /grant:r "Administrators:(OI)(CI)F" /T | Out-Null
  & icacls $Dir /grant:r "SYSTEM:(OI)(CI)F" /T | Out-Null
  & icacls $Dir /grant:r "$env:USERNAME:(OI)(CI)M" /T | Out-Null
  & icacls $Dir /grant:r "Users:(OI)(CI)RX" /T | Out-Null
}

if($ApplyProtection){
  foreach($m in $Modules){
    $d = Join-Path $Root $m
    Protect-Tree $d
  }
  Write-Host "[OK] 통일 보호조치 적용 완료" -ForegroundColor Green
}

Write-Host "`n[DONE] onboard-monitors completed : $branch" -ForegroundColor Cyan
