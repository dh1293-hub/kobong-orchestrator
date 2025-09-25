;(function(){try{if(location.protocol==="file:"){var s=localStorage.getItem("KOBONG_API_BASE");if(!s){localStorage.setItem("KOBONG_API_BASE","http://127.0.0.1:8080");}}}catch(e){}})();
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
(()=>{try{console.log("[sts-gh-min] ready");const e=t=>{const n=document.getElementById("kobong-status");n&&(n.textContent=t)};e("js loaded @ "+(new Date).toLocaleTimeString());const o=window.__KOBONG_EVENTS_URL||"/events";try{const t=new EventSource(o);t.onopen=(()=>e("stream: open")),t.onmessage=(()=>e("msg @ "+(new Date).toLocaleTimeString())),t.onerror=(()=>{e("stream: error (check server/CORS)");try{t.close()}catch{}})}catch{}}catch(e){console.error("[sts-gh-min] init error",e)}})();
try{ window.__kobong_api_base_promise__ && window.__kobong_api_base_promise__.then(function(u){ window.API_BASE=u; console.log('[API] base',u); }); }catch(e){}