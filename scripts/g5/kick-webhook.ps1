#requires -Version 7.0
param([int]$Port=8088,[string]$Bind='127.0.0.1',[string]$Root='.')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Resolve-Path $Root).Path
$Base = 'http://{0}:{1}' -f $Bind, $Port

# 0) 파이썬 찾기(.venv 우선)
$py = Join-Path $RepoRoot 'server\.venv\Scripts\python.exe'
if (-not (Test-Path $py)) { $py = (Get-Command python).Path }

# 1) 포트 점유 프로세스 정리 후 Uvicorn (reload 비활성: 안정)
$owners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select -ExpandProperty OwningProcess -Unique
if ($owners) { $owners | % { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue } }

$RunDir = Join-Path $RepoRoot 'logs\run'; New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $RunDir "uvicorn-$ts.out.log"
$err = Join-Path $RunDir "uvicorn-$ts.err.log"

Start-Process -FilePath $py `
  -ArgumentList @('-m','uvicorn','server.app_entry:app','--host',$Bind,'--port',$Port,'--log-level','info') `
  -WorkingDirectory $RepoRoot `
  -RedirectStandardOutput $out -RedirectStandardError $err | Out-Null

# 2) 헬스 체크(/health, /diag/health, /api/health 순 시도)
$HealthPaths = @('/health','/diag/health','/api/health')
$ok = $null; foreach($hp in $HealthPaths){
  for($i=0;$i -lt 40;$i++){ Start-Sleep -Milliseconds 250
    try { $h = Invoke-RestMethod -Uri ($Base+$hp) -TimeoutSec 1 -ErrorAction Stop; $ok=$hp; break } catch {}
  }
  if ($ok) { break }
}
if (-not $ok) {
  Write-Host "[FAIL] 서버 응답 없음. 로그 꼬리:" -ForegroundColor Red
  if (Test-Path $err) { Get-Content $err -Tail 80 }
  if (Test-Path $out) { Get-Content $out -Tail 40 }
  exit 12
}
Write-Host "[OK] health: $ok" -ForegroundColor Green

# 3) openapi.json 로드
try { $api = Invoke-RestMethod -Uri ($Base+'/openapi.json') -TimeoutSec 5 }
catch {
  Write-Host "[WARN] openapi.json 실패: $($_.Exception.Message)" -ForegroundColor Yellow
  if (Test-Path $err) { "`n[TAIL] uvicorn.err" | Write-Host -ForegroundColor Cyan; Get-Content $err -Tail 80 }
  exit 12
}

# 4) POST 웹훅 후보 탐색
$pp = $api.paths.PSObject.Properties
$cands = foreach($p in $pp){
  $m=$p.Value.PSObject.Properties.Name
  if (($m -contains 'post') -and ($p.Name -match 'webhook|github')) { $p.Name }
}
$WebhookPath = $cands | Select-Object -First 1
if (-not $WebhookPath) {
  Write-Host "[MISS] POST /.*(webhook|github).* 경로 없음. 경로 목록:" -ForegroundColor Yellow
  $pp.Name | Sort-Object | % { " - $_" } | Write-Host
  exit 10
}
Write-Host "[USE] webhook endpoint: $WebhookPath" -ForegroundColor Cyan

# 5) GitHub 'ping' 페이로드 + HMAC-SHA256 서명
$secret = ($env:KOBONG_WEBHOOK_SECRET ?? 'dev_secret')
$payload = @{
  zen = "Keep it logically awesome."
  hook_id = 123456
  repository = @{ full_name = "dh1293-hub/kobong-orchestrator"; private = $false }
  sender = @{ login = "local-test" }
} | ConvertTo-Json -Depth 6 -Compress

$bytes  = [Text.Encoding]::UTF8.GetBytes($payload)
$key    = [Text.Encoding]::UTF8.GetBytes($secret)
$hmac   = [System.Security.Cryptography.HMACSHA256]::new($key)
$sigHex = -join ($hmac.ComputeHash($bytes) | % { $_.ToString('x2') })
$headers = @{
  'User-Agent'          = 'GitHub-Hookshot/test'
  'X-GitHub-Event'      = 'ping'
  'X-GitHub-Delivery'   = [guid]::NewGuid().ToString()
  'X-Hub-Signature-256' = "sha256=$sigHex"
  'Content-Type'        = 'application/json'
}

# 6) 웹훅 발사
$resp = Invoke-WebRequest -Uri ($Base + $WebhookPath) -Method POST -Headers $headers -Body $payload -TimeoutSec 10 -SkipHttpErrorCheck
Write-Host ("[RESULT] {0} {1}" -f [int]$resp.StatusCode, $resp.StatusDescription) -ForegroundColor Green
if ($resp.Content) { "[BODY]"; $resp.Content.Substring(0, [Math]::Min(400, $resp.Content.Length)) }

# 7) 여분 후보 안내
$extra = $cands | Select-Object -Skip 1 | Sort-Object -Unique
if ($extra) {
  Write-Host "`n[ALSO CANDIDATES] (POST)" -ForegroundColor DarkCyan
  $extra | ForEach-Object { " - $_" } | Write-Host
}