(()=> {
  if (window.__GHMON_BRIDGE_ACTIVE__) { console.info("[GHMON] bridge already active (skip)"); return; }
  window.__GHMON_BRIDGE_ACTIVE__ = true;

  const BASE = (window.GHMON_BASE || "http://localhost:5182/api/ghmon").replace(/\/$/, "");
  const q  = (s,root=document)=>root.querySelector(s);
  const qa = (s,root=document)=>Array.from(root.querySelectorAll(s));
  const log = (...a)=>{ try { console.info("[GHMON]", ...a); } catch(_){} };
  const state = Object.create(null);

  // ---- 탭 별칭(라우트 → 로더) ----
  const KEY_ALIASES = {
    ci: "actions",
    security: "alerts",
    release: "actions"  // 서버에 releases가 없으니 actions로 대체 표시
  };

  // ---- 섹션/테이블 탐색 + 자동 마운트 ----
  function findSection(key){
    return q(`#sec-${key}`) || q(`#${key}`) || q(`[data-section="${key}"]`) || document.body;
  }
  function findTable(key){
    // 활성 섹션 우선 (현재 보여주는 탭에 그려 넣기)
    const activeKey = document.body?.dataset?.page || key;
    const activeRoot = findSection(activeKey);
    // UI 맵 우선
    const MAP = (window.GHMON_UI_MAP && window.GHMON_UI_MAP[activeKey] && window.GHMON_UI_MAP[activeKey].table) || null;
    if (MAP) { const el = q(MAP); if (el) return el; }
    // 흔한 테이블 셀렉터
    const cands = [
      `#tbl-${activeKey}`, `.tbl-${activeKey}`, `.table-${activeKey}`,
      "table"
    ];
    for (const sel of cands) {
      const el = q(sel, activeRoot) || q(sel, document);
      if (el) return el;
    }
    return null;
  }
  function ensureTable(key){
    let table = findTable(key);
    if (table) return table;
    // 조용한 자동 마운트: 섹션 끝에 테이블 1개 삽입(디자인 클래스 최소만)
    const root = findSection(document.body?.dataset?.page || key);
    table = document.createElement("table");
    table.id = `tbl-${key}`;
    table.className = "table ghmon-auto"; // 기존 CSS가 있으면 따라감, 없으면 기본 테이블
    const thead = document.createElement("thead");
    const tbody = document.createElement("tbody");
    table.appendChild(thead); table.appendChild(tbody);
    root.appendChild(table);
    return table;
  }

  // ---- 정규화 ----
  function kvPairsFromObj(obj){
    const rows = [];
    for (const k of Object.keys(obj||{})) {
      if (k === "ok" || k === "code" || k === "service" || k === "ts" || k === "env" || k === "durationMs") continue;
      const v = obj[k];
      if (Array.isArray(v) || typeof v !== "object" || v === null) rows.push({ name: String(k), value: v });
    }
    return rows;
  }
  function normItems(j){
    if (Array.isArray(j)) return j;
    if (Array.isArray(j?.items)) return j.items;
    if (Array.isArray(j?.data))  return j.data;
    const kv = kvPairsFromObj(j||{});
    if (kv.length) return kv;
    return [];
  }

  // ---- 렌더러 ----
  function renderTable(table, rows, cols){
    if (!table) return log("renderTable: table not found");
    const thead = table.querySelector("thead") || table.createTHead();
    const tbody = table.querySelector("tbody") || table.createTBody();
    tbody.innerHTML = "";
    const safeCols = Array.isArray(cols) && cols.length ? cols : Object.keys(rows?.[0]||{});
    // 헤더(최초 1회만)
    if (!thead.dataset.ghmon){
      thead.innerHTML = "";
      const trh = document.createElement("tr");
      for (const c of (safeCols.length? safeCols : ["name","value"])) {
        const th = document.createElement("th"); th.textContent = c; trh.appendChild(th);
      }
      thead.appendChild(trh);
      thead.dataset.ghmon = "1";
    }
    if (!rows || !rows.length) {
      const tr = document.createElement("tr");
      const td = document.createElement("td");
      td.colSpan = Math.max(1, safeCols.length||2);
      td.textContent = "No data";
      tr.appendChild(td); tbody.appendChild(tr); return;
    }
    const tdOf = (v)=>{
      const td = document.createElement("td");
      if (v instanceof Node) td.appendChild(v); else td.textContent = (v==null ? "" : String(v));
      return td;
    };
    for (const it of rows) {
      const tr = document.createElement("tr");
      for (const c of (safeCols.length? safeCols : Object.keys(it))) {
        let v = c.split(".").reduce((x,k)=>(x&&k in x)?x[k]:undefined, it);
        if ((c==="html_url"||c==="url") && v) {
          const a=document.createElement("a"); a.href=String(v); a.target="_blank"; a.rel="noopener";
          a.textContent=String(it.title||it.name||v); v=a;
        }
        tr.appendChild(tdOf(v));
      }
      tbody.appendChild(tr);
    }
    table.setAttribute("data-ghmon-filled","true");
  }

  // ---- 기본 컬럼 ----
  const DEFAULT_COLS = {
    overview: ["name","value"],
    prs: ["number","title","user.login","head.ref","base.ref","state","draft","updated_at","html_url"],
    issues: ["number","title","user.login","state","labels","updated_at","html_url"],
    actions: ["run_number","name","status","conclusion","event","head_branch","actor.login","created_at","html_url"],
    hooks: ["id","name","active","events","config.url","updated_at"],
    labels: ["name","color","description"],
    alerts: ["number","state","severity","dependency","manifest","created_at","html_url"]
  };

  // ---- fetch 헬퍼 ----
  async function fetchJson(url, opt){ const r=await fetch(url, opt||{cache:"no-store"}); if(!r.ok) throw new Error("HTTP "+r.status); return r.json(); }
  async function tryJson(paths){
    let last; for (const p of paths){
      try { const opt=typeof p==="string"?{url:p,method:"GET"}:p;
            return await fetchJson(opt.url, { method:opt.method||"GET", headers:{"Content-Type":"application/json"}, body: opt.body?JSON.stringify(opt.body):undefined, cache:"no-store" }); }
      catch(e){ last=e; }
    }
    throw last || new Error("fetch failed");
  }

  // ---- 로더(컨테이너 키를 받아 해당 섹션에 그림) ----
  const loaders = {
    overview: async (containerKey)=>{
      const j = await tryJson([ `${BASE}/overview`, `${BASE}/list/overview`, {url:`${BASE}/action/list@overview`, method:"POST"} ]);
      let rows = normItems(j);
      if (!rows.length) {
        rows = kvPairsFromObj(j);
        if (!rows.length) rows = [{name:"status", value: j?.ok? "OK":"N/A"}];
      }
      renderTable(ensureTable(containerKey||"overview"), rows, DEFAULT_COLS.overview);
      log("loader overview ok:", rows.length);
    },
    prs: async (containerKey)=>{
      const j = await tryJson([ `${BASE}/prs?state=open&limit=50`, `${BASE}/list/prs`, {url:`${BASE}/action/list@prs`, method:"POST"} ]);
      const rows = normItems(j);
      renderTable(ensureTable(containerKey||"prs"), rows, DEFAULT_COLS.prs);
      log("loader prs ok:", rows.length);
    },
    issues: async (containerKey)=>{
      const j = await tryJson([ `${BASE}/issues?state=open&limit=50`, `${BASE}/list/issues`, {url:`${BASE}/action/list@issues`, method:"POST"} ]);
      const rows = normItems(j);
      renderTable(ensureTable(containerKey||"issues"), rows, DEFAULT_COLS.issues);
      log("loader issues ok:", rows.length);
    },
    actions: async (containerKey)=>{
      const j = await tryJson([ `${BASE}/actions/runs?limit=30`, `${BASE}/list/actions`, {url:`${BASE}/action/list@actions`, method:"POST"} ]);
      const rows = normItems(j);
      renderTable(ensureTable(containerKey||"actions"), rows, DEFAULT_COLS.actions);
      log("loader actions ok:", rows.length);
    },
    hooks: async (containerKey)=>{
      const j = await tryJson([ `${BASE}/hooks`, `${BASE}/list/hooks`, {url:`${BASE}/action/list@hooks`, method:"POST"} ]);
      const rows = normItems(j);
      renderTable(ensureTable(containerKey||"hooks"), rows, DEFAULT_COLS.hooks);
      log("loader hooks ok:", rows.length);
    },
    labels: async (containerKey)=>{
      const j = await tryJson([ `${BASE}/labels`, `${BASE}/list/labels`, {url:`${BASE}/action/list@labels`, method:"POST"} ]);
      const rows = normItems(j);
      renderTable(ensureTable(containerKey||"labels"), rows, DEFAULT_COLS.labels);
      log("loader labels ok:", rows.length);
    },
    alerts: async (containerKey)=>{
      const j = await tryJson([ `${BASE}/alerts`, `${BASE}/alerts/dependabot`, `${BASE}/list/alerts`, {url:`${BASE}/action/list@alerts`, method:"POST"} ]);
      const rows = normItems(j);
      renderTable(ensureTable(containerKey||"alerts"), rows, DEFAULT_COLS.alerts);
      log("loader alerts ok:", rows.length);
    }
  };

  // ---- 액션/라우팅/헬스 ----
  const actBtns = qa("[data-ghmon-action], [data-action]");
  function afterActionReload(actionKey){
    const low = String(actionKey||"").toLowerCase();
    const map = [
      ["prs",    /prs|pull/],
      ["issues", /issue/],
      ["actions",/action(?!s$)|workflow|run/],
      ["hooks",  /hook/],
      ["labels", /label/],
      ["alerts", /alert|dependabot|codeql/]
    ];
    for (const [key,rx] of map){ if (rx.test(low)) { ensureLoaded(key, true); } }
  }
  function wireActions(){
    actBtns.forEach(b=>{
      b.addEventListener("click", async ()=>{
        const action = b.getAttribute("data-ghmon-action") || b.getAttribute("data-action") || "";
        const url = `${BASE}/action/${encodeURIComponent(action)}`;
        const t0 = performance.now();
        try {
          const j = await fetchJson(url, { method:"POST", headers:{"Content-Type":"application/json"} });
          const dt = Math.round(performance.now()-t0);
          log(`${action}: ok=${j?.ok} code=${j?.code} (${dt}ms)`);
          if (j?.ok) afterActionReload(action);
        }catch(e){ log(`${action}: error ${e.message||e}`); }
      }, { passive:true });
    });
  }

  const sections = qa(".section");
  const navBtns  = qa("[data-nav], .nav-btn[data-nav], a.nav-btn[data-nav]");
  function setActive(key, opts={push:true}){
    const target = findSection(key);
    if (!target) return log("route missing section", key);
    sections.forEach(s => s.classList.toggle("active", s === target));
    navBtns.forEach(b => {
      const k = b.getAttribute("data-nav") || "";
      b.classList.toggle("active", k===key);
      if (k===key) b.setAttribute("aria-current","page"); else b.removeAttribute("aria-current");
    });
    document.body.dataset.page = key;
    if (opts.push) try { history.pushState({page:key},"",`#${key}`); } catch(_){}
    log("route →", key);
    ensureLoaded(key, true); // key는 라우트 키(별칭 처리 포함)
  }
  function currentKey(){
    const h=(location.hash||"").replace(/^#/,"");
    if (h) return h;
    const active = q(".section.active"); if (active?.id?.startsWith("sec-")) return active.id.substring(4);
    const firstBtn = navBtns[0]; if (firstBtn) return firstBtn.getAttribute("data-nav");
    return "overview";
  }
  function wireNav(){
    navBtns.forEach(b=>{
      b.addEventListener("click", (ev)=>{ const k=b.getAttribute("data-nav"); if(!k) return; ev.preventDefault(); setActive(k,{push:true}); }, { passive:false });
    });
    window.addEventListener("hashchange", ()=> setActive(currentKey(), {push:false}));
  }

  let lastOK=false;
  async function health(){
    try {
      const j = await fetchJson(`${BASE}/health`, { cache:"no-store" });
      const ok = j && j.ok===true; const code = typeof j.code==="number" ? j.code : (ok?0:1);
      actBtns.forEach(b=> b.disabled = !ok || code!==0);
      if (ok!==lastOK) log("health", {ok, code, ts: j.ts ?? null});
      lastOK = ok;
    } catch(e){
      actBtns.forEach(b=> b.disabled = true);
      log("health error:", e.message||e); lastOK=false;
    }
  }

  function ensureLoaded(routeKey, force=false){
    const key = KEY_ALIASES[routeKey] || routeKey; // 실제 데이터 키
    const now=Date.now(), last=state["t_"+routeKey]||0;
    if (!force && (now-last)<15000) return;
    state["t_"+routeKey]=now;
    const fn = loaders[key];
    if (typeof fn==="function") {
      const t=ensureTable(routeKey); if (t) t.setAttribute("aria-busy","true");
      fn(routeKey).catch(e=>log(`loader ${key} error:`, e.message||e)).finally(()=>{ const t2=findTable(routeKey); if (t2) t2.removeAttribute("aria-busy"); });
    } else { log("no loader for key:", routeKey); }
  }

  window.addEventListener("pageshow", ()=>health(), {once:true});
  document.addEventListener("visibilitychange", ()=>{ if (!document.hidden) health(); });
  wireActions(); wireNav();
  const bootKey = currentKey();
  setActive(bootKey, {push:false});
  health(); setInterval(health, 10000);
  log("bridge boot", { BASE, btnCount: qa("[data-ghmon-action],[data-action]").length, navCount: qa("[data-nav]").length, bootKey });
})();