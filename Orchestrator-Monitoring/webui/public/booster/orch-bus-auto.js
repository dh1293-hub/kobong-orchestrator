(()=>{ if(window.ORCHBUS){ console.log("[ORCHBUS] already present"); return; }
const DEF='http://localhost:5193/api/orchmon';
if(!window.ORCHMON_API_BASE || !/\/api\/orchmon$/.test(window.ORCHMON_API_BASE)){
  window.ORCHMON_API_BASE = DEF;
  console.log("[ORCHBUS] ORCHMON_API_BASE set →", window.ORCHMON_API_BASE);
}
const API    = window.ORCHMON_API_BASE.replace(/\/$/,'');
const ORIGIN = API.replace(/\/api\/orchmon$/,'') || location.origin;
const CANDS  = [ API + "/timeline", ORIGIN + "/timeline" ];

const subs = new Set(); let es=null, idx=0, backoff=1000, currentUrl=null;
function publish(o){ subs.forEach(fn=>{ try{ fn(o); }catch(e){ /* isolate */ } }); }
function openNext(){
  if(es){ try{ es.close(); }catch{} es=null; }
  const url = CANDS[idx % CANDS.length]; currentUrl=url;
  try{
    es = new EventSource(url);
    es.onopen    = ()=>{ backoff=1000; currentUrl=url; console.log("[ORCHBUS] open", url); };
    es.onerror   = ()=>{ const wait=backoff; backoff=Math.min(15000, Math.floor(backoff*1.7)); idx++;
                         console.warn("[ORCHBUS] error; retry in", wait, "→", CANDS[idx % CANDS.length]); setTimeout(openNext, wait); };
    es.onmessage = (e)=>{ try{ publish(JSON.parse(e.data||'{}')); }catch{} };
  }catch(e){ console.error("[ORCHBUS] create failed", e); setTimeout(openNext, backoff); }
}
window.ORCHBUS = {
  subscribe(fn){ subs.add(fn); return ()=>subs.delete(fn); },
  start(){ /* already auto-start */ },
  count(){ return subs.size; },
  get url(){ return currentUrl; },
  _auto:true
};
openNext();
})();