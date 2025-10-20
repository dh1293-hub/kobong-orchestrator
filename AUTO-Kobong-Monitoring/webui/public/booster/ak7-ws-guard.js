/*! ak7-ws-guard v3 */
(function(){
  var NativeWS = window.WebSocket;
  if(!NativeWS || NativeWS.__ak7_patched) return;
  function baseInfo(){
    var b = (typeof window.AK7_API_BASE==='string' && window.AK7_API_BASE) ? window.AK7_API_BASE : 'http://localhost:5191/api/ak7';
    try{
      var u = new URL(b);
      var proto = (u.protocol==='https:')?'wss:':'ws:';
      var host = u.hostname || 'localhost';
      var port = u.port || (proto==='wss:'? '443' : '5191');
      return {proto, host, port};
    }catch(e){ return {proto:'ws:', host:'localhost', port:'5191'}; }
  }
  function fix(url){
    var info = baseInfo();
    try{
      if(typeof url!=='string') return url;
      // 기본 보정: host가 비거나 orchmon 경로일 때
      url = url.replace('/api/orchmon','/api/ak7');
      url = url.replace(/^ws(s)?:\/\/:(\d+)/i, function(_,$1,$2){ return 'ws'+($1||'')+'://'+info.host+':'+($2||info.port); });
      var u = new URL(url, info.proto+'//'+info.host+':'+info.port);
      // /api/ak7/shell 로 오면 base host/port로 강제
      if(/\/api\/ak7\/shell/.test(u.pathname)){
        u.hostname = info.host; u.port = info.port; u.protocol = info.proto;
      }
      return u.protocol+'//'+u.hostname+(u.port?(':'+u.port):'')+u.pathname+u.search+u.hash;
    }catch(e){ return info.proto+'//'+info.host+':'+info.port+'/api/ak7/shell'; }
  }
  function PatchedWS(url, protocols){ return new NativeWS(fix(url), protocols); }
  PatchedWS.prototype = NativeWS.prototype;
  PatchedWS.__ak7_patched = true;
  window.WebSocket = PatchedWS;
  console.log('[AK7] ws-guard v3 ready');
})();
