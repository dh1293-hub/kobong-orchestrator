(function(g){
  var NS="ghmon", pref="ghmon";
  var API=(g[NS+"_API_BASE"]||"").replace(/\/+$/,"");
  function box(){return document.querySelector("[data-"+pref+"-messages]");}
  function log(m){var el=box(); if(!el) return; var d=document.createElement("div"); d.textContent=m; el.prepend(d);}
  async function postAction(a){
    try{
      var r = await fetch(API+"/action",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({action:a,at:Date.now()})});
      var j = await r.json(); log("[ok] "+a+" → "+(j&&j.ok)+" id="+(j&&j.id));
    }catch(e){ log("[err] "+a+" → "+e.message); }
  }
  g[NS]={ postAction };
  document.querySelectorAll("[data-"+pref+"-action]").forEach(function(b){ b.addEventListener("click",function(){ postAction(b.getAttribute("data-"+pref+"-action")); }); });
  fetch(API+"/health").then(function(){log("[health] ok")}).catch(function(e){log("[health] fail "+e.message)});
})(window);