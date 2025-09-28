# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Root = "D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",
  [switch]$ConfirmApply,
  [switch]$AutoPush # 원격 푸시까지 수행하려면 함께 지정 (또는 ENV로 ON)
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }
if ($env:AUTO_PUSH -eq 'true') { $AutoPush = $true }

# --- KLC 로깅 (없으면 JSONL 폴백) ---
function Write-KLC {
  param([string]$Level='INFO',[string]$Action='webui-restore',[string]$Outcome='DRYRUN',[string]$ErrorCode='',[string]$Message='')
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module scripts --action $Action --outcome $Outcome --error $ErrorCode --message $Message 2>$null
      return
    }
  } catch {}
  $log = Join-Path $Root 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{ timestamp=(Get-Date).ToString('o'); level=$Level; module='scripts'; action=$Action; outcome=$Outcome; errorCode=$ErrorCode; message=$Message; } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

# --- 락 파일 (규정) ---
$Lock = Join-Path $Root '.gpt5.lock'
if (Test-Path $Lock) { Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -ErrorCode 'CONFLICT' -Message '.gpt5.lock exists'; throw '.gpt5.lock exists' }
"locked $(Get-Date -Format o)" | Out-File $Lock -Encoding utf8 -NoNewline

# --- 도우미 ---
function New-AtomicFile {
  param([string]$Path,[string]$Content)
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $dir = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if (Test-Path $Path) { Copy-Item -LiteralPath $Path -Destination "$Path.bak-$ts" -Force } # URS 백업 규정
  $tmp = Join-Path $dir ('.'+[IO.Path]::GetFileName($Path)+'.tmp')
  $Content | Out-File -LiteralPath $tmp -Encoding utf8 -NoNewline
  Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Restore-FromGitHead([string]$RelPath){
  $here = Join-Path $Root $RelPath
  $dir  = Split-Path -Parent $here
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $ok = $false
  try {
    # index/HEAD에서 바로 복구 시도
    $null = (Push-Location $Root); git checkout -- "$RelPath" 2>$null; Pop-Location | Out-Null
    $ok = Test-Path $here
  } catch {}
  return $ok
}

function Restore-FromGitHistory([string]$RelPath){
  $here = Join-Path $Root $RelPath
  $dir  = Split-Path -Parent $here
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  try {
    Push-Location $Root
    $last = git log -n 1 --pretty=format:%H -- "$RelPath" 2>$null
    if ($last) { $blob = git show "$last:$RelPath" 2>$null; if ($blob) { if($ConfirmApply){ New-AtomicFile -Path $here -Content $blob }; Pop-Location; return $true } }
    Pop-Location
  } catch { try { Pop-Location } catch {} }
  return $false
}

function Restore-FromRollbacks([string]$FileName,[string]$TargetPath){
  $cand = Get-ChildItem -LiteralPath $Root -Filter "$FileName*" -Recurse -ErrorAction SilentlyContinue |
          Where-Object { $_.FullName -match '\\\.rollbacks\\' } |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($cand){ $txt = Get-Content -LiteralPath $cand.FullName -Raw -Encoding UTF8; if($ConfirmApply){ New-AtomicFile -Path $TargetPath -Content $txt }; return $true }
  return $false
}

# --- 타깃 정의 (3분리 표준) ---
$Targets = @(
  @{ Dir='AUTO-Kobong\webui';           NS='AK7';    Port=5181; File='AUTO-Kobong-Han.html'           },
  @{ Dir='GitHub-Moniteoling\webui';    NS='GHMON';  Port=5182; File='GitHub-Moniteoling-Min.html'    },
  @{ Dir='Orchestrator-Moniteoling\webui'; NS='ORCHMON'; Port=5183; File='Orchestrator-Moniteoling-Su.html' }
)

# --- 보고서 ---
$Report = New-Object System.Collections.Generic.List[string]

try {
  Push-Location $Root
  $repoRoot = (git rev-parse --show-toplevel 2>$null)
  if(-not $repoRoot){ $repoRoot = $Root }
  if(-not (Test-Path $repoRoot)){ throw "Repo root not found: $repoRoot" }

  # A) 삭제 포인트 탐지 및 후보 복구
  foreach($t in $Targets){
    $absDir = Join-Path $repoRoot $t.Dir
    New-Item -ItemType Directory -Force -Path $absDir | Out-Null
    $want = Join-Path $t.Dir $t.File
    $abs  = Join-Path $repoRoot $want

    $Report.Add("== [$($t.NS)] $($t.Dir) ==")
    $deleted = (git ls-files --deleted -- "$($t.Dir)/*.html" 2>$null) -split "`n" | Where-Object { $_ }
    foreach($rel in $deleted){
      $Report.Add("DELETED (index): $rel")
      if($ConfirmApply){
        if (Restore-FromGitHead $rel){ $Report.Add("  -> restored from HEAD: $rel") }
      }
    }

    # B) 기본 파일이 없으면 (1) GitHistory (2) .rollbacks (3) 스켈레톤
    if (!(Test-Path $abs)){
      $Report.Add("MISSING: $want")

      $ok = $false
      if(!$ok){ $ok = Restore-FromGitHistory $want; if($ok){ $Report.Add("  -> restored from GIT-HISTORY: $want") } }
      if(!$ok){ $ok = Restore-FromRollbacks $t.File $abs; if($ok){ $Report.Add("  -> restored from ROLLBACKS: $($t.File)") } }

      if(-not $ok){
        # 3) 스켈레톤 (3분리 표준 적용)
        $s = @"
<!doctype html><html lang="ko"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>$($t.NS) 모니터</title>
<style>
  body{background:#0B0F12;color:#E6F1FF;font:16px/1.6 system-ui,Segoe UI,Apple SD Gothic Neo}
  .wrap{max-width:1100px;margin:32px auto;padding:16px}
  .row{display:flex;flex-wrap:wrap;gap:12px;margin-bottom:16px}
  .btn{min-width:140px;padding:14px 16px;border:1px solid #334155;border-radius:12px;background:#10151A;color:#E6F1FF;cursor:pointer}
  .btn:focus{outline:3px solid #22D3EE}
  #messages{border:1px solid #22303c;border-radius:12px;padding:12px}
</style></head><body>
<div class="wrap"><h1>$($t.NS) 콘솔</h1>
<div class="row">
  <button class="btn" data-$([string]$t.NS).ToLower()-action="next">다음 단계</button>
  <button class="btn" data-$([string]$t.NS).ToLower()-action="stop">중단</button>
  <button class="btn" data-$([string]$t.NS).ToLower()-action="fix-preview">Fix 미리보기</button>
  <button class="btn" data-$([string]$t.NS).ToLower()-action="fix-apply">Fix 적용</button>
  <button class="btn" data-$([string]$t.NS).ToLower()-action="good">Mark Good</button>
  <button class="btn" data-$([string]$t.NS).ToLower()-action="rollback">Rollback</button>
  <button class="btn" data-$([string]$t.NS).ToLower()-action="shell-open">셸 열기</button>
  <button class="btn" data-$([string]$t.NS).ToLower()-action="logs-export">로그 Export</button>
</div>
<section id="messages" data-$([string]$t.NS).ToLower()-messages></section>
</div>
<script>window.$($t.NS)_API_BASE='http://localhost:$($t.Port)/api/$(([string]$t.NS).ToLower())';</script>
<script src="$(([string]$t.NS).ToLower())-bridge.js"></script>
<script>(function(w){var NS='$($t.NS)',p=NS.toLowerCase();function msg(m){var el=document.getElementById('messages');if(!el)return;var d=document.createElement('div');d.textContent='[fallback] '+m;el.prepend(d);}if(!w[NS]){w[NS]={postAction:function(a){msg(NS+' '+a+' (브릿지 없음)');}};document.querySelectorAll('[data-'+p+'-action]').forEach(b=>b.addEventListener('click',()=>w[NS].postAction(b.getAttribute('data-'+p+'-action'))));msg('브릿지 미탑재로 Fallback 모드');}})(window);</script>
</body></html>
"@
        if($ConfirmApply){ New-AtomicFile -Path $abs -Content $s }
        $Report.Add("  -> scaffolded: $want")
      }
    }

    # 현황 요약
    $files = Get-ChildItem -LiteralPath $absDir -Filter *.html -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    foreach($f in $files){ $Report.Add("FOUND: " + $f.FullName) }
  }

  # C) 커밋/푸시 (옵션)
  if($ConfirmApply){
    git add -A
    if ((git status --porcelain) -ne $null){
      $branch = "fix/webui-restore-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
      git checkout -b $branch | Out-Null
      git commit -m "chore(webui): restore html (**good**)" | Out-Null
      $Report.Add("COMMIT: created $branch with **good**")
      if($AutoPush){
        git push -u origin $branch | Out-Null
        $Report.Add("PUSHED: origin/$branch")
      }
    } else {
      $Report.Add("NO-CHANGES: nothing to commit")
    }
  } else {
    $Report.Add("DRYRUN: set CONFIRM_APPLY=true for real write/commit")
  }

} catch {
  Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -ErrorCode 'LOGIC' -Message $_.Exception.Message
  throw
} finally {
  try {
    $out = Join-Path $Root 'logs\webui-restore-report.txt'
    New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
    $Report | Out-File -FilePath $out -Encoding utf8
    Write-Host "`n[REPORT] $out"
  } catch {}
  Remove-Item -LiteralPath $Lock -Force -ErrorAction SilentlyContinue
  Write-KLC -Outcome ($ConfirmApply?'SUCCESS':'DRYRUN') -Message 'done'
}
