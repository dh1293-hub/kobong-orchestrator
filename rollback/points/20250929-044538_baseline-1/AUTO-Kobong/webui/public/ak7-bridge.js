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
