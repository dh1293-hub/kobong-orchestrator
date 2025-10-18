"use strict";
const http = require("http"), https = require("https"), url = require("url");
const PORT  = process.env.PORT || 5182;
let   CUR_REPO = (process.env.GH_REPO || "").trim();     // ★ 런타임 변경 가능
const TOKEN    = (process.env.GH_TOKEN || "").trim();

// ---- 공통 응답(CORS)
function send(res, code, obj){
  const b = JSON.stringify(obj);
  res.writeHead(code, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Max-Age": "86400"
  });
  res.end(b);
}
const ok = (res, extras)=> send(res, 200, { ok:true, code:0, ...extras });
const bad= (res, code, msg, extras={})=> send(res, code, { ok:false, code:1, message: msg, ...extras });

function parseRepo(s){ const [owner, repo] = String(s||"").split("/"); return { owner, repo }; }
function gh(path, accept){
  return new Promise((resolve, reject)=>{
    const { owner, repo } = parseRepo(CUR_REPO);
    if (!owner || !repo) return reject(new Error("GH_REPO missing (owner/repo)"));
    const opts = {
      hostname: "api.github.com",
      path,
      method: "GET",
      headers: {
        "User-Agent": "ghmon-shells-plus",
        "Accept": accept || "application/vnd.github+json"
      }
    };
    if (TOKEN) opts.headers["Authorization"] = "Bearer " + TOKEN;
    const req = https.request(opts, (r)=>{
      const chunks = [];
      r.on("data",(c)=>chunks.push(c));
      r.on("end", ()=>{
        const raw = Buffer.concat(chunks).toString("utf8");
        let j = null; try { j = JSON.parse(raw); } catch(_) { j = { raw }; }
        if (r.statusCode>=200 && r.statusCode<300) return resolve(j);
        const e = new Error("HTTP " + r.statusCode); e.status=r.statusCode; e.body=raw; reject(e);
      });
    });
    req.on("error", reject); req.end();
  });
}

// ---- GitHub 호출들 (CUR_REPO 기준)
async function listPRs(q){ const state=q.state||"open"; const per=Number(q.limit||50);
  const {owner,repo}=parseRepo(CUR_REPO);
  return gh(`/repos/${owner}/${repo}/pulls?state=${encodeURIComponent(state)}&per_page=${per}`);
}
async function listIssues(q){ const state=q.state||"open"; const per=Number(q.limit||50);
  const {owner,repo}=parseRepo(CUR_REPO);
  const data=await gh(`/repos/${owner}/${repo}/issues?state=${encodeURIComponent(state)}&per_page=${per}`);
  return Array.isArray(data)? data.filter(x=>!x.pull_request) : data;
}
async function listRuns(q){ const per=Number(q.limit||30);
  const {owner,repo}=parseRepo(CUR_REPO);
  const data=await gh(`/repos/${owner}/${repo}/actions/runs?per_page=${per}`); return data.workflow_runs||[];
}
async function listLabels(){ const {owner,repo}=parseRepo(CUR_REPO); return gh(`/repos/${owner}/${repo}/labels?per_page=100`); }
async function listHooks(){  const {owner,repo}=parseRepo(CUR_REPO); return gh(`/repos/${owner}/${repo}/hooks?per_page=100`); }
async function listAlerts(q){ const per=Number(q.limit||50);
  const {owner,repo}=parseRepo(CUR_REPO);
  try{
    const acc="application/vnd.github+json";
    const data=await gh(`/repos/${owner}/${repo}/dependabot/alerts?per_page=${per}`, acc);
    return Array.isArray(data)?data:[];
  } catch(e){ if (e.status===403 || e.status===404) return []; throw e; }
}
async function overview(){
  const [prs,issues,runs]=await Promise.all([ listPRs({}), listIssues({}), listRuns({}) ]);
  const newestRun=(runs[0]?.created_at)||null;
  return [
    { name:"repo", value: CUR_REPO },
    { name:"open_prs", value: Array.isArray(prs)?prs.length:0 },
    { name:"open_issues", value: Array.isArray(issues)?issues.length:0 },
    { name:"latest_workflow_run", value: newestRun }
  ];
}

