param([string]$Root)

$ErrorActionPreference = "Stop"

# (선택) 유틸 모듈 시도 — 실패해도 무시
Import-Module Microsoft.PowerShell.Utility -ErrorAction SilentlyContinue | Out-Null

# 0) 루트 결정 (우선순위: 인자 → ENV → 스크립트 상위)
$root = $Root
if (-not $root) { $root = $env:HAN_GPT5_ROOT }
if (-not $root) { $root = (Resolve-Path "$PSScriptRoot\..").Path }
if (-not (Test-Path $root)) { throw "Invalid root: $root" }

# 1) 선언 파일 경로
$yaml = Join-Path $root 'project.decl.yaml'
$json = Join-Path $root 'project.decl.json'

# 2) 파싱 (ConvertFrom-Yaml 있으면 YAML, 아니면 JSON)
$decl = $null
if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
  if (Test-Path $yaml) { $decl = Get-Content $yaml -Raw | ConvertFrom-Yaml }
}
if (-not $decl -and (Test-Path $json)) {
  $decl = Get-Content $json -Raw | ConvertFrom-Json
}
if (-not $decl) { throw "PRECONDITION: declaration parse failed (need ConvertFrom-Yaml or $([IO.Path]::GetFileName($json)))." }

# 3) 기본 검증
if ($decl.decl_version -ne 1) { throw 'Unsupported decl_version' }
if (-not $decl.paths.root_env) { throw 'paths.root_env required' }

# 4) ENV 주입 (프로세스 스코프)
$rootEnvName = [string]$decl.paths.root_env
if (-not [Environment]::GetEnvironmentVariable($rootEnvName, 'Process')) {
  [Environment]::SetEnvironmentVariable($rootEnvName, $root, 'Process')
}
$rootFromEnv = [Environment]::GetEnvironmentVariable($rootEnvName, 'Process')
if (-not $rootFromEnv) { throw "ENV not set: $rootEnvName" }

# 5) 필수 디렉터리 보장
$paths = @('out','logs','cache','tmp') | ForEach-Object { Join-Path $rootFromEnv $decl.paths.$_ }
foreach ($p in $paths) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

Write-Host '[OK] declaration validated'
