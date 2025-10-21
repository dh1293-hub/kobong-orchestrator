(()=>{ 'use strict';
/* overview-cards.js — 안정판(v2)
   - 전역 WebSocket 가드: 'ws://:PORT/…' → 'ws://localhost:PORT/…' 자동 보정
   - BASE/ORIGIN 자동결정: window.{SVC}_API_BASE || {SVC}_BASE || {SVC}_MODE(DEV/MOCK)로 추론
   - 기존 섹션(작업 요약 / 상태 요약 / 연결 상태) 기능 유지
*/

/* ===== 0) 중복 로드 방지 ===== */
if (window.__orch_overview_cards_v2) return;
window.__orch_overview_cards_v2 = 1;

/* ===== 1) 유틸: 선택자/스타일 삽입 ===== */
const $  = (s,p=document)=>p.querySelector(s);
const $$ = (s,p=document)=>Array.from(p.querySelectorAll(s));

const css = `
.orch-led{display:inline-block;width:10px;height:10px;border-radius:999px;background:#666;vertical-align:-1px}
.orch-led.ok{background:#19c37d}.orch-led.err{background:#f24822}.orch-led.warn{background:#f5a623}
.orch-kv{display:grid;grid-template-columns:auto 1fr;gap:6px 10px;align-items:center}
.orch-mono{font:12px/1.2 ui-monospace,Consolas,monospace}.orch-small{opacity:.85;font-size:.92em}
.orch-box{border:1px solid var(--border,#ffffff22);border-radius:10px;padding:8px}
.orch-table{width:100%;border-collapse:separate;border-spacing:0 6px}.orch-table td{padding:4px 6px}
.orch-badge{display:inline-block;padding:2px 6px;border-radius:999px;border:1px solid #ffffff22;font:12px/1 ui-monospace,Consolas,monospace}`;
const st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

/* ===== 2) 환경 추론: BASE / ORIGIN ===== */
function pickBase(svc, devPort, mockPort){
  const up = svc.toUpperCase();
  // 호환: *_API_BASE 또는 *_BASE 를 우선 사용
  let base = (window[`${up}_API_BASE`] || window[`${up}_BASE`] || '').trim();
  if (!base) {
    const mode = (String(window[`${up}_MODE`]||'DEV').toUpperCase()==='MOCK') ? 'MOCK' : 'DEV';
    const port = (mode==='MOCK') ? mockPort : devPort;
    base = `http://localhost:${port}/api/${up.toLowerCase()}`;
  }
  // 말단 슬래시 제거
  return base.replace(/\/$/,'');
}
function originOf(base){
  try{
    const u = new URL(base);
    // /api/… 앞부분까지를 ORIGIN 으로 사용
    return `${u.protocol}//${u.host}`;
  }catch(_){
    // file:/// 등 URL 파싱 실패 시 localhost로 가정하지 않고 빈값 반환
    return '';
  }
}
function svcObj(name, devPort, mockPort){
  const api = pickBase(name, devPort, mockPort);
  return {
    name,
    api,
    origin: originOf(api),
    sse: api ? (api + '/timeline') : null
  };
}

/* ===== 3) 서비스 구성(3중 분리 표준 포트) ===== */
const SVC = {
  ORCHMON: svcObj('ORCHMON', 5183, 5193),
  GHMON:   svcObj('GHMON',   5182, 5199),
  AK7:     svcObj('AK7',     5181, 5191),
};

/* ===== 4) 전역 WebSocket 가드 + 카운터 래퍼(단일 래핑) ===== */
if (!window.__orch_ws_wrap) {
  window.__orch_ws_wrap = { cnt:{} };
  const WSO = window.WebSocket;

  function normalizeWsUrl(u){
    // 문자열만 처리 (URL 객체는 그대로)
    if (typeof u === 'string'){
      // ws://:PORT → ws://localhost:PORT
      u = u.replace(/^ws:\/\/:(\d+)\//i,  (_,$1)=>`ws://localhost:${$1}/`);
      u = u.replace(/^wss:\/\/:(\d+)\//i, (_,$1)=>`wss://localhost:${$1}/`);
    }
    return u;
  }
  function httpOriginFromWs(u){
    try{
      const s = String(u);
      const proto = s.startsWith('wss:') ? 'https:' : 'http:';
      const m = s.match(/^wss?:\/\/([^/]+)\//i);
      const host = (m && m[1]) ? m[1] : '';
      return host ? `${proto}//${host}` : '';
    }catch{ return ''; }
  }

  const G5WS = function(u,p){
    // 1) URL 보정
    u = normalizeWsUrl(u);
    // 2) 카운트 키 산출
    const httpOrigin = httpOriginFromWs(u);
    // 3) 실제 생성
    const ws = new WSO(u,p);
    // 4) 카운트 증감
    if (httpOrigin){
      const map = window.__orch_ws_wrap.cnt;
      map[httpOrigin] = (map[httpOrigin]||0) + 1;
      const dec = ()=>{ map[httpOrigin] = Math.max(0, (map[httpOrigin]||1) - 1); };
      ws.addEventListener('close',dec); ws.addEventListener('error',dec);
    }
    return ws;
  };

  // 원형/정적 프로퍼티 유지
  Object.setPrototypeOf(G5WS, WSO);
  G5WS.prototype = WSO.prototype;
  window.WebSocket = G5WS;
}

/* ===== 5) 카드 DOM 참조 ===== */
const cards = $$('#tab-overview .cards article.card');
const findByTitle = t => cards.find(c => ( $('h5',c)?.textContent || '' ).includes(t));

/* ===== 6) (1) 작업 요약 ===== */
(function(){
  const host = findByTitle('작업 요약'); if(!host || $('[data-orch-work]',host)) return;
  const box = document.createElement('div'); box.className='orch-box'; box.setAttribute('data-orch-work','');
  box.innerHTML = `
    <div class="orch-kv orch-small">
      <div>FixLoop</div><div><span class="orch-badge" id="wFix">0</span></div>
      <div>GOOD</div><div><span class="orch-badge" id="wGood">0</span></div>
      <div>롤백</div><div><span class="orch-badge" id="wRollback">0</span></div>
    </div>
    <div class="orch-small" style="margin-top:8px"><b>최근 이벤트</b></div>
    <ul id="wRecent" class="orch-mono" style="margin:6px 0 0 0;padding-left:16px;max-height:120px;overflow:auto"></ul>`;
  host.appendChild(box);

  const inc = id => { const n=$('#'+id, box); n.textContent = String((+n.textContent||0)+1); };
  const recent = $('#wRecent', box);

  if (SVC.ORCHMON.sse){
    try{
      const es = new EventSource(SVC.ORCHMON.sse);
      es.onmessage = (e)=>{
        try{
          const o = JSON.parse(e.data||'{}');
          if (o.type==='action'){
            const a=(o.action||'').toLowerCase();
            if (a.includes('fix'))      inc('wFix');
            if (a.includes('good'))     inc('wGood');
            if (a.includes('rollback')) inc('wRollback');
            const li=document.createElement('li');
            li.textContent = `[${new Date().toLocaleTimeString()}] ${o.type} · ${o.action}`;
            recent.prepend(li); while(recent.children.length>8) recent.lastChild.remove();
          }
        }catch{}
      };
    }catch{}
  }
})();

/* ===== 7) (2) 상태 요약 ===== */
(function(){
  const host = findByTitle('상태 요약'); if(!host || $('[data-orch-status]',host)) return;
  const box = document.createElement('div'); box.className='orch-box'; box.setAttribute('data-orch-status','');
  const API = SVC.ORCHMON.api;
  box.innerHTML = `
    <table class="orch-table orch-small">
      <tr><td>현재 API</td><td class="orch-mono"><span id="sApi">${API||'—'}</span></td></tr>
      <tr><td>DEV (5181)</td><td><i id="sDev" class="orch-led"></i> <span class="orch-mono">http://localhost:5181</span></td></tr>
      <tr><td>MOCK (5191)</td><td><i id="sMock" class="orch-led"></i> <span class="orch-mono">http://localhost:5191</span></td></tr>
    </table>
    <div class="orch-small">아래 버튼으로 /health 점검</div>`;
  host.appendChild(box);

  const ping = async (base, led)=>{
    led.className='orch-led warn';
    try{ const r=await fetch(base+'/health',{cache:'no-store'}); led.className = 'orch-led ' + (r.ok?'ok':'err'); }
    catch{ led.className='orch-led err'; }
  };

  const healthBtn = $('#healthBtn', host) || (()=>{ const b=document.createElement('button'); b.className='btn'; b.textContent='/health 점검'; host.appendChild(b); return b; })();
  const run = ()=>{ ping('http://localhost:5181', $('#sDev',box)); ping('http://localhost:5191', $('#sMock',box)); };
  healthBtn.onclick = run; run();
})();

/* ===== 8) (3) 연결 상태 (ORCHMON/GHMON/AK7) ===== */
(function(){
  const host = findByTitle('연결 상태'); if(!host || $('[data-orch-conn]',host)) return;
  const box = document.createElement('div'); box.className='orch-box'; box.setAttribute('data-orch-conn','');
  box.innerHTML = `
    <table class="orch-table orch-small" id="svcTbl">
      <tr><td><b>서비스</b></td><td><b>API Base</b></td><td><b>WS 연결</b></td><td><b>최근 토스트</b></td></tr>
      ${['ORCHMON','GHMON','AK7'].map(k=>{
        const s=SVC[k]; return `<tr data-svc="${k}">
          <td>${s.name}</td>
          <td class="orch-mono"><span data-k="api">${s.api||'—'}</span></td>
          <td><span class="orch-badge" data-k="ws">0</span></td>
          <td class="orch-mono" style="max-width:340px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis"><span data-k="toast">—</span></td>
        </tr>`; }).join('')}
    </table>`;
  host.appendChild(box);

  const refresh=()=>{
    const map=window.__orch_ws_wrap.cnt||{};
    for (const k of ['ORCHMON','GHMON','AK7']){
      const s=SVC[k]; const row=box.querySelector(`tr[data-svc="${k}"]`); if(!row) continue;
      const val = String(map[s.origin]||0);
      row.querySelector('[data-k="ws"]').textContent = val;
    }
  };
  setInterval(refresh, 1500); refresh();

  // 최근 토스트 (ORCHMON SSE)
  const setToast=(k,msg)=>{ const r=box.querySelector(`tr[data-svc="${k}"]`); r && (r.querySelector('[data-k="toast"]').textContent=msg); };
  if (SVC.ORCHMON.sse){
    try{
      const es=new EventSource(SVC.ORCHMON.sse);
      es.onmessage=(e)=>{ try{
        const o=JSON.parse(e.data||'{}');
        if(o.type){ setToast('ORCHMON', `${o.type}${o.action?(' · '+o.action):''}`); }
      }catch{} };
    }catch{}
  }
  if (SVC.GHMON.api) setToast('GHMON','SSE 미구성(API_BASE 정의됨)');
  if (SVC.AK7.api)   setToast('AK7','SSE 미구성(API_BASE 정의됨)');
})();

})(); 
