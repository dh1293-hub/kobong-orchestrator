(function(){
  var API_BASE=(function(){
  var fromLS=localStorage.getItem("KOBONG_API_BASE");
  var def=(location.protocol==="file:"?"http://127.0.0.1:8080":(window.location.origin||(window.location.protocol+"//"+window.location.host)));
  var base=(window.__KOBONG_API_BASE__||fromLS||def);
  if(String(base).startsWith("file:")){ base="http://127.0.0.1:8080"; try{ localStorage.setItem("KOBONG_API_BASE",base) }catch(e){} }
  return String(base).replace(/\/+$/,"");
})();
  var OWNER=localStorage.getItem("GH_OWNER")||"octocat";
  var REPO =localStorage.getItem("GH_REPO") ||"Hello-World";
  function host(){ var card=document.querySelector(".card"); var h=document.getElementById("gh-status"); if(!h){ h=document.createElement("div"); h.id="gh-status"; h.style.marginTop="12px"; (card||document.body).appendChild(h);} return h; }
  function el(id){ return document.getElementById(id); }
  function setText(id,label,text){ var e=el(id); if(!e){ e=document.createElement("div"); e.id=id; host().appendChild(e);} e.textContent=label+": "+text; }
  function setHtml(id,html){ var e=el(id); if(!e){ e=document.createElement("div"); e.id=id; host().appendChild(e);} 
function relTime(t){ try{ var d=new Date(t); var s=(Date.now()-d.getTime())/1000; if(!isFinite(s)) return ""; var m=s/60,h=m/60,dz=h/24; if(s<60)return Math.floor(s)+"s ago"; if(m<60)return Math.floor(m)+"m ago"; if(h<48)return Math.floor(h)+"h ago"; return Math.floor(dz)+"d ago"; }catch(e){ return "" } }
function renderList(id, items, map){ var host=document.getElementById(id); if(!host) return; if(!items||items.length===0){ host.innerHTML = '<li class="kb-item kb-meta">no data</li>'; return } host.innerHTML = items.map(map).join(""); }
e.innerHTML=html; }
  function badgeRow(info){ var i=+info.issues||0,p=+info.prs||0,r=+info.runs||0; return ['<div class="badges">','<span class="badge issues"><span class="dot"></span><span>Issues</span><strong> '+i+'</strong></span>','<span class="badge prs"><span class="dot"></span><span>PRs</span><strong> '+p+'</strong></span>','<span class="badge runs"><span class="dot"></span><span>Runs</span><strong> '+r+'</strong></span>','</div>'].join(""); }
  function lastUpdated(ts){ var d=ts?new Date(ts):new Date(); return '<div class="muted">Last updated: '+d.toLocaleString()+'</div>' }
  function calcCounts(j){ var issues=Array.isArray(j?.issues)?j.issues.length:(j?.issues_count||0); var prs=Array.isArray(j?.prs)?j.prs.length:(j?.prs_count||0); var runs=Array.isArray(j?.workflow_runs)?j.workflow_runs.length:(j?.runs_count||0); return {issues,prs,runs}; }
  function bindControls(){ var api=el("inp-api"),owner=el("inp-owner"),repo=el("inp-repo"); if(api){ api.value=localStorage.getItem("KOBONG_API_BASE")||API_BASE; } if(owner){ owner.value=OWNER; } if(repo){ repo.value=REPO; } var save=el("btn-save"),refresh=el("btn-refresh"); if(save){ save.onclick=function(){ try{ if(api&&api.value){ localStorage.setItem("KOBONG_API_BASE",api.value.trim()); API_BASE=api.value.trim().replace(/\/+$/,""); } if(owner&&owner.value){ localStorage.setItem("GH_OWNER",owner.value.trim()); OWNER=owner.value.trim(); } if(repo&&repo.value){ localStorage.setItem("GH_REPO",repo.value.trim()); REPO=repo.value.trim(); } }catch(e){}; probe(); }; } if(refresh){ refresh.onclick=function(){ probe(); }; } }
  setHtml("gh-api-base","API_BASE: <code>"+API_BASE+"</code>");
  setText("gh-health","health","checking…");
  setText("gh-summary","summary","checking…");
  async function healthProbe(){
    try{
      let r=await fetch(API_BASE+"/healthz",{cache:"no-store"});
      if(r.ok){ try{ let j=await r.json(); let gh=j.github||{}; let t=j.token_present?"token":"no-token"; let reach=(gh.reachable===true?"GH:reachable":(gh.reachable===false?"GH:offline":"GH:unknown")); setText("gh-health","health","OK — "+t+"; "+reach); return true; }catch(e){} }
    }catch(e){}
    try{ let r2=await fetch(API_BASE+"/health",{cache:"no-store"}); let t=""; try{ t=await r2.text(); }catch(e){} setText("gh-health","health",(r2.ok?"OK":"FAIL")+(t? " — ":"")+ (t||"")); return r2.ok; }catch(e){ setText("gh-health","health","OFFLINE"); return false; }
  }
  async function fetchSummary(){
    var now=new Date(), from=new Date(now.getTime()-7*86400000);
    var u1=new URL(API_BASE+"/api/github/summary-v1"); u1.searchParams.set("owner",OWNER); u1.searchParams.set("repo",REPO); u1.searchParams.set("from",from.toISOString()); u1.searchParams.set("to",now.toISOString());
    try{ let r=await fetch(u1.toString(),{cache:"no-store"}); if(r.ok){ return await r.json(); }
      let u2=new URL(API_BASE+"/api/github/summary"); u2.searchParams.set("owner",OWNER); u2.searchParams.set("repo",REPO); u2.searchParams.set("from",from.toISOString()); u2.searchParams.set("to",now.toISOString());
      let r2=await fetch(u2.toString(),{cache:"no-store"}); if(r2.ok){ return await r2.json(); }
      let t=await r2.text(); if(/"loc"\s*:\s*\[\s*"query"\s*,\s*"repos"\s*\]/.test(t)){ let u3=new URL(API_BASE+"/api/github/summary"); u3.searchParams.set("owner",OWNER); u3.searchParams.set("repos",REPO); u3.searchParams.set("from",from.toISOString()); u3.searchParams.set("to",now.toISOString()); let r3=await fetch(u3.toString(),{cache:"no-store"}); if(r3.ok){ return await r3.json(); } }
      return null;
    }catch(e){ return null; }
  }
  async function probe(){ await healthProbe(); let j=await fetchSummary(); if(j){ let info=calcCounts(j); setHtml("gh-summary", badgeRow(info)+lastUpdated(Date.now())); try{window.__kobongRenderPanels&&window.__kobongRenderPanels(j);}catch(e){}; } else { setText("gh-summary","summary","ERR/NO DATA"); } }
  bindControls(); probe(); setInterval(probe,15000);
})();