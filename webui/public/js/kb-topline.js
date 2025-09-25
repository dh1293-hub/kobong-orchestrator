/* kobong-step4-topline v1 */
(function(){
  const E = sel => document.querySelector(sel);
  const root = E('#kb-topline'); if(!root) return;
  const chip = key => root.querySelector(`.chip[data-key="${key}"]`);
  function set(key, val, state){
    const c = chip(key); if(!c) return;
    c.querySelector('.v').textContent = val;
    c.classList.remove('ok','warn','bad');
    if(state) c.classList.add(state);
  }
  function parseMaybeJson(t){ try{ return JSON.parse(t) }catch{ return null } }
  function parseProm(t){
    const o={}; (t||'').split(/\r?\n/).forEach(line=>{
      const m = line.trim().match(/^([A-Za-z_][A-Za-z0-9_:]*)\s+(-?\d+(?:\.\d+)?)$/);
      if(m){ o[m[1]] = Number(m[2]) }
    }); return o;
  }
  function updateFrom(obj){
    if(!obj) return;
    const be = obj.build_errors ?? obj.buildErrors ?? obj.errors ?? 0;
    const prs = obj.open_prs ?? obj.openPRs ?? obj.prs ?? obj.open_pull_requests ?? null;
    const iss = obj.open_issues ?? obj.issues ?? obj.openIssues ?? null;
    const lat = obj.latency_ms ?? obj.latency ?? obj.response_ms ?? null;
    set('build_errors', be, be>0?'bad':'ok');
    if(prs!=null) set('open_prs', prs, prs>50?'warn':'ok');
    if(iss!=null) set('open_issues', iss, iss>200?'warn':'ok');
    if(lat!=null) set('latency_ms', (Math.round(lat)+' ms'), lat>1500?'warn':'ok');
  }
  window.addEventListener('kb:metrics', ev=>{
    const d = ev.detail||{};
    const txt = d.text || d.body || d.raw || '';
    const asJson = parseMaybeJson(txt);
    if(asJson){ updateFrom(asJson); return }
    updateFrom(parseProm(txt));
  });
  try {
    fetch('/metrics',{cache:'no-store'}).then(r=>r.text()).then(t=>{
      const j=parseMaybeJson(t); if(j){ updateFrom(j); return }
      updateFrom(parseProm(t));
    }).catch(()=>{});
  }catch(e){}
})();