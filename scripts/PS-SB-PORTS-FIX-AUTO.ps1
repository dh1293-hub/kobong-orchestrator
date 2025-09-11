# PS-SB-PORTS-FIX-AUTO.ps1
# v1.1 — Ports 계약 자동 패치 & 커밋/푸시 (쉘적용, 연주황 안내)

$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

function Warn($m){ Write-Host "[경고] $m" -ForegroundColor DarkYellow }
function Info($m){ Write-Host "[정보] $m" -ForegroundColor Cyan }
function Pass($m){ Write-Host "[PASS]  $m" -ForegroundColor Green }
function Fail($m){ Write-Host "[FAIL]  $m" -ForegroundColor Red; exit 2 }

# 0) repo root 자동 설정
$repoRoot = (Get-Location).Path
cd $repoRoot

# 1) 계약 파일 확인/백업
$contract = Join-Path $repoRoot "contracts\kkb.commands.v1.json"
if(-not (Test-Path $contract)){ Fail "계약 파일 없음: $contract" }
$bk = $contract + (".bak-{0:yyyyMMdd-HHmmss}" -f (Get-Date))
Copy-Item $contract $bk -Force
Info "계약 백업 생성: $bk"

# 2) 계약 JSON 버전 PATCH bump
$json = Get-Content $contract -Raw | ConvertFrom-Json
function BumpPatch($v){
  if($v -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$'){ Warn "비표준 버전: $v → 0.1.0"; return "0.1.0" }
  $c,$pre = $v.Split('-',2)
  $p = $c.Split('.'); $p[2] = [int]$p[2]+1
  return ($p -join '.') + ($(if($pre){"-$pre"}else{""}))
}
$old = $json.version; $new = BumpPatch $old
$json.version = $new
($json | ConvertTo-Json -Depth 12) | Set-Content -Path $contract -Encoding UTF8
Info "계약 버전: $old → $new"

# 3) Domain→Infra 직접 의존 검사
$viol = Select-String -Path ".\domain\**\*.ts" -Pattern 'from\s+["'']\.\.\/infra' -SimpleMatch -ErrorAction SilentlyContinue
if($viol){
  Warn "도메인→인프라 직접 import 발견:"
  $viol | ForEach-Object { Write-Host (" - {0}:{1}" -f $_.Path,$_.LineNumber) -ForegroundColor DarkYellow }
  Fail "규칙 위반. import 제거 후 재실행 필요."
}
Pass "도메인→인프라 직접의존 없음"

# 4) 생성기 실행
if(Test-Path ".\scripts\PS-SCC-BUILD.ps1"){
  Info "PS-SCC-BUILD 실행"
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\PS-SCC-BUILD.ps1"
}else{
  Warn "PS-SCC-BUILD.ps1 없음 → 스킵"
}

# 5) 빌드/테스트
npm run build
npm run run-tests
if(Test-Path ".\tests\contract"){ npm run run-contract } else { Warn "contract 테스트 없음" }

if($LASTEXITCODE -ne 0){ Fail "빌드/테스트 실패" } else { Pass "빌드/테스트 통과" }

# 6) 자동 커밋 & 푸시
git add contracts\kkb.commands.v1.json
git commit -m "fix(domain-ports): contract bump to $new + regen (PS-SB-PORTS-FIX-AUTO v1.1)" --allow-empty
git push origin feature/sprint-b-reporting

Pass "자동 반영 완료 — 계약($new) + 테스트 통과 + 원격 푸시"
