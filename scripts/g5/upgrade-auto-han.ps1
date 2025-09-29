# APPLY IN SHELL — AUTO-Kobong-Han.html에 AK7 브릿지 주입(문자/버튼 간섭 없음)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$HtmlRel = 'AUTO-Kobong/webui/AUTO-Kobong-Han.html',
  [string]$BridgeRel = 'AUTO-Kobong/webui/public/ak7-bridge.js'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'

# 0) 루트/경로
$repo = (git rev-parse --show-toplevel 2>$null); if(-not $repo){ $repo=(Get-Location).Path }
$htmlPath   = Join-Path $repo $HtmlRel
$bridgePath = Join-Path $repo $BridgeRel
New-Item -ItemType Directory -Force -Path (Split-Path $htmlPath)   | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $bridgePath) | Out-Null

# 1) 브릿지 파일(없으면 생성/있으면 보존)
if(-not (Test-Path $bridgePath)){
@'
(()=>{ 
  // === AK7 Bridge (SIM/LIVE) — 문자/버튼 간섭 없음 ===
  const qs = new URLSearchParams(location.search);
  const port = qs.get("api") || "5193";                    // 탭마다 포트 선택 (?api=5192|5193)
  const LIVE_FORCE = window.AK7_API_FORCE || document.querySelector('meta[name="ak7-live-base"]')?.content || null;
  const MODE = (localStorage.getItem('AK7_MODE') || 'sim'); // 'sim' | 'live'
  const BASE = (MODE==='live' && LIVE_FORCE) ? LIVE_FORCE : `http://localhost:${port}/api/ak7`;
  const HEALTH = BASE.replace('/api/ak7','/health');
  window.AK7 = { base:BASE, health:HEALTH, port, mode:MODE,
    setMode(m){ localStorage.setItem('AK7_MODE', m); location.reload() },
    async postAction(action, payload={}) {
      const method = (['next','scan','test','fixloop','fix-preview','fix-apply','good','rollback','stop','klc'].includes(action))?'POST':'GET';
      const url = `${BASE}/${action}`;
      const idem = crypto.randomUUID(); const t0=performance.now();
      paint.req(`action=${action}; id=${idem}`);
      try{
        const res = await fetch(url,{method,headers:{'Content-Type':'application/json','X-Idempotency-Key':idem,'Connection':'close'},
          body: method==='POST' ? JSON.stringify({ts:new Date().toISOString(),action,...payload}) : undefined});
        const j = await res.json(); const dt=Math.round(performance.now()-t0);
        paint.res(`status=${j.ok===false?'err':'ok'}; durationMs=${dt}; sig=${(j.sig||'').slice(0,16)}`);
        toast(`${action} → ${j.ok===false?'ERR':'OK'}`);
        return j;
      }catch(e){ paint.res(`error=${e.message}`,'err'); toast(`${action} 실패`); return {ok:false,error:e.message} }
    }
  };

  // == UI: 토스트/LED 카드(메시지 영역 자동 탐지) ==
  const css = `.ak7-toast{position:fixed;top:16px;right:16px;padding:10px 12px;border-radius:8px;background:#121820;color:#E6F0FF;box-shadow:0 0 6px #65D1FF;z-index:9999}
  .ak7-card{background:#121820;color:#E6F0FF;border:1px solid #0B0F14;border-radius:12px;padding:10px;margin:6px 0;box-shadow:inset 0 0 2px currentColor,0 0 6px rgba(101,209,255,.25)}
  .ak7-title{display:flex;align-items:center;gap:10px;font-weight:600;margin-bottom:6px}
  .ak7-led{width:12px;height:12px;border-radius:50%;box-shadow:inset 0 0 2px currentColor,0 0 6px currentColor}
  .ok{color:#2ECC71}.warn{color:#F1C40F}.err{color:#E74C3C}.info{color:#3498DB}
  .ak7-badge{position:fixed;top:10px;left:10px;padding:4px 8px;border-radius:8px;background:#0B0F14;border:1px solid #65D1FF;color:#E6F0FF;z-index:9999;font:12px/1.2 system-ui}`;
  const st=document.createElement('style'); st.textContent=css; document.head.appendChild(st);
  function holder(){ return document.querySelector('[data-ak7-messages]') || document.getElementById('messages') || document.body }
  function card(title,meta,status='info'){ const d=document.createElement('div'); d.className='ak7-card';
    d.innerHTML=`<div class="ak7-title"><span class="ak7-led ${status}"></span><span>${title}</span></div><div>${meta}</div>`; return d }
  function toast(msg){ const t=document.createElement('div'); t.className='ak7-toast'; t.textContent=msg; document.body.appendChild(t); setTimeout(()=>t.remove(),1800) }
  const paint = {
    req(m){ holder().prepend(card('Request',m,'info')) },
    res(m,s){ holder().prepend(card('Response',m,s||'ok')) }
  };

  // 상태 배지(모드/포트/헬스)
  const b=document.createElement('div'); b.className='ak7-badge';
  b.textContent=`AK7 ${port} [${MODE.toUpperCase()}]`; document.body.appendChild(b);
  fetch(HEALTH,{cache:'no-store'}).then(r=>r.ok?b.classList.add('ok'):b.classList.add('warn')).catch(()=>b.classList.add('err'));

  // 위임 클릭: data-ak7-action 버튼만 감지(문자/스타일 불변)
  document.addEventListener('click',ev=>{
    const el=ev.target.closest('[data-ak7-action]'); if(!el) return;
    ev.preventDefault(); AK7.postAction(el.getAttribute('data-ak7-action'));
  },{capture:true});

  // GH 더미 조회(옵션): data-gh-refresh 클릭 시 좌/우 컨테이너에 채움
  async function fetchJSON(u){ const r=await fetch(u,{cache:'no-store'}); if(!r.ok) return null; return r.json() }
  window.AK7_refreshGH = async ()=>{
    const portTxt = BASE.split('/api/ak7')[0].split('://')[1].split(':')[1];
    const root = `http://localhost:${portTxt}`;
    const inbox = await fetchJSON(root+'/api/gh/inbox'); const prs = await fetchJSON(root+'/api/gh/prs');
    const checks= await fetchJSON(root+'/api/gh/checks'); const kpi = await fetchJSON(root+'/api/kpi');
    console.log('[AK7 GH]',{inbox,prs,checks,kpi}); toast('GH 갱신');
  };
})();
'@ | Set-Content -LiteralPath $bridgePath -Encoding UTF8
  Write-Host "[OK] 생성: $BridgeRel"
} else {
  Write-Host "[SKIP] 존재: $BridgeRel"
}

