(function(){
  var base = "http://localhost:5191";
  var g = (typeof window!=="undefined"?window:globalThis);
  var AK7 = g.AK7 || {};
  AK7.postAction = async function(action, body){
    try{
      var url = base + "/api/ak7/" + encodeURIComponent(action);
      var tid = (typeof crypto!=="undefined" && crypto.randomUUID)?crypto.randomUUID():String(Date.now());
      var payload = Object.assign({ts:new Date().toISOString(),traceId:tid}, body||{});
      var res = await fetch(url,{method:"POST",headers:{"Content-Type":"application/json","X-Trace-Id":tid,"X-Idempotency-Key":tid},body:JSON.stringify(payload)});
      if(!res.ok) throw new Error("AK7 "+action+" -> "+res.status);
      try{return await res.json()}catch(_){return {ok:true}}
    }catch(e){ console.error(e); return {ok:false,error:String(e&&e.message||e)} }
  };
  g.AK7 = AK7;
})();

/* === AK7 Auto-Wire plugin (text → action fallback, SIM/LIVE badge toggle) === */
(()=>{ try{
  if (window.AK7 && !window.AK7._autowire){
    window.AK7._autowire = true;
    const KNOWN = ['next','stop','fix-preview','fix-apply','good','rollback','logs-export','prefs','health','scan','test','fixloop'];
    const MAP = [
      { re:/^(다음\s*단계|다음|next)$/i, action:'next' },
      { re:/^(중단|stop)$/i, action:'stop' },
      { re:/(fix\s*미리보기|미리보기|preview|fix-?preview)/i, action:'fix-preview' },
      { re:/(fix\s*적용|적용|apply|fix-?apply)/i, action:'fix-apply' },
      { re:/(good|합격|승인|mark\s*good)/i, action:'good' },
      { re:/(rollback|되돌리기|롤백)/i, action:'rollback' },
      { re:/(로그\s*export|logs?\s*export|logs?)/i, action:'logs-export' },
      { re:/(설정|prefs)/i, action:'prefs' },
      { re:/(헬스|상태|health)/i, action:'health' },
      { re:/(스캔|scan)/i, action:'scan' },
      { re:/(테스트|test)/i, action:'test' },
      { re:/(fixloop)/i, action:'fixloop' }
    ];
    function detectAction(el){
      if(!el) return null;
      for (const a of ['data-action','data-role','data-purpose','data-cmd','data-click']) {
        const v = el.getAttribute && el.getAttribute(a);
        if (v) {
          const n = (v+'').toLowerCase();
          for (const k of KNOWN){ if(n.includes(k)) return k; }
        }
      }
      const t = ((el.innerText||el.value||'')+'').replace(/\s+/g,' ').trim();
      if(!t) return null;
      for (const m of MAP){ if(m.re.test(t)) return m.action; }
      return null;
    }
    document.addEventListener('click', (ev) => {
      const el = ev.target.closest('button, a, [role="button"], [data-action], [data-role], [data-purpose], [data-cmd], [data-click]');
      if (!el || el.hasAttribute('data-ak7-action')) return;
      const act = detectAction(el);
      if (!act) return;
      el.setAttribute('data-ak7-action', act);
      ev.preventDefault();
      if (window.AK7 && typeof window.AK7.postAction==='function'){ window.AK7.postAction(act); }
    }, {capture:true});
    const badge=document.querySelector('.ak7-badge');
    if (badge) {
      badge.title='Shift+Click → SIM/LIVE 전환';
      badge.addEventListener('click',(e)=>{ if(!e.shiftKey) return; const m=(window.AK7.mode==='sim')?'live':'sim'; window.AK7.setMode && window.AK7.setMode(m); });
    }
  }
}catch(e){ console.warn('[AK7 autowire]', e); }})();

/* === AK7 Auto-Wire plugin (text → action fallback, SIM/LIVE badge toggle) === */
(()=>{ try{
  if (window.AK7 && !window.AK7._autowire){
    window.AK7._autowire = true;
    const KNOWN = ['next','stop','fix-preview','fix-apply','good','rollback','logs-export','prefs','health','scan','test','fixloop'];
    const MAP = [
      { re:/^(다음\s*단계|다음|next)$/i, action:'next' },
      { re:/^(중단|stop)$/i, action:'stop' },
      { re:/(fix\s*미리보기|미리보기|preview|fix-?preview)/i, action:'fix-preview' },
      { re:/(fix\s*적용|적용|apply|fix-?apply)/i, action:'fix-apply' },
      { re:/(good|합격|승인|mark\s*good)/i, action:'good' },
      { re:/(rollback|되돌리기|롤백)/i, action:'rollback' },
      { re:/(로그\s*export|logs?\s*export|logs?)/i, action:'logs-export' },
      { re:/(설정|prefs)/i, action:'prefs' },
      { re:/(헬스|상태|health)/i, action:'health' },
      { re:/(스캔|scan)/i, action:'scan' },
      { re:/(테스트|test)/i, action:'test' },
      { re:/(fixloop)/i, action:'fixloop' }
    ];
    function detectAction(el){
      if(!el) return null;
      for (const a of ['data-action','data-role','data-purpose','data-cmd','data-click']) {
        const v = el.getAttribute && el.getAttribute(a);
        if (v) {
          const n = (v+'').toLowerCase();
          for (const k of KNOWN){ if(n.includes(k)) return k; }
        }
      }
      const t = ((el.innerText||el.value||'')+'').replace(/\s+/g,' ').trim();
      if(!t) return null;
      for (const m of MAP){ if(m.re.test(t)) return m.action; }
      return null;
    }
    document.addEventListener('click', (ev) => {
      const el = ev.target.closest('button, a, [role="button"], [data-action], [data-role], [data-purpose], [data-cmd], [data-click]');
      if (!el || el.hasAttribute('data-ak7-action')) return;
      const act = detectAction(el);
      if (!act) return;
      el.setAttribute('data-ak7-action', act);
      ev.preventDefault();
      if (window.AK7 && typeof window.AK7.postAction==='function'){ window.AK7.postAction(act); }
    }, {capture:true});
    const badge=document.querySelector('.ak7-badge');
    if (badge) {
      badge.title='Shift+Click → SIM/LIVE 전환';
      badge.addEventListener('click',(e)=>{ if(!e.shiftKey) return; const m=(window.AK7.mode==='sim')?'live':'sim'; window.AK7.setMode && window.AK7.setMode(m); });
    }
  }
}catch(e){ console.warn('[AK7 autowire]', e); }})();
