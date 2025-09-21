import express from "express";
import cors from "cors";
const app = express();
const PORT = Number(process.env.PORT||5057);
const ORIGIN = process.env.CORS_ORIGIN || "*";
const TOKEN = process.env.GITHUB_TOKEN || "";
app.use(cors({ origin: ORIGIN, credentials: true }));
app.use(express.json({ type: ["application/json","application/*+json"] }));
const baseHeaders = { "User-Agent":"octapulse-gh-monitor", "Accept":"application/vnd.github+json", ...(TOKEN?{Authorization:`Bearer ${TOKEN}`}:{}) };
const etagCache = new Map();
async function gh(path){ const url=`https://api.github.com${path}`; const h={...baseHeaders}; const c=etagCache.get(url);
  if(c?.etag) h["If-None-Match"]=c.etag; const r=await fetch(url,{headers:h});
  if(r.status===304 && c) return c.body; const et=r.headers.get("etag"); const body=await r.json().catch(()=>({})); if(et) etagCache.set(url,{etag:et,body}); return body; }
function ok(req,res){ const {owner,repo}=req.query; if(!owner||!repo){res.status(400).json({error:"owner/repo required"}); return null} return {owner,repo}; }
app.get("/api/status", async (req,res)=>{ try{ const p=ok(req,res); if(!p)return;
  const [repoInfo, issues, prs, runs, rate] = await Promise.all([
    gh(`/repos/${p.owner}/${p.repo}`),
    gh(`/search/issues?q=repo:${p.owner}/${p.repo}+is:issue+is:open`),
    gh(`/search/issues?q=repo:${p.owner}/${p.repo}+is:pr+is:open`),
    gh(`/repos/${p.owner}/${p.repo}/actions/runs?per_page=5`),
    gh(`/rate_limit`)
  ]);
  res.json({ repoInfo, counts:{issues:issues.total_count, prs:prs.total_count}, workflows:runs, rate });
} catch(e){ res.status(500).json({error:String(e?.message||e)}) }});
app.get("/api/events", async (req,res)=>{ try{ const p=ok(req,res); if(!p)return; res.json(await gh(`/repos/${p.owner}/${p.repo}/events?per_page=30`)); } catch(e){ res.status(500).json({error:String(e?.message||e)}) }});
app.get("/api/rate", async (_req,res)=>{ try{ res.json(await gh("/rate_limit")) } catch(e){ res.status(500).json({error:String(e?.message||e)}) }});
const clients=new Set();
app.get("/api/stream",(req,res)=>{ const {owner,repo}=req.query; if(!owner||!repo) return res.status(400).end();
  res.setHeader("Content-Type","text/event-stream"); res.setHeader("Cache-Control","no-cache"); res.setHeader("Connection","keep-alive");
  const c={res,owner,repo}; clients.add(c); res.write(`event: hello\ndata: {"ok":true}\n\n`); req.on("close",()=>clients.delete(c));
});
setInterval(async()=>{ for (const c of clients){ try{ const ev=await gh(`/repos/${c.owner}/${c.repo}/events?per_page=10`);
  c.res.write(`event: events\ndata: ${JSON.stringify(ev)}\n\n`); } catch(e){ c.res.write(`event: error\ndata: ${JSON.stringify({error:String(e?.message||e)})}\n\n`); } } },15000);
app.listen(PORT,()=>console.log(`gh-bridge listening on http://localhost:${PORT}`));