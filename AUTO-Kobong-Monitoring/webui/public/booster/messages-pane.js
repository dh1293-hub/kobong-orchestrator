(()=>{ if(window.__orch_messages_pane_v1){return;} window.__orch_messages_pane_v1=1;
const card = document.querySelector('#tab-messages .card'); if(!card){ console.warn('[messages] host not found'); return; }
const oldArea = card.querySelector('[data-orchmon-messages]');
const host = document.createElement('div'); host.className='messages-pane'; card.appendChild(host);

const css = `
.msg-bar{display:flex;gap:8px;flex-wrap:wrap;margin:8px 0 12px}
.msg-bar input,.msg-bar select{padding:8px 10px;border-radius:10px;border:1px solid var(--border,#ffffff22);background:transparent;color:var(--fg,inherit)}
.msg-bar .btn{padding:8px 12px;border-radius:10px;border:1px solid #ffffff22;background:transparent;cursor:pointer}
.msg-badge{font:12px/1 ui-monospace,Consolas,monospace;border:1px solid #ffffff22;border-radius:999px;padding:2px 8px}
.msg-list{list-style:none;margin:0;padding:0;max-height:48vh;overflow:auto;border:1px solid #ffffff22;border-radius:10px}
.msg-li{padding:10px 12px;border-bottom:1px dashed #ffffff22}
.msg-li:last-child{border-bottom:none}
.msg-head{display:flex;gap:8px;align-items:center;justify-content:space-between}
.msg-meta{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.msg-chip{font:11px/1 ui-monospace,Consolas,monospace;border:1px solid #ffffff22;border-radius:999px;padding:2px 6px}
.msg-chip.err{border-color:#f24822}
.msg-chip.ok{border-color:#19c37d}
.msg-chip.info{border-color:#66b3ff}
.msg-chip.action{border-color:#f5a623}
.msg-time{opacity:.8;font:12px/1 ui-monospace,Consolas,monospace}
.msg-body{margin-top:6px;white-space:pre-wrap;word-break:break-word}
.msg-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}
.msg-dot{width:8px;height:8px;border-radius:999px;background:#66b3ff;display:inline-block}
.msg-dot.read{background:#ffffff33}
.msg-pin{all:unset;cursor:pointer;border:1px solid #ffffff22;border-radius:8px;padding:2px 6px}
`;
const st=document.createElement('style'); st.textContent=css; document.head.appendChild(st);

const bar=document.createElement('div'); bar.className='msg-bar';
bar.innerHTML = `
  <input placeholder="검색(메시지/지문)" data-k="q" size="22">
  <select data-k="type"><option value="">type:전체</option><option>error</option><option>action</option><option>info</option><option>log</option></select>
  <input placeholder="action 필터" data-k="act" size="14">
  <select data-k="role"><option value="">role:전체</option><option>input</option><option>server</option><option>vserver</option><option>aux</option><option>extra</option></select>
  <label><input type="checkbox" data-k="autoscroll" checked> autoscroll</label>
  <button class="btn" data-k="pause">⏸ pause</button>
  <button class="btn" data-k="live">↘ live</button>
  <button class="btn" data-k="markread">모두 읽음</button>
  <button class="btn" data-k="export">⤓ export (ndjson)</button>
  <button class="btn" data-k="clear">clear</button>
  <span class="msg-badge" data-k="meta">0 items · 0 unread</span>`;
host.appendChild(bar);

const ul=document.createElement('ul'); ul.className='msg-list'; host.appendChild(ul);
const state = { paused:false, autoscroll:true, buf:[], unread:0 };
const getK = k => bar.querySelector(`[data-k="${k}"]`);
getK('autoscroll').addEventListener('change',e=> state.autoscroll = e.target.checked);
getK('pause').addEventListener('click',()=>{ state.paused=!state.paused; getK('pause').textContent = state.paused?'▶ resume':'⏸ pause'; });
getK('live').addEventListener('click',()=>{ ul.scrollTop = ul.scrollHeight; });
getK('markread').addEventListener('click',()=>{ state.unread=0; ul.querySelectorAll('.msg-dot').forEach(d=>d.classList.add('read')); refreshMeta(); });
getK('clear').addEventListener('click',()=>{ ul.innerHTML=''; state.buf.length=0; state.unread=0; refreshMeta(); });
getK('export').addEventListener('click',()=>{
  const nd = state.buf.map(o=>JSON.stringify(o)).join('\\n')+'\\n';
  const blob = new Blob([nd], {type:'application/x-ndjson'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob);
  a.download='messages_'+new Date().toISOString().replace(/[:.]/g,'')+'.ndjson'; a.click();
  setTimeout(()=>URL.revokeObjectURL(a.href),1000);
});
bar.addEventListener('input', applyFilters);
function refreshMeta(){ getK('meta').textContent = `${state.buf.length} items · ${state.unread} unread`; }
function passFilter(o){
  const q=(getK('q').value||'').toLowerCase();
  const ty=(getK('type').value||'').toLowerCase();
  const rl=(getK('role').value||'').toLowerCase();
  const ac=(getK('act').value||'').toLowerCase();
  const T=(o.type||'').toLowerCase(), R=(o.role||'').toLowerCase(), A=(o.action||'').toLowerCase();
  const M=((o.msg||o.message||'')+'').toLowerCase();
  if(ty && T!==ty) return false; if(rl && R!==rl) return false; if(ac && !A.includes(ac)) return false; if(q && !(M.includes(q)||A.includes(q))) return false; return true;
}
function applyFilters(){ [...ul.children].forEach(li=>{ const o=li.__data; li.style.display = passFilter(o) ? '' : 'none'; }); }
function chipCls(type){ const t=(type||'').toLowerCase(); if(t==='error')return'msg-chip err'; if(t==='action')return'msg-chip action'; if(t==='info')return'msg-chip info'; return 'msg-chip'; }
function addItem(o){
  const li=document.createElement('li'); li.className='msg-li'; li.__data=o;
  const time=new Date(o.ts||Date.now()).toLocaleTimeString(); const type=o.type||'-', role=o.role||'-', action=o.action||'-';
  const msg=(o.msg||o.message||'')+'';
  li.innerHTML = `
    <div class="msg-head">
      <div class="msg-meta">
        <span class="${chipCls(type)}">${type}</span>
        <span class="msg-chip">${role}</span>
        <span class="msg-chip">${action}</span>
        <span class="msg-time">${time}</span>
      </div>
      <div class="msg-meta">
        <span class="msg-dot" title="unread"></span>
        <button class="msg-pin" data-act="pin">☆ pin</button>
      </div>
    </div>
    <div class="msg-body">${msg}</div>
    <div class="msg-actions">
      <button class="btn" data-act="copy-text">복사(텍스트)</button>
      <button class="btn" data-act="copy-json">복사(JSON)</button>
    </div>`;
  li.addEventListener('click', async (e)=>{
    const b=e.target.closest('button[data-act]'); 
    if(!b){ const dot=li.querySelector('.msg-dot'); if(dot && !dot.classList.contains('read')){ dot.classList.add('read'); state.unread=Math.max(0,state.unread-1); refreshMeta(); } return; }
    const act=b.dataset.act;
    if(act==='pin'){ const pinned=b.textContent.includes('★'); b.textContent = pinned?'☆ pin':'★ pinned'; }
    if(act==='copy-text'){ try{ await navigator.clipboard.writeText(msg); b.textContent='복사됨!'; setTimeout(()=>b.textContent='복사(텍스트)',800);}catch{} }
    if(act==='copy-json'){ try{ await navigator.clipboard.writeText(JSON.stringify(o,null,2)); b.textContent='복사됨!'; setTimeout(()=>b.textContent='복사(JSON)',800);}catch{} }
  });
  ul.appendChild(li);
  if(state.autoscroll) ul.scrollTop=ul.scrollHeight;
  applyFilters();
}
function push(o){ state.buf.push(o); if(state.buf.length>2000) state.buf.shift(); if(!state.paused){ addItem(o); } state.unread++; refreshMeta(); }
function onEvent(o){ const t=(o.type||'').toLowerCase(); if(!t) return; if(['info','log','action','error'].includes(t)){ push(o); } }
if(window.ORCHBUS && typeof ORCHBUS.subscribe==='function'){ ORCHBUS.subscribe(onEvent); } else {
  console.warn('[messages] ORCHBUS not found; samples only');
  [{type:'info',role:'host',action:'health',msg:'{"ok":true,"service":"orchmon","mode":"MOCK"}',ts:Date.now()-45000},
   {type:'action',role:'input',action:'good',msg:'user pressed GOOD',ts:Date.now()-30000},
   {type:'error',role:'web',action:'health',msg:'[ORCHMON] health: ERROR Failed to fetch',ts:Date.now()-20000},
   {type:'info',role:'server',action:'start',msg:'mock v2 ready at :5193',ts:Date.now()-15000},
   {type:'log',role:'server',action:'sse',msg:'timeline connected',ts:Date.now()-12000}].forEach(onEvent);
}
if(oldArea){ const last=state.buf[state.buf.length-1]; if(last){ oldArea.textContent=`[${new Date(last.ts||Date.now()).toLocaleTimeString()}] ${last.action||last.type}: ${ (last.msg||last.message||'')+'' }`; } }
setTimeout(()=>{ console.log('Messages ready · items:', state.buf.length, 'unread:', state.unread); }, 800);
})();