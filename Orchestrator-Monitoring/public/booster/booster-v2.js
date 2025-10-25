(()=>{ if(window.__orch_boost_v2){console.warn("booster already active");return;} window.__orch_boost_v2=1;
"use strict";

/* ===== 공통 ===== */
const API  = (window.ORCHMON_API_BASE||"").replace(/\/$/,"");
const ORIGIN = API.replace(/\/api\/orchmon$/,"") || location.origin;
const q  = (s,p=document)=>p.querySelector(s);
const qa = (s,p=document)=>Array.from(p.querySelectorAll(s));

/* ===== LED 액션 라이프사이클 (busy→OK/ERR, 10s timeout) ===== */
const ledEl = q('[data-orchmon-led]') || q('.led');
const setLED = (s)=>{ if(ledEl) ledEl.setAttribute('data-state', s); };
const _fetch = window.fetch.bind(window);
window.fetch = async (input, init)=>{
  const url = (typeof input==='string'? input : input?.url) || '';
  const isAction = typeof url==='string' && /\/api\/orchmon\/action\//.test(url);
  let to=null;
  if(isAction){ setLED('warn'); to=setTimeout(()=>setLED('err'), 10_000); }
  try{
    const res = await _fetch(input, init);
    if(isAction){ clearTimeout(to); setLED(res.ok?'ok':'err'); }
    return res;
  }catch(e){
    if(isAction){ clearTimeout(to); setLED('err'); }
    throw e;
  }
};

/* ===== Overview: 연결 상태 카드 주입 (디자인 불변) ===== */
(function injectConnCard(){
  // 주입 위치: Overview 탭의 마지막 카드 뒤
  const host = q('#tab-overview'); if(!host) return;
  if(q('[data-orchmon-conn]', host)) return; // 멱등
  const card = document.createElement('section');
  card.className='card'; card.setAttribute('data-orchmon-conn','');
  card.innerHTML = `
    <h5>연결 상태</h5>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
      <div><b>모드</b><div data-f="mode">—</div></div>
      <div><b>API Base</b><div data-f="api"></div></div>
      <div><b>DEV</b><div><code>http://localhost:5183</code> <i class="led" data-f="dev-led"></i></div></div>
      <div><b>MOCK</b><div><code>http://localhost:5193</code> <i class="led" data-f="mock-led"></i></div></div>
    </div>
    <div style="margin-top:8px;display:flex;gap:8px;flex-wrap:wrap">
      <button class="btn" data-act="health">Health</button>
      <button class="btn" data-act="copy">상태 복사</button>
      <button class="btn" data-act="shells">Shells 열기</button>
    </div>`;
  host.appendChild(card);

  const F=(k)=>q(`[data-f="${k}"]`, card);
  const set=(k,v)=>{ const el=F(k); if(el) el.textContent=v; };
  const led=(k,st)=>{ const el=F(k); if(el) el.setAttribute('data-state', st); };

  const mode = /:5193\b/.test(ORIGIN) ? 'MOCK' : 'DEV';
  set('mode', mode); set('api', API);

  async function ping(url){
    try{ const r=await fetch(url+'/health',{cache:'no-store'}); return r.ok; }catch{ return false; }
  }
  (async ()=>{
    led('dev-led', (await ping('http://localhost:5183'))?'ok':'err');
    led('mock-led',(await ping('http://localhost:5193'))?'ok':'err');
  })();

  card.addEventListener('click', async (e)=>{
    const b = e.target.closest('button[data-act]'); if(!b) return;
    const act=b.dataset.act;
    if(act==='health'){
      try{ const r=await fetch(ORIGIN+'/health'); setLED(r.ok?'ok':'err'); }catch{ setLED('err'); }
    }
    if(act==='copy'){
      const msg=`mode=${mode} api=${API}`;
      try{ await navigator.clipboard.writeText(msg); }catch{}
    }
    if(act==='shells'){
      q('[data-orchmon-action="shell-open"]')?.click();
    }
  });
})();
console.log('%cOrchMon booster-v2 active','background:#19c37d;color:#111;padding:2px 6px;border-radius:6px');
})();