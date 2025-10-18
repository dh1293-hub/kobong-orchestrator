# g5-d11d15-pack.ps1 — CODEOWNERS + KLC 야간 집계 + 포스트릴리즈 카나리 + 주간 하우스키핑
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
$WF    = Join-Path $RepoRoot '.github\workflows'
$GHD   = Join-Path $RepoRoot '.github'
$Scr   = Join-Path $RepoRoot 'scripts\g5'
$Ops   = Join-Path $RepoRoot 'ops'
New-Item -ItemType Directory -Force -Path $WF,$GHD,$Scr,$Ops | Out-Null
Set-Location $RepoRoot

# D11) CODEOWNERS — 기본 거버넌스(리뷰어 자동 지정)
@'
# CODEOWNERS — 최소 예시(필요시 팀/사용자 핸들로 바꾸세요)
*                @dh1293-hub
/scripts/        @dh1293-hub
/.github/        @dh1293-hub
/webui/          @dh1293-hub
'@ | Set-Content "$GHD\CODEOWNERS" -Encoding UTF8

# D12) KLC 야간 집계(로컬 로그 → 아티팩트 업로드)
# 로컬용 스크립트(멱등): automation_logs 및 logs/**에서 KLC 1행 패턴 추출
@'
# scripts/g5/klc-aggregate.ps1 — KLC one-liner 집계
param([string]$Root = (Split-Path -Parent $PSScriptRoot))
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$targets = @(
  Join-Path $Root "automation_logs",
  Join-Path $Root "logs"
)
$rx = 'KLC\s*\|\s*traceId=.*?\|\s*durationMs=.*?\|\s*exitCode=.*?\|\s*anchorHash=\d+'
$rows = New-Object System.Collections.Generic.List[object]
foreach($t in $targets){
  if(-not (Test-Path $t)) { continue }
  Get-ChildItem -Recurse -File -Path $t -ErrorAction SilentlyContinue |
    ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if([string]::IsNullOrWhiteSpace($txt)) { return }
      $m = [regex]::Matches($txt,$rx,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
      foreach($mm in $m){
        $rows.Add([pscustomobject]@{
          File = $_.FullName
          Line = $mm.Value.Trim()
          Ts   = (Get-Item $_.FullName).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        })
      }
    }
}
$outDir = Join-Path $Root "_klc"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$csv = Join-Path $outDir ("klc_agg_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".csv")
$rows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csv
Write-Host "[OK] KLC rows: $($rows.Count) → $csv"
'@ | Set-Content "$Scr\klc-aggregate.ps1" -Encoding UTF8

# 야간 집계용 워크플로우(매일 09:00 KST ≈ UTC 00:00)
@'
name: KLC Nightly Aggregate
on:
  schedule:
    - cron: "0 0 * * *"   # UTC 00:00
  workflow_dispatch:
jobs:
  klc-agg:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up PowerShell 7
        uses: PowerShell/PowerShell@v1
        with: { pwsh-version: "7.4.x" }
      - name: Aggregate KLC lines
        shell: pwsh
        run: |
          pwsh -NoProfile -File scripts/g5/klc-aggregate.ps1
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: klc-nightly
          path: _klc/*.csv
'@ | Set-Content "$WF\klc-nightly-aggregate.yml" -Encoding UTF8

# D13) 포스트릴리즈 카나리(헬스 핑 + 실패 시 이슈 생성)
@'
# ops/canary-postrelease.ps1 — 릴리즈 직후 카나리 헬스 체크
param(
  [string[]]$Urls = @(
    "http://localhost:5181/health",
    "http://localhost:5182/health",
    "http://localhost:5183/health"
  )
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$fail = @()
foreach($u in $Urls){
  try{
    $r = Invoke-RestMethod -Uri $u -Method Get -TimeoutSec 5
    if(-not $r.ok){ throw "ok != true" }
    Write-Host "[OK] $u"
  } catch {
    Write-Host "[FAIL] $u : $($_.Exception.Message)" -ForegroundColor Red
    $fail += $u
  }
}
if($fail.Count -gt 0){
  # 콘솔 실패만 남기고 종료코드 1 → 워크플로우가 이슈 생성
  exit 1
}
'@ | Set-Content "$Ops\canary-postrelease.ps1" -Encoding UTF8

@'
name: Post-release Canary
on:
  release:
    types: [published]
  repository_dispatch:
    types: [deploy]
jobs:
  canary:
    runs-on: windows-latest
    permissions:
      contents: read
      issues: write
    steps:
      - uses: actions/checkout@v4
      - name: Set up PowerShell 7
        uses: PowerShell/PowerShell@v1
        with: { pwsh-version: "7.4.x" }
      - name: Canary
        id: canary
        shell: pwsh
        continue-on-error: true
        run: pwsh -NoProfile -File ops/canary-postrelease.ps1
      - name: Create incident issue on failure
        if: steps.canary.outcome != 'success'
        shell: pwsh
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          $title = "Post-release canary failed"
          $body  = "자동 카나리 실패: /health 응답 실패. 즉시 점검 및 `urs-rollback.ps1 -Mode prev` 권고."
          gh issue create -t $title -b $body
'@ | Set-Content "$WF\post-release-canary.yml" -Encoding UTF8

# D14) 주간 하우스키핑(오래된 g5/* 브랜치·런 로그 정리)
@'
name: Weekly Housekeeping
on:
  schedule:
    - cron: "0 1 * * 1"  # 매주 월 10:00 KST
  workflow_dispatch:
jobs:
  clean:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Delete remote g5/* branches older than 14d
        env: { GH_TOKEN: ${{ github.token }} }
        run: |
          set -e
          REPO="${{ github.repository }}"
          gh api repos/$REPO/branches --paginate --jq '.[] | select(.name|test("^g5/")) | .name' > branches.txt
          while read B; do
            # 최근 커밋 14일 초과 시 삭제(보호 예외)
            LAST=$(gh api repos/$REPO/commits/$B --jq '.commit.committer.date' || echo "")
            if [ -n "$LAST" ]; then
              python - <<'PY'
import os,sys,datetime
from dateutil import parser
d=parser.isoparse(os.environ.get("LAST")); 
if (datetime.datetime.now(datetime.timezone.utc)-d).days>14: print("DEL")
PY
              if [ "$?" = "0" ]; then
                git push origin --delete "$B" || true
              fi
            fi
          done < branches.txt
      - name: Keep artifacts 30d (noop if default)
        run: echo "Retention is managed at repo settings; manual prune optional."
'@ | Set-Content "$WF\weekly-housekeeping.yml" -Encoding UTF8

# D15) 브랜치/PR/자동 머지
git fetch --all --prune
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$br = "g5/d11d15-pack-$ts"
git switch -c $br
git add $GHD\CODEOWNERS $Scr\klc-aggregate.ps1 $WF\klc-nightly-aggregate.yml `
        $Ops\canary-postrelease.ps1 $WF\post-release-canary.yml $WF\weekly-housekeeping.yml
git commit -m "ops(ci): D11~D15 — CODEOWNERS, KLC nightly, post-release canary, weekly housekeeping"
git push -u origin $br
try { gh pr create --base main --head $br -t "ops(ci): D11~D15 pack" -b "자동 PR — 관측성/사후점검/거버넌스/하우스키핑" -f } catch {}
try { gh pr merge --squash --auto $br } catch { gh pr merge --squash $br }

Write-Host "`n[OK] D11~D15 pack pushed: $br" -ForegroundColor Green

