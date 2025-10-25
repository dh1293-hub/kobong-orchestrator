(()=>{ 
  const DEF = 'http://localhost:5191/api/ak7';
  if(!window.AK7_API_BASE){ window.AK7_API_BASE = localStorage.getItem('AK7_API_BASE') || DEF; }
  // 호환: 기존 부스터들이 ORCHMON_API_BASE를 읽는 경우 동기화
  window.ORCHMON_API_BASE = window.AK7_API_BASE;
  const echo=document.getElementById('apiBaseEcho'); if(echo){ echo.textContent='API Base: '+window.AK7_API_BASE; }
  console.log('[AK7] API_BASE =', window.AK7_API_BASE);
})();