// ---- 추가: owner의 repo 목록을 가져오되 users/orgs 모두 시도
async function listReposByOwner(owner){
  const accept="application/vnd.github+json";
  const tryGet = (p)=> new Promise((res,rej)=>{
    const opts={ hostname:"api.github.com", path:p, method:"GET",
      headers:{ "User-Agent":"ghmon-shells-plus", "Accept": accept } };
    if (TOKEN) opts.headers["Authorization"]="Bearer "+TOKEN;
    const req=https.request(opts,(r)=>{ const chunks=[]; r.on("data",c=>chunks.push(c)); r.on("end",()=>{
      const raw=Buffer.concat(chunks).toString("utf8"); let j=null; try{ j=JSON.parse(raw);}catch(_){ j={raw}; }
      return (r.statusCode>=200 && r.statusCode<300) ? res(j) : rej(Object.assign(new Error("HTTP "+r.statusCode),{status:r.statusCode, body:raw}));
    }); });
    req.on("error",rej); req.end();
  });
  try { return await tryGet(`/users/${owner}/repos?per_page=100&type=all&sort=updated`); }
  catch(e){ /* ignore */ }
  return await tryGet(`/orgs/${owner}/repos?per_page=100&type=all&sort=updated`);
}

// ---- 서버
const server = http.createServer(async (req,res)=>{
  // CORS preflight
  if (req.method==="OPTIONS"){
    res.writeHead(204,{
      "Access-Control-Allow-Origin":"*",
      "Access-Control-Allow-Methods":"GET,POST,OPTIONS",
      "Access-Control-Allow-Headers":"Content-Type, Authorization",
      "Access-Control-Max-Age":"86400"
    }); return res.end();
  }

  const u=url.parse(req.url,true); const p=u.pathname||"";
  const common={ service:"ghmon-shells-plus", ts:new Date().toISOString() };

  // Health
  if (req.method==="GET" && (p==="/health" || p==="/api/ghmon/health")){
    return ok(res, { ...common, env:{ GH_REPO: CUR_REPO? "set":"unset", GH_TOKEN_ASCII_LEN: TOKEN?TOKEN.length:0 }, repo: CUR_REPO });
  }

  // API prefix
  if (!p.startsWith("/api/ghmon/")){
    return bad(res, 404, "Not Found", { ...common, path:p });
  }

  try{
    // ---- 신규: owner의 레포 목록
    if (req.method==="GET" && p==="/api/ghmon/repos"){
      const owner=(u.query.owner||"").trim();
      if (!owner) return bad(res, 400, "owner required", common);
      const list = await listReposByOwner(owner);            // Array of repo objects
      return ok(res, { ...common, items: Array.isArray(list)? list: [] });
    }

    // ---- 신규: 런타임 repo 설정 (쿼리 owner,repo)
    if (req.method==="POST" && p==="/api/ghmon/action/set-repo"){
      const owner=(u.query.owner||"").trim();
      const repo =(u.query.repo ||"").trim();
      if (!owner || !repo) return bad(res, 400, "owner and repo required", common);
      CUR_REPO = `${owner}/${repo}`;
      return ok(res, { ...common, repo: CUR_REPO, message:"repo switched" });
    }

    // 기존 목록 엔드포인트
    if (req.method==="GET" && p==="/api/ghmon/overview")     return ok(res, { ...common, items: await overview() });
    if (req.method==="GET" && p==="/api/ghmon/prs")          return ok(res, { ...common, items: await listPRs(u.query||{}) });
    if (req.method==="GET" && p==="/api/ghmon/issues")       return ok(res, { ...common, items: await listIssues(u.query||{}) });
    if (req.method==="GET" && p==="/api/ghmon/actions/runs") return ok(res, { ...common, items: await listRuns(u.query||{}) });
    if (req.method==="GET" && p==="/api/ghmon/labels")       return ok(res, { ...common, items: await listLabels() });
    if (req.method==="GET" && p==="/api/ghmon/hooks")        return ok(res, { ...common, items: await listHooks() });
    if (req.method==="GET" && p==="/api/ghmon/alerts")       return ok(res, { ...common, items: await listAlerts(u.query||{}) });

    // 별칭
    const m = p.match(/^\/api\/ghmon\/list\/([a-z\-]+)$/);
    if (req.method==="GET" && m){
      const k=m[1]; const map={overview,prs:listPRs,issues:listIssues,actions:listRuns,hooks:listHooks,labels:listLabels,alerts:listAlerts};
      const fn=map[k]; if (fn){ const items=await fn(u.query||{}); return ok(res, { ...common, items }); }
    }

    // 액션 패스스루(기존)
    if (req.method==="POST" && p.startsWith("/api/ghmon/action/")){
      const action=decodeURIComponent(p.split("/").pop()||"");
      return ok(res, { ...common, action });
    }

    return bad(res, 404, "Not Found", { ...common, path:p });
  }catch(e){
    return ok(res, { ...common, error:String(e.message||e), stack:(e.stack||"").split("\n").slice(0,2).join("\n") });
  }
});
server.listen(PORT, ()=> console.log(`[GHMON] shells+api up :${PORT} repo=${CUR_REPO||"n/a"}`));
