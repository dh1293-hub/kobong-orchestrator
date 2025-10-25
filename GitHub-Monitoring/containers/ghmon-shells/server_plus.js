"use strict";
const http = require("http"), https = require("https"), url = require("url");
const { spawn } = require("child_process");
const fs = require("fs");
const crypto = require("crypto");

const PORT  = process.env.PORT || 5182;
let   CUR_REPO = (process.env.GH_REPO || "").trim();        // 런타임 변경 가능
const TOKEN    = (process.env.GH_TOKEN || "").trim();       // 비상용 PAT (있으면 우선)

// ── GitHub App 인증(장기운영) ────────────────────────────────────────────────
const APP_ID       = (process.env.GH_APP_ID||"").trim();
const INST_ID      = (process.env.GH_INSTALLATION_ID||"").trim();
const APP_PK       = (process.env.GH_APP_PK||"").trim();           // (선택) PEM 내용
const APP_PK_FILE  = (process.env.GH_APP_PK_FILE||"").trim();      // (권장) PEM 파일 경로
let _installToken  = { token:null, exp:0 };                        // 설치 토큰 캐시

const b64u = s => Buffer.from(s).toString("base64")
  .replace(/=/g,"").replace(/\+/g,"-").replace(/\//g,"_");

function loadPem(){
  if (APP_PK) return APP_PK;
  if (APP_PK_FILE) { try { return fs.readFileSync(APP_PK_FILE,"utf8"); } catch(_){} }
  return null;
}
function makeAppJWT(){
  const pem = loadPem(); if (!APP_ID || !pem) return null;
  const now = Math.floor(Date.now()/1000);
  const header  = { alg:"RS256", typ:"JWT" };
  const payload = { iat: now-30, exp: now+8*60, iss: APP_ID };  // 8분 TTL
  const head = b64u(JSON.stringify(header));
  const body = b64u(JSON.stringify(payload));
  const data = head+"."+body;
  const sig  = crypto.createSign("RSA-SHA256").update(data)
                .sign(pem,"base64").replace(/=/g,"").replace(/\+/g,"-").replace(/\//g,"_");
  return data+"."+sig;
}
function fetchInstallationToken(){
  return new Promise((resolve,reject)=>{
    const jwt = makeAppJWT(); if (!jwt) return resolve(null);
    const opts = {
      hostname: "api.github.com",
      path: `/app/installations/${INST_ID}/access_tokens`,
      method: "POST",
      headers: { "User-Agent":"ghmon-shells-plus", "Accept":"application/vnd.github+json", "Authorization":"Bearer "+jwt }
    };
    const req = https.request(opts, r=>{
      const bufs=[]; r.on("data",c=>bufs.push(c)); r.on("end",()=>{
        const raw = Buffer.concat(bufs).toString("utf8"); let j={}; try{ j=JSON.parse(raw);}catch(_){}
        if (r.statusCode>=200 && r.statusCode<300) return resolve(j);
        reject(Object.assign(new Error("HTTP "+r.statusCode), {status:r.statusCode, body:raw}));
      });
    });
    req.on("error", reject); req.end();
  });
}
async function getAuthHeaders(accept){
  const headers = { "User-Agent":"ghmon-shells-plus", "Accept": accept || "application/vnd.github+json" };
  if (TOKEN){ headers.Authorization = "Bearer "+TOKEN; return headers; }
  if (!APP_ID || !INST_ID) return headers;     // 무인증(공개 API만)
  const now = Date.now();
  if (!_installToken.token || now >= _installToken.exp - 60_000){
    const tok = await fetchInstallationToken();
    _installToken.token = tok?.token || null;
    _installToken.exp   = tok?.expires_at ? Date.parse(tok.expires_at) : 0;
  }
  if (_installToken.token) headers.Authorization = "Bearer "+_installToken.token;
  return headers;
}

// ── 공통 응답/CORS ──────────────────────────────────────────────────────────
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

// ── 저수준 HTTP 호출(Repo 필요/불필요) ───────────────────────────────────────
async function gh(path, accept){                                     // repo 필요한 GET
  const { owner, repo } = parseRepo(CUR_REPO);
  if (!owner || !repo) throw new Error("GH_REPO missing (owner/repo)");
  const headers = await getAuthHeaders(accept);
  return httpCall("GET", path, null, headers);
}
async function ghWrite(path, method, body, accept){                   // repo 필요한 WRITE
  const { owner, repo } = parseRepo(CUR_REPO);
  if (!owner || !repo) throw new Error("GH_REPO missing (owner/repo)");
  const headers = await getAuthHeaders(accept);
  headers["Content-Type"]="application/json";
  return httpCall(method, path, body, headers);
}
async function httpCall(method, path, body, headers){                 // 공통 호출
  const data = body ? Buffer.from(JSON.stringify(body),"utf8") : null;
  const opts = { hostname:"api.github.com", path, method, headers: { ...(headers||{}) } };
  if (data) opts.headers["Content-Length"] = String(data.length);
  return new Promise((resolve,reject)=>{
    const req = https.request(opts, r=>{
      const chunks=[]; r.on("data",c=>chunks.push(c)); r.on("end",()=>{
        const raw=Buffer.concat(chunks).toString("utf8"); let j; try{ j=raw?JSON.parse(raw):{}; }catch(_){ j={raw}; }
        if (r.statusCode>=200 && r.statusCode<300) return resolve(j);
        const e=new Error("HTTP "+r.statusCode); e.status=r.statusCode; e.body=raw; reject(e);
      });
    });
    req.on("error", reject); if (data) req.write(data); req.end();
  });
}
function parseRepo(s){ const [owner, repo] = String(s||"").split("/"); return { owner, repo }; }

// ── Body 유틸 & Webhook 서명검증 ────────────────────────────────────────────
function readJson(req){ return new Promise(resolve=>{
  const bufs=[]; req.on("data",c=>bufs.push(c));
  req.on("end",()=>{ let j={}; try{ j=JSON.parse(Buffer.concat(bufs).toString("utf8")||"{}"); }catch(_){ j={}; } resolve(j); });
});}
function readRaw(req){ return new Promise(resolve=>{
  const bufs=[]; req.on("data",c=>bufs.push(c)); req.on("end",()=>resolve(Buffer.concat(bufs)));
});}
function verifySig(secret, rawBody, sigHeader){
  if (!secret) return true; // 개발용: 시크릿 미설정 시 건너뜀
  const mac = "sha256="+crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
  try { return crypto.timingSafeEqual(Buffer.from(mac), Buffer.from(sigHeader||"")); }
  catch { return false; }
}

// ── 리스트/개요 ────────────────────────────────────────────────────────────
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

// ── Security 목록 ──────────────────────────────────────────────────────────
async function listCodeAlerts(q){
  const per = Number(q?.limit || 100);
  const { owner, repo } = parseRepo(CUR_REPO);
  try {
    return await gh(`/repos/${owner}/${repo}/code-scanning/alerts?per_page=${per}`, "application/vnd.github+json");
  } catch (e){ if (e.status===403 || e.status===404) return []; throw e; }
}
async function listSecretAlerts(q){
  const per = Number(q?.limit || 100);
  const { owner, repo } = parseRepo(CUR_REPO);
  try {
    return await gh(`/repos/${owner}/${repo}/secret-scanning/alerts?per_page=${per}`, "application/vnd.github+json");
  } catch (e){ if (e.status===403 || e.status===404) return []; throw e; }
}

// ── PR 상세 ────────────────────────────────────────────────────────────────
async function getPR(no){
  const { owner, repo } = parseRepo(CUR_REPO);
  return gh(`/repos/${owner}/${repo}/pulls/${Number(no)}`);
}
async function getPRChecks(no){
  const pr = await getPR(no);
  const sha = pr?.head?.sha;
  if (!sha) return { head_sha:null, status:null, checks:[] };
  const { owner, repo } = parseRepo(CUR_REPO);
  const accept = "application/vnd.github+json";
  const runs = await gh(`/repos/${owner}/${repo}/commits/${sha}/check-runs`, accept);
  const checks = Array.isArray(runs?.check_runs) ? runs.check_runs : [];
  let status = null; try { status = await gh(`/repos/${owner}/${repo}/commits/${sha}/status`, accept); } catch(_) {}
  return { head_sha: sha, status, checks };
}
async function getPRTimeline(no){
  const { owner, repo } = parseRepo(CUR_REPO);
  const accept = "application/vnd.github+json";
  const items = await gh(`/repos/${owner}/${repo}/issues/${Number(no)}/timeline?per_page=100`, accept);
  return Array.isArray(items) ? items : [];
}
async function getPRFiles(no){
  const { owner, repo } = parseRepo(CUR_REPO);
  const items = await gh(`/repos/${owner}/${repo}/pulls/${Number(no)}/files?per_page=300`);
  return Array.isArray(items) ? items.map(f => ({
    filename: f.filename, status: f.status, additions: f.additions, deletions: f.deletions,
    changes: f.changes, blob_url: f.blob_url, raw_url: f.raw_url,
    patch: f.patch && String(f.patch).slice(0, 8000)
  })) : [];
}

// ── Security 쓰기 액션 ─────────────────────────────────────────────────────
async function getAlertByType(type, number){
  const { owner, repo } = parseRepo(CUR_REPO);
  const n = Number(number);
  const acc = "application/vnd.github+json";
  if (type==="deps")   return gh(`/repos/${owner}/${repo}/dependabot/alerts/${n}`, acc);
  if (type==="code")   return gh(`/repos/${owner}/${repo}/code-scanning/alerts/${n}`, acc);
  if (type==="secret") return gh(`/repos/${owner}/${repo}/secret-scanning/alerts/${n}`, acc);
  throw new Error("unknown type");
}
async function ensureTrackingIssue(type, number, extras){
  const { owner, repo } = parseRepo(CUR_REPO);
  const tag = `sec-alert-${type}-${number}`;
  const cand = await listIssues({ state:"open", limit: 100 });
  const hit = (cand||[]).find(i => (i.title||"").includes(tag) || (i.body||"").includes(tag));
  if (hit) return hit;

  const a = await getAlertByType(type, number).catch(()=>null);
  const title = `[SEC][${type}] Alert #${number} ${a?.rule?.id || a?.dependency?.package?.name || a?.secret_type || ""} — ${tag}`;
  const body  = [
    `자동 생성된 추적 이슈\n`,
    `- 타입: ${type}`,
    `- 알림번호: ${number}`,
    a?.html_url ? `- 링크: ${a.html_url}` : "",
    `- 태그: ${tag}`,
  ].filter(Boolean).join("\n");
  const payload = { title, body, labels: ["security", `sec/${type}`].concat(extras?.labels||[]) };
  if (Array.isArray(extras?.assignees) && extras.assignees.length) payload.assignees = extras.assignees;
  return ghWrite(`/repos/${owner}/${repo}/issues`, "POST", payload);  // ★따옴표 오탈자 주의
}
async function addIssueAssignees(issue_number, assignees){
  const { owner, repo } = parseRepo(CUR_REPO);
  if (!assignees || !assignees.length) return { ok:true, skipped:"no-assignees" };
  return ghWrite(`/repos/${owner}/${repo}/issues/${Number(issue_number)}`, "PATCH", { assignees });
}
async function addIssueLabels(issue_number, labels){
  const { owner, repo } = parseRepo(CUR_REPO);
  if (!labels || !labels.length) return { ok:true, skipped:"no-labels" };
  return ghWrite(`/repos/${owner}/${repo}/issues/${Number(issue_number)}`, "PATCH", { labels });
}
async function dismissAlert(type, number, fields){
  const { owner, repo } = parseRepo(CUR_REPO);
  const n = Number(number);
  if (type==="code"){
    const body = { state:"dismissed" };
    if (fields?.reason)  body.dismissed_reason  = fields.reason;
    if (fields?.comment) body.dismissed_comment = fields.comment;
    return ghWrite(`/repos/${owner}/${repo}/code-scanning/alerts/${n}`, "PATCH", body);
  }
  if (type==="deps"){
    const body = { state:"dismissed" };
    if (fields?.reason)  body.dismissed_reason  = fields.reason;
    if (fields?.comment) body.dismissed_comment = fields.comment;
    return ghWrite(`/repos/${owner}/${repo}/dependabot/alerts/${n}`, "PATCH", body);
  }
  if (type==="secret"){
    const body = { state:"resolved" };
    if (fields?.reason)  body.resolution = fields.reason;
    return ghWrite(`/repos/${owner}/${repo}/secret-scanning/alerts/${n}`, "PATCH", body);
  }
  throw new Error("unknown type");
}

// ── Release helpers ────────────────────────────────────────────────────────
async function genReleaseNotes(tag, target){
  const { owner, repo } = parseRepo(CUR_REPO);
  try {
    return await ghWrite(`/repos/${owner}/${repo}/releases/generate-notes`,
      "POST", { tag_name: tag, target_commitish: target || "main" });
  } catch (e){ return { name: tag, body: "" }; }
}
async function createRelease(tag, target, name, body){
  const { owner, repo } = parseRepo(CUR_REPO);
  return ghWrite(`/repos/${owner}/${repo}/releases`, "POST", {
    tag_name: tag, target_commitish: target || "main",
    name: name || tag, body: body || "", draft: false, prerelease: false
  });
}

// ── 서버 라우터 ────────────────────────────────────────────────────────────
const server = http.createServer(async (req,res)=>{
  // CORS 프리플라이트
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
    const tokLen = TOKEN ? TOKEN.length : (_installToken.token ? 999 : 0); // App 토큰이면 길이 노출X
    return ok(res, { ...common, env:{ GH_REPO: CUR_REPO? "set":"unset", GH_TOKEN_ASCII_LEN: tokLen }, repo: CUR_REPO });
  }

  // API prefix만 허용
  if (!p.startsWith("/api/ghmon/")) return bad(res, 404, "Not Found", { ...common, path:p });

  try{
    // ── Webhook 수신
    if (req.method==="POST" && p==="/api/ghmon/webhook"){
      const raw = await readRaw(req);
      const evt = req.headers["x-github-event"] || "";
      const id  = req.headers["x-github-delivery"] || "";
      const sig = req.headers["x-hub-signature-256"] || "";
      const secret = process.env.GH_WEBHOOK_SECRET || "";
      if (!verifySig(secret, raw, sig)) return bad(res, 401, "invalid signature", { event:evt, delivery:id });
      let payload={}; try{ payload=JSON.parse(raw.toString("utf8")); }catch(_){}
      console.log("[WEBHOOK]", evt, id, payload.action||"");
      return ok(res, { received:true, event:evt, delivery:id });
    }

    // ── 레포 목록(비공개 포함): 토큰/앱 토큰 있으면 /user/repos → owner로 필터
    if (req.method==="GET" && p==="/api/ghmon/repos"){
      const owner=(u.query.owner||"").trim(); if (!owner) return bad(res, 400, "owner required", common);
      const headers = await getAuthHeaders("application/vnd.github+json");

      async function call(path, hdrs){ return httpCall("GET", path, null, hdrs); }

      let list=[];
      if (headers.Authorization){
        list = await call(`/user/repos?per_page=100&sort=updated&direction=desc&visibility=all&affiliation=owner,collaborator,organization_member`, headers);
        if (Array.isArray(list)) list = list.filter(r=>String(r?.owner?.login||"").toLowerCase()===owner.toLowerCase());
      } else {
        try{ list=await call(`/users/${owner}/repos?per_page=100&type=all&sort=updated`, headers); }
        catch(_){ list=await call(`/orgs/${owner}/repos?per_page=100&type=all&sort=updated`, headers); }
      }
      return ok(res, { ...common, items: Array.isArray(list)? list: [] });
    }

    // ── 런타임 Repo 설정
    if (req.method==="POST" && p==="/api/ghmon/action/set-repo"){
      const owner=(u.query.owner||"").trim(); const repo=(u.query.repo||"").trim();
      if (!owner || !repo) return bad(res, 400, "owner and repo required", common);
      CUR_REPO = `${owner}/${repo}`; return ok(res, { ...common, repo: CUR_REPO, message:"repo switched" });
    }

    // ── PR 상세 3종
    if (req.method==="GET" && p==="/api/ghmon/pr/checks"){
      const no=Number(u.query.number||0); if (!no) return bad(res, 400, "number required", common);
      const data=await getPRChecks(no); return ok(res, { ...common, number:no, ...data });
    }
    if (req.method==="GET" && p==="/api/ghmon/pr/timeline"){
      const no=Number(u.query.number||0); if (!no) return bad(res, 400, "number required", common);
      const items=await getPRTimeline(no); return ok(res, { ...common, number:no, items });
    }
    if (req.method==="GET" && p==="/api/ghmon/pr/files"){
      const no=Number(u.query.number||0); if (!no) return bad(res, 400, "number required", common);
      const items=await getPRFiles(no); return ok(res, { ...common, number:no, items });
    }

    // ── Security 목록
    if (req.method==="GET" && p==="/api/ghmon/security/code"){   const items=await listCodeAlerts(u.query||{});   return ok(res, { ...common, items }); }
    if (req.method==="GET" && p==="/api/ghmon/security/deps"){   const items=await listAlerts(u.query||{});       return ok(res, { ...common, items }); }
    if (req.method==="GET" && p==="/api/ghmon/security/secret"){ const items=await listSecretAlerts(u.query||{});  return ok(res, { ...common, items }); }

    // ── Security 쓰기 액션
    if (req.method==="POST" && p.startsWith("/api/ghmon/action/security@")){
      const action = decodeURIComponent(p.split("@")[1]||"");
      const type   = String(u.query.type||"").trim() || "deps";
      const number = Number(u.query.number||0);
      const body   = await readJson(req);

      if (!["create_issues","assign","label","dismiss_with_reason"].includes(action))
        return bad(res, 400, "unknown action", { ...common, action });
      if (!number && action!=="label")
        return bad(res, 400, "number required", { ...common, action });

      if (action==="create_issues"){
        const issue = await ensureTrackingIssue(type, number, { labels: body.labels||[], assignees: body.assignees||[] });
        return ok(res, { ...common, action, type, number, issue });
      }
      if (action==="assign"){
        const issue = await ensureTrackingIssue(type, number, {});
        const list = Array.isArray(body.assignees)?body.assignees:String(body.assignees||"").split(",").map(s=>s.trim()).filter(Boolean);
        const r = await addIssueAssignees(issue.number, list);
        return ok(res, { ...common, action, type, number, issue, result:r });
      }
      if (action==="label"){
        const issue = await ensureTrackingIssue(type, number, {});
        const list = Array.isArray(body.labels)?body.labels:String(body.labels||"").split(",").map(s=>s.trim()).filter(Boolean);
        const r = await addIssueLabels(issue.number, list);
        return ok(res, { ...common, action, type, number, issue, result:r });
      }
      if (action==="dismiss_with_reason"){
        const r = await dismissAlert(type, number, { reason: body.reason||u.query.reason, comment: body.comment||u.query.comment });
        return ok(res, { ...common, action, type, number, result:r });
      }
    }

    // ── Release 3종
    if (req.method==="POST" && p==="/api/ghmon/release/create"){
      const q=u.query||{}; const body=await readJson(req);
      const tag=String(body.tag||q.tag||"").trim(); const target=String(body.target||q.target||"main").trim();
      let notes=String(body.notes||"").trim();
      if (!tag) return bad(res, 400, "tag required", common);
      if (!notes){ const g=await genReleaseNotes(tag, target); notes=String(g.body||""); }
      const rel=await createRelease(tag, target, tag, notes);
      return ok(res, { ...common, release:{ id:rel.id, html_url:rel.html_url, tag_name:rel.tag_name, body:rel.body } });
    }
    if (req.method==="POST" && p==="/api/ghmon/release/trigger-deploy"){
      const q=u.query||{}; const body=await readJson(req);
      const { owner, repo } = parseRepo(CUR_REPO);
      const event_type=String(body.event||q.event||"deploy").trim();
      const payload={ ref:String(body.target||q.target||"main"),
                      version:String(body.tag||q.tag||"").trim()||undefined,
                      notes:String(body.notes||"").slice(0,2000) };
      await ghWrite(`/repos/${owner}/${repo}/dispatches`, "POST", { event_type, client_payload: payload });
      return ok(res, { ...common, dispatched:true, event_type, payload });
    }
    if (req.method==="POST" && p==="/api/ghmon/release/backport"){
      const body=await readJson(req);
      const tag=String(body.tag||"").trim(); const target=String(body.target||"release").trim();
      if (!tag) return bad(res, 400, "tag required", common);
      const { owner, repo } = parseRepo(CUR_REPO);
      const title=`[Backport] ${tag} → ${target}`;
      const text =`자동 생성된 백포트 추적 이슈\n- tag: ${tag}\n- target: ${target}\n- created by ghmon`;
      const issue=await ghWrite(`/repos/${owner}/${repo}/issues`, "POST", { title, body:text, labels:["release","backport"] });
      return ok(res, { ...common, issue:{ number:issue.number, html_url:issue.html_url, title:issue.title } });
    }

    // ── Shell Ops
    if (req.method==="GET" && p==="/api/ghmon/shell/health"){
      const ids=[..."12"]; const list=ids.map(id=>({ id, running:false }));  // 간소화
      return ok(res, { ...common, items:list });
    }
    if (req.method==="POST" && p==="/api/ghmon/shell/connect"){
      const id=String(u.query.id||"1"); return ok(res, { ...common, id, connected:true });
    }
    if (req.method==="POST" && p==="/api/ghmon/shell/stop"){
      const id=String(u.query.id||"1"); return ok(res, { ...common, id, stopped:true });
    }
    if (req.method==="POST" && p==="/api/ghmon/shell/exec"){
      const id=String(u.query.id||"1"); const body=await readJson(req); const cmd=(body.cmd||"").trim();
      if (!cmd) return bad(res, 400, "cmd required", common);
      const ps = spawn("powershell.exe", ["-NoLogo","-NoProfile","-ExecutionPolicy","Bypass","-Command", cmd], { windowsHide:true });
      let out="",err=""; ps.stdout.on("data",c=>out+=c.toString("utf8")); ps.stderr.on("data",c=>err+=c.toString("utf8"));
      ps.on("error", e=> ok(res, { ...common, id, error:String(e.message||e), out, err }));
      ps.on("close", code=> ok(res, { ...common, id, code, out, err }));
      return;
    }

    // ── 요약/목록 라우트
    if (req.method==="GET" && p==="/api/ghmon/overview")     return ok(res, { ...common, items: await overview() });
    if (req.method==="GET" && p==="/api/ghmon/prs")          return ok(res, { ...common, items: await listPRs(u.query||{}) });
    if (req.method==="GET" && p==="/api/ghmon/issues")       return ok(res, { ...common, items: await listIssues(u.query||{}) });
    if (req.method==="GET" && p==="/api/ghmon/actions/runs") return ok(res, { ...common, items: await listRuns(u.query||{}) });
    if (req.method==="GET" && p==="/api/ghmon/labels")       return ok(res, { ...common, items: await listLabels() });
    if (req.method==="GET" && p==="/api/ghmon/hooks")        return ok(res, { ...common, items: await listHooks() });
    if (req.method==="GET" && p==="/api/ghmon/alerts")       return ok(res, { ...common, items: await listAlerts(u.query||{}) });

    // /list/<key>
    const m = p.match(/^\/api\/ghmon\/list\/([a-z\-]+)$/);
    if (req.method==="GET" && m){
      const k=m[1]; const map={overview,prs:listPRs,issues:listIssues,actions:listRuns,hooks:listHooks,labels:listLabels,alerts:listAlerts};
      const fn=map[k]; if (fn){ const items=await fn(u.query||{}); return ok(res, { ...common, items }); }
    }

    // 자리표시자 액션(그 외)
    if (req.method==="POST" && p.startsWith("/api/ghmon/action/")){
      const action=decodeURIComponent(p.split("/").pop()||""); return ok(res, { ...common, action });
    }

    return bad(res, 404, "Not Found", { ...common, path:p });
  }catch(e){
    return ok(res, { ...common, error:String(e.message||e), stack:(e.stack||"").split("\n").slice(0,2).join("\n") });
  }
});
server.listen(PORT, ()=> console.log(`[GHMON] shells+api up :${PORT} repo=${CUR_REPO||"n/a"}`));
