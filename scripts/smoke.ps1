#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues["*:Encoding"]="utf8"

$RepoRoot=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$EnvFile = Join-Path $RepoRoot "webui\.env.local"
$envText = (Test-Path $EnvFile) ? (Get-Content -LiteralPath $EnvFile -Raw) : ""
function ReadEnv($k,$def=""){ if($envText -match "(?m)^$([regex]::Escape($k))=(.*)$"){ return $Matches[1].Trim() } $def }
$Token = ReadEnv "VITE_GH_TOKEN" ""
$Owner = ReadEnv "VITE_DEFAULT_OWNER" "dh1293-hub"
$Repo  = ReadEnv "VITE_DEFAULT_REPO"  "kobong-orchestrator"
if(-not $Token){ throw "VITE_GH_TOKEN not found in .env.local" }

$h = @{ Authorization = "Bearer $Token"; Accept='application/vnd.github+json'; 'X-GitHub-Api-Version'='2022-11-28' }
$rate = Invoke-RestMethod -Headers $h -Uri 'https://api.github.com/rate_limit' -TimeoutSec 10
"{0,-10}: {1}/{2} (reset {3})" -f 'core', $rate.resources.core.remaining, $rate.resources.core.limit, ([DateTimeOffset]::FromUnixTimeSeconds($rate.resources.core.reset).ToLocalTime()) | Write-Host

$ok1 = (Invoke-WebRequest -Headers $h -Uri "https://api.github.com/repos/$Owner/$Repo" -TimeoutSec 10).StatusCode
$ok2 = (Invoke-WebRequest -Headers $h -Uri "https://api.github.com/repos/$Owner/$Repo/actions/runs?per_page=1" -TimeoutSec 10).StatusCode
$ok3 = 0; try { $ok3 = (Invoke-WebRequest -Headers $h -Uri "https://api.github.com/repos/$Owner/$Repo/releases/latest" -TimeoutSec 10).StatusCode } catch { $ok3 = $_.Exception.Response.StatusCode.value__ }
$since = [uri]::EscapeDataString([DateTime]::UtcNow.AddHours(-24).ToString('o'))
$ok4 = (Invoke-WebRequest -Headers $h -Uri "https://api.github.com/repos/$Owner/$Repo/commits?since=$since&per_page=1" -TimeoutSec 10).StatusCode
"{0,-10}: {1}" -f 'repo',    $ok1 | Write-Host
"{0,-10}: {1}" -f 'actions', $ok2 | Write-Host
"{0,-10}: {1}" -f 'release', $ok3 | Write-Host
"{0,-10}: {1}" -f 'commits', $ok4 | Write-Host
