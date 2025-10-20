(()=>{ if(window.__orch_messages_v1){return;} window.__orch_messages_v1=1;
// ORCHBUS 구독 → #tab-messages 내 [data-orchmon-messages] 갱신 + Shells 하단 메시지도 동기
const $=(s,p=document)=>p.querySelector(s), $$=(s,p=document)=>Array.from(p.querySelectorAll(s));
const areas = $$('[data-orchmon-messages]');
if(!areas.length){ console.log("[messages] no message areas"); return; }

const ring=[]; const MAX=200;
function pushLine(txt){ ring.push(txt); if(ring.length>MAX) ring.shift(); areas.forEach(a=>a.textContent=txt); }

function fmt(o){
  const ts=new Date(o.ts||Date.now()).toLocaleTimeString();
  const head=[o.type,o.action,o.role].filter(Boolean).join(' · ');
  const msg=(o.msg||o.message||'')+''; 
  return `[${ts}] ${head}${msg?(' :: '+msg):''}`;
}

function onEvent(o){
  // 메시지로 적합한 이벤트만(임의 기준): type in {info,log,action,error} 등
  const t=(o.type||'').toLowerCase();
  if(!t) return;
  if(t==='info'||t==='log'||t==='action'||t==='error'){
    pushLine(fmt(o));
  }
}

// 버스 구독(없으면 조용히 skip)
if(window.ORCHBUS && typeof ORCHBUS.subscribe==='function'){
  ORCHBUS.subscribe(onEvent);
  console.log("[messages] wired to ORCHBUS");
}else{
  console.warn("[messages] ORCHBUS not found; wiring skipped");
}
})();