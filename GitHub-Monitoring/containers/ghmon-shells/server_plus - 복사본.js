"use strict";
const http = require("http"), https = require("https"), url = require("url");
const PORT  = process.env.PORT || 5182;
const REPO  = (process.env.GH_REPO  || "").trim();   // owner/repo
const TOKEN = (process.env.GH_TOKEN || "").trim();

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
function parseRepo(s){ const [owner, repo] = String(s||"").split("/"); return { owner, repo }; }
function gh(path, accept){
  return new Promise((resolve, reject)=>{
    const { owner, repo } = parseRepo(REPO);
    if (!owner || !repo) return reject(new Error("GH_REPO missing (owner/repo)"));
    const opts = {
      hostname: "api.github.com",
      path, method: "GET",
      headers: { "User-Agent": "ghmon-shells-plus", "Accept": accept || "application/vnd.github+json" }
    };
    if (TOKEN) opts.headers["Authorization"] = "Bearer " + TOKEN;
    const req = https.request(opts, (r)=>{
      const chunks=[]; r.on("data",(c)=>chunks.push(c));
      r.on("end",()=>{
        const raw = Buffer.concat(chunks).toString("utf8");
        let j=null; try{ j=JSON.parse(raw);}catch(_){ j={raw}; }
        if (r.statusCode>=200 && r.statusCode<300) return resolve(j);
        const e=new Error("HTTP "+r.statusCode); e.status=r.statusCode; e.body=raw; reject(e);
      });
    });
    req.on("error", reject); req.end();
  });
}
async function listPRs(q){ const state=q.state||"open"; const per=Number(q.limit||50); const {owner,repo}=parseRepo(REPO);
  return gh(`/repos/${owner}/${repo}/pulls?state=${encodeURIComponent(state)}&per_page=${per}`); }
async function listIssues(q){ const state=q.state||"open"; const per=Number(q.limit||50); const {owner,repo}=parseRepo(REPO);
  const data=await gh(`/repos/${owner}/${repo}/issues?state=${encodeURIComponent(state)}&per_page=${per}`);
  return Array.isArray(data)? data.filter(x=>!x.pull_request) : data; }
async function listRuns(q){ const per=Number(q.limit||30); const {owner,repo}=parseRepo(REPO);
  const data=await gh(`/repos/${owner}/${repo}/actions/runs?per_page=${per}`); return data.workflow_runs||[]; }
async function listLabels(){ const {owner,repo}=parseRepo(REPO); return gh(`/repos/${owner}/${repo}/labels?per_page=100`); }
async function listHooks(){  const {owner,repo}=parseRepo(REPO); return gh(`/repos/${owner}/${repo}/hooks?per_page=100`); }
async function listAlerts(q){ const per=Number(q.limit||50); const {owner,repo}=parseRepo(REPO);
  try { const acc="application/vnd.github+json";
    const data=await gh(`/repos/${owner}/${repo}/dependabot/alerts?per_page=${per}`, acc); return Array.isArray(data)?data:[]; }
  catch(e){ if(e.status===403||e.status===404) return []; throw e; } }
async function overview(){
  const [prs,issues,runs]=await Promise.all([listPRs({}),listIssues({}),listRuns({})]);
  const newestRun=(runs[0]?.created_at)||null;
  return [
    {name:"repo", value: REPO},
    {name:"open_prs", value: Array.isArray(prs)?prs.length:0},
    {name:"open_issues", value: Array.isArray(issues)?issues.length:0},
    {name:"latest_workflow_run", value: newestRun}
  ];
}

const server=http.createServer(async (req,res)=>{
  // Preflight
  if (req.method==="OPTIONS"){ res.writeHead(204,{
    "Access-Control-Allow-Origin":"*",
    "Access-Control-Allow-Methods":"GET,POST,OPTIONS",
    "Access-Control-Allow-Headers":"Content-Type, Authorization",
    "Access-Control-Max-Age":"86400"
  }); return res.end(); }

  const u=url.parse(req.url,true); const p=u.pathname||""; const start=Date.now();
  const common={service:"ghmon-shells-plus", ts:new Date().toISOString()};

  if (req.method==="GET" && (p==="/health"||p==="/api/ghmon/health"))
    return send(res,200,{ok:true,code:0,...common,env:{GH_REPO:REPO?"set":"unset",GH_TOKEN_ASCII_LEN:TOKEN?TOKEN.length:0}});

  try{
    if (req.method==="GET" && p==="/api/ghmon/overview")     return send(res,200,{ok:true,code:0,items:await overview(),...common,durationMs:Date.now()-start});
    if (req.method==="GET" && p==="/api/ghmon/prs")          return send(res,200,{ok:true,code:0,items:await listPRs(u.query||{}),...common});
    if (req.method==="GET" && p==="/api/ghmon/issues")       return send(res,200,{ok:true,code:0,items:await listIssues(u.query||{}),...common});
    if (req.method==="GET" && p==="/api/ghmon/actions/runs") return send(res,200,{ok:true,code:0,items:await listRuns(u.query||{}),...common});
    if (req.method==="GET" && p==="/api/ghmon/labels")       return send(res,200,{ok:true,code:0,items:await listLabels(),...common});
    if (req.method==="GET" && p==="/api/ghmon/hooks")        return send(res,200,{ok:true,code:0,items:await listHooks(),...common});
    if (req.method==="GET" && p==="/api/ghmon/alerts")       return send(res,200,{ok:true,code:0,items:await listAlerts(u.query||{}),...common});

    const m=p.match(/^\/api\/ghmon\/list\/([a-z\-]+)$/);
    if (req.method==="GET" && m){
      const map={overview,prs:listPRs,issues:listIssues,actions:listRuns,hooks:listHooks,labels:listLabels,alerts:listAlerts};
      const fn=map[m[1]]; if (fn) return send(res,200,{ok:true,code:0,items:await fn(u.query||{}),...common});
    }
    const a=p.match(/^\/api\/ghmon\/action\/list@([a-z\-]+)$/);
    if (req.method==="POST" && a){
      const map={overview,prs:listPRs,issues:listIssues,actions:listRuns,hooks:listHooks,labels:listLabels,alerts:listAlerts};
      const fn=map[a[1]]; if (fn) return send(res,200,{ok:true,code:0,items:await fn({}),...common});
    }
    if (req.method==="POST" && p.startsWith("/api/ghmon/action/")){
      const action=decodeURIComponent(p.split("/").pop()||""); return send(res,200,{ok:true,code:0,action,...common});
    }
    return send(res,404,{ok:false,code:1,message:"Not Found",path:p,...common});
  }catch(e){
    return send(res,200,{ok:false,code:1,message:String(e.message||e),stack:(e.stack||"").split("\n").slice(0,2).join("\n"),...common});
  }
});
server.listen(PORT,()=>console.log(`[GHMON] shells+api up :${PORT} repo=${REPO||"n/a"}`));