(()=>{ if(window.__orch_settings_v1){return;} window.__orch_settings_v1=1;
const card = document.querySelector('#tab-settings .card'); if(!card){ console.warn('[settings] host not found'); return; }
const echo = document.querySelector('#apiBaseEcho');

const $ = (s,p=document)=>p.querySelector(s);
const API_DEF = 'http://localhost:5193/api/orchmon';
function getAPIBase(){ const ls = localStorage.getItem('ORCHMON_API_BASE'); return (window.ORCHMON_API_BASE || ls || API_DEF); }
function setAPIBase(v){ window.ORCHMON_API_BASE = v; localStorage.setItem('ORCHMON_API_BASE', v); echo && (echo.textContent = 'API Base: '+v); }
function getOriginFromBase(base){ return (base||'').replace(/\/api\/orchmon\/?$/,'') || location.origin; }
async function testHealth(base){ const origin = getOriginFromBase(base); const url = origin + '/health'; const t0 = performance.now();
  try{ const r = await fetch(url,{cache:'no-store'}); const ms=Math.round(performance.now()-t0); if(!r.ok) throw new Error('HTTP '+r.status); const j=await r.json(); return {ok:true,ms,json:j,url}; }
  catch(e){ const ms=Math.round(performance.now()-t0); return {ok:false,ms,err:String(e),url}; } }
function badge(text){ const b=document.createElement('span'); b.className='set-badge'; b.textContent=text; return b; }
function save(k,v){ localStorage.setItem(k, typeof v==='string'?v:JSON.stringify(v)); }
function load(k,def){ try{ const v=localStorage.getItem(k); return v==null?def:JSON.parse(v);}catch{ const v=localStorage.getItem(k); return v==null?def:v; } }

const css = `
.set-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px;margin-top:8px}
@media(max-width:960px){.set-grid{grid-template-columns:1fr}}
.set-box{border:1px solid #ffffff22;border-radius:14px;padding:12px;background:rgba(20,21,23,.85)}
.set-h{display:flex;align-items:center;justify-content:space-between;margin-bottom:8px}
.set-h h6{margin:0;font-size:14px}
.set-row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:8px 0}
.set-row input[type="text"]{min-width:360px;max-width:100%;padding:8px 10px;border-radius:10px;border:1px solid #ffffff22;background:transparent;color:inherit}
.set-row select,.set-row input[type="number"]{padding:8px 10px;border-radius:10px;border:1px solid #ffffff22;background:transparent;color:inherit}
.set-row label{display:flex;gap:6px;align-items:center}
.set-badge{font:12px/1 ui-monospace,Consolas,monospace;border:1px solid #ffffff22;border-radius:999px;padding:2px 8px}
.set-btn{padding:8px 12px;border-radius:10px;border:1px solid #ffffff22;background:transparent;cursor:pointer}
.set-note{opacity:.75;font-size:12px}
.set-kbd{font:12px/1 ui-monospace,Consolas,monospace;border:1px solid #ffffff22;border-radius:6px;padding:2px 6px}
`;
const st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

const grid = document.createElement('div'); grid.className='set-grid';

/* --- A. API Base & 모드 --- */
const A = document.createElement('div'); A.className='set-box';
A.innerHTML = `
  <div class="set-h"><h6>API Base & 모드</h6><span class="set-badge" data-k="health">-</span></div>
  <div class="set-row">
    <label>API Base</label>
    <input type="text" data-k="apibase" placeholder="http://host:port/api/orchmon">
    <button class="set-btn" data-k="probe">/health 점검</button>
    <button class="set-btn" data-k="apply">적용</button>
    <button class="set-btn" data-k="apply-reload">적용+새로고침</button>
  </div>
  <div class="set-row">
    <label>모드</label>
    <label><input type="radio" name="mode" value="OFFLINE"> OFFLINE</label>
    <label><input type="radio" name="mode" value="MOCK"> MOCK</label>
    <label><input type="radio" name="mode" value="DEV"> DEV</label>
    <label><input type="radio" name="mode" value="APPLY"> APPLY</label>
    <span class="set-note">* 모드는 클라이언트 메타로 저장되며 서버엔 강제되지 않습니다.</span>
  </div>
  <div class="set-row"><span class="set-note" data-k="health-echo"></span></div>
`;
grid.appendChild(A);

/* --- B. 단축키 --- */
const B = document.createElement('div'); B.className='set-box';
B.innerHTML = `
  <div class="set-h"><h6>단축키</h6><span class="set-badge">global</span></div>
  <div class="set-row">
    <label><input type="checkbox" data-k="hotkeys"> 단축키 활성화</label>
    <span class="set-note">P: 타임라인 pause/resume · L: live · E: export · C: clear · M: 메시지 모두읽음</span>
  </div>
  <div class="set-row">
    <span class="set-kbd">P</span><span class="set-kbd">L</span><span class="set-kbd">E</span><span class="set-kbd">C</span><span class="set-kbd">M</span>
  </div>
`;
grid.appendChild(B);

/* --- C. 로그 Export --- */
const C = document.createElement('div'); C.className='set-box';
C.innerHTML = `
  <div class="set-h"><h6>로그 Export 설정</h6><span class="set-badge" data-k="ex-meta">-</span></div>
  <div class="set-row">
    <label>Format</label>
    <select data-k="ex-fmt">
      <option value="ndjson">NDJSON</option>
      <option value="json">JSON</option>
      <option value="txt">TXT</option>
    </select>
    <label>Max</label>
    <input type="number" data-k="ex-max" min="50" max="10000" step="50" value="1000">
  </div>
  <div class="set-row">
    <label><input type="checkbox" data-k="f-ts" checked> ts</label>
    <label><input type="checkbox" data-k="f-type" checked> type</label>
    <label><input type="checkbox" data-k="f-role" checked> role</label>
    <label><input type="checkbox" data-k="f-action" checked> action</label>
    <label><input type="checkbox" data-k="f-msg" checked> msg</label>
  </div>
  <div class="set-row">
    <button class="set-btn" data-k="ex-timeline">Export · Timeline</button>
    <button class="set-btn" data-k="ex-messages">Export · Messages</button>
    <button class="set-btn" data-k="ex-errkb">Export · Error-KB</button>
  </div>
  <div class="set-row"><span class="set-note">* 포맷/필드는 Settings에서만 적용됩니다(기존 각 탭의 export와 별개).</span></div>
`;
grid.appendChild(C);

card.appendChild(grid);

/* 초기화 */
const apibase = getAPIBase();
A.querySelector('[data-k="apibase"]').value = apibase;
echo && (echo.textContent='API Base: '+apibase);
const savedMode = load('ORCHMON_MODE','MOCK'); const r = A.querySelector(`input[name="mode"][value="${savedMode}"]`); if(r) r.checked = true;
A.addEventListener('change', e=>{ if(e.target.name==='mode'){ save('ORCHMON_MODE', e.target.value); }});
const hotOn = load('ORCH_SHORTCUTS_ENABLED', true); B.querySelector('[data-k="hotkeys"]').checked = !!hotOn;

/* A. 액션 */
A.querySelector('[data-k="probe"]').addEventListener('click', async ()=>{
  const base = A.querySelector('[data-k="apibase"]').value.trim();
  const res = await testHealth(base); const h=A.querySelector('[data-k="health"]'), he=A.querySelector('[data-k="health-echo"]');
  if(res.ok){ h.textContent=`OK ${res.ms}ms`; h.style.borderColor='#19c37d'; he.textContent=JSON.stringify(res.json); }
  else{ h.textContent='ERROR'; h.style.borderColor='#f24822'; he.textContent=`${res.url} → ${res.ms}ms · ${res.err}`; }
});
A.querySelector('[data-k="apply"]').addEventListener('click', ()=>{
  const base = A.querySelector('[data-k="apibase"]').value.trim() || API_DEF; setAPIBase(base);
  console.log('[settings] API_BASE applied:', base, ' — 새로고침 시 ORCHBUS가 재연결됩니다.');
});
A.querySelector('[data-k="apply-reload"]').addEventListener('click', ()=>{
  const base = A.querySelector('[data-k="apibase"]').value.trim() || API_DEF; setAPIBase(base); location.reload();
});

/* B. 단축키 */
function tlAPI(){ return window.__TL_API; }
function msgQuery(k){ return document.querySelector('#tab-messages .msg-bar [data-k="'+k+'"]'); }
function enableHotkeys(flag){
  save('ORCH_SHORTCUTS_ENABLED', !!flag);
  if(flag && !window.__orch_hotkeys_bound){
    window.__orch_hotkeys_bound = true;
    document.addEventListener('keydown', (e)=>{
      if(!load('ORCH_SHORTCUTS_ENABLED', true)) return;
      if(e.target && /input|textarea|select/i.test(e.target.tagName)) return;
      const k=(e.key||'').toLowerCase();
      if(k==='p'){ const st=tlAPI()?.state; if(st){ st.paused=!st.paused; const b=document.querySelector('#tab-timeline .tl-bar [data-k="pause"]'); if(b){ b.textContent=st.paused?'▶ resume':'⏸ pause'; } } }
      if(k==='l'){ tlAPI()?.state?.ul && (tlAPI().state.ul.scrollTop=tlAPI().state.ul.scrollHeight); }
      if(k==='e'){ document.querySelector('#tab-timeline .tl-bar [data-k="export"]')?.click(); }
      if(k==='c'){ document.querySelector('#tab-timeline .tl-bar [data-k="clear"]')?.click(); }
      if(k==='m'){ msgQuery('markread')?.click(); }
    });
  }
}
B.querySelector('[data-k="hotkeys"]').addEventListener('change', e=> enableHotkeys(e.target.checked));
enableHotkeys(hotOn);

/* C. Export */
function pickFields(o, fields){ const out={}; fields.forEach(f=>{ if(f==='msg'){ out.msg=(o.msg??o.message??'')+''; } else { out[f]=o[f]; } }); return out; }
function download(name, fmt, arr){
  let data, mime, fname=name+'_'+new Date().toISOString().replace(/[:.]/g,'');
  if(fmt==='ndjson'){ data=arr.map(x=>JSON.stringify(x)).join('\n')+'\n'; mime='application/x-ndjson'; fname+='.ndjson'; }
  else if(fmt==='json'){ data=JSON.stringify(arr,null,2); mime='application/json'; fname+='.json'; }
  else { data=arr.map(x=>JSON.stringify(x)).join('\n'); mime='text/plain'; fname+='.txt'; }
  const blob=new Blob([data],{type:mime}); const a=document.createElement('a'); a.href=URL.createObjectURL(blob); a.download=fname; a.click(); setTimeout(()=>URL.revokeObjectURL(a.href),1000);
}
function currentExportPrefs(){
  const fmt = C.querySelector('[data-k="ex-fmt"]').value;
  const max = +C.querySelector('[data-k="ex-max"]').value || 1000;
  const fields = ['f-ts','f-type','f-role','f-action','f-msg'].filter(k=>C.querySelector('[data-k="'+k+'"]').checked)
                  .map(k=>({ 'f-ts':'ts','f-type':'type','f-role':'role','f-action':'action','f-msg':'msg' }[k]));
  return {fmt,max,fields};
}
function exportTimeline(){
  const st = window.__TL_STATE; if(!st || !Array.isArray(st.buf)){ alert('Timeline 버퍼 없음'); return; }
  const {fmt,max,fields} = currentExportPrefs(); const src = st.buf.slice(-max).map(o=>pickFields(o, fields)); download('timeline', fmt, src);
}
function exportMessages(){
  const lis = Array.from(document.querySelectorAll('#tab-messages .msg-li'));
  const {fmt,max,fields} = currentExportPrefs();
  const src = lis.slice(-max).map(li=>{
    const o = li.__data || {}; const time = li.querySelector('.msg-time')?.textContent ?? '';
    const type = li.querySelector('.msg-chip')?.textContent ?? o.type; const chips = li.querySelectorAll('.msg-chip');
    const role = chips?.[1]?.textContent ?? o.role; const action = chips?.[2]?.textContent ?? o.action;
    const msg = li.querySelector('.msg-body')?.textContent ?? (o.msg||o.message||'');
    return pickFields({ts:o.ts||time,type,role,action,msg}, fields);
  });
  download('messages', fmt, src);
}
function exportErrKB(){
  const cards = Array.from(document.querySelectorAll('#tab-errkb .errkb-card'));
  const {fmt,max,fields} = currentExportPrefs();
  const src = cards.slice(0,max).map(c=>{
    const key=c.querySelector('.errkb-title')?.textContent??''; const cnt=c.querySelector('.errkb-bad')?.textContent??''; const meta=c.querySelector('.errkb-meta')?.textContent??''; const msg=c.querySelector('.errkb-msg')?.textContent??'';
    const m=/type=(.+?) · role=(.+?) · action=(.+?) · last=(.+)/.exec(meta)||[];
    const rec={ ts:m[4]||'', type:m[1]||'', role:m[2]||'', action:m[3]||'', msg:`[${key} ×${cnt}] `+msg };
    return pickFields(rec, fields);
  });
  download('errkb', fmt, src);
}
C.querySelector('[data-k="ex-timeline"]').addEventListener('click', exportTimeline);
C.querySelector('[data-k="ex-messages"]').addEventListener('click', exportMessages);
C.querySelector('[data-k="ex-errkb"]').addEventListener('click', exportErrKB);

/* 최초 헬스 상태 */
(async ()=>{ const base=getAPIBase(); const res=await testHealth(base);
  const h=A.querySelector('[data-k="health"]'), he=A.querySelector('[data-k="health-echo"]');
  if(res.ok){ h.textContent=`OK ${res.ms}ms`; h.style.borderColor='#19c37d'; he.textContent=JSON.stringify(res.json); }
  else{ h.textContent='ERROR'; h.style.borderColor='#f24822'; he.textContent=`${res.url} → ${res.ms}ms · ${res.err}`; }
})();
console.log('%cSettings pane ready','background:#19c37d;color:#111;padding:2px 6px;border-radius:6px');
})();