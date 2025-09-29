# B-두방 오토파일럿 — 서버(5192/5193)+UI(듀얼)+브라우저 자동 오픈
#requires -PSEdition Core
#requires -Version 7.0
param(
  [int]$PortA = 5192,
  [int]$PortB = 5193,
  [int]$WebPort = 8080,
  [string]$HtmlRel = 'GitHub-Moniteoling/webui/gh-dual.html'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'

# 레포 루트
$repo = (git rev-parse --show-toplevel 2>$null); if(-not $repo){ $repo=(Get-Location).Path }
$g5   = Join-Path $repo 'scripts/g5'
New-Item -ItemType Directory -Force -Path $g5 | Out-Null

# ---------- 1) 모의 서버 파일(강화판) 보장: mock-api-ak7.ps1 ----------
$serverPath = Join-Path $g5 'mock-api-ak7.ps1'
$needsUpdate = $true
if (Test-Path $serverPath) {
  $txt = Get-Content -Raw -LiteralPath $serverPath -Encoding UTF8
  if ($txt -match '/api/gh/inbox' -and $txt -match '/api/ak7/notify') { $needsUpdate=$false }
}
if ($needsUpdate) {
$server = @'
# AK7/GH mock API (듀얼 포트 지원)
#requires -PSEdition Core
#requires -Version 7.0
param([int]$Port=5192,[string]$Bind='localhost')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'
Add-Type -AssemblyName System.Net.HttpListener
$prefix = "http://{0}:{1}/" -f $Bind, $Port
$hl = [System.Net.HttpListener]::new(); $hl.Prefixes.Add($prefix)
try { $hl.Start() } catch {
  Write-Error "리스너 시작 실패: $($_.Exception.Message)`n관리자 권한 또는 URLACL 필요할 수 있음: `n netsh http add urlacl url=http://+:$Port/ user=Everyone"
  exit 1
}
Write-Host "[AK7] Mock API listening at $prefix (Ctrl+C 종료)"
Write-Host "  GET  /health     GET  /api/kpi"
Write-Host "  GET  /api/ak7/prefs"
Write-Host "  POST /api/ak7/notify  POST /api/ak7/next"
Write-Host "  GET|POST /api/ak7/(scan|test|fixloop)"
Write-Host "  GET  /api/gh/inbox  /api/gh/prs  /api/gh/checks"
function Send-Json($ctx,$obj,[int]$code=200){
  $res=$ctx.Response; $res.StatusCode=$code; $res.ContentType='application/json; charset=utf-8'
  $json=($obj|ConvertTo-Json -Compress); $buf=[Text.Encoding]::UTF8.GetBytes($json)
  $res.ContentLength64=$buf.Length
  $res.Headers['Access-Control-Allow-Origin']=$ctx.Request.Headers['Origin'] ?? '*'
  $res.Headers['Access-Control-Allow-Methods']='GET,POST,OPTIONS'
  $res.Headers['Access-Control-Allow-Headers']='Content-Type,X-Trace-Id,X-Idempotency-Key'
  $res.OutputStream.Write($buf,0,$buf.Length); $res.OutputStream.Close()
}
while ($hl.IsListening){
  $ctx=$hl.GetContext(); $req=$ctx.Request; $res=$ctx.Response
  $path=$req.Url.AbsolutePath.ToLowerInvariant(); $m=$req.HttpMethod
  if($m -eq 'OPTIONS'){ $res.StatusCode=204; $res.Headers['Access-Control-Allow-Origin']=$req.Headers['Origin'] ?? '*'
    $res.Headers['Access-Control-Allow-Methods']='GET,POST,OPTIONS'
    $res.Headers['Access-Control-Allow-Headers']='Content-Type,X-Trace-Id,X-Idempotency-Key'
    $res.Close(); continue }
  try {
    switch -Regex ($path){
      '^/health$' { Send-Json $ctx @{ ok=$true; service='ak7-mock'; port=$Port; ts=(Get-Date).ToString('o') } }
      '^/api/kpi$' { Send-Json $ctx @{ ok=$true; repo='mock/repo'; openPR=2; failingChecks=1; alerts=0; ts=(Get-Date).ToString('o') } }
      '^/api/ak7/prefs$' { Send-Json $ctx @{ ok=$true; theme='dark'; lang='ko-KR'; version='mock-1' } }
      '^/api/ak7/notify$' {
        $sr=New-Object IO.StreamReader $req.InputStream,([Text.Encoding]::UTF8)
        $json=$sr.ReadToEnd(); $sr.Close(); $data=if($json){$json|ConvertFrom-Json}else{@{}}
        Write-Host "[notify] $($data.level): $($data.msg)"
        Send-Json $ctx @{ ok=$true; received=$data; ts=(Get-Date).ToString('o') }
      }
      '^/api/ak7/next$' { Send-Json $ctx @{ ok=$true; action='next'; ts=(Get-Date).ToString('o'); job='queued' } }
      '^/api/ak7/(scan|test|fixloop)$' {
        $act=($path.Split('/')[-1]); Send-Json $ctx @{ ok=$true; action=$act; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/inbox$' {
        $items=@(
          @{ type='pr';    id=101; title='B-두방: 브릿지 주입'; state='open'; author='kobong-bot'; branch='feature/gh-bridge' },
          @{ type='issue'; id=202; title='UI: LED 카드 정교화'; state='open'; author='hanmins00' }
        ); Send-Json $ctx @{ ok=$true; items=$items; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/prs$' {
        $prs=@(
          @{ number=177; title='fix(ui): safe regex'; state='open'; checks=@(@{name='lint';status='success'},@{name='build';status='pending'}) },
          @{ number=178; title='feat(mon): GH console'; state='draft'; checks=@(@{name='lint';status='success'}) }
        ); Send-Json $ctx @{ ok=$true; prs=$prs; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/checks$' {
        $checks=@(@{name='lint';status='success'},@{name='build';status='pending'},@{name='test';status='queued'})
        Send-Json $ctx @{ ok=$true; checks=$checks; ts=(Get-Date).ToString('o') }
      }
      default { Send-Json $ctx @{ ok=$false; error='not_found'; path=$path } 404 }
    }
  } catch { Send-Json $ctx @{ ok=$false; error='exception'; message=$_.Exception.Message } 500 }
}
'@
$bak="$serverPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"; if(Test-Path $serverPath){ Copy-Item $serverPath $bak -Force }
$server | Set-Content -LiteralPath $serverPath -Encoding UTF8
Write-Host "[OK] mock-api-ak7.ps1 업데이트/생성 완료"
}

# ---------- 2) 듀얼 UI 페이지(새 파일) 생성: gh-dual.html ----------
$webdir = Split-Path -Parent (Join-Path $repo $HtmlRel)
New-Item -ItemType Directory -Force -Path $webdir | Out-Null
$htmlPath = Join-Path $repo $HtmlRel
if (-not (Test-Path $htmlPath)) {
$dual = @'
<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>GH Console — B-두방</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{background:#0B0F14;color:#E6F0FF;font-family:system-ui,Segoe UI,Noto Sans KR,Arial,sans-serif;margin:0}
.top{height:56px;display:flex;align-items:center;gap:10px;padding:0 12px;border-bottom:1px solid #121820}
.btn{height:40px;padding:0 12px;border-radius:8px;border:1px solid #65D1FF;background:#121820;color:#E6F0FF;cursor:pointer}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:12px}@media(max-width:1024px){.grid{grid-template-columns:1fr}}
.panel{min-height:320px;border:1px solid #121820;border-radius:12px;padding:12px}
.card{background:#121820;border:1px solid #0B0F14;border-radius:10px;margin:6px 0;padding:8px 10px}
.badge{display:inline-block;margin-left:8px;padding:2px 6px;border-radius:6px;background:#0B0F14;border:1px solid #65D1FF}
</style></head><body>
<div class="top">
  <span id="port-badge" class="badge">…</span>
  <button class="btn" id="refresh">새로고침</button>
  <button class="btn" data-ak7-action="next">NEXT</button>
  <button class="btn" data-ak7-action="scan">SCAN</button>
  <button class="btn" data-ak7-action="test">TEST</button>
  <button class="btn" data-ak7-action="fixloop">FIXLOOP</button>
</div>
<div class="grid">
  <section class="panel"><h3>좌: Inbox / PRs</h3><div id="left"></div></section>
  <section class="panel"><h3>우: Checks / KPI</h3><div id="right"></div></section>
</div>
<script>
(()=>{ const p=new URLSearchParams(location.search).get('api')||'5192';
  window.AK7_API_BASE=`http://localhost:${p}/api/ak7`;
  window.AK7_HEALTH  =`http://localhost:${p}/health`;
  window.GH_INBOX    =`http://localhost:${p}/api/gh/inbox`;
  window.GH_PRS      =`http://localhost:${p}/api/gh/prs`;
  window.GH_CHECKS   =`http://localhost:${p}/api/gh/checks`;
  window.GH_KPI      =`http://localhost:${p}/api/kpi`;
  document.getElementById('port-badge').textContent='AK7 '+p;
})();
async function loadJSON(u){ const r=await fetch(u,{cache:'no-store'}); if(!r.ok) throw new Error(u+':'+r.status); return r.json() }
async function refreshAll(){
  const L=document.getElementById('left'), R=document.getElementById('right'); L.innerHTML='로딩…'; R.innerHTML='로딩…';
  try{
    const [inbox,prs,checks,kpi]=await Promise.all([loadJSON(GH_INBOX),loadJSON(GH_PRS),loadJSON(GH_CHECKS),loadJSON(GH_KPI)]);
    L.innerHTML = (inbox.items||[]).map(x=>`<div class="card">[${x.type}] #${x.id||x.number} — ${x.title}</div>`).join('') +
                  (prs.prs||[]).map(x=>`<div class="card">PR #${x.number} — ${x.title} <span class="badge">${x.state}</span></div>`).join('');
    R.innerHTML = (checks.checks||[]).map(c=>`<div class="card">check: ${c.name} — ${c.status}</div>`).join('') +
                  `<div class="card">KPI — openPR:${kpi.openPR} / failingChecks:${kpi.failingChecks}</div>`;
  }catch(e){ L.innerHTML=R.innerHTML='<div class="card">불러오기 실패</div>'; console.warn(e); }
}
document.getElementById('refresh').addEventListener('click',()=>refreshAll());
document.addEventListener('click',async ev=>{
  const el=ev.target.closest('[data-ak7-action]'); if(!el) return; ev.preventDefault();
  const a=el.getAttribute('data-ak7-action'); const method=(a==='next'||a==='scan'||a==='test'||a==='fixloop')?'POST':'GET';
  try{
    const res=await fetch(AK7_API_BASE+'/'+a,{method,headers:{'Content-Type':'application/json'},
      body: method==='POST'? JSON.stringify({ts:new Date().toISOString(),action:a}):undefined});
    const j=await res.json(); alert(a+' → '+(j.ok?'OK':'ERR'));
  }catch(e){ alert('연결 실패'); }
});
refreshAll();
</script>
</body></html>
'@
$dual | Set-Content -LiteralPath $htmlPath -Encoding UTF8
Write-Host "[OK] UI 생성 → $HtmlRel"
} else {
  Write-Host "[SKIP] UI 존재 → $HtmlRel"
}

# ---------- 3) 모의 서버 2개 백그라운드 기동 ----------
$pidsFile = Join-Path $repo '.kobong/b-dubang.pids'
New-Item -ItemType Directory -Force -Path (Split-Path $pidsFile) | Out-Null
$procs=@()
foreach($port in @($PortA,$PortB)){
  $proc = Start-Process -PassThru pwsh -ArgumentList '-NoLogo','-NoProfile','-File',$serverPath,'-Port',"$port",'-Bind','localhost'
  $procs += $proc; Start-Sleep -Milliseconds 200
  try { Invoke-RestMethod -TimeoutSec 3 -Uri ("http://localhost:{0}/health" -f $port) | Out-Null; Write-Host "[OK] mock @ $port" }
  catch { Write-Warning "health 실패 @ $port (서버 콘솔 확인)" }
}
$procs | ForEach-Object { $_.Id } | Set-Content -LiteralPath $pidsFile -Encoding ascii

# ---------- 4) 정적 서버(HTTP) 띄우기 후 브라우저 두 탭 ----------
$rootUrl = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
  $web = Start-Process -PassThru python -ArgumentList '-m','http.server',"$WebPort" -WorkingDirectory $repo
  Write-Host "[OK] static http://localhost:$WebPort/"
  $rootUrl = "http://localhost:$WebPort/"
} else {
  Write-Warning "python 없음 → file:// 로 오픈(브라우저 정책으로 통신이 제한될 수 있음)"
}
$relUrl = $HtmlRel -replace '\\','/'
if($rootUrl){
  Start-Process ($rootUrl + $relUrl + '?api=' + $PortA)
  Start-Process ($rootUrl + $relUrl + '?api=' + $PortB)
} else {
  $fileUrl = 'file:///' + ((Join-Path $repo $HtmlRel) -replace '\\','/')
  Start-Process ($fileUrl + '?api=' + $PortA)
  Start-Process ($fileUrl + '?api=' + $PortB)
}
Write-Host "`n== B-두방 준비 완료 =="
Write-Host "좌/우 탭이 각각 ?api=$PortA, ?api=$PortB 로 열렸습니다."
Write-Host "중지하려면: pwsh -File scripts/g5/b-dubang-stop.ps1"
