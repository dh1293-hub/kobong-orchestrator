# v1.0 — PS-SB-PORTS-FIX.ps1 (쉘적용, 연주황 안내)
$ErrorActionPreference = 'Stop'
$repoRoot = "D:\ChatGPT5_AI_Link\dosc\gpt5-conductor"
Set-Location $repoRoot

function Warn($m){ Write-Host "[경고] $m" -ForegroundColor DarkYellow }
function Info($m){ Write-Host "[정보] $m" -ForegroundColor Cyan }
function Pass($m){ Write-Host "[PASS]  $m" -ForegroundColor Green }
function Fail($m){ Write-Host "[FAIL]  $m" -ForegroundColor Red; exit 2 }

# 1) 계약 파일 존재 및 백업
$contract = Join-Path $repoRoot "contracts\kkb.commands.v1.json"
if(-not (Test-Path $contract)){ Fail "계약 파일 없음: $contract" }
$bk = $contract + (".bak-{0:yyyyMMdd-HHmmss}" -f (Get-Date))
Copy-Item $contract $bk -Force
Info "계약 백업 생성: $bk"

# 2) 계약 JSON 최소 검증 + PATCH bump
$json = Get-Content $contract -Raw | ConvertFrom-Json
$need = @('version','ports')
$miss = $need | Where-Object { -not $json.PSObject.Properties.Name.Contains($_) }
if($miss){ Fail ("계약 JSON 필수키 누락: {0}" -f ($miss -join ', ')) }

function BumpPatch($v){
  if($v -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$'){ Warn "비표준 버전: $v → 0.1.0"; return "0.1.0" }
  $c,$pre = $v.Split('-',2)
  $p = $c.Split('.'); $p[2] = [int]$p[2]+1
  return ($p -join '.') + ($(if($pre){"-$pre"}else{""}))
}
$old = $json.version; $new = BumpPatch $old
$json.version = $new
($json | ConvertTo-Json -Depth 12) | Set-Content -Path $contract -Encoding UTF8
Info "계약 버전: $old → $new (PATCH)"

# 3) Domain→Infra 직접의존 검사
$viol = Select-String -Path ".\domain\**\*.ts" -Pattern 'from\s+["'']\.\.\/infra' -SimpleMatch -ErrorAction SilentlyContinue
if($viol){
  Warn "도메인→인프라 직접 import 발견:"
  $viol | ForEach-Object { Write-Host (" - {0}:{1}" -f $_.Path,$_.LineNumber) -ForegroundColor DarkYellow }
  Fail "규칙 위반. 위 import 제거 후 재실행."
}
Pass "도메인→인프라 직접의존 없음"

# 4) 계약 기반 생성기 실행(있으면)
if(Test-Path ".\scripts\PS-SCC-BUILD.ps1"){
  Info "PS-SCC-BUILD 실행"
  pwsh -NoProfile -File ".\scripts\PS-SCC-BUILD.ps1"
}else{
  Warn "PS-SCC-BUILD.ps1 없음 → 스킵"
}

# 5) 빌드 & 테스트
npm run build
npm run run-tests
if(Test-Path ".\tests\contract"){ npm run run-contract } else { Warn "contract 테스트 폴더 없음 → 스킵" }

if($LASTEXITCODE -ne 0){ Fail "빌드/테스트 실패" } else { Pass "빌드/테스트 통과" }

# 6) 커밋 가이드
Write-Host "`n다음 실행:" -ForegroundColor Cyan
Write-Host ('git add "{0}"' -f $contract) -ForegroundColor DarkYellow
Write-Host ('git commit -m "fix(domain-ports): contract patch bump to {0} + ports regen (PS-SB-PORTS-FIX v1)"' -f $new) -ForegroundColor DarkYellow
Write-Host 'git push origin feature/sprint-b-reporting' -ForegroundColor DarkYellow
Pass "PS-SB-PORTS-FIX v1 완료"
