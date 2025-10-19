(()=>{ if(window.__tl_tools_v2){return;} window.__tl_tools_v2=1;
const API=(window.ORCHMON_API_BASE||"").replace(/\/$/,"");
const ORIGIN=API.replace(/\/api\/orchmon$/,"")||location.origin;
const SSE_URL = API ? (API + "/timeline") : (ORIGIN + "/timeline");
const $=(s,p=document)=>p.querySelector(s), $$=(s,p=document)=>Array.from(p.querySelectorAll(s));
const host = $('#tab-timeline .card') || $('#tab-timeline'); if(!host) return;
let ul = host.querySelector('ul'); if(!ul){ ul=document.createElement('ul'); ul.style.marginTop='8px'; ul.style.listStyle='none'; ul.style.padding='0'; host.appendChild(ul); }
let bar = host.querySelector('.tl-bar'); if(!bar){ bar=document.createElement('div'); bar.className='tl-bar'; bar.innerHTML=`
  <input placeholder="검색" data-k="q" size="18">
  <select data-k="type"><option value="">type:전체</option><option>action</option><option>info</option><option>log</option><option>ws-open</option><option>ws-close</option></select>
  <input placeholder="action 필터" data-k="act" size="14">
  <select data-k="role"><option value="">role:전체</option><option>input</option><option>server</option><option>vserver</option><option>aux</option><option>extra</option></select>
  <label><input type="checkbox" data-k="pinnedOnly"> pinned만</label>
  <label><input type="checkbox" data-k="autoscroll" checked> autoscroll</label>
  <button class="btn" data-k="pause">⏸ pause</button>
  <button class="btn" data-k="jump">↘ live</button>
  <button class="btn" data-k="export">⤓ export ndjson</button>
  <button class="btn" data-k="clear">clear</button>
  <span class="tl-mono" data-k="cnt">0</span>`; host.prepend(bar); }
const state = window.__TL_STATE = (window.__TL_STATE||{ paused:false, autoscroll:true, buf:[], cnt:0 });
state.ul=ul; state.bar=bar;
const getK=k=>$('[data-k="'+k+'"]',bar);
getK('autoscroll').checked=!!state.autoscroll;
getK('autoscroll').addEventListener('change',e=> state.autoscroll=e.target.checked);
getK('pause').textContent = state.paused?'▶ resume':'⏸ pause';
getK('pause').addEventListener('click',()=>{ state.paused=!state.paused; getK('pause').textContent = state.paused?'▶ resume':'⏸ pause'; });
getK('jump').addEventListener('click',()=>{ ul.scrollTop=ul.scrollHeight; });
getK('clear').addEventListener('click',()=>{ while(ul.firstChild) ul.removeChild(ul.firstChild); });
getK('export').addEventListener('click',()=>{ const nd=state.buf.map(o=>JSON.stringify(o)).join('\n')+'\n';
  const blob=new Blob([nd],{type:'application/x-ndjson'}); const a=document.createElement('a'); a.href=URL.createObjectURL(blob);
  a.download='timeline_'+new Date().toISOString().replace(/[:.]/g,'')+'.ndjson'; a.click(); setTimeout(()=>URL.revokeObjectURL(a.href),1000); });
function applyFilters(){ const qv=(getK('q').value||'').toLowerCase(); const ty=(getK('type').value||''); const rl=(getK('role').value||''); const ac=(getK('act').value||'').toLowerCase(); const onlyPinned=getK('pinnedOnly').checked;
  $$('li',ul).forEach(li=>{ const t=li.textContent.toLowerCase(); const isTy=!ty||t.includes(` ${ty}`)||t.includes(`type:${ty}`); const isRl=!rl||t.includes(` ${rl}`)||t.includes(`role:${rl}`); const isAc=!ac||t.includes(` ${ac}`)||t.includes(`action:${ac}`); const isQ=!qv||t.includes(qv); const isPin=!onlyPinned||li.classList.contains('tl-pinned'); li.style.display=(isTy&&isRl&&isAc&&isQ&&isPin)?'':''; }); }
bar.addEventListener('input', applyFilters);
function addItem(o){ const li=document.createElement('li'); li.className='tl-mono';
  const ts=new Date(o.ts||Date.now()).toLocaleTimeString(); const meta=[o.type,o.role,o.action].filter(Boolean).join(' · '); const msg=(o.msg||o.message||'')+'';
  li.textContent=`[${ts}] ${meta}${msg?(' :: '+msg):''}`; li.title='클릭: pin 토글'; li.addEventListener('click',()=>li.classList.toggle('tl-pinned'));
  ul.appendChild(li); if(state.autoscroll) ul.scrollTop=ul.scrollHeight; if(ul.children.length>2000) ul.removeChild(ul.firstChild); }
function onEvent(o){ state.buf.push(o); if(state.buf.length>5000) state.buf.shift(); state.cnt++; getK('cnt').textContent=String(state.cnt); if(!state.paused){ addItem(o); applyFilters(); } }
if(window.ORCHBUS && typeof window.ORCHBUS.subscribe==='function'){ window.ORCHBUS.subscribe(onEvent); }
else{ let es=null, backoff=1000;(function connect(){ es&&es.close(); es=new EventSource(SSE_URL);
  es.onopen=()=>{ backoff=1000; }; es.onerror=()=>{ setTimeout(connect,backoff); backoff=Math.min(15000,Math.floor(backoff*1.7)); };
  es.onmessage=(e)=>{ try{ onEvent(JSON.parse(e.data||'{}')); }catch{} }; })(); }
window.__TL_API={ addItem, applyFilters, state };
})();