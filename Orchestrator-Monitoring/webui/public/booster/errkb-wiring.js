(()=>{ if(window.__orch_errkb_v1){return;} window.__orch_errkb_v1=1;
// ORCHBUS 구독 → #tab-errkb .card 내부에 간단한 에러 지문 집계 테이블 렌더
const $=(s,p=document)=>p.querySelector(s), $$=(s,p=document)=>Array.from(p.querySelectorAll(s));
const host = $('#tab-errkb .card'); if(!host){ console.log("[errkb] host not found"); return; }

const box = document.createElement("div"); box.className="orch-box"; host.appendChild(box);
box.innerHTML = `
  <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
    <b class="orch-small">Error-KB (실시간 집계)</b>
    <span class="orch-mono orch-small" data-k="meta">0 entries</span>
  </div>
  <table class="orch-table orch-small" id="kbTbl">
    <thead><tr><td><b>#</b></td><td><b>Fingerprint</b></td><td><b>Count</b></td><td><b>Last</b></td></tr></thead>
    <tbody></tbody>
  </table>
`;

const tbody = box.querySelector("tbody"); const meta = box.querySelector('[data-k="meta"]');
const map = new Map(); // key -> {count, lastTs, sample}
const MAX_ROWS=20;

function fingerprint(o){
  // 우선순위: errCode || action || msg 일부
  const code = (o.errCode||o.code||'').toString().trim();
  if(code) return 'E#'+code;
  const act = (o.action||'').toString().trim();
  if(act) return 'ACT:'+act;
  const msg = (o.msg||o.message||'').toString().trim();
  if(msg) return 'MSG:'+msg.slice(0,80);
  return (o.type||'unknown');
}

function upsert(o){
  const key=fingerprint(o);
  const cur=map.get(key)||{count:0,lastTs:0,sample:o};
  cur.count++; cur.lastTs = o.ts||Date.now(); cur.sample=o;
  map.set(key,cur);
}

function render(){
  // count desc → lastTs desc
  const rows=[...map.entries()].sort((a,b)=>{
    if(b[1].count!==a[1].count) return b[1].count-a[1].count;
    return (b[1].lastTs||0)-(a[1].lastTs||0);
  }).slice(0,MAX_ROWS);

  tbody.innerHTML='';
  rows.forEach(([,v],i)=>{
    const tr=document.createElement('tr');
    const last=new Date(v.lastTs||Date.now()).toLocaleTimeString();
    tr.innerHTML = `<td>${i+1}</td><td class="orch-mono">${(v.sample && (v.sample.errCode||v.sample.action||((v.sample.msg||v.sample.message||'').toString().slice(0,80))))||'-'}</td><td>${v.count}</td><td class="orch-mono">${last}</td>`;
    tbody.appendChild(tr);
  });
  meta.textContent = `${map.size} entries`;
}

function onEvent(o){
  const t=(o.type||'').toLowerCase();
  // 에러로 볼만한 것만 집계: type=error 이거나, action/메시지에 error/fail/rollback 지문
  const a=(o.action||'').toLowerCase();
  const m=((o.msg||o.message||'')+'').toLowerCase();
  if(t==='error' || /error|fail|rollback|exception|timeout/.test(a) || /error|fail|rollback|exception|timeout/.test(m)){
    upsert(o); render();
  }
}

if(window.ORCHBUS && typeof ORCHBUS.subscribe==='function'){
  ORCHBUS.subscribe(onEvent);
  console.log("[errkb] wired to ORCHBUS");
}else{
  console.warn("[errkb] ORCHBUS not found; wiring skipped");
}
})();