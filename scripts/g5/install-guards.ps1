# install-guards.ps1 — Unified Guards v1.0  (PS7)
# 목적: 지정 루트들에 통일된 보호 규칙 적용 (NTFS ACL + ReadOnly)
# 안전: 기존 ACL 백업 → 적용 → 요약 출력. 파일 손상 없음.
# 사용: pwsh -NoProfile -File .\install-guards.ps1

# ===== 설정 =====
$GuardRoots = @(
  'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring',
  'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\GitHub-Monitoring',
  'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\Orchestrator-Monitoring',
  'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\containers\orch-shells'
)

# 서비스/운영 계정(있으면 추가)
$ServiceAccounts = @('Administrators','SYSTEM')  # 필요 시 'svc-ak7','svc-orch','svc-ghmon','DOMAIN\svc' 등 추가

# ... (중략) 기본 그랜트 후, 추가 계정만 Modify 부여
foreach ($acct in $ServiceAccounts) {
  if ($acct -notin @('Administrators','SYSTEM')) {
    $grantStr = "$($acct):(OI)(CI)(M)"
    & icacls $root /grant $grantStr /t /c | Out-Null
  }
}
# 쓰기 허용(운영 산출물) 폴더명 (루트 하위 어디에 있어도 매칭)
$WritableDirs = @('logs','automation_logs','_inventory','backups','release','temp','tmp')

# 정적/기동 파일 패턴(읽기전용+RX)
$StartupGlobs  = @('*.ps1','*.psm1','*.psd1','*.cmd','*.bat','*.html','*.htm','*-bridge.js')

# ===== 시작 =====
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ACL 백업 폴더
$stamp = (Get-Date -Format 'yyyyMMdd_HHmmss')
$BackupDir = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\_acl_backups'
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

foreach ($root in $GuardRoots) {
  if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-Warning "경로 없음 → 건너뜀: $root"
    continue
  }

  Write-Host "== 보호 적용: $root" -ForegroundColor Cyan

  # 0) 기존 ACL 백업 (icacls /save)
  $aclBackup = Join-Path $BackupDir ("acl_" + ($root -replace '[:\\]','_') + "_$stamp.txt")
  & icacls $root /save $aclBackup /t /c | Out-Null

  # 1) 상속 비활성(ACE 보존) + 기본 권한 재정렬
  & icacls $root /inheritance:d /t /c | Out-Null
  & icacls $root /grant:r "Administrators:(OI)(CI)(F)" "SYSTEM:(OI)(CI)(F)" "Users:(OI)(CI)(RX)" /t /c | Out-Null
  foreach ($acct in $ServiceAccounts) {
    if ($acct -notin @('Administrators','SYSTEM')) {
      # ✅ 수정 라인(권장)
      & icacls $root /grant "$($acct):(OI)(CI)(M)" /t /c | Out-Null
    }
  }

  # 2) 운영 산출물 폴더만 쓰기 허용(있을 때만)
  Get-ChildItem -LiteralPath $root -Directory -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $WritableDirs -contains $_.Name } |
    ForEach-Object {
      & icacls $_.FullName /grant "Users:(OI)(CI)(M)" /t /c | Out-Null
    }

  # 3) 정적/기동 파일은 읽기전용 속성 + Users=RX
  foreach ($glob in $StartupGlobs) {
  Get-ChildItem -LiteralPath $root -Recurse -File -Filter $glob -ErrorAction SilentlyContinue |
    ForEach-Object {
      try {
        attrib +R $_.FullName
        & icacls $_.FullName /grant:r "Users:RX" /c | Out-Null
      } catch { Write-Warning "속성/ACL 적용 실패: $($_.FullName) → $($_.Exception.Message)" }
    }
}


  Write-Host "  → 완료. 백업: $aclBackup" -ForegroundColor Green
}

Write-Host "`n[완료] 통일 보호 규칙 적용을 마쳤습니다." -ForegroundColor Green
