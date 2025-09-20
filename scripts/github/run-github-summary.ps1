# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$Root,
  [string]$Owner,
  [string]$Repo,
  [int]$Port = 8787,
  [switch]$ConfirmApply,
  [switch]$AskToken,
  [switch]$SkipTokenCheck,
  [string]$Token
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Read-GitHubToken {
  Write-Host "[INPUT] GitHub PAT을 입력하세요. (입력값은 화면에 표시되지 않습니다)"
  $sec = Read-Host -Prompt "PAT" -AsSecureString
  if (-not $sec) { throw "빈 토큰" }
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
  try { ([Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)).Trim() }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

# 토큰 소스 우선순위: -Token > ENV > 프롬프트(AskToken 시 강제)
if ($AskToken) { Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue }
if ($PSBoundParameters.ContainsKey('Token') -and -not [string]::IsNullOrWhiteSpace($Token)) {
  $token = $Token.Trim()
  $env:GITHUB_TOKEN = $token
} elseif (-not $env:GITHUB_TOKEN -or [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
  $token = Read-GitHubToken
  if ([string]::IsNullOrWhiteSpace($token)) { throw "토큰이 비었습니다." }
  $env:GITHUB_TOKEN = $token
} else {
  $token = $env:GITHUB_TOKEN
}

# (선택) 토큰 검증: token → Bearer 폴백
if (-not $SkipTokenCheck) {
  $headersList = @(
    @{ Authorization = "token $token";  Accept = "application/vnd.github+json"; "User-Agent" = "kobong-github-summary-ps7" },
    @{ Authorization = "Bearer $token"; Accept = "application/vnd.github+json"; "User-Agent" = "kobong-github-summary-ps7" }
  )
  $ok = $false
  foreach ($H in $headersList) {
    try { Invoke-RestMethod -Uri 'https://api.github.com/rate_limit' -Headers $H -TimeoutSec 15 | Out-Null; $ok=$true; break } catch { }
  }
  if (-not $ok) { throw "토큰 검증 실패 — 권한 또는 값 확인 필요 (401/Forbidden)" }
  Write-Host "[OK] 토큰 확인 완료."
} else {
  Write-Host "[SKIP] 토큰 검증 생략(-SkipTokenCheck)."
}

# 경로/락 정리
$RepoRoot = (Resolve-Path $Root).Path
$ServerPs1 = Join-Path $RepoRoot 'github-summary-server.ps1'
$LockFile  = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { try { Remove-Item -Force $LockFile } catch {} }
if (-not (Test-Path $ServerPs1)) {
  Write-Error "server script not found: $ServerPs1"
  Read-Host "Press Enter to close..."
  exit 10
}

# 실행
try {
  Write-Host "[RUN] $ServerPs1 -Owner $Owner -Repo $Repo -Port $Port"
  & $ServerPs1 -Owner $Owner -Repo $Repo -Port $Port -ConfirmApply:$ConfirmApply
} catch {
  Write-Host "[ERR] $($_.Exception.Message)"
} finally {
  Write-Host ""
  Write-Host "[HOLD] http://127.0.0.1:$Port/api/github/summary 열림 상태를 확인하세요."
  Read-Host "Press Enter to close..."
}
