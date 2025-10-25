(()=>{ if(window.ORCHBUS){return;}
const API=(window.ORCHMON_API_BASE||"").replace(/\/$/,"");
const ORIGIN=API.replace(/\/api\/orchmon$/,"")||location.origin;
const SSE_URL = API ? (API + "/timeline") : (ORIGIN + "/timeline");
const subs = new Set(); let es=null, backoff=1000;
function publish(o){ subs.forEach(fn=>{ try{ fn(o);}catch{} }); }
function start(){ if(es) return;
  try{ es=new EventSource(SSE_URL);
    es.onopen = ()=>{ backoff=1000; console.log('[ORCHBUS] open', SSE_URL); };
    es.onerror= ()=>{ try{ es.close(); }catch{} es=null; console.warn('[ORCHBUS] error; retry in', backoff); setTimeout(start, backoff); backoff=Math.min(15000,Math.floor(backoff*1.7)); };
    es.onmessage = (e)=>{ try{ publish(JSON.parse(e.data||'{}')); }catch{} };
  }catch(e){ console.error('[ORCHBUS] start fail', e); } }
function subscribe(fn){ subs.add(fn); return ()=>subs.delete(fn); }
window.ORCHBUS = { subscribe, start, url:SSE_URL, count:()=>subs.size };
start();
})();