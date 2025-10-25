(()=>{ if(window.__orch_overview_cards_v1){return;} window.__orch_overview_cards_v1=1;
const API=(window.ORCHMON_API_BASE||"").replace(/\/$/,"");
const ORIGIN=API.replace(/\/api\/orchmon$/,"")||location.origin;
const SVC={ ORCHMON:{name:"ORCHMON", api:API, origin:ORIGIN, sse: API? (API+"/timeline"):null},
            GHMON:{name:"GHMON", api:(window.GHMON_API_BASE||"").replace(/\/$/,""),
                   origin:(window.GHMON_API_BASE||"").replace(/\/api\/.*$/,""), sse: window.GHMON_API_BASE? (window.GHMON_API_BASE.replace(/\/$/,"")+"/timeline"):null},
            AK7:{name:"AK7", api:(window.AK7_API_BASE||"").replace(/\/$/,""),
                 origin:(window.AK7_API_BASE||"").replace(/\/api\/.*$/,""), sse: window.AK7_API_BASE? (window.AK7_API_BASE.replace(/\/$/,"")+"/timeline"):null} };
const $=(s,p=document)=>p.querySelector(s), $$=(s,p=document)=>Array.from(p.querySelectorAll(s));

const css=`.orch-led{display:inline-block;width:10px;height:10px;border-radius:999px;background:#666;vertical-align:-1px}
.orch-led.ok{background:#19c37d}.orch-led.err{background:#f24822}.orch-led.warn{background:#f5a623}
.orch-kv{display:grid;grid-template-columns:auto 1fr;gap:6px 10px;align-items:center}
.orch-mono{font:12px/1.2 ui-monospace,Consolas,monospace}.orch-small{opacity:.85;font-size:.92em}
.orch-box{border:1px solid var(--border,#ffffff22);border-radius:10px;padding:8px}
.orch-table{width:100%;border-collapse:separate;border-spacing:0 6px}.orch-table td{padding:4px 6px}
.orch-badge{display:inline-block;padding:2px 6px;border-radius:999px;border:1px solid #ffffff22;font:12px/1 ui-monospace,Consolas,monospace}`;
const st=document.createElement("style"); st.textContent=css; document.head.appendChild(st);

const cards = $$('#tab-overview .cards article.card');
const findByTitle = t=> cards.find(c=> ( $('h5',c)?.textContent||'' ).includes(t));

/* 1) 작업 요약 */
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

  if(SVC.ORCHMON.sse){
    try{
      const es = new EventSource(SVC.ORCHMON.sse);
      es.onmessage = (e)=>{ try{
        const o = JSON.parse(e.data||'{}');
        if(o.type==='action'){
          const a=(o.action||'').toLowerCase();
          if(a.includes('fix')) inc('wFix');
          if(a.includes('good')) inc('wGood');
          if(a.includes('rollback')) inc('wRollback');
          const li=document.createElement('li');
          li.textContent = `[${new Date().toLocaleTimeString()}] ${o.type} · ${o.action}`;
          recent.prepend(li); while(recent.children.length>8) recent.lastChild.remove();
        }
      }catch{} };
    }catch{}
  }
})();

/* 2) 상태 요약 */
(function(){
  const host = findByTitle('상태 요약'); if(!host || $('[data-orch-status]',host)) return;
  const box = document.createElement('div'); box.className='orch-box'; box.setAttribute('data-orch-status','');
  box.innerHTML = `
    <table class="orch-table orch-small">
      <tr><td>현재 API</td><td class="orch-mono"><span id="sApi">${API||'—'}</span></td></tr>
      <tr><td>DEV (5183)</td><td><i id="sDev" class="orch-led"></i> <span class="orch-mono">http://localhost:5183</span></td></tr>
      <tr><td>MOCK (5193)</td><td><i id="sMock" class="orch-led"></i> <span class="orch-mono">http://localhost:5193</span></td></tr>
    </table>
    <div class="orch-small">아래 버튼으로 /health 점검</div>`;
  host.appendChild(box);

  const ping = async (base, led)=>{ led.className='orch-led warn';
    try{ const r=await fetch(base+'/health',{cache:'no-store'}); led.className = 'orch-led ' + (r.ok?'ok':'err'); }
    catch{ led.className='orch-led err'; } };

  const healthBtn = $('#healthBtn', host) || (()=>{ const b=document.createElement('button'); b.className='btn'; b.textContent='/health 점검'; host.appendChild(b); return b; })();
  const run = ()=>{ ping('http://localhost:5183', $('#sDev',box)); ping('http://localhost:5193', $('#sMock',box)); };
  healthBtn.onclick = run; run();
})();

/* 3) 연결 상태 (ORCHMON/GHMON/AK7) */
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

  // WS 연결수 래퍼(멱등)
  if(!window.__orch_ws_wrap){
    window.__orch_ws_wrap={cnt:{}};
    const WSO=window.WebSocket;
    window.WebSocket=function(u,p){ const ws=new WSO(u,p); try{
      const httpOrigin=String(u).replace(/^wss:/,'https:').replace(/^ws:/,'http:').replace(/(\/api|\/ws|\/socket).*/,'');
      window.__orch_ws_wrap.cnt[httpOrigin]=(window.__orch_ws_wrap.cnt[httpOrigin]||0)+1;
      const dec=()=>{ window.__orch_ws_wrap.cnt[httpOrigin]=Math.max(0,(window.__orch_ws_wrap.cnt[httpOrigin]||1)-1); };
      ws.addEventListener('close',dec); ws.addEventListener('error',dec);
    }catch{} return ws; };
    Object.setPrototypeOf(window.WebSocket, WSO); window.WebSocket.prototype=WSO.prototype;
  }
  const refresh=()=>{ const map=window.__orch_ws_wrap.cnt||{};
    for(const k of ['ORCHMON','GHMON','AK7']){ const s=SVC[k]; const row=box.querySelector(`tr[data-svc="${k}"]`); if(!row) continue;
      box.querySelector(`[data-svc="${k}"] [data-k="ws"]`).textContent = String(map[s.origin]||0);
    } };
  setInterval(refresh, 1500); refresh();

  // 최근 토스트 (ORCHMON SSE)
  const setToast=(k,msg)=>{ const r=box.querySelector(`tr[data-svc="${k}"]`); r && (r.querySelector('[data-k="toast"]').textContent=msg); };
  if(SVC.ORCHMON.sse){ try{ const es=new EventSource(SVC.ORCHMON.sse);
    es.onmessage=(e)=>{ try{ const o=JSON.parse(e.data||'{}'); if(o.type){ setToast('ORCHMON', `${o.type}${o.action?(' · '+o.action):''}`); } }catch{} }; }catch{} }
  if(SVC.GHMON.api) setToast('GHMON','SSE 미구성(API_BASE 정의됨)');
  if(SVC.AK7.api)   setToast('AK7','SSE 미구성(API_BASE 정의됨)');
})();
})();