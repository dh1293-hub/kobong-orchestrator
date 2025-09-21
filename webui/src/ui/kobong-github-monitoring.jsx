import React, { useEffect, useMemo, useRef, useState } from "react";
import { Rocket, RefreshCw, Moon, Sun, GitBranch, GitPullRequest, GitCommit, GitMerge, MessageSquare, AlertCircle, Star, Settings, Download, Camera } from "lucide-react";
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, RadialBarChart, RadialBar } from "recharts";

const pretty=(n)=> typeof n==="number"? n.toLocaleString(): (n??"—");
const urlJoin=(base,u)=> u.startsWith("http")?u: (base.replace(/\/$/,"") + (u.startsWith("/")?u:"/"+u));
const getApiBase=()=> new URLSearchParams(location.search).get("api") || localStorage.getItem("KO_API_BASE") || "http://127.0.0.1:8088";
const ago = (iso)=>{ try{ const s=new Date(iso).getTime(); const d=Date.now()-s; const m=Math.floor(d/60000); if(m<1) return "now"; if(m<60) return m+"m"; const h=Math.floor(m/60); if(h<24) return h+"h"; return Math.floor(h/24)+"d"}catch{return "—"} };
async function j(u,{timeout=8000,base,method='GET',body}={}){ const url=urlJoin(base||getApiBase(),u); const c=new AbortController(); const t=setTimeout(()=>c.abort(),timeout); try{ const r=await fetch(url,{method,headers:{'content-type':'application/json'},body:body?JSON.stringify(body):undefined,signal:c.signal}); if(!r.ok) throw new Error("HTTP "+r.status); return await r.json() } finally{ clearTimeout(t) } }
function mockGH(){ const now=Date.now(); const days=[...Array(14)].map((_,i)=>{ const d=new Date(now-(13-i)*86400000); const dd=`${d.getMonth()+1}/${d.getDate()}`; return { day:dd, prs_open:~~(Math.random()*8), prs_merged:~~(Math.random()*8), issues_opened:~~(Math.random()*6), issues_closed:~~(Math.random()*6) } }); return { summary:{ stars:120+~~(Math.random()*15), forks:10+~~(Math.random()*6), open_issues:6+~~(Math.random()*6), open_prs:4+~~(Math.random()*5), release:"v0.1."+~~(Math.random()*20), branches:8, contributors:7, ci_pass_rate:75+~~(Math.random()*20) }, days, prs:[], commits:[], wfs:[], issues:[], rate:{limit:0,remaining:0} }; }
function mockChat(){ const now=Date.now(); const mins=[...Array(30)].map((_,i)=>{ const d=new Date(now-(29-i)*60000); return { t:d.toTimeString().slice(0,5), in:~~(Math.random()*5), out:~~(Math.random()*5) } }); const recent=[...Array(10)].map((_,i)=>({ id:"m"+i, role:i%2?"assistant":"user", text:i%2?"결과 요약…":"상태 점검해줘", ts:new Date(now-i*45000).toLocaleTimeString(), ok:i%5?true:false })); return { mins, recent, p50:240, p95:520, err_rate: ~~(Math.random()*6) } }

function KCard({title,icon,children,footer,className=""}){ return (<div className={"rounded-2xl border bg-white dark:bg-neutral-900 border-neutral-200 dark:border-neutral-800 shadow-sm p-4 "+className}><div className="flex items-center justify-between mb-3"><div className="flex items-center gap-2 font-semibold">{icon}<span>{title}</span></div>{footer}</div>{children}</div>) }
function SmallBadge({children}){ return (<span className="text-[10px] px-2 py-1 rounded-full bg-neutral-100 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700 text-neutral-600 dark:text-neutral-300">{children}</span>) }
function StatusDot({level}){ const m={ok:"bg-emerald-500 ring-emerald-300/40",warn:"bg-yellow-400 ring-yellow-300/40",err:"bg-red-500 ring-red-300/40"}[level||"ok"]; return (<span className={`h-3.5 w-3.5 rounded-full ${m} shadow-[0_0_0_3px_rgba(0,0,0,0.05)] ring-4 inline-block`}/>) }
function Scroll({children,max="max-h-80"}){ return (<div className={`${max} overflow-y-auto pr-1 custom-scroll`}>{children}</div>) }
function Bar({value,max}){ const pct = max? Math.min(100,Math.round(value/max*100)) : 0; const col = pct>75?'bg-red-500':pct>50?'bg-yellow-400':'bg-emerald-500'; return (<div className="h-1.5 bg-neutral-200 dark:bg-neutral-800 rounded"><div className={`h-1.5 ${col} rounded`} style={{width:`${pct}%`}}/></div>) }
const csv = (rows)=>URL.createObjectURL(new Blob([rows.map(r=>r.map(x=>`"${String(x??'').replace(/"/g,'""')}"`).join(',')).join('\r\n')],{type:'text/csv;charset=utf-8;'}));

