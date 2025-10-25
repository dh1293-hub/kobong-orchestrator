/*! ak7-net-override.js — force AK7 endpoints, kill 5193/orchmon */
(function(){
  function baseInfo(){
    var b = (window.AK7_API_BASE || window.ORCHMON_API_BASE || "http://localhost:5191/api/ak7").replace(/\/+$/,'');
    try{
      var u = new URL(b);
      var proto = (u.protocol==="https:")?"https:":"http:";
      var wsproto = (proto==="https:")?"wss:":"ws:";
      var host = u.hostname || "localhost";
      var port = u.port || (proto==="https:"? "443" : "5191");
      return { base: b, proto, wsproto, host, port, httpBase: proto+"//"+host+(port?(":"+port):"") };
    }catch(e){
      return { base:"http://localhost:5191/api/ak7", proto:"http:", wsproto:"ws:", host:"localhost", port:"5191", httpBase:"http://localhost:5191" };
    }
  }
  function rewrite(url){
    try{
      var I = baseInfo();
      var s = String(url);
      // api 경로 교정
      s = s.replace(/\/api\/orchmon\b/g, "/api/ak7");
      // 5193 → AK7 호스트/포트
      s = s.replace(/https?:\/\/localhost:5193/gi, I.httpBase);
      // 남은 :5193 포트 표기 치환
      s = s.replace(/:5193\b/g, ":"+I.port);
      // 상대/빈호스트 보정
      try{
        var u = new URL(s, I.httpBase);
        if(/\/api\/ak7\b/.test(u.pathname)){ u.hostname=I.host; u.port=I.port; u.protocol=I.proto; }
        s = u.protocol+"//"+u.hostname+(u.port?(":"+u.port):"")+u.pathname+u.search+u.hash;
      }catch(e){}
      return s;
    }catch(e){ return url; }
  }

  // fetch override
  (function(){
    if(!window.fetch || window.fetch.__ak7_patched) return;
    var F = window.fetch;
    var P = function(input, init){
      if(typeof input === "string"){
        input = rewrite(input);
      }else if(input && input.url){
        var u = rewrite(input.url);
        if(u !== input.url) input = new Request(u, input);
      }
      return F(input, init);
    };
    P.__ak7_patched = true;
    window.fetch = P;
    console.log("[AK7] net-override: fetch patched");
  })();

  // EventSource override (SSE)
  (function(){
    var ES = window.EventSource;
    if(!ES || ES.__ak7_patched) return;
    function Patched(url, opts){ return new ES(rewrite(url), opts); }
    Patched.prototype = ES.prototype;
    Patched.__ak7_patched = true;
    window.EventSource = Patched;
    console.log("[AK7] net-override: EventSource patched");
  })();

  // WebSocket override (최종 보호 — ws-guard가 이미 있더라도 중복 안전)
  (function(){
    var WS = window.WebSocket;
    if(!WS || WS.__ak7_netpatched) return;
    function Patched(url, prot){ 
      var I = baseInfo();
      var s = rewrite(url).replace(/^ws(s)?:\/\/:(\d+)/i, function(_,$1,$2){ 
        return "ws"+($1||"")+"://"+I.host+":"+( $2||I.port ); 
      });
      try{
        var u = new URL(s, I.wsproto+"//"+I.host+":"+I.port);
        if(/\/api\/ak7\/shell\b/.test(u.pathname)){ u.protocol=I.wsproto; u.hostname=I.host; u.port=I.port; }
        s = u.protocol+"//"+u.hostname+(u.port?(":"+u.port):"")+u.pathname+u.search+u.hash;
      }catch(e){}
      return new WS(s, prot);
    }
    Patched.prototype = WS.prototype;
    Patched.__ak7_netpatched = true;
    window.WebSocket = Patched;
    console.log("[AK7] net-override: WebSocket patched");
  })();

  // fetch-redirect 완전 차단 + ORCHBUS_URL 고정(경합에도 승리)
  try{
    var I = baseInfo();
    var tl = I.base.replace(/\/+$/,'') + "/timeline";
    Object.defineProperty(window,'FETCH_REDIRECT',{configurable:true,get:function(){return ""},set:function(v){console.warn("[AK7] fetch-redirect blocked:",v)}});
    localStorage.removeItem("FETCH_REDIRECT");
    window.ORCHBUS_URL = tl;
    localStorage.setItem("ORCHBUS_URL", tl);
    console.log("[AK7] net-override: ORCHBUS_URL =", tl);
  }catch(e){}
})();
