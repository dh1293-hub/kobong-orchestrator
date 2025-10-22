# NO-SHELL
# Test-ApplyPatches.ps1 — 공용 apply-patches.ps1 적합성 자가진단 (DRYRUN만)
param([string]$Repo='.', [string]$Tool='scripts/g5/apply-patches.ps1')
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$ok=@(); $ng=@()
function T($name,[scriptblock]$sb){ try{ & $sb; $ok+= "[OK] $name" }catch{ $ng+= "[NG] $name :: $($_.Exception.Message)" } }

# 1) 존재/호출 검사
T 'exists' { if(-not (Test-Path $Tool)){ throw "not found: $Tool" } }
T 'ps7-header' {
  $t=Get-Content -Raw $Tool -Encoding UTF8
  if($t -notmatch '#requires\s*-Version\s+7'){ throw 'missing PS7 #requires' }
  if($t -notmatch 'Set-StrictMode\s*-Version\s+Latest'){ throw 'missing StrictMode' }
}
# 2) DRYRUN 실행(샘플 PATCH 1건)
$patch = @"
# PATCH START
TARGET: __selfcheck.txt
MODE: insert-after
MULTI: false
FIND <<'EOF'
^$
EOF
REPLACE <<'EOF'
__SELFTEST__
EOF
# PATCH END
"@
$pp = Join-Path $Repo ".kobong\patches.pending.txt"
New-Item -Force -ItemType Directory (Split-Path $pp) | Out-Null
$patch | Out-File -Encoding utf8 $pp
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Repo '__selfcheck.txt')
T 'dryrun' { pwsh -NoProfile -File $Tool -Root $Repo | Out-Null }
# 3) 산출물/락/로그/백업 검사(있을 수도/없을 수도 있으니 존재만 확인)
T 'log-jsonl' { if(-not (Test-Path (Join-Path $Repo 'logs\apply-log.jsonl'))) { throw 'logs/apply-log.jsonl not found' } }
T 'lock-release' { if(Test-Path (Join-Path $Repo '.gpt5.lock')) { throw 'lock not released' } }
# 4) Exit
$ok + $ng | ForEach-Object { Write-Host $_ }
if($ng){ exit 13 } else { exit 0 }
