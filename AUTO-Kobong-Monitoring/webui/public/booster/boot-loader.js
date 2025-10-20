 /*! boot-loader.js (AK7 safe v4) — auto generated */
 (function(){
   var list = [
  'public/booster/ak7-net-override.js',
  'public/booster/ak7-ws-guard.js',
  'public/booster/ak7-bus-guard.js',
  'public/booster/ak7-compat-shim.js',
  'public/booster/ak7-bridge.js',
  'public/booster/errkb-cards.js',
  'public/booster/errkb-wiring.js',
  'public/booster/messages-pane.js',
  'public/booster/messages-wiring.js',
  'public/booster/orch-bus-auto.js',
  'public/booster/orch-bus.js',
  'public/booster/overview-cards.js',
  'public/booster/settings-pane.js',
  'public/booster/timeline-tools.js',
  'public/booster/timeline-wiring.js'
   ];
   var loaded = Object.create(null);
   function loadNext(i){
     if(i >= list.length) return;
     var src = list[i];
     if(loaded[src]) return loadNext(i+1);
     var s = document.createElement('script');
     s.src = src; s.async = false;
     s.onload  = function(){ loaded[src]=1; loadNext(i+1); };
     s.onerror = function(){ console.error('[BOOT] failed to load', src); loadNext(i+1); };
     (document.head || document.body || document.documentElement).appendChild(s);
   }
   loadNext(0);
 })();
