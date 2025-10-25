/* kobong-step5-theme v1 */
(function(){
  const KEY='kb.theme.pref';
  const $ = s=>document.querySelector(s);
  const btn = $('#kb-theme-toggle');
  const mm = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  function load(){
    try { return JSON.parse(localStorage.getItem(KEY)||'null') } catch { return null }
  }
  function save(o){
    try { localStorage.setItem(KEY, JSON.stringify(o)) } catch {}
  }
  function applyTheme(theme, hc, explicit){
    const html = document.documentElement;
    html.setAttribute('data-theme', theme);
    html.classList.toggle('kb-hc', !!hc);
    if (btn) { btn.textContent = (theme==='dark'?'🌙':'☀️') + (hc?' HC':''); }
    save({theme, hc:!!hc, explicit: !!explicit});
  }

  const pref = load();
  const sysDark = !!(mm && mm.matches);
  const initialTheme = pref?.theme ?? (sysDark ? 'dark' : 'light');
  applyTheme(initialTheme, !!pref?.hc, !!pref?.explicit);

  if (btn) {
    btn.addEventListener('click', function(){
      const cur = document.documentElement.getAttribute('data-theme') || 'light';
      const next = cur==='dark'?'light':'dark';
      const hc = document.documentElement.classList.contains('kb-hc');
      applyTheme(next, hc, true);
    });
  }

  // 고대비: Alt+Shift+C
  document.addEventListener('keydown', function(e){
    if (e.altKey && e.shiftKey && (e.code==='KeyC' || e.key?.toLowerCase()==='c')) {
      const html = document.documentElement;
      const hc = !html.classList.contains('kb-hc');
      const cur = html.getAttribute('data-theme') || 'light';
      applyTheme(cur, hc, true);
    }
  });

  // 시스템 테마 변경시, 사용자가 명시 설정하지 않았다면 따라감
  if (mm) {
    mm.addEventListener('change', function(ev){
      const p = load();
      if (p && p.explicit) return;
      const next = ev.matches ? 'dark' : 'light';
      const hc = !!(p && p.hc);
      applyTheme(next, hc, false);
    });
  }
})();