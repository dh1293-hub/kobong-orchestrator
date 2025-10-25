# g5-d3d5-pack.ps1 — 컨테이너/부팅 런북 강화 + 게이트/디스패치 + 가드 (PS7)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root    = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP'
$WF      = Join-Path $Root '.github\workflows'
$Scripts = Join-Path $Root 'scripts\g5'
Set-Location $Root
New-Item -ItemType Directory -Force -Path $WF,$Scripts | Out-Null

# 1) 포트 청소 스크립트 (D3)
@'
# ports-clean.ps1 — 5181/5182/5183/5191/5193/5199 LISTEN 프로세스 강제 종료(관리자 권한 권장)
param([int[]]$Ports=@(5181,5182,5183,5191,5193,5199))
$cons = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in $Ports }
$cons | Sort-Object LocalPort -Unique | ForEach-Object {
  try {
    if ($_.OwningProcess) { Stop-Process -Id $_.OwningProcess -Force -ErrorAction Stop; Write-Host "[KILL] Port $($_.LocalPort) PID=$($_.OwningProcess)" -ForegroundColor Yellow }
  } catch { Write-Warning "Fail kill port $($_.LocalPort): $($_.Exception.Message)" }
}
'@ | Set-Content "$Scripts\ports-clean.ps1" -Encoding UTF8

# 2) 부팅 후 자동 점검(보호→헬스) 스크립트 + 스케줄러 (D3)
@'
# autostart-verify.ps1 — 부팅 후 자동 보호/헬스 스모크(+로그)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Split-Path -Parent $root
$logd = Join-Path $proj 'automation_logs'
New-Item -ItemType Directory -Force -Path $logd | Out-Null
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$log = Join-Path $logd "autostart_$ts.log"
try {
  pwsh -NoProfile -File "$root\install-guards.ps1"   *>> $log
  pwsh -NoProfile -File "$root\verify-protection.ps1" *>> $log
  pwsh -NoProfile -File "$root\health-smoke.ps1"      *>> $log
  Write-Host "[OK] Autostart verify done → $log" -ForegroundColor Green
} catch { Write-Host "[FAIL] Autostart: $($_.Exception.Message)" -ForegroundColor Red }
'@ | Set-Content "$Scripts\autostart-verify.ps1" -Encoding UTF8

# 스케줄러(매 부팅 + 지연 60초)
$taskName = "G5-Autostart-Verify"
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
$act = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -File `"$Scripts\autostart-verify.ps1`""
$trg = New-ScheduledTaskTrigger -AtStartup
$sett= New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $taskName -Action $act -Trigger $trg -Settings $sett -RunLevel Highest `
  -Description "부팅 후 자동 보호/헬스 점검(멱등)"

# 3) Sentinel/Bridge 가드(CI) — HTML 직접편집 방지 (D4)
@'
name: Guard Sentinel & Bridge (HTML shape)
on:
  pull_request: { branches: [ main ] }
jobs:
  guard:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify sentinel comment and bridge wiring
        shell: pwsh
        run: |
          $hits = 0
          $files = Get-ChildItem -Recurse -Include *.html,*.htm -Path . -File -ErrorAction SilentlyContinue
          foreach($f in $files){
            $t = Get-Content $f.FullName -Raw
            if($t -match '<!-- __G5_SENTINEL:.*?_v1\.1__' -and $t -match '<script>window\.' -and $t -match '-bridge\.js'){
              $hits++
            }
          }
          if($files.Count -gt 0 -and $hits -eq 0){
            Write-Error "No sentinel/bridge wiring found in HTML. Prevent direct edits. FAIL."
            exit 1
          }
          Write-Host "Sentinel/bridge OK in $hits file(s)."
'@ | Set-Content "$WF\guard-sentinel.yml" -Encoding UTF8

# 4) Release → repository_dispatch 트리거(배포 훅) (D4)
@'
name: Dispatch On Release
on:
  release:
    types: [published]
jobs:
  dispatch:
    runs-on: windows-latest
    permissions:
      contents: read
    steps:
      - name: Fire repository_dispatch (deploy)
        shell: pwsh
        env:
          GH_TOKEN: ${{ github.token }}
          TAG_NAME: ${{ github.event.release.tag_name }}
        run: |
          $payload = @{ tag = $env:TAG_NAME; env = "DEV" } | ConvertTo-Json -Compress
          gh api -X POST repos/:owner/:repo/dispatches `
            -H "Accept: application/vnd.github+json" `
            -f event_type="deploy" `
            -f client_payload="$payload"
          Write-Host "repository_dispatch sent: deploy → $($env:TAG_NAME)"
'@ | Set-Content "$WF\dispatch-on-release.yml" -Encoding UTF8

# 5) KLC Verify 엄격화(있으면 교체, 없으면 생성) (D4)
$klc = "$WF\klc-verify.yml"
if (Test-Path $klc){
  (Get-Content $klc -Raw) -replace 'exit 0','exit 1' | Set-Content $klc -Encoding UTF8
} else {
@'
name: KLC Verify
on:
  pull_request: { branches: [ main ] }
  push:         { branches: [ main ] }
jobs:
  klc-verify:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up PowerShell 7
        uses: PowerShell/PowerShell@v1
        with: { pwsh-version: "7.4.x" }
      - name: Run KLC schema check (strict)
        shell: pwsh
        run: |
          $hits = Get-ChildItem -Recurse -File -Include *.jsonl,*.log -ErrorAction SilentlyContinue |
            Select-String -Pattern 'traceId','durationMs','exitCode','anchorHash' -SimpleMatch
          if(-not $hits){ Write-Error 'No KLC lines → FAIL'; exit 1 }
          Write-Host "KLC lines detected: $($hits.Count)"
'@ | Set-Content $klc -Encoding UTF8
}

# 6) 브랜치 생성 → 커밋/푸시 → PR/자동 머지(구 gh 호환) (D5)
git fetch --all --prune
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$br = "g5/d3d5-pack-$ts"
git switch -c $br
git add $Scripts\ports-clean.ps1 $Scripts\autostart-verify.ps1 $WF\guard-sentinel.yml $WF\dispatch-on-release.yml $klc
git commit -m "ops(ci): D3~D5 pack — ports clean, autostart verify, guard sentinel, dispatch on release, KLC strict"
git push -u origin $br
try { gh pr create --base main --head $br -t "ops(ci): D3~D5 pack" -b "자동 PR — 런북/가드/디스패치/KLC 엄격화" -f } catch {}
try { gh pr merge --squash --auto $br } catch { gh pr merge --squash $br }

Write-Host "`n[OK] D3~D5 pack pushed: $br" -ForegroundColor Green
