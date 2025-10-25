(()=>{"use strict";
  const API=(window.ORCHMON_API_BASE||'').replace(/\/$/,'');
  const OFF=!!window.ORCHMON_FORCE_OFFLINE;
  const elMsg=document.querySelector('[data-orchmon-messages]'); const led=document.querySelector('.led');
  function toast(t){ if(elMsg){ elMsg.textContent='['+new Date().toLocaleTimeString()+'] '+t } }
  function setLED(s){ if(led){ led.setAttribute('data-state',s) } }
  async function callAction(a){
    setLED('warn');
    if(OFF){ await new Promise(r=>setTimeout(r,150)); setLED('ok'); toast(a+': OK (offline)'); return {ok:true,code:0,message:'offline'} }
    const r=await fetch(API+'/action/'+a,{method:'POST'}); const j=await r.json();
    setLED(j.ok?'ok':'err'); toast(a+': '+(j.ok?'OK':'NG')+' (code='+j.code+')'); return j;
  }
  document.querySelectorAll('[data-orchmon-action]').forEach(b=>{
    b.addEventListener('click',()=>{ callAction(b.getAttribute('data-orchmon-action')) })
  });
  // xterm 5개 (OFFLINE일 땐 안내만)
  const Terms={}; function attach(el,role){
    const term=new window.Terminal(); term.open(el);
    term.write('[connected:'+role+'] PowerShell$ ');
    if(!OFF){
      const proto=location.protocol==='https:'?'wss':'ws';
      const ws=new WebSocket(proto+'://'+location.hostname+':'+(location.port||'5183')+'/api/orchmon/shell?role='+encodeURIComponent(role));
      ws.onmessage=e=>term.write(e.data); term.onData(d=>ws.send(d)); ws.onclose=()=>term.write('\\r\\n[disconnected:'+role+']');
      Terms[role]={term,ws};
    } else {
      term.write('\\r\\n(offline stub — type disabled)');
    }
  }
  document.querySelectorAll('[data-orchmon-shell]').forEach(el=>attach(el,el.getAttribute('data-orchmon-shell')));
  setLED(OFF?'warn':'ok'); toast('bridge ready ('+(OFF?'OFFLINE':'LIVE')+')');
})();