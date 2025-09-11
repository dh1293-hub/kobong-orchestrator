# PS-SB-PORTS-FIX-AUTO_v1.3.1 — 계약 PATCH + 빌드 + ESM↔CJS 브리지 + 테스트 + 커밋/푸시
$ErrorActionPreference = "Stop"
function Warn($m){ Write-Host "[경고] $m" -ForegroundColor DarkYellow }
function Info($m){ Write-Host "[정보] $m" -ForegroundColor Cyan }
function Pass($m){ Write-Host "[PASS]  $m" -ForegroundColor Green }
function Fail($m){ Write-Host "[FAIL]  $m" -ForegroundColor Red; exit 2 }

$repoRoot = (Get-Location).Path
Info "repo = $repoRoot"

# 1) 계약 확인/백업/버전 PATCH
$contract = Join-Path $repoRoot "contracts\kkb.commands.v1.json"
if(-not (Test-Path $contract)){
  New-Item -ItemType Directory -Force -Path (Split-Path $contract) | Out-Null
  '{ "version": "0.1.0", "ports": [] }' | Set-Content -Path $contract -Encoding UTF8
  Warn "계약 없어서 템플릿 생성"
}
$bk = $contract + (".bak-{0:yyyyMMdd-HHmmss}" -f (Get-Date))
Copy-Item $contract $bk -Force
Info "계약 백업: $bk"

$json = Get-Content $contract -Raw | ConvertFrom-Json
function BumpPatch($v){
  if($v -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$'){ return "0.1.0" }
  $c,$pre=$v.Split('-',2); $p=$c.Split('.'); $p[2]=[int]$p[2]+1
  return ($p -join '.') + ($(if($pre){"-$pre"}else{""}))
}
$old=$json.version; $new=BumpPatch $old; $json.version=$new
($json|ConvertTo-Json -Depth 12) | Set-Content -Path $contract -Encoding UTF8
Info "계약 버전: $old → $new"

# 2) Domain→Infra 직접의존 차단
$viol = Select-String -Path ".\domain\**\*.ts" -Pattern 'from\s+["'']\.\.\/infra' -SimpleMatch -ErrorAction SilentlyContinue
if($viol){ $viol|%{ Write-Host (" - {0}:{1}" -f $_.Path,$_.LineNumber) -ForegroundColor DarkYellow }; Fail "도메인→인프라 import 발견" }

# 3) 빌드
npm run build; if($LASTEXITCODE -ne 0){ Fail "build 실패" }

# 4) ESM↔CJS 브리지 (idempotent)
$js = Join-Path $repoRoot "dist\app\bootstrap.js"
if(Test-Path $js){
  $cjs = [System.IO.Path]::ChangeExtension($js, '.cjs')
  if(-not (Test-Path $cjs)){ Copy-Item $js $cjs -Force; Info "CJS 복제: dist/app/bootstrap.cjs" }
  $content = Get-Content $js -Raw
  if(-not ($content -match 'createRequire\(')){
@"
/// ESM wrapper (AUTO v1.3.1)
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
require('./bootstrap.cjs');
"@ | Set-Content -Path $js -Encoding UTF8
    Info "ESM 래퍼 주입"
  } else { Info "ESM 래퍼 이미 적용됨" }
} else { Warn "dist/app/bootstrap.js 없음 → 브리지 스킵" }

# 5) 테스트
npm run run-tests
if($LASTEXITCODE -ne 0){ Fail "테스트 실패" } else { Pass "테스트 통과 (AUTO v1.3.1)" }

# 6) 커밋 & 푸시(현재 브랜치 자동)
git add $contract
$branch = (git rev-parse --abbrev-ref HEAD); if([string]::IsNullOrWhiteSpace($branch)){ $branch="main" }
git commit -m "fix(domain-ports): contract bump to $new + ESM↔CJS bridge (PS-SB-PORTS-FIX-AUTO v1.3.1)" --allow-empty
git push origin $branch
Pass "자동 반영 완료 — 계약($new) 푸시 브랜치=$branch"
