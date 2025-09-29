(function(){
  var AK7_BASE = "http://localhost:5191";
  var of = window.fetch ? window.fetch.bind(window) : null;
  if(of){
    window.fetch = function(input, init){
      try{
        var u = (typeof input==="string") ? input : (input && input.url)||"";
        // file:///.../g5/... → http://localhost:5191/... 로 변환
        if(u && u.indexOf("file:///")===0 && u.indexOf("/g5/")>0){
          var tail = u.split("/g5/")[1] || "";
          // prefs 같은 리소스는 /api/ak7/prefs로 보냄
          if(tail.replace(/^\/*/,"")==="prefs"){ return of(AK7_BASE + "/api/ak7/prefs", init); }
          return of(AK7_BASE + "/" + tail, init);
        }
      }catch(_){ }
      return of(input, init);
    };
  }
  window.addEventListener("DOMContentLoaded", function(){ console.log("app.js ready (CORS rewrite active)"); });
})();