# 2) HTML 스니펫(</body> 직전): API_FORCE + bridge.js
$snippet = @"
<script>/* 운영 전환 시 한 줄: window.AK7_API_FORCE='https://KO-BASE/api/ak7' */</script>
<script src="$([IO.Path]::GetFileName($BridgeRel))"></script>
"@
$html = if(Test-Path $htmlPath){ Get-Content -Raw -LiteralPath $htmlPath -Encoding UTF8 } else {
"<!doctype html><html lang=""ko""><head><meta charset=""utf-8""><title>AUTO-Kobong</title></head><body>
<section id=""messages"" data-ak7-messages></section>
</body></html>"
}
if ($html -match [regex]::Escape((Split-Path -Leaf $BridgeRel))) {
  Write-Host "[SKIP] 이미 주입: $HtmlRel"
} else {
  $bak = "$htmlPath.bak-ak7-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  Copy-Item -LiteralPath $htmlPath -Destination $bak -Force -ErrorAction SilentlyContinue
  $rx='(?is)</\s*body\s*>'
  if([regex]::IsMatch($html,$rx)){ $html = [regex]::Replace($html,$rx,$snippet + '</body>') } else { $html += "`r`n$snippet" }
  $tmp="$htmlPath.tmp"; $html | Out-File -LiteralPath $tmp -Encoding UTF8
  Move-Item -LiteralPath $tmp -Destination $htmlPath -Force
  Write-Host "[OK] 주입 완료: $HtmlRel (백업: $(Split-Path -Leaf $bak))"
}
Write-Host "`n== 업그레이드 끝: 이 파일만 기억하세요 =="
Write-Host " - HTML: $HtmlRel"
Write-Host " - JS  : $BridgeRel"
