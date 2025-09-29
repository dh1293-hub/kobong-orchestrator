# restore_all_local.ps1
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",
  [switch]$NoOpenBrowser # 브라우저 자동열기 억제 옵션
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Log([string]$msg,[string]$lvl='INFO'){
  $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  Write-Host ("[{0}] {1} {2}" -f $lvl,$ts,$msg)
}

if(-not (Test-Path -LiteralPath $Root)){ throw "루트 폴더가 없습니다: $Root" }

# === 0) 타겟 정의 (3중 모니터 분리 표준) ===
$Targets = @(
  @{ dir=Join-Path $Root 'AUTO-Kobong\webui';               html='AUTO-Kobong-Han.html';            bridge='ak7-bridge.js';   ns='AK7';    port=5181 },
  @{ dir=Join-Path $Root 'GitHub-Moniteoling\webui';         html='GitHub-Moniteoling-Min.html';     bridge='ghmon-bridge.js'; ns='GHMON';  port=5182 },
  @{ dir=Join-Path $Root 'Orchestrator-Moniteoling\webui';   html='Orchestrator-Moniteoling-Su.html';bridge='orchmon-bridge.js';ns='ORCHMON';port=5183 }
)

# === 1) 현재 로컬 스냅샷(.rollbacks) ===
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$roll = Join-Path $Root ".rollbacks\$stamp"
New-Item -ItemType Directory -Force -Path $roll | Out-Null
foreach($t in $Targets){
  if(Test-Path -LiteralPath $t.dir){
    $dst = Join-Path $roll ($t.dir.Substring($Root.Length).TrimStart('\') -replace '[\\/:*?"<>|]','_')
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    try {
      Copy-Item -LiteralPath $t.dir -Destination $dst -Recurse -Force -ErrorAction SilentlyContinue
    } catch { Log "스냅샷 복사 경고: $($_.Exception.Message)" 'WARN' }
  }
}
Log "스냅샷 저장: $roll"

# === 2) 보조 함수들 ===
function Ensure-Dir([string]$p){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
function Find-Backup([string]$fileName){
  Get-ChildItem -LiteralPath $Root -Recurse -ErrorAction SilentlyContinue `
  | Where-Object { $_.FullName -match '\\\.rollbacks\\' -and $_.Name -like "$fileName*" } `
  | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
function Restore-FromBackup([string]$destPath){
  $fn = Split-Path $destPath -Leaf
  $cand = Find-Backup $fn
  if($cand){
    Log "백업에서 복원: $($cand.FullName) → $destPath"
    Get-Content -LiteralPath $cand.FullName -Raw -Encoding UTF8 | Set-Content -LiteralPath $destPath -Encoding UTF8
    return $true
  }
  return $false
}
function Is-GitRepo($r){ Test-Path (Join-Path $r ".git") }
function Restore-FromGit([string]$destPath){
  if(-not (Is-GitRepo $Root)){ return $false }
  $rel = $destPath.Replace("$Root\","")
  Push-Location $Root
  try {
    # 2-1) 정확 경로 우선
    $commit = (& git log -n 1 --pretty=format:%H -- $rel) 2>$null
    if(-not [string]::IsNullOrWhiteSpace($commit)){
      Log "git 복원 시도(경로 일치): $rel @ $commit"
      (& git show "$commit`:$rel") | Set-Content -LiteralPath $destPath -Encoding UTF8
      return $true
    }
    # 2-2) 파일명 기반 최근 탐색(최근 200개 커밋 범위)
    $name = Split-Path $destPath -Leaf
    $hist = (& git log -n 200 --name-only --pretty=format: | Where-Object {$_ -match '\.html$'}) 2>$null
    $candPath = $hist | Where-Object { $_ -and (Split-Path $_ -Leaf) -eq $name } | Select-Object -First 1
    if($candPath){
      $commit2 = (& git log -n 1 --pretty=format:%H -- $candPath) 2>$null
      if($commit2){
        Log "git 복원 시도(파일명 일치): $candPath @ $commit2"
        (& git show "$commit2`:$candPath") | Set-Content -LiteralPath $destPath -Encoding UTF8
        return $true
      }
    }
  } catch {
    Log "git 복원 중 오류: $($_.Exception.Message)" 'WARN'
  } finally { Pop-Location }
  return $false
}
function Ensure-BridgeJs([string]$dir,[string]$bridge,[string]$ns){
  $p = Join-Path $dir $bridge
  if(Test-Path -LiteralPath $p){ return }
  @"
(function(w,d){
  var NS='$ns'; var API=w[NS+'_API_BASE']||'';
  function out(s){ try{ var el=d.querySelector('[data-'+NS.toLowerCase()+'-messages]'); if(el){ var p=d.createElement('div'); p.textContent=s; el.prepend(p); } }catch(e){} }
  w[NS] = w[NS] || {
    postAction: function(a,p){ out('[bridge:'+NS+'] '+a+' '+(p||'')); /* TODO: fetch(API+'/action', {method:'POST',body:JSON.stringify({a:a,p:p})}) */ }
  };
  d.querySelectorAll('[data-'+NS.toLowerCase()+'-action]').forEach(function(b){
    b.addEventListener('click', function(){ w[NS].postAction(b.getAttribute('data-'+NS.toLowerCase()+'-action')); });
  });
  out('브릿지 로드 완료: '+NS);
})(window,document);
"@ | Set-Content -LiteralPath $p -Encoding UTF8
  Log "브릿지 생성: $p"
}
function New-SkeletonHtml([string]$destHtml,[string]$ns,[int]$port,[string]$bridge){
  @"
<!doctype html><html lang="ko"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>$ns 모니터</title>
<style>
  :root{--bg:#0b0f12;--fg:#e6f1ff;--bd:#2a3340}
  body{background:var(--bg);color:var(--fg);font:16px/1.6 system-ui,Segoe UI,Apple SD Gothic Neo}
  .wrap{max-width:1100px;margin:32px auto;padding:16px}
  .row{display:flex;flex-wrap:wrap;gap:12px;margin-bottom:16px}
  .btn{min-width:140px;padding:14px 16px;border:1px solid var(--bd);border-radius:12px;background:#10151A;color:var(--fg);cursor:pointer}
  .btn:focus{outline:3px solid #22D3EE}
  #messages{border:1px solid var(--bd);border-radius:12px;padding:12px}
</style></head><body>
<div class="wrap">
  <h1>$ns 콘솔</h1>
  <div class="row">
    <button class="btn" data-${($ns.ToLower())}-action="next">다음 단계</button>
    <button class="btn" data-${($ns.ToLower())}-action="stop">중단</button>
    <button class="btn" data-${($ns.ToLower())}-action="fix-preview">Fix 미리보기</button>
    <button class="btn" data-${($ns.ToLower())}-action="fix-apply">Fix 적용</button>
    <button class="btn" data-${($ns.ToLower())}-action="good">Mark Good</button>
    <button class="btn" data-${($ns.ToLower())}-action="rollback">Rollback</button>
    <button class="btn" data-${($ns.ToLower())}-action="shell-open">셸 열기</button>
    <button class="btn" data-${($ns.ToLower())}-action="logs-export">로그 Export</button>
  </div>
  <section id="messages" data-${($ns.ToLower())}-messages></section>
</div>
<script>window.${ns}_API_BASE='http://localhost:${port}/api/${($ns.ToLower())}';</script>
<script src="$bridge"></script>
</body></html>
"@ | Set-Content -LiteralPath $destHtml -Encoding UTF8
  Log "스켈레톤 생성: $destHtml"
}

# === 3) 복구 루프(백업 → git → 스켈레톤) ===
$restored = @()
foreach($t in $Targets){
  Ensure-Dir $t.dir
  $html = Join-Path $t.dir $t.html
  if(Test-Path -LiteralPath $html){
    Log "존재 확인: $html"
    Ensure-BridgeJs -dir $t.dir -bridge $t.bridge -ns $t.ns
    $restored += $html
    continue
  }
  if( Restore-FromBackup $html ){ Ensure-BridgeJs -dir $t.dir -bridge $t.bridge -ns $t.ns; $restored += $html; continue }
  if( Restore-FromGit $html ){    Ensure-BridgeJs -dir $t.dir -bridge $t.bridge -ns $t.ns; $restored += $html; continue }
  # 마지막 수단: 스켈레톤
  New-SkeletonHtml -destHtml $html -ns $t.ns -port $t.port -bridge $t.bridge
  Ensure-BridgeJs -dir $t.dir -bridge $t.bridge -ns $t.ns
  $restored += $html
}

# === 4) 요약 및 브라우저 열기 ===
Log "복구/생성 완료 파일:"
$restored | ForEach-Object { Log " - $_" }
if(-not $NoOpenBrowser){
  foreach($p in $restored){ try { Start-Process $p } catch {} }
}
Log "DONE"