export default function App(){
  const [dark,setDark]=useState(true);
  const [owner,setOwner]=useState("'+$Owner+'"); const [repo,setRepo]=useState("'+$Repo+'");
  const [apiBase,setApiBase]=useState(getApiBase()); useEffect(()=>{ localStorage.setItem("KO_API_BASE",apiBase)},[apiBase]);
  const [gh,setGh]=useState(()=>mockGH()); const [chat,setChat]=useState(()=>mockChat());
  const [health,setHealth]=useState(null); const [mode,setMode]=useState("PREVIEW"); const [busy,setBusy]=useState(false);
  const [rate,setRate]=useState({limit:0,remaining:0});
  const [auto,setAuto]=useState(()=>localStorage.getItem("KO_AUTO")==='1'); const [intv,setIntv]=useState(()=>parseInt(localStorage.getItem("KO_AUTO_MS")||"15000"));
  const [tok,setTok]=useState(()=>localStorage.getItem("KO_GH_TOKEN")||""); const [settings,setSettings]=useState(false);

  useEffect(()=>{ localStorage.setItem("KO_AUTO", auto?'1':'0') },[auto]);
  useEffect(()=>{ localStorage.setItem("KO_AUTO_MS", String(intv)) },[intv]);
  useEffect(()=>{ document.title='KoBong · GitHub Monitor' },[]);

  async function load(){
    setBusy(true);
    try{
      const h  = await j("/api/mon/health",{base:apiBase}).catch(()=>null); setHealth(h);
      const sum= await j(`/api/mon/github/summary?owner=${owner}&repo=${repo}`,{base:apiBase}).catch(()=>null);
      const prs= await j(`/api/mon/github/prs?owner=${owner}&repo=${repo}&state=open&per_page=12`,{base:apiBase}).catch(()=>null);
      const cms= await j(`/api/mon/github/commits?owner=${owner}&repo=${repo}&per_page=12`,{base:apiBase}).catch(()=>null);
      const iss= await j(`/api/mon/github/issues?owner=${owner}&repo=${repo}&state=open&per_page=12`,{base:apiBase}).catch(()=>null);
      const wfs= await j(`/api/mon/github/workflows?owner=${owner}&repo=${repo}&per_page=10`,{base:apiBase}).catch(()=>null);
      const rlt= await j(`/api/mon/github/rate_limit`,{base:apiBase}).catch(()=>null);
      const csum = await j("/api/mon/chat/summary",{base:apiBase}).catch(()=>null);
      const crec = await j("/api/mon/chat/recent?limit=20",{base:apiBase}).catch(()=>null);

      if (rlt) setRate(rlt);
      setGh(x=>{
        const nx={...x};
        if(sum){ nx.summary={ ...nx.summary,
          stars:sum.stars??nx.summary.stars, forks:sum.forks??nx.summary.forks,
          open_issues:sum.open_issues??nx.summary.open_issues, open_prs:sum.prs_open??nx.summary.open_prs,
          release:sum.release??nx.summary.release, branches:sum.branches??nx.summary.branches, contributors:sum.contributors??nx.summary.contributors, ci_pass_rate:sum.ci_pass_rate??nx.summary.ci_pass_rate } }
        nx.prs = prs?.items||[]; nx.commits = cms?.items||[]; nx.wfs = wfs?.items||[]; nx.issues = iss?.items||[];
        return nx;
      });
      setChat(x=>{ const nx={...x}; if(csum){ nx.p50=csum.p50??nx.p50; nx.p95=csum.p95??nx.p95; nx.err_rate = csum.err_rate??nx.err_rate; } nx.recent=crec?.items||nx.recent; return nx; });
      setMode((h||sum) ? "LIVE" : "PREVIEW");
    } finally { setBusy(false) }
  }
  useEffect(()=>{ load() },[apiBase,owner,repo]);
  useEffect(()=>{ if(!auto) return; const id=setInterval(load, Math.max(5000, intv||15000)); return ()=>clearInterval(id) },[auto,intv,apiBase,owner,repo]);

  const theme = dark ? "dark bg-neutral-900 text-neutral-100" : "bg-white text-neutral-900";
  const pass = Math.round(gh.summary.ci_pass_rate||0); const err = Math.round(chat.err_rate||0);
  const apiLevel = health?.ok ? "ok" : "err";
  const ghLevel  = (rate.remaining>0) ? "ok" : "warn";

  const dl = (name, rows) => { const a=document.createElement('a'); a.href=csv(rows); a.download=name; a.click(); };

  async function saveToken(){
    if (!tok) return;
    try{
      await j("/api/mon/github/token",{base:apiBase,method:"POST",body:{token:tok}});
      localStorage.setItem("KO_GH_TOKEN", tok);
      alert("GitHub 토큰 적용 완료 (서버 재시작 없이 반영됨).");
      load();
    }catch(e){ alert("토큰 저장 실패: "+e.message) }
  }

  return (
    <div className={theme+" min-h-screen"}>
      <style>{`.custom-scroll::-webkit-scrollbar{width:10px}.custom-scroll::-webkit-scrollbar-thumb{background:rgba(120,120,120,.35);border-radius:10px}.custom-scroll::-webkit-scrollbar-track{background:transparent}.logo-fixed{position:fixed;left:50%;transform:translateX(-50%);bottom:18px;opacity:.9}.logo-fixed img{height:36px;object-fit:contain;filter:drop-shadow(0 2px 6px rgba(0,0,0,.35))}`}</style>

      <div className="max-w-[1450px] mx-auto px-6 py-5">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Rocket className="text-emerald-400"/><h1 className="text-xl sm:text-2xl font-extrabold">kobong-github-monitoring</h1>
            <SmallBadge>{mode}</SmallBadge>
            <div className="flex items-center gap-2 ml-4">
              <StatusDot level={apiLevel}/><span className="text-xs text-neutral-500">API</span>
              <StatusDot level={ghLevel}/><span className="text-xs text-neutral-500">GitHub</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input className="px-2 py-1 rounded border bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700 text-xs w-36" value={owner} onChange={e=>setOwner(e.target.value)} placeholder="owner"/>
            <input className="px-2 py-1 rounded border bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700 text-xs w-56" value={repo} onChange={e=>setRepo(e.target.value)} placeholder="repo"/>
            <button onClick={()=>setSettings(s=>!s)} className="inline-flex items-center gap-2 rounded-2xl border px-3 py-2 text-sm shadow-sm bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700"><Settings size={16}/>설정</button>
            <button onClick={load} disabled={busy} className="inline-flex items-center gap-2 rounded-2xl border px-3 py-2 text-sm shadow-sm bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700"><RefreshCw size={16}/>{busy?"로딩…":"새로고침"}</button>
            <button onClick={()=>document.documentElement.classList.toggle("dark")} className="inline-flex items-center gap-2 rounded-2xl border px-3 py-2 text-sm shadow-sm bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700"><Moon size={16}/></button>
          </div>
        </div>

        {/* Settings panel */}
        {settings && (
          <div className="mt-3 p-3 rounded-2xl border bg-white/70 dark:bg-neutral-900/70 backdrop-blur border-neutral-200 dark:border-neutral-800">
            <div className="flex flex-wrap items-center gap-3">
              <div className="flex items-center gap-2"><input type="checkbox" checked={auto} onChange={e=>setAuto(e.target.checked)}/><span className="text-sm">Auto-Refresh</span></div>
              <div className="flex items-center gap-2"><span className="text-sm">Interval</span><input className="px-2 py-1 rounded border w-24 bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700 text-xs" type="number" min={5000} step={1000} value={intv} onChange={e=>setIntv(parseInt(e.target.value||"15000"))}/><span className="text-xs text-neutral-500">ms</span></div>
              <div className="flex items-center gap-2"><span className="text-sm">GitHub Token</span><input className="px-2 py-1 rounded border w-[360px] bg-white/80 dark:bg-neutral-800/80 border-neutral-200 dark:border-neutral-700 text-xs" value={tok} onChange={e=>setTok(e.target.value)} placeholder="ghp_…"/></div>
              <button onClick={saveToken} className="inline-flex items-center gap-2 rounded-2xl border px-3 py-2 text-sm shadow-sm bg-emerald-600 text-white border-emerald-700"><Settings size={16}/>저장</button>
            </div>
          </div>
        )}

        {/* Top stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-4">
          <KCard title="GitHub 요약" icon={<GitBranch size={16}/>}>
            <div className="grid grid-cols-2 gap-4">
              <div><div className="text-xs text-neutral-500">Stars</div><div className="text-2xl font-bold">{pretty(gh.summary.stars)}</div></div>
              <div><div className="text-xs text-neutral-500">Forks</div><div className="text-2xl font-bold">{pretty(gh.summary.forks)}</div></div>
              <div><div className="text-xs text-neutral-500">Open PRs</div><div className="text-2xl font-bold">{pretty(gh.summary.open_prs)}</div></div>
              <div><div className="text-xs text-neutral-500">Open Issues</div><div className="text-2xl font-bold">{pretty(gh.summary.open_issues)}</div></div>
            </div>
          </KCard>
          <KCard title="CI / 품질" icon={<AlertCircle size={16}/>}>
            <div className="grid grid-cols-2 gap-4">
              <div><div className="text-xs text-neutral-500">CI Pass</div><div className={`text-2xl font-bold ${pass<70?'text-red-500':pass<90?'text-yellow-400':'text-emerald-500'}`}>{pass}%</div></div>
              <div><div className="text-xs text-neutral-500">Error Rate</div><div className={`text-2xl font-bold ${err>10?'text-red-500':err>=5?'text-yellow-400':'text-emerald-500'}`}>{err}%</div></div>
            </div>
          </KCard>
          <KCard title="Rate Limit" icon={<Star size={16}/>}>
            <div className="space-y-2">
              <div className="text-xs text-neutral-500">Remaining / Limit</div>
              <div className="text-xl font-semibold">{rate.remaining} / {rate.limit}</div>
              <Bar value={(rate.limit||0)-(rate.remaining||0)} max={rate.limit||1}/>
            </div>
          </KCard>
          <KCard title="Repo" icon={<GitCommit size={16}/>}>
            <div className="grid grid-cols-2 gap-4">
              <div><div className="text-xs text-neutral-500">Contrib.</div><div className="text-2xl font-bold">{pretty(gh.summary.contributors)}</div></div>
              <div><div className="text-xs text-neutral-500">Branches</div><div className="text-2xl font-bold">{pretty(gh.summary.branches)}</div></div>
            </div>
          </KCard>
        </div>

        {/* Charts row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mt-4">
          <KCard title="PR / Issue 추이(14일)" icon={<GitPullRequest size={16}/>}>
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={gh.days}><defs><linearGradient id="g1" x1="0" x2="0" y1="0" y2="1"><stop offset="5%" stopOpacity={.4}/><stop offset="95%" stopOpacity={0}/></linearGradient></defs>
                <CartesianGrid strokeDasharray="3 3"/><XAxis dataKey="day"/><YAxis allowDecimals={false}/><Tooltip/>
                <Area dataKey="prs_open" fillOpacity={1} fill="url(#g1)" stroke="currentColor"/>
                <Area dataKey="issues_opened" fillOpacity={0.6} fill="url(#g1)" stroke="currentColor"/>
              </AreaChart>
            </ResponsiveContainer>
          </KCard>
          <KCard title="요청 처리량(최근 30분)" icon={<Rocket size={16}/>}>
            <ResponsiveContainer width="100%" height={260}>
              <LineChart data={(window.__KO_MINUTES__||[])}><CartesianGrid strokeDasharray="3 3"/><XAxis dataKey="t"/><YAxis/><Tooltip/><Line type="monotone" dataKey="in"/><Line type="monotone" dataKey="out"/></LineChart>
            </ResponsiveContainer>
          </KCard>
        </div>

        {/* Detail lists */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-4 mt-4">
          <KCard title="Open PRs" icon={<GitPullRequest size={16}/>} footer={<div className="flex items-center gap-2"><SmallBadge>{gh.prs.length} items</SmallBadge><button onClick={()=>dl(`prs_${owner}_${repo}.csv`, [['number','title','user','updated_at','draft','url'], ...gh.prs.map(p=>[p.number,p.title,p.user,p.updated_at,p.draft,p.html_url])])} className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700"><Download size={14}/>CSV</button></div>}>
            <Scroll max="max-h-72">
              <table className="w-full text-sm">
                <thead className="text-neutral-500"><tr><th className="text-left">#</th><th className="text-left">Title</th><th>By</th><th>Upd</th><th>Draft</th></tr></thead>
                <tbody>{(gh.prs||[]).map(p=>(<tr key={p.number} className="border-t border-neutral-200 dark:border-neutral-800"><td className="py-2 pr-2">{p.number}</td><td className="py-2 pr-2 truncate max-w-[280px]"><a href={p.html_url} target="_blank" className="underline hover:opacity-80">{p.title}</a></td><td className="py-2 text-center">{p.user}</td><td className="py-2 text-center">{ago(p.updated_at)}</td><td className="py-2 text-center">{p.draft? 'Y':'N'}</td></tr>))}</tbody>
              </table>
            </Scroll>
          </KCard>

          <KCard title="Recent Commits" icon={<GitCommit size={16}/>} footer={<div className="flex items-center gap-2"><SmallBadge>{(gh.commits||[]).length} items</SmallBadge><button onClick={()=>dl(`commits_${owner}_${repo}.csv`, [['sha','message','author','date'], ...gh.commits.map(c=>[c.sha,c.message,c.author,c.date])])} className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700"><Download size={14}/>CSV</button></div>}>
            <Scroll max="max-h-72">
              <ul className="space-y-2">{(gh.commits||[]).map((c,i)=>(
                <li key={i} className="flex items-center justify-between border-b border-neutral-200 dark:border-neutral-800 pb-2">
                  <div className="min-w-0"><div className="font-medium truncate max-w-[280px]">{c.message}</div><div className="text-xs text-neutral-500">{c.author} • {c.sha} • {ago(c.date)}</div></div>
                </li>
              ))}</ul>
            </Scroll>
          </KCard>

          <KCard title="Open Issues" icon={<AlertCircle size={16}/>} footer={<div className="flex items-center gap-2"><SmallBadge>{(gh.issues||[]).length} items</SmallBadge><button onClick={()=>dl(`issues_${owner}_${repo}.csv`, [['number','title','user','updated_at','url'], ...gh.issues.map(i=>[i.number,i.title,i.user,i.updated_at,i.html_url])])} className="inline-flex items-center gap-1 text-xs px-2 py-1 rounded border border-neutral-300 dark:border-neutral-700"><Download size={14}/>CSV</button></div>}>
            <Scroll max="max-h-72">
              <table className="w-full text-sm">
                <thead className="text-neutral-500"><tr><th className="text-left">#</th><th className="text-left">Title</th><th>By</th><th>Upd</th></tr></thead>
                <tbody>{(gh.issues||[]).map((i)=>(
                  <tr key={i.number} className="border-t border-neutral-200 dark:border-neutral-800">
                    <td className="py-2 pr-2">{i.number}</td>
                    <td className="py-2 pr-2 truncate max-w-[280px]"><a className="underline hover:opacity-80" target="_blank" href={i.html_url}>{i.title}</a></td>
                    <td className="py-2 text-center">{i.user}</td>
                    <td className="py-2 text-center">{ago(i.updated_at)}</td>
                  </tr>
                ))}</tbody>
              </table>
            </Scroll>
          </KCard>
        </div>

        {/* Chat section */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4 mt-4">
          <KCard title="Chat · 최근 메시지" icon={<MessageSquare size={16}/>}>
            <Scroll max="max-h-72">
              <ul className="space-y-1">{(chat.recent||[]).map(m=>(
                <li key={m.id} className="flex items-center gap-2 border-b border-neutral-200 dark:border-neutral-800 py-1">
                  <StatusDot level={m.ok?'ok':'err'}/><span className="text-xs w-16 text-neutral-500">{m.ts||''}</span>
                  <span className="text-[11px] px-2 py-0.5 rounded bg-neutral-100 dark:bg-neutral-800 border border-neutral-200 dark:border-neutral-700">{m.role}</span>
                  <span className="truncate">{m.text}</span>
                </li>
              ))}</ul>
            </Scroll>
          </KCard>
          <KCard title="Chat · 지연(p50/p95)" icon={<AlertCircle size={16}/>}>
            <ResponsiveContainer width="100%" height={240}>
              <RadialBarChart innerRadius="40%" outerRadius="95%" data={[{name:'p50',value:chat.p50||0},{name:'p95',value:chat.p95||0}]}>
                <RadialBar minAngle={15} background clockWise dataKey="value" />
                <Tooltip/>
              </RadialBarChart>
            </ResponsiveContainer>
          </KCard>
        </div>

        <div className="text-xs text-neutral-500 dark:text-neutral-400 mt-6">API: {apiBase} • 상태: {health?.ok ? "OK" : "—"}</div>
      </div>

      <div className="logo-fixed"><img src={`/sts_logo/sts_이름_이미지.PNG?v=${Date.now()}`} alt="Company Logo" onError={(e)=>{e.currentTarget.style.display='none'}}/></div>
    </div>
  )
}