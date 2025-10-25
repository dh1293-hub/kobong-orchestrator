/*! ak7-bus-guard v3 */
(function(){
  try{
    var base = (typeof window.AK7_API_BASE==='string' && window.AK7_API_BASE) ? window.AK7_API_BASE : 'http://localhost:5191/api/ak7';
    base = base.replace(/\/+$/,'');
    // 전역/로컬스토리지 동기화
    window.ORCHMON_API_BASE = base;
    try{ localStorage.setItem("AK7_API_BASE", base); localStorage.setItem("ORCHMON_API_BASE", base); }catch(e){}
    // redirect 완전 차단
    try{
      localStorage.removeItem("FETCH_REDIRECT");
      Object.defineProperty(window,'FETCH_REDIRECT',{configurable:true,get:function(){return ''},set:function(v){console.warn('[AK7] redirect blocked:',v)}});
      if (window.fetch_redirect_target) window.fetch_redirect_target = '';
    }catch(e){}
    // ORCHBUS_URL 강제 + 짧은 재적용 루프(경합 승리)
    var t = base + "/timeline";
    function apply(){
      window.ORCHBUS_URL = t;
      try{ localStorage.setItem("ORCHBUS_URL", t); }catch(e){}
    }
    apply(); for(var i=1;i<=10;i++){ setTimeout(apply, i*150); }
    console.log("[AK7] bus-guard v3 ORCHBUS_URL =", t);
  }catch(e){ console.warn("[AK7] bus-guard err", e); }
})();
