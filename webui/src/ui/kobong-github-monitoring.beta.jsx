import React, { useEffect, useMemo, useState } from "react";
import { Rocket, RefreshCw, Moon, GitBranch, GitPullRequest, GitCommit, GitMerge, AlertCircle, Star, Tag, BarChart3, ListTree, CheckCircle2, XCircle, Clock, Link2, Server, Trash2, ArrowUp, ArrowDown, Plus, Edit3, Save, X } from "lucide-react";
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, RadialBarChart, RadialBar } from "recharts";

const pretty=(n)=> typeof n==="number"? n.toLocaleString(): (n??"—");
const urlJoin=(base,u)=> u?.startsWith("http")?u: (base.replace(/\/$/,"") + (u?.startsWith("/")?u:"/"+u));
const getApiBase=()=> new URLSearchParams(location.search).get("api") || localStorage.getItem("KO_API_BASE") || "http://127.0.0.1:8088";
const getOwner=()=> new URLSearchParams(location.search).get("owner") || localStorage.getItem("KO_GH_OWNER") || "dh1293-hub";
const getRepo =()=> new URLSearchParams(location.search).get("repo")  || localStorage.getItem("KO_GH_REPO")  || "kobong-orchestrator";
const ago = (iso)=>{ try{ const s=new Date(iso).getTime(); const d=Date.now()-s; const m=Math.floor(d/60000); if(m<1) return "now"; if(m<60) return m+"m"; const h=Math.floor(m/60); if(h<24) return h+"h"; return Math.floor(h/24)+"d"}catch{return "—"} };
async function j(u,{timeout=9000,base,method='GET',body}={}){ const url=urlJoin(base||getApiBase(),u); const c=new AbortController(); const t=setTimeout(()=>c.abort(),timeout); try{ const r=await fetch(url,{method,headers:{'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:c.signal}); if(!r.ok) throw new Error("HTTP "+r.status); return await r.json() } finally{ clearTimeout(t) } }
async function probe(method,path,{base}={}){ const url=urlJoin(base||getApiBase(),path); const t0=performance.now(); try{ const r=await fetch(url,{method}); return {ok:r.ok,status:r.status,ms:Math.round(performance.now()-t0),url} }catch(e){ return {ok:false,status:0,ms:0,url} } }

function KCard({title,icon,children,footer,className=""}){ return (<div className={"rounded-2xl border bg-white dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 shadow-sm p-4 "+className}><div className="flex items-center justify-between mb-3"><div className="flex items-center gap-2 font-semibold">{icon}<span>{title}</span></div>{footer}</div>{children}</div>) }
function SmallBadge({children}){ return (<span className="text-[10px] px-2 py-1 rounded-full bg-neutral-100 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 text-neutral-600 dark:text-neutral-300">{children}</span>) }
function StatusDot({level}){ const m={ok:"bg-emerald-500 ring-emerald-300/40",warn:"bg-yellow-400 ring-yellow-300/40",err:"bg-red-500 ring-red-300/40"}[level||"ok"]; return (<span className={`h-3.5 w-3.5 rounded-full ${m} shadow-[0_0_0_3px_rgba(0,0,0,0.05)] ring-4 inline-block`}/>) }
function BarThin({value,max}){ const pct = max? Math.min(100,Math.round(value/max*100)) : 0; const col = pct>75?'bg-red-500':pct>50?'bg-yellow-400':'bg-emerald-500'; return (<div className="h-1.5 bg-neutral-200 dark:bg-neutral-800 rounded"><div className={`h-1.5 ${col} rounded`} style={{width:`${pct}%`}}/></div>) }

const defaultEndpoints=(owner,repo)=>[
  {id:"health",   method:"GET", path:"/api/mon/health", enabled:true},
  {id:"time",     method:"GET", path:"/api/mon/time", enabled:true},
  {id:"summary",  method:"GET", path:"/api/mon/github/summary?owner={owner}&repo={repo}", enabled:true},
  {id:"releases", method:"GET", path:"/api/mon/github/releases?owner={owner}&repo={repo}&per_page=5", enabled:true},
  {id:"branches", method:"GET", path:"/api/mon/github/branch_builds?owner={owner}&repo={repo}&branches=3", enabled:true},
  {id:"wf_list",  method:"GET", path:"/api/mon/github/workflows_list?owner={owner}&repo={repo}", enabled:true},
  {id:"wf_ov",    method:"GET", path:"/api/mon/github/workflows_overview?owner={owner}&repo={repo}&max=3&per_runs=5", enabled:true},
  {id:"sla",      method:"GET", path:"/api/mon/sla/summary", enabled:true},
  {id:"docs",     method:"GET", path:"/docs", enabled:true},
  {id:"root",     method:"GET", path:"/", enabled:true},
];

export default function App(){
  const [dark,setDark]=useState(true);

  // === Owner/Repo 편집 가능 + 영속화 ===
  const [owner,setOwner]=useState(getOwner());
  const [repo,setRepo]=useState(getRepo());
  useEffect(()=>{ localStorage.setItem("KO_GH_OWNER", owner) },[owner]);
  useEffect(()=>{ localStorage.setItem("KO_GH_REPO",  repo)  },[repo]);

  const [apiBase,setApiBase]=useState(getApiBase()); useEffect(()=>{ localStorage.setItem("KO_API_BASE",apiBase)},[apiBase]);
  const [busy,setBusy]=useState(false); const [mode,setMode]=useState("PREVIEW");
  const [editOpen,setEditOpen]=useState(false);
  const [editOwner,setEditOwner]=useState(owner);
  const [editRepo,setEditRepo]=useState(repo);

  const [summary,setSummary]=useState({stars:0,forks:0,open_issues:0,prs_open:0,release:null,branches:0,contributors:0,ci_pass_rate:0});
  const [releases,setReleases]=useState([]); const [baseTag,setBaseTag]=useState(""); const [headTag,setHeadTag]=useState(""); const [cmp,setCmp]=useState(null);
  // AUTOSET_TAGS_DEFAULT
  useEffect(()=>{ try{
    const tags=(releases||[]).map(r=>r.tag).filter(Boolean);
    if(!baseTag && !headTag && tags.length>=2){ setBaseTag(tags[1]); setHeadTag(tags[0]); }
  }catch{} }, [releases]);
  const [branches,setBranches]=useState([]); const [rate,setRate]=useState({limit:0,remaining:0});
  const [sla,setSla]=useState([]);
  // BOTTOM LOG PANEL + FULLSCREEN
  const [logFS,setLogFS]=useState(false);
  const [demoLog,setDemoLog]=useState([]);
  useEffect(()=>{ const t=setInterval(()=>{ setDemoLog(prev=>{ const line = "[" + new Date().toLocaleTimeString("ko-KR",{hour12:false}) + "] demo event #" + (prev.length+1); const nx=[...prev,line]; return nx.length>300? nx.slice(-300):nx }); }, 1500); return ()=>clearInterval(t) },[]);
  const [wfCat,setWfCat]=useState([]); const [wfOv,setWfOv]=useState([]);

  // workflows pins & 필터 (충돌 방지: wfFailOnly 사용)
  const [pins,setPins]=useState(()=>{ try{return JSON.parse(localStorage.getItem("KO_PIN_WF_IDS")||"[]")}catch{return []} });
  const togglePin=(id)=> setPins(p=>{ const s=new Set((p||[]).map(String)); const k=String(id); if(s.has(k)) s.delete(k); else s.add(k); const nx=[...s]; localStorage.setItem("KO_PIN_WF_IDS", JSON.stringify(nx)); return nx });
  const [wfFailOnly,setWfFailOnly]=useState(()=>localStorage.getItem("KO_WF_FAIL_ONLY")==="1");
  useEffect(()=>{ localStorage.setItem("KO_WF_FAIL_ONLY", wfFailOnly?'1':'0') },[wfFailOnly]);

  // Endpoint 커스터마이즈
  const [epCfg,setEpCfg]=useState(()=>{ try{ return JSON.parse(localStorage.getItem("KO_EPS_CFG")||"") } catch{ return null } });
  const epItems = useMemo(()=> (epCfg?.items?.length? epCfg.items : defaultEndpoints(owner,repo)), [epCfg, owner, repo]);
  const saveEpCfg=(items)=>{ const cfg={items}; setEpCfg(cfg); localStorage.setItem("KO_EPS_CFG", JSON.stringify(cfg)) };
  const resetEpCfg=()=>{ if (confirm("엔드포인트를 기본값으로 되돌릴까요?")) { localStorage.removeItem("KO_EPS_CFG"); setEpCfg(null) } };

  // 엔드포인트 프로브
  const [eps,setEps]=useState([]);
  async function refreshEndpoints(){
    const base = apiBase.replace(/\/$/,'');
    const list = epItems;
    const out=[]
    for (const it of list){
      if (!it.enabled) continue;
      const path = (it.path||"").replaceAll("{owner}",owner).replaceAll("{repo}",repo);
      const r = await probe(it.method||"GET", path,{base}).catch(()=>({ok:false,status:0,ms:0,url:base+path}));
      out.push({...it, pathResolved:path, ...r})
    }
    out.sort((a,b)=>{const ra=(a.ok?2:(a.status?1:0)); const rb=(b.ok?2:(b.status?1:0)); if(ra!==rb) return ra-rb; return (b.ms||0)-(a.ms||0)}); out.sort((a,b)=>{const ra=(a.ok?2:(a.status?1:0)); const rb=(b.ok?2:(b.status?1:0)); if(ra!==rb) return ra-rb; return (b.ms||0)-(a.ms||0)}); setEps(out);}

  // 시간
  const [kstNow,setKstNow]=useState(()=>new Date()); const [srv,setSrv]=useState(null);
  useEffect(()=>{ const t=setInterval(()=>setKstNow(new Date()),1000); return ()=>clearInterval(t) },[]);

  async function load(){
    setBusy(true);
    try{
      const sum = await j(`/api/mon/github/summary?owner=${owner}&repo=${repo}`,{base:apiBase}).catch(()=>null);
      const rel = await j(`/api/mon/github/releases?owner=${owner}&repo=${repo}&per_page=20`,{base:apiBase}).catch(()=>null);
      const bld = await j(`/api/mon/github/branch_builds?owner=${owner}&repo=${repo}&branches=8`,{base:apiBase}).catch(()=>null);
      const rlt = await j(`/api/mon/github/rate_limit`,{base:apiBase}).catch(()=>null);
      const sla = await j(`/api/mon/sla/summary`,{base:apiBase}).catch(()=>null);
      const cat = await j(`/api/mon/github/workflows_list?owner=${owner}&repo=${repo}`,{base:apiBase}).catch(()=>null);
      const ov  = await j(`/api/mon/github/workflows_overview?owner=${owner}&repo=${repo}&max=12&per_runs=15`,{base:apiBase}).catch(()=>null);
      const tm  = await j(`/api/mon/time`,{base:apiBase}).catch(()=>null);

      if (sum) setSummary(sum);
      if (rel) setReleases(rel.items||[]);
      if (bld) setBranches(bld.items||[]);
      if (rlt) setRate(rlt);
      if (sla) setSla(sla.items||[]);
      if (cat) setWfCat(cat.items||[]);
      if (ov)  setWfOv(ov.items||[]);
      if (tm)  setSrv(tm);

      setMode(sum? "LIVE":"PREVIEW");
    } finally { setBusy(false) }
  }
  useEffect(()=>{ load() },[apiBase,owner,repo]);
  useEffect(()=>{ refreshEndpoints() },[apiBase,owner,repo,epCfg]);

  // 파생
  const pass = Math.round(summary.ci_pass_rate||0);
  const kstStr = new Intl.DateTimeFormat('ko-KR',{ timeZone:'Asia/Seoul', hour:'2-digit', minute:'2-digit', second:'2-digit', year:'numeric', month:'2-digit', day:'2-digit'}).format(kstNow);
  const srvStr = srv?.server_iso ? new Date(srv.server_iso).toLocaleString('ko-KR',{ hour12:false }) : '—';
  const deltaMin = (srv?.server_epoch_ms ? Math.round((Date.now() - srv.server_epoch_ms)/60000) : 0);

  // WF 표시 (핀 우선, 실패만 필터)
  const pinSet = useMemo(()=> new Set((pins||[]).map(String)), [pins]);
  const wfShown = useMemo(()=>{
    const arr = wfOv||[];
    const pinned = arr.filter(w=> pinSet.has(String(w.id)));
    let rest = arr.filter(w=> !pinSet.has(String(w.id)));
    if (wfFailOnly) rest = rest.filter(w=> (w.last_conclusion && w.last_conclusion !== 'success'));
    return [...pinned, ...rest];
  },[wfOv, pinSet, wfFailOnly]);

  // 설정 패널 유틸(엔드포인트 커스텀)
  const [newMethod,setNewMethod]=useState("GET");
  const [newPath,setNewPath]=useState("/api/mon/health");
  const move=(idx,dir)=>{ const items=[...epItems]; const j=idx+dir; if(j<0||j>=items.length) return; const t=items[idx]; items[idx]=items[j]; items[j]=t; saveEpCfg(items) }
  const update=(idx,patch)=>{ const items=epItems.map((it,i)=> i===idx? {...it,...patch}:it); saveEpCfg(items) }
  const remove=(idx)=>{ const items=epItems.filter((_,i)=> i!==idx); saveEpCfg(items) }
  const add=()=>{ if(!newPath) return; const items=[...epItems,{id:String(Date.now()),method:newMethod||"GET",path:newPath,enabled:true}]; saveEpCfg(items); setNewPath("") }

  return (
    <div className={(dark?"dark ":"")+"min-h-screen "+(dark?"bg-neutral-900 text-neutral-100":"bg-white text-neutral-900")}>
      <style>{`.custom-scroll::-webkit-scrollbar{width:10px}.custom-scroll::-webkit-scrollbar-thumb{background:rgba(120,120,120,.35);border-radius:10px}.custom-scroll::-webkit-scrollbar-track{background:transparent}.logo-fixed{position:fixed;left:50%;transform:translateX(-50%);bottom:18px;opacity:.9}.logo-fixed img{height:36px;object-fit:contain;filter:drop-shadow(0 2px 6px rgba(0,0,0,.35))}`}</style>
      <div className="max-w-[1500px] mx-auto px-6 py-5">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Rocket className="text-emerald-400"/><h1 className="text-xl sm:text-2xl font-extrabold">kobong-github-monitoring · β</h1>
            <SmallBadge>{mode}</SmallBadge>
            <SmallBadge>{owner}/{repo}</SmallBadge>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-xs">API: <a className="underline hover:opacity-80" href={apiBase} target="_blank">{apiBase}</a></div>
            <div className="flex items-center gap-1 text-xs"><Clock size={14}/><span>KST</span><span className="font-semibold">{kstStr}</span></div>
            <div className="flex items-center gap-1 text-xs"><Server size={14}/><span>Server</span><span className="font-semibold">{srvStr}</span><SmallBadge>Δ {deltaMin}m</SmallBadge></div>
            <button onClick={()=>{ setEditOwner(owner); setEditRepo(repo); setEditOpen(true) }} className="inline-flex items-center gap-1 rounded-2xl border px-3 py-2 text-xs shadow-sm bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700"><Edit3 size={14}/>변경</button>
            <button onClick={load} disabled={busy} className="inline-flex items-center gap-2 rounded-2xl border px-3 py-2 text-sm shadow-sm bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700"><RefreshCw size={16}/>{busy?"로딩…":"새로고침"}</button>
            <button onClick={()=>{ document.documentElement.classList.toggle("dark"); setDark(d=>!d) }} className="inline-flex items-center gap-2 rounded-2xl border px-3 py-2 text-sm shadow-sm bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700"><Moon size={16}/></button>
          </div>
        </div>

        {/* Owner/Repo 편집 패널 (모달) */}
        {editOpen && (
          <div className="fixed inset-0 bg-black/30 flex items-center justify-center z-50">
            <div className="w-[420px] rounded-2xl border bg-white dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 shadow-xl p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="font-semibold flex items-center gap-2"><Edit3 size={16}/>GitHub 타겟 변경</div>
                <button onClick={()=>setEditOpen(false)}><X size={18}/></button>
              </div>
              <div className="space-y-3">
                <div>
                  <div className="text-xs text-neutral-500 mb-1">Owner</div>
                  <input value={editOwner} onChange={e=>setEditOwner(e.target.value)} className="w-full px-3 py-2 rounded border bg-white dark:bg-neutral-800 border-neutral-300 dark:border-neutral-700"/>
                </div>
                <div>
                  <div className="text-xs text-neutral-500 mb-1">Repo</div>
                  <input value={editRepo} onChange={e=>setEditRepo(e.target.value)} className="w-full px-3 py-2 rounded border bg-white dark:bg-neutral-800 border-neutral-300 dark:border-neutral-700"/>
                </div>
              </div>
              <div className="flex justify-end gap-2 mt-4">
                <button onClick={()=>setEditOpen(false)} className="px-3 py-1.5 rounded border border-neutral-300 dark:border-neutral-700 text-sm">취소</button>
                <button onClick={()=>{ setOwner(editOwner.trim()||owner); setRepo(editRepo.trim()||repo); setEditOpen(false) }} className="inline-flex items-center gap-1 px-3 py-1.5 rounded border border-neutral-300 dark:border-neutral-700 text-sm"><Save size={16}/>저장</button>
              </div>
              <div className="text-[11px] text-neutral-500 mt-2">URL 쿼리로도 지정 가능: <code>?owner=&repo=</code></div>
            </div>
          </div>
        )}

        {/* Top stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-4">
          <KCard title="GitHub 요약" icon={<GitBranch size={16}/>}>
            <div className="grid grid-cols-2 gap-4">
              <div><div className="text-xs text-neutral-500">Stars</div><div className="text-2xl font-bold">{pretty(summary.stars)}</div></div>
              <div><div className="text-xs text-neutral-500">Forks</div><div className="text-2xl font-bold">{pretty(summary.forks)}</div></div>
              <div><div className="text-xs text-neutral-500">Open PRs</div><div className="text-2xl font-bold">{pretty(summary.prs_open)}</div></div>
              <div><div className="text-xs text-neutral-500">Open Issues</div><div className="text-2xl font-bold">{pretty(summary.open_issues)}</div></div>
            </div>
          </KCard>
          <KCard title="CI / 품질" icon={<AlertCircle size={16}/>}>
            <div className="grid grid-cols-2 gap-4">
              <div><div className="text-xs text-neutral-500">CI Pass</div><div className={`text-2xl font-bold ${Math.round(summary.ci_pass_rate||0)<60?'text-red-500': Math.round(summary.ci_pass_rate||0)<85?'text-yellow-400':'text-emerald-500'}`}>{Math.round(summary.ci_pass_rate||0)}%</div></div>
              <div><div className="text-xs text-neutral-500">Rate Limit</div><div className="text-2xl font-bold">{rate.remaining}/{rate.limit}</div></div>
            </div>
          </KCard>
          <KCard title="Repo" icon={<GitCommit size={16}/>}>
            <div className="grid grid-cols-2 gap-4">
              <div><div className="text-xs text-neutral-500">Contrib.</div><div className="text-2xl font-bold">{pretty(summary.contributors)}</div></div>
              <div><div className="text-xs text-neutral-500">Branches</div><div className="text-2xl font-bold">{pretty(summary.branches)}</div></div>
            </div>
          </KCard>
          <KCard title="Latest Release" icon={<Star size={16}/>}>
            <div className="space-y-1"><div className="text-xs text-neutral-500">Tag</div><div className="text-xl font-semibold">{summary.release||'—'}</div></div>
          </KCard>
        </div>

        {/* Endpoint Settings */}
        <KCard title="엔드포인트 설정(커스터마이즈)" icon={<Link2 size={16}/>} className="mt-4" footer={
          <div className="flex items-center gap-2">
            <button onClick={resetEpCfg} className="text-xs px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700">기본값</button>
            <button onClick={refreshEndpoints} className="text-xs px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700">프로브</button>
          </div>
        }>
          <div className="max-h-64 overflow-y-auto custom-scroll">
            <table className="w-full text-sm">
              <thead className="text-neutral-500"><tr><th>On</th><th>Method</th><th className="text-left">Path(템플릿: {'{owner}'}, {'{repo}'})</th><th>순서</th><th>삭제</th></tr></thead>
              <tbody>
                {epItems.map((e,i)=>(
                  <tr key={e.id||i} className="border-t border-neutral-200 dark:border-neutral-800">
                    <td className="py-1 text-center"><input type="checkbox" checked={!!e.enabled} onChange={ev=>{ const items=epItems.map((it,ix)=>ix===i?{...it,enabled:ev.target.checked}:it); localStorage.setItem("KO_EPS_CFG", JSON.stringify({items})); setEpCfg({items}) }}/></td>
                    <td className="py-1 text-center">
                      <select value={e.method||"GET"} onChange={ev=>{ const items=epItems.map((it,ix)=>ix===i?{...it,method:ev.target.value}:it); localStorage.setItem("KO_EPS_CFG", JSON.stringify({items})); setEpCfg({items}) }} className="px-1 py-0.5 rounded border bg-white dark:bg-neutral-800 border-neutral-300 dark:border-neutral-700 text-xs">
                        <option>GET</option><option>POST</option><option>PUT</option><option>DELETE</option>
                      </select>
                    </td>
                    <td className="py-1 pr-2">
                      <input value={e.path||""} onChange={ev=>{ const items=epItems.map((it,ix)=>ix===i?{...it,path:ev.target.value}:it); localStorage.setItem("KO_EPS_CFG", JSON.stringify({items})); setEpCfg({items}) }} className="w-full px-2 py-1 rounded border bg-white dark:bg-neutral-800 border-neutral-300 dark:border-neutral-700 text-xs"/>
                      <div className="text-[10px] text-neutral-500 mt-0.5">→ {(e.path||"").replaceAll("{owner}",owner).replaceAll("{repo}",repo)}</div>
                    </td>
                    <td className="py-1 text-center">
                      <button onClick={()=>{ const items=[...epItems]; if(i>0){ const t=items[i-1]; items[i-1]=items[i]; items[i]=t; localStorage.setItem("KO_EPS_CFG", JSON.stringify({items})); setEpCfg({items}) }}} className="px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700 mr-1"><ArrowUp size={14}/></button>
                      <button onClick={()=>{ const items=[...epItems]; if(i<items.length-1){ const t=items[i+1]; items[i+1]=items[i]; items[i]=t; localStorage.setItem("KO_EPS_CFG", JSON.stringify({items})); setEpCfg({items}) }}} className="px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700"><ArrowDown size={14}/></button>
                    </td>
                    <td className="py-1 text-center"><button onClick={()=>{ const items=epItems.filter((_,ix)=>ix!==i); localStorage.setItem("KO_EPS_CFG", JSON.stringify({items})); setEpCfg({items}) }} className="px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700"><Trash2 size={14}/></button></td>
                  </tr>
                ))}
                <tr className="border-t border-neutral-200 dark:border-neutral-800">
                  <td className="py-1 text-center">+</td>
                  <td className="py-1 text-center">
                    <select value={newMethod} onChange={e=>setNewMethod(e.target.value)} className="px-1 py-0.5 rounded border bg-white dark:bg-neutral-800 border-neutral-300 dark:border-neutral-700 text-xs">
                      <option>GET</option><option>POST</option><option>PUT</option><option>DELETE</option>
                    </select>
                  </td>
                  <td className="py-1 pr-2"><input value={newPath} onChange={e=>setNewPath(e.target.value)} placeholder="/api/mon/..." className="w-full px-2 py-1 rounded border bg-white dark:bg-neutral-800 border-neutral-300 dark:border-neutral-700 text-xs"/></td>
                  <td className="py-1 text-center" colSpan={2}><button onClick={()=>{ if(!newPath) return; const items=[...epItems,{id:String(Date.now()),method:newMethod||"GET",path:newPath,enabled:true}]; localStorage.setItem("KO_EPS_CFG", JSON.stringify({items})); setEpCfg({items}); setNewPath("") }} className="inline-flex items-center gap-1 px-3 py-1 rounded border border-neutral-300 dark:border-neutral-700 text-xs"><Plus size={14}/>추가</button></td>
                </tr>
              </tbody>
            </table>
          </div>
        </KCard>

        {/* Endpoint info */}
        <KCard title="엔드포인트 정보" icon={<Link2 size={16}/>} className="mt-4" footer={<button onClick={refreshEndpoints} className="text-xs px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700">새로고침</button>}>
          <div className="max-h-60 overflow-y-auto custom-scroll">
            <table className="w-full text-sm">
              <thead className="text-neutral-500"><tr><th className="text-left">Method</th><th className="text-left">Path</th><th>Status</th><th>RT</th></tr></thead>
              <tbody>
                {(eps||[]).map((e,i)=>(
                  <tr key={i} className="border-t border-neutral-200 dark:border-neutral-800">
                    <td className="py-1 pr-2">{e.method}</td>
                    <td className="py-1 pr-2 truncate max-w-[540px]"><a className="underline hover:opacity-80" href={e.url} target="_blank">{e.pathResolved||e.path}</a></td>
                    <td className="py-1 text-center">{ e.ok ? <StatusDot level="ok"/> : (e.status? <StatusDot level="warn"/> : <StatusDot level="err"/>) } <span className="text-xs">{e.status||'—'}</span></td>
                    <td className="py-1 text-center text-xs">{e.ms? e.ms+' ms':'—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </KCard>

        {/* Release Diff */}
        <KCard title="릴리즈 노트 Diff" icon={<Tag size={16}/>} className="mt-4" footer={<SmallBadge>{releases.length} tags</SmallBadge>}>
          <div className="flex flex-wrap items-center gap-2 mb-3">
            <select value={baseTag} onChange={e=>setBaseTag(e.target.value)} className="px-2 py-1 rounded border bg-white dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-sm">
              <option value="">Base(tag)</option>
              {(releases||[]).map(r=>(<option key={r.tag} value={r.tag}>{r.tag}</option>))}
            </select>
            <span className="text-neutral-500 text-sm">…</span>
            <select value={headTag} onChange={e=>setHeadTag(e.target.value)} className="px-2 py-1 rounded border bg-white dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700 text-sm">
              <option value="">Head(tag)</option>
              {(releases||[]).map(r=>(<option key={r.tag} value={r.tag}>{r.tag}</option>))}
            </select>
            <button onClick={async()=>{ setCmp(null); const r = await j(`/api/mon/github/compare?owner=${owner}&repo=${repo}&base=${encodeURIComponent(baseTag)}&head=${encodeURIComponent(headTag)}`,{base:apiBase}).catch(()=>null); setCmp(r) }} disabled={!baseTag||!headTag} className="inline-flex items-center gap-2 rounded-2xl border px-3 py-1.5 text-sm bg-white dark:bg-neutral-800 border-neutral-200 dark:border-neutral-700"><GitMerge size={16}/>비교</button>
            {cmp && <SmallBadge>commits {cmp.total_commits} • files {cmp.files?.length||0}</SmallBadge>}
          </div>
          {cmp && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <div>
                <div className="text-xs text-neutral-500 mb-1">변경 파일 Top 10</div>
                <div className="max-h-72 overflow-y-auto custom-scroll">
                  <table className="w-full text-sm">
                    <thead className="text-neutral-500"><tr><th className="text-left">File</th><th>Δ</th><th>Add</th><th>Del</th></tr></thead>
                    <tbody>{[...cmp.files].sort((a,b)=>(b.changes||0)-(a.changes||0)).slice(0,10).map((f,i)=>(
                      <tr key={i} className="border-t border-neutral-200 dark:border-neutral-800">
                        <td className="py-1 pr-2 truncate max-w-[340px]">{f.filename}</td>
                        <td className="py-1 text-center">{f.changes}</td>
                        <td className="py-1 text-center text-emerald-500">+{f.additions}</td>
                        <td className="py-1 text-center text-red-500">-{f.deletions}</td>
                      </tr>
                    ))}</tbody>
                  </table>
                </div>
              </div>
              <div>
                <div className="text-xs text-neutral-500 mb-1">커밋 메시지</div>
                <div className="max-h-72 overflow-y-auto custom-scroll">
                  <ul className="space-y-2">{(cmp.commits||[]).map((c,i)=>(
                    <li key={i} className="border-b border-neutral-200 dark:border-neutral-800 pb-2">
                      <div className="font-medium truncate">{c.message}</div>
                      <div className="text-xs text-neutral-500">{c.author} • {c.sha} • {ago(c.date)}</div>
                    </li>
                  ))}</ul>
                </div>
              </div>
            </div>
          )}
        </KCard>

        {/* Branch Build Status */}
        <KCard title="브랜치별 빌드 현황" icon={<BarChart3 size={16}/>} className="mt-4" footer={<SmallBadge>{branches.length} branches</SmallBadge>}>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-2">
            {(branches||[]).map((b,i)=>(
              <div key={i} className="rounded-xl border border-neutral-200 dark:border-neutral-800 p-3 flex items-center justify-between bg-white/70 dark:bg-neutral-900/70">
                <div className="min-w-0">
                  <div className="font-semibold truncate max-w-[220px]">{b.branch}</div>
                  <div className="text-xs text-neutral-500">{ago(b.updated_at)}</div>
                </div>
                <a href={b.html_url||'#'} target="_blank" className="flex items-center gap-2">
                  <StatusDot level={b.conclusion==='success'?'ok':(b.conclusion? (b.conclusion==='cancelled'?'warn':'err') : 'warn')}/>
                  <span className="text-xs">{b.conclusion||b.status||'—'}</span>
                </a>
              </div>
            ))}
          </div>
        </KCard>

        {/* Workflows 카탈로그 */}
        <KCard title=".github/workflows/*" icon={<ListTree size={16}/>} className="mt-4" footer={<SmallBadge>{wfCat.length} items</SmallBadge>}>
          <div className="max-h-60 overflow-y-auto custom-scroll">
            <table className="w-full text-sm">
              <thead className="text-neutral-500"><tr><th className="text-left">Name</th><th>State</th><th className="text-left">Path</th><th>Upd</th></tr></thead>
              <tbody>{(wfCat||[]).map((w,i)=>(
                <tr key={i} className="border-t border-neutral-200 dark:border-neutral-800">
                  <td className="py-2 pr-2">{w.name}</td>
                  <td className="py-2 text-center">{w.state}</td>
                  <td className="py-2 pr-2 truncate max-w-[280px]">{w.path}</td>
                  <td className="py-2 text-center">{ago(w.updated_at)}</td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        </KCard>

        {/* Workflow Runs */}
        <KCard title="Workflow Runs (최근)" icon={<GitPullRequest size={16}/>} footer={
          <div className="flex items-center gap-3">
            <label className="text-xs flex items-center gap-1"><input type="checkbox" checked={wfFailOnly} onChange={e=>setWfFailOnly(e.target.checked)}/>실패만</label>
            <SmallBadge>핀 {pins.length}</SmallBadge>
          </div>
        }>
          <div className="max-h-72 overflow-y-auto custom-scroll">
            <table className="w-full text-sm">
              <thead className="text-neutral-500"><tr><th className="text-left">★</th><th className="text-left">Workflow</th><th>Success</th><th>Last</th><th>When</th></tr></thead>
              <tbody>{(wfShown||[]).map((w,i)=>(
                <tr key={i} className="border-t border-neutral-200 dark:border-neutral-800">
                  <td className="py-2 pr-2"><button onClick={()=>togglePin(w.id)} title="고정/해제"><Star size={14} className={pinSet.has(String(w.id))?'text-yellow-400':''}/></button></td>
                  <td className="py-2 pr-2 truncate max-w-[240px]"><a className="underline hover:opacity-80" href={w.html_url||'#'} target="_blank">{w.name}</a></td>
                  <td className="py-2 text-center">{w.success_rate}%</td>
                  <td className="py-2 text-center">
                    {w.last_conclusion==='success' ? <CheckCircle2 className="inline text-emerald-500" size={16}/> :
                     w.last_conclusion ? <XCircle className="inline text-red-500" size={16}/> :
                     <AlertCircle className="inline text-yellow-400" size={16}/>}
                  </td>
                  <td className="py-2 text-center">{ago(w.updated_at)}</td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        </KCard>

        {/* SLA */}
        <KCard title="팀별 SLA (p95 vs Target)" className="mt-4" icon={<BarChart3 size={16}/>} footer={<SmallBadge>{sla.length} teams / 24h</SmallBadge>}>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
            {(sla||[]).map((t,i)=>(
              <div key={i} className="rounded-xl border border-neutral-200 dark:border-neutral-800 p-3 bg-white/70 dark:bg-neutral-900/70">
                <div className="flex items-center justify-between">
                  <div className="font-semibold">{t.name}</div>
                  <StatusDot level={t.status}/>
                </div>
                <div className="text-xs text-neutral-500 mt-1">p50 {t.p50_ms}ms • p95 {t.p95_ms}ms • target {t.target_ms}ms</div>
                <div className="mt-2"><BarThin value={t.p95_ms} max={Math.max(t.target_ms, 1)}/></div>
                <div className="text-xs text-neutral-500 mt-1">err {t.error_rate}% • n={t.count}</div>
              </div>
            ))}
          </div>
        </KCard>

        <KCard title="하단 로그 (스크롤/전체 화면)" icon={<ListTree size={16}/>} className="mt-4" footer={<button onClick={()=>setLogFS(true)} className="text-xs px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700">전체 화면</button>}>
  <div className="max-h-72 overflow-y-auto custom-scroll font-mono text-xs leading-5 whitespace-pre-wrap">
    {(demoLog||[]).slice(-150).map((l,i)=>(<div key={i}>{l}</div>))}
  </div>
</KCard>

{logFS && (
  <div className="fixed inset-0 z-[100] bg-black/60 backdrop-blur-sm flex flex-col">
    <div className="flex items-center justify-between p-3 bg-white dark:bg-neutral-900 border-b border-neutral-200 dark:border-neutral-800">
      <div className="font-semibold">전체 화면 로그 뷰어</div>
      <button onClick={()=>setLogFS(false)} className="px-3 py-1.5 rounded border border-neutral-300 dark:border-neutral-700 text-sm">닫기</button>
    </div>
    <div className="flex-1 overflow-y-auto custom-scroll p-4 bg-white dark:bg-neutral-900">
      <div className="max-w-[1600px] mx-auto font-mono text-sm whitespace-pre-wrap">
        {(demoLog||[]).map((l,i)=>(<div key={i}>{l}</div>))}
      </div>
    </div>
  </div>
)}
<div className="text-xs text-neutral-500 dark:text-neutral-400 mt-6">API: {apiBase}</div>
      </div>

      <div className="logo-fixed"><img src={`/sts_logo/sts_이름_이미지.PNG?v=${Date.now()}`} alt="Company Logo" onError={(e)=>{e.currentTarget.style.display='none'}}/></div>
    </div>
  )
}