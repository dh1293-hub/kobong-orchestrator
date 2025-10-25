/* kobong-step3-sse-wrapper v1 */
(function(){
  if (window.KB && window.KB.sseConnect) return;
  const KB = (window.KB = window.KB || {});
  KB.sseState = { connected:false, attempts:0, lastError:null, fallback:false };
  KB.sseConnect = function(url, onMessage){
    url = url || '/events';
    if (!('EventSource' in window)) { console.warn('[KB] EventSource unsupported; fallback to polling'); startPoll('/metrics'); return {close(){}}; }
    let es=null; const MAX=30000;
    function dispatch(type, detail){ try{ window.dispatchEvent(new CustomEvent('kb:sse',{detail:{type, ...(detail||{})}})); }catch{} }
    function connect(){
      KB.sseState.attempts++;
      try{ es = new EventSource(url); }catch(e){ KB.sseState.lastError=e?.message||'ctor'; }
      if (!es) { scheduleReconnect(); return; }
      es.onopen = function(){ KB.sseState.connected=true; KB.sseState.lastError=null; KB.sseState.fallback=false; dispatch('open'); };
      es.onerror = function(e){
        KB.sseState.connected=false;
        KB.sseState.lastError = (e && e.message) || 'error';
        try{ es.close(); }catch{}
        scheduleReconnect();
        dispatch('error',{error:KB.sseState.lastError, attempts:KB.sseState.attempts});
      };
      es.onmessage = function(ev){
        dispatch('message',{data:ev.data});
        if (onMessage) { try{ onMessage(ev) }catch{} }
      };
    }
    function scheduleReconnect(){
      const delay = Math.min(1000 * Math.pow(2, Math.min(KB.sseState.attempts,5)), MAX);
      setTimeout(function(){
        if (KB.sseState.attempts >= 8 && !KB.sseState.connected) { console.warn('[KB] SSE fallback → polling /metrics'); startPoll('/metrics'); return; }
        connect();
      }, delay);
    }
    connect();
    return { close(){ try{ es && es.close(); }catch{} } };
  };
  function startPoll(url, interval){
    url = url || '/metrics'; interval = interval || 15000;
    KB.sseState.fallback = true;
    async function tick(){
      try{
        const r = await fetch(url, {cache:'no-store'});
        const t = await r.text();
        window.dispatchEvent(new CustomEvent('kb:metrics',{detail:{ok:r.ok,text:t}}));
      }catch(e){}
      setTimeout(tick, interval);
    }
    tick();
  }
  window.addEventListener('kb:sse', function(ev){
    var el = document.getElementById('sse-conn') || document.getElementById('sse-dot');
    if (!el) return;
    var type = ev.detail && ev.detail.type;
    if (type==='open'){ el.textContent='online'; el.style.opacity='0.7'; }
    else if (type==='error'){ el.textContent='reconnecting…'; el.style.opacity='0.5'; }
  });
})();
/* kobong-step1-sse-badge-note: badge hidden by CSS (#sse-error,.sse-error-badge) */
(async function(){
  const upEl = document.getElementById("updated");
  const httpEl = document.querySelector("#httpCard .rows");
  const tcpEl  = document.querySelector("#tcpCard .rows");
  const taskEl = document.querySelector("#taskCard .rows");
  async function load(){
    try{
      const resp = await fetch(`/data/gh-monitor.json?_=${Date.now()}`, {cache:"no-store"});
      if(!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const j = await resp.json();
      upEl.textContent = new Date(j.timestamp).toLocaleString();
      httpEl.innerHTML = "";
      (j.http||[]).forEach(x=>{
        const row = document.createElement("div"); row.className="row";
        const left = document.createElement("div"); left.textContent = x.url;
        const right = document.createElement("div");
        const span = document.createElement("span");
        const ok = !!x.ok;
        span.className = "pill " + (ok ? "ok" : "bad");
        span.textContent = ok ? `OK ${x.status}` : `ERR`;
        right.appendChild(span);
        row.append(left,right); httpEl.appendChild(row);
      });
      tcpEl.innerHTML = "";
      (j.tcp||[]).forEach(x=>{
        const row = document.createElement("div"); row.className="row";
        const left = document.createElement("div"); left.textContent = `:${x.port}`;
        const right = document.createElement("div");
        const span = document.createElement("span");
        const st = (x.state||'').toLowerCase();
        span.className = "pill " + (st === "listening" ? "ok" : "warn");
        span.textContent = x.state + (x.proc? ` (${x.proc}#${x.pid??''})`:'');
        right.appendChild(span);
        row.append(left,right); tcpEl.appendChild(row);
      });
      taskEl.innerHTML = "";
      const t = j.task||{};
      [["name", t.name ?? "MyTask_Interactive_v2"],
       ["lastRun", t.lastRun ?? "-"],
       ["result", (typeof t.result==="number" ? "0x"+(t.result>>>0).toString(16).padStart(8,'0') : (t.result??"-"))]
      ].forEach(([k,v])=>{
        const row = document.createElement("div"); row.className="row";
        const left = document.createElement("div"); left.textContent = k;
        const right = document.createElement("div");
        const span = document.createElement("span"); span.className="pill ok"; span.textContent = v;
        right.appendChild(span);
        row.append(left,right); taskEl.appendChild(row);
      });
    } catch(e){
      upEl.textContent = "Load error — " + e.message;
    }
  }
  await load();
  setInterval(load, 10000);
})();
