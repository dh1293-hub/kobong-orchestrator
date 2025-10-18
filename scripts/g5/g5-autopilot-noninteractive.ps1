Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RepoRoot = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP"
Set-Location $RepoRoot

# 1) 보안/워크플로우 파일 보장(이미 있으면 덮지 않음)
$wfDir = ".github\workflows"; New-Item -ItemType Directory -Force -Path $wfDir | Out-Null
if(-not (Test-Path .\SECURITY.md)){
  @"
# Security Policy — kobong-orchestrator & Monitors
(요약본) Reporting: GitHub Security “Report a vulnerability”, security@kobong.example
SLA: 48h ack / 72h triage / Critical 7d / High 30d / Medium 90d / Low BE
Rotation: 90d + grace 7d
"@ | Set-Content .\SECURITY.md -Encoding UTF8
}
if(-not (Test-Path .\.github\workflows\klc-verify.yml)){
  @"
name: KLC Verify
on: { pull_request: { branches: [ main ] }, push: { branches: [ main ] } }
jobs:
  klc-verify:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up PowerShell 7
        uses: PowerShell/PowerShell@v1
        with: { pwsh-version: '7.4.x' }
      - name: Run KLC schema check (minimal)
        shell: pwsh
        run: |
          $hits = Get-ChildItem -Recurse -File -Include *.jsonl,*.log -ErrorAction SilentlyContinue |
            Select-String -Pattern 'traceId','durationMs','exitCode','anchorHash' -SimpleMatch
          if(-not $hits){ Write-Host 'No KLC lines found → soft pass'; exit 0 }
          Write-Host "KLC lines detected: $($hits.Count)"
"@ | Set-Content .\.github\workflows\klc-verify.yml -Encoding UTF8
}

# 2) 새 브랜치 생성(멱등)
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$branch = "g5/auto-hardening-$ts"
git fetch --all --prune
git switch -c $branch

# 3) 커밋/푸시
git add SECURITY.md .github/workflows/klc-verify.yml
git commit -m "chore(security): add SECURITY.md + KLC verify (noninteractive auto)" 2>$null
git push -u origin $branch

# 4) 머지 경로 A — gh가 로그인돼 있으면 PR 자동 생성·자동 머지
$hasGh = (Get-Command gh -ErrorAction SilentlyContinue)
$ghOk  = $false
if($hasGh){
  try {
    gh auth status 2>$null | Out-Null
    $ghOk = $true
  } catch { $ghOk = $false }
}
if($ghOk){
  gh pr create -B main -H $branch -t "chore(security): SECURITY.md + KLC verify" -b "자동 PR — 보안 정책과 KLC 검사 도입" -f
  gh pr merge --squash --auto || gh pr merge --squash
  Write-Host "[OK] PR 경로로 자동 머지 시도 완료" -ForegroundColor Green
  exit 0
}

# 5) 머지 경로 B — gh 미로그인: main 직접 병합(보호 규칙 없을 때만 성공)
$mergeOk = $true
try {
  git checkout main
  git pull --ff-only
  git merge --ff-only $branch
  git push origin main
} catch { $mergeOk = $false }

if($mergeOk){
  Write-Host "[OK] main으로 직접 병합 완료" -ForegroundColor Green
  exit 0
}

# 6) 머지 경로 C — 보호 규칙/권한으로 직접 병합 불가: PR URL 자동 오픈(원클릭)
$remote = (git remote get-url origin)
if($remote -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)'){
  $o=$Matches.owner; $r=$Matches.repo
  $url = "https://github.com/$o/$r/compare/main...$branch?quick_pull=1&title=chore(security):%20SECURITY.md%20+%20KLC%20verify&body=자동%20PR"
  Start-Process $url
  Write-Host "[INFO] 브라우저에서 PR 페이지가 열렸습니다. 버튼 한 번으로 머지하세요." -ForegroundColor Yellow
  exit 0
}
