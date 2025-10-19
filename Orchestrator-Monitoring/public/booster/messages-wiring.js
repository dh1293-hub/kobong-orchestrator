(()=>{ if(window.__orch_messages_v1){console.warn('messages wiring already active');return;} window.__orch_messages_v1=1;
/* ===== 환경 ===== */
const API=(window.ORCHMON_API_BASE||'').replace(/\/$/,'');
const ORIGIN = API.replace(/\/api\/orchmon$/,'') || location.origin;
const SSE_URL = API ? (API + '/timeline') : (ORIGIN + '/timeline');
const host = document.querySelector('[data-orchmon-messages]');
if(!host){ console.warn('[messages] messages host not found'); return; }

/* ===== 출력기 ===== */
const MAX_LINES = 500;
const lines = [];
const koTime = (d=new Date()) => {
  // 예: [오전 6:35:23]
  const t = d.toLocaleTimeString('ko-KR', { hour12:true, hour:'numeric', minute:'2-digit', second:'2-digit' });
  return `[${t}]`;
};
const print = (text) => {
  lines.push(text);
  if(lines.length>MAX_LINES) lines.shift();
  host.textContent = lines.join('\n');
  host.scrollTop = host.scrollHeight;
};
print(`${koTime()} messages: ready`);

/* ===== SSE 타임라인 수신 → 메시지로 요약 ===== */
let es=null, backoff=1000;
function connectSSE(){
  try{ es && es.close(); }catch{}
  es = new EventSource(SSE_URL);
  es.onopen = () => { backoff=1000; print(`${koTime()} sse: open`); };
  es.onerror= () => { print(`${koTime()} sse: error → retry ${Math.floor(backoff/1000)}s`); setTimeout(connectSSE, backoff); backoff=Math.min(15000, Math.floor(backoff*1.7)); };
  es.onmessage = (e) => {
    try{
      const o=JSON.parse(e.data||'{}');
      const tag = o.type || 'event';
      const role= o.role ? (' · '+o.role) : '';
      const act = o.action ? (' · '+o.action) : '';
      const msg = (o.msg||o.message) ? (' :: '+String(o.msg||o.message)) : '';
      print(`${koTime(new Date(o.ts||Date.now()))} ${tag}${role}${act}${msg}`);
    }catch{}
  };
}
connectSSE();

/* ===== /health & /action 페치 요약(기존 래퍼와 공존) ===== */
if(!window.__orch_fetch_msg_wrap__){
  window.__orch_fetch_msg_wrap__ = true;
  const _fetch = window.fetch.bind(window);
  window.fetch = async (input, init)=>{
    const url = (typeof input==='string' ? input : (input && input.url) || '');
    const isHealth = typeof url==='string' && /\/health(\?|$)/.test(url);
    const isAction = typeof url==='string' && /\/api\/orchmon\/action\//.test(url);

    if(isHealth) print(`${koTime()} health: checking…`);
    if(isAction){
      const act = url.split('/action/')[1]||'';
      print(`${koTime()} action: ${decodeURIComponent(act)} → start`);
    }

    try{
      const res = await _fetch(input, init);
      if(isHealth) print(`${koTime()} health: ${res.ok?'OK':'ERR '+res.status}`);
      if(isAction) print(`${koTime()} action: ${res.ok?'OK':'ERR '+res.status}`);
      return res;
    }catch(e){
      if(isHealth) print(`${koTime()} health: ERROR`);
      if(isAction) print(`${koTime()} action: ERROR`);
      throw e;
    }
  };
}

/* ===== WebSocket 열림/닫힘 감시(연결 상태 알림) ===== */
if(!window.__orch_ws_msg_wrap__){
  window.__orch_ws_msg_wrap__=true;
  const WSO=window.WebSocket;
  window.WebSocket=function(u,proto){
    const ws=new WSO(u,proto);
    const origin = String(u).replace(/^wss:/,'https:').replace(/^ws:/,'http:').replace(/(\/api|\/ws|\/socket).*/,'');
    const label  = origin.replace(location.origin,'(this)');
    ws.addEventListener('open',  ()=> print(`${koTime()} ws-open: ${label}`));
    ws.addEventListener('close', (ev)=> print(`${koTime()} ws-close: ${label} (code=${ev.code})`));
    ws.addEventListener('error', ()=> print(`${koTime()} ws-error: ${label}`));
    return ws;
  };
  Object.setPrototypeOf(window.WebSocket, WSO);
  window.WebSocket.prototype = WSO.prototype;
}

/* ===== 네비게이션 보조(선택) — Timeline 탭 버튼을 Messages 설명에 맞춰 노출 확인 ===== */
// (원본 네비 구조 유지. 필요 시 아래 한 줄로 메시지 탭을 포커싱할 수 있습니다.)
// document.querySelector('button.navbtn[data-orchmon-tab="messages"]')?.click();

console.log('%cMessages wiring active','background:#19c37d;color:#111;padding:2px 6px;border-radius:6px');
})();
