(()=>{try{
  const ID='ko-brand-footer';
  const name=(typeof window!=='undefined' && window.__KOBONG_BRAND_NAME__)||" + (ConvertTo-Json KoBong Orchestrator.) + @";
  const logo=(typeof window!=='undefined' && window.__KOBONG_BRAND_LOGO__)||'/assets/company-logo.png';
  const old=document.getElementById(ID); if(old) old.remove();
  const bar=document.createElement('div'); bar.id=ID;
  Object.assign(bar.style,{
    position:'fixed', left:'50%', bottom:'16px', transform:'translateX(-50%)',
    display:'flex', alignItems:'center', gap:'14px',
    padding:'12px 16px', borderRadius:'16px',
    background:'rgba(3,7,18,.75)', color:'#e6edf3',
    border:'1px solid rgba(148,163,184,.30)', backdropFilter:'blur(6px)',
    zIndex:2147483647, fontFamily:'system-ui,Segoe UI,Roboto,Apple SD Gothic Neo,Malgun Gothic,sans-serif',
    fontWeight:'700', fontSize:'28px'
  });
  const img=new Image(); img.alt='Logo'; img.src=logo; img.decoding='async'; img.loading='lazy';
  img.style.height='40px'; img.style.width='auto';
  const span=document.createElement('span'); span.textContent=name;
  bar.append(img,span); document.body.appendChild(bar);
}catch(e){console && console.warn && console.warn('brand footer inject failed',e);}})();