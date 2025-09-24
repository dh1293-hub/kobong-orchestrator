(async function(){
  const upEl = document.getElementById("updated");
  const httpEl = document.querySelector("#httpCard .rows");
  const tcpEl  = document.querySelector("#tcpCard .rows");
  const taskEl = document.querySelector("#taskCard .rows");
  async function load(){
    try{
      const resp = await fetch(`/data/gh-monitor.json?_=${Date.now()}`, {cache:"no-store"});
      if(!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const j = await resp.json();
      upEl.textContent = new Date(j.timestamp).toLocaleString();
      httpEl.innerHTML = "";
      (j.http||[]).forEach(x=>{
        const row = document.createElement("div"); row.className="row";
        const left = document.createElement("div"); left.textContent = x.url;
        const right = document.createElement("div");
        const span = document.createElement("span");
        const ok = !!x.ok;
        span.className = "pill " + (ok ? "ok" : "bad");
        span.textContent = ok ? `OK ${x.status}` : `ERR`;
        right.appendChild(span);
        row.append(left,right); httpEl.appendChild(row);
      });
      tcpEl.innerHTML = "";
      (j.tcp||[]).forEach(x=>{
        const row = document.createElement("div"); row.className="row";
        const left = document.createElement("div"); left.textContent = `:${x.port}`;
        const right = document.createElement("div");
        const span = document.createElement("span");
        const st = (x.state||'').toLowerCase();
        span.className = "pill " + (st === "listening" ? "ok" : "warn");
        span.textContent = x.state + (x.proc? ` (${x.proc}#${x.pid??''})`:'');
        right.appendChild(span);
        row.append(left,right); tcpEl.appendChild(row);
      });
      taskEl.innerHTML = "";
      const t = j.task||{};
      [["name", t.name ?? "MyTask_Interactive_v2"],
       ["lastRun", t.lastRun ?? "-"],
       ["result", (typeof t.result==="number" ? "0x"+(t.result>>>0).toString(16).padStart(8,'0') : (t.result??"-"))]
      ].forEach(([k,v])=>{
        const row = document.createElement("div"); row.className="row";
        const left = document.createElement("div"); left.textContent = k;
        const right = document.createElement("div");
        const span = document.createElement("span"); span.className="pill ok"; span.textContent = v;
        right.appendChild(span);
        row.append(left,right); taskEl.appendChild(row);
      });
    } catch(e){
      upEl.textContent = "Load error — " + e.message;
    }
  }
  await load();
  setInterval(load, 10000);
})();
