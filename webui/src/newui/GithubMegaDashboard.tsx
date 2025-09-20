import * as React from "react";
type CardProps = React.HTMLAttributes<HTMLDivElement> & {
  title?: React.ReactNode;
  right?: React.ReactNode;
  dense?: boolean;
  className?: string;
  children?: React.ReactNode;
};

/**
 * Tailwind-only GitHub Mega Dashboard
 * - 목표: 브라우저 전체 활용 / 빈 공간 최소화 / 정보량 극대화 / 직관 / 다크 그레이 / 약간 화려 / 전문가 느낌
 * - 외부 라이브러리 0 (아이콘/스파크라인/게이지 모두 인라인 SVG)
 */

type RepoStat = { name: string; issues: number; prs: number; stars: number; forks: number; ciPass: number; coverage: number; activity: number[]; };
type Workflow = { name: string; status: "success"|"running"|"failed"|"queued"; durationMin: number; branch: string; commit: string; actor: string; startedAt: string; };
type Incident = { level: "info"|"warn"|"error"; title: string; repo: string; time: string; };
type Runner = { name: string; status: "idle"|"busy"|"offline"; os: string; queued: number; };

const DUMMY_REPOS: RepoStat[] = [
  { name:"orchestrator", issues:12, prs:5, stars:820, forks:97, ciPass:96, coverage:83, activity:[5,6,7,9,12,9,8,12,15,11,9,10,12,18,16,12,11,9,7,6,9,12,14,18,20,19,15,13,12,14] },
  { name:"webui", issues:3, prs:2, stars:402, forks:41, ciPass:99, coverage:90, activity:[2,3,2,4,6,7,5,4,8,12,10,11,13,12,12,11,9,10,8,9,7,8,9,11,12,10,8,7,6,7] },
  { name:"actions", issues:7, prs:4, stars:210, forks:29, ciPass:92, coverage:78, activity:[1,2,3,3,4,4,5,6,7,8,7,9,10,9,8,7,6,5,4,4,6,7,8,8,7,7,6,5,5,4] },
  { name:"api-gateway", issues:1, prs:0, stars:120, forks:14, ciPass:98, coverage:95, activity:[0,1,0,1,2,3,2,2,3,4,5,6,6,5,6,7,8,7,6,6,5,4,3,3,2,2,3,4,5,6] },
];

const DUMMY_WFS: Workflow[] = [
  { name:"Build & Test", status:"success", durationMin:8,  branch:"main",  commit:"6a1b9c2", actor:"dev1", startedAt:"11:20" },
  { name:"E2E",         status:"running", durationMin:14, branch:"develop", commit:"ae92d10", actor:"qa2",  startedAt:"11:28" },
  { name:"Lint",        status:"failed",  durationMin:2,  branch:"feature/ui", commit:"3c7d51f", actor:"dev2", startedAt:"11:15" },
  { name:"Release",     status:"queued",  durationMin:0,  branch:"main",  commit:"6a1b9c2", actor:"ops1", startedAt:"…" },
];

const DUMMY_INC: Incident[] = [
  { level:"warn",  title:"High flakiness on E2E", repo:"webui", time:"11:12" },
  { level:"error", title:"Sonar coverage drop",   repo:"actions", time:"10:58" },
  { level:"info",  title:"New tag v0.14.0",       repo:"orchestrator", time:"10:45" },
];

const DUMMY_RUNNERS: Runner[] = [
  { name:"runner-a01", status:"busy",    os:"windows", queued:2 },
  { name:"runner-a02", status:"idle",    os:"linux",   queued:0 },
  { name:"runner-b12", status:"offline", os:"linux",   queued:0 },
  { name:"runner-x03", status:"busy",    os:"macos",   queued:1 },
];

function cls(...xs:(string|false|undefined)[]){ return xs.filter(Boolean).join(" "); }

const Card = ({ title, right, className, dense, children }: CardProps) => (
  <section className={cls(
    "relative rounded-2xl border border-zinc-800/80 bg-gradient-to-b from-zinc-900 to-zinc-950 shadow-xl shadow-emerald-900/10",
    "ring-1 ring-inset ring-zinc-800/60 hover:ring-emerald-500/30 transition",
    dense ? "p-3" : "p-5",
    className
  )}>
    {(title || right) && (
      <header className="mb-3 flex items-center justify-between">
        <h3 className="text-sm font-semibold tracking-wide text-zinc-200">{title}</h3>
        {right}
      </header>
    )}
    <div>{children}</div>
  </section>
);

const StatTile: React.FC<{label:string; value:React.ReactNode; change?:number; tone?:"ok"|"warn"|"bad"}> = ({label,value,change,tone})=>{
  const toneCls = tone==="ok" ? "text-emerald-400" : tone==="warn" ? "text-amber-400" : tone==="bad" ? "text-rose-400" : "text-zinc-300";
  const chip = change===undefined ? null :
    (<span className={cls("ml-2 inline-flex items-center rounded-md px-1.5 py-0.5 text-[10px] font-semibold",
                          change>0?"bg-emerald-500/10 text-emerald-300":"bg-rose-500/10 text-rose-300")}>
      {change>0? "▲":"▼"} {Math.abs(change)}%
     </span>);
  return (
    <div className="rounded-xl bg-zinc-900/70 px-3 py-2 ring-1 ring-inset ring-zinc-800/70">
      <div className="text-[11px] uppercase tracking-wider text-zinc-400">{label}</div>
      <div className={cls("mt-0.5 text-lg font-bold", toneCls)}>{value}{chip}</div>
    </div>
  );
};

const Spark: React.FC<{points:number[]; h?:number; w?:number; tone?:"ok"|"warn"|"bad"}> = ({points,h=40,w=160,tone})=>{
  const max=Math.max(1,...points), min=Math.min(...points);
  const xs = points.map((_,i)=> i*(w/(points.length-1)));
  const ys = points.map(v => h - ((v-min)/(max-min||1))*h );
  const d = xs.map((x,i)=> `${i===0?"M":"L"}${x.toFixed(1)},${ys[i].toFixed(1)}`).join(" ");
  const stroke = tone==="ok"?"#34d399":tone==="warn"?"#f59e0b":tone==="bad"?"#f43f5e":"#a1a1aa";
  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} className="block">
      <path d={d} fill="none" stroke={stroke} strokeWidth="2" />
      <rect x="0" y="0" width={w} height={h} rx="6" className="fill-none" />
    </svg>
  );
};

const Ring: React.FC<{value:number; size?:number; label?:string;}> = ({value,size=84,label})=>{
  const r=32, c=2*Math.PI*r, off = c*(1-Math.max(0,Math.min(100,value))/100);
  return (
    <div className="relative">
      <svg width={size} height={size} viewBox="0 0 80 80">
        <circle cx="40" cy="40" r={r} stroke="#27272a" strokeWidth="10" fill="none"/>
        <circle cx="40" cy="40" r={r} stroke="#34d399" strokeWidth="10" fill="none"
                strokeDasharray={c.toFixed(1)} strokeDashoffset={off.toFixed(1)} strokeLinecap="round"
                transform="rotate(-90 40 40)"/>
        <text x="50%" y="52%" textAnchor="middle" className="fill-zinc-200 text-[14px] font-bold">{value}%</text>
      </svg>
      {label && <div className="absolute inset-x-0 -bottom-1 text-center text-xs text-zinc-400">{label}</div>}
    </div>
  );
};

const Badge: React.FC<{tone:"ok"|"warn"|"bad"|"muted"; children:React.ReactNode}> = ({tone,children})=>{
  const map = { ok:"bg-emerald-500/10 text-emerald-300", warn:"bg-amber-500/10 text-amber-300", bad:"bg-rose-500/10 text-rose-300", muted:"bg-zinc-700/30 text-zinc-300" };
  return <span className={cls("rounded-md px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset ring-zinc-700/70", map[tone])}>{children}</span>;
};

const SectionTitle: React.FC<{title:string; subtitle?:string}> = ({title,subtitle}) => (
  <div className="mb-2 flex items-end justify-between">
    <div>
      <h2 className="text-lg font-bold text-zinc-100">{title}</h2>
      {subtitle && <p className="text-xs text-zinc-400">{subtitle}</p>}
    </div>
  </div>
);

const Toolbar: React.FC<{dense:boolean; setDense:(b:boolean)=>void}> = ({dense,setDense}) => (
  <div className="flex flex-wrap items-center gap-2">
    <label className="flex cursor-pointer select-none items-center gap-2 rounded-xl bg-zinc-900/60 px-3 py-2 ring-1 ring-inset ring-zinc-800/70">
      <input type="checkbox" checked={dense} onChange={e=>setDense(e.currentTarget.checked)} className="h-4 w-4 accent-emerald-500" />
      <span className="text-xs text-zinc-300">Compact</span>
    </label>
    <button className="rounded-xl bg-zinc-900/60 px-3 py-2 text-xs text-zinc-300 ring-1 ring-inset ring-zinc-800/70 hover:bg-zinc-800/60">Refresh</button>
    <div className="ml-auto text-xs text-zinc-500">Dark Gray • Tailwind-only</div>
  </div>
);

const GithubMegaDashboard: React.FC = () => {
  const [dense,setDense] = React.useState(false);

  return (
    <div className="min-h-screen w-screen overflow-x-hidden bg-zinc-950 text-zinc-100">
      {/* Top bar */}
      <header className="sticky top-0 z-40 border-b border-zinc-800/80 bg-zinc-950/80 backdrop-blur">
        <div className="mx-auto flex max-w-[2000px] items-center gap-4 px-6 py-3">
          <div className="flex items-center gap-3">
            <div className="h-7 w-7 rounded-lg bg-gradient-to-br from-emerald-500 to-cyan-500 shadow-lg shadow-emerald-900/30" />
            <div className="text-sm font-bold tracking-wide">GitHub Monitoring — Kobong</div>
          </div>
          <div className="ml-auto w-full max-w-[560px]">
            <div className="group flex items-center gap-2 rounded-2xl bg-zinc-900/70 px-4 py-2 ring-1 ring-inset ring-zinc-800/70 focus-within:ring-emerald-500/40">
              <svg width="16" height="16" viewBox="0 0 24 24" className="text-zinc-400"><circle cx="11" cy="11" r="7" stroke="currentColor" fill="none"/><line x1="21" y1="21" x2="16.65" y2="16.65" stroke="currentColor"/></svg>
              <input placeholder="Search repos, workflows, issues…" className="w-full bg-transparent text-sm text-zinc-200 placeholder:text-zinc-500 focus:outline-none" />
            </div>
          </div>
        </div>
      </header>

      {/* Content container */}
      <main className={cls("mx-auto max-w-[2000px] px-6", dense ? "py-4" : "py-6")}>
        <div className="mb-3 flex items-center gap-4">
          <SectionTitle title="Overview" subtitle="All GitHub states in one glance" />
          <Toolbar dense={dense} setDense={setDense} />
        </div>

        {/* Responsive masonry-like grid: auto-fill to avoid gaps */}
        <div className={cls(
          "grid gap-4",
          "grid-cols-[repeat(auto-fill,minmax(300px,1fr))]"
        )}>

          {/* Repo summary cards */}
          {DUMMY_REPOS.map((r,idx)=>(
            <Card key={r.name} title={r.name} dense={dense} className="col-span-1">
              <div className="grid grid-cols-2 gap-3">
                <StatTile label="Issues" value={r.issues} tone={r.issues>10?"warn":"ok"} />
                <StatTile label="PRs" value={r.prs} tone={r.prs>8?"warn":"ok"} />
                <StatTile label="Stars" value={r.stars.toLocaleString()} />
                <StatTile label="Forks" value={r.forks} />
              </div>
              <div className="mt-3 grid grid-cols-2 items-center gap-3">
                <div className="flex items-center justify-around gap-6">
                  <Ring value={r.ciPass} label="CI Pass" />
                  <Ring value={r.coverage} label="Coverage" />
                </div>
                <div className="rounded-xl bg-zinc-900/60 p-2 ring-1 ring-inset ring-zinc-800/70">
                  <Spark points={r.activity} tone="ok" w={220} h={60}/>
                </div>
              </div>
            </Card>
          ))}

          {/* Workflows */}
          <Card title="Workflows" dense={dense} className="col-span-1">
            <ul className="divide-y divide-zinc-800/80">
              {DUMMY_WFS.map(w=>(
                <li key={w.name+w.branch} className="flex items-center justify-between gap-3 py-2">
                  <div className="min-w-0">
                    <div className="truncate text-sm font-semibold">{w.name} <span className="text-zinc-500">({w.branch})</span></div>
                    <div className="truncate text-xs text-zinc-400">#{w.commit} • {w.actor} • {w.startedAt}</div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Badge tone={w.status==="success"?"ok":w.status==="running"?"warn":w.status==="failed"?"bad":"muted"}>{w.status}</Badge>
                    <div className="text-xs text-zinc-400">{w.durationMin}m</div>
                  </div>
                </li>
              ))}
            </ul>
          </Card>

          {/* Incidents / Events */}
          <Card title="Events & Incidents" dense={dense} className="col-span-1">
            <ul className="space-y-2">
              {DUMMY_INC.map((e,i)=>(
                <li key={i} className="flex items-start gap-3 rounded-xl bg-zinc-900/50 p-3 ring-1 ring-inset ring-zinc-800/70">
                  <span>{e.level==="error"?"❗":"⚠️"}</span>
                  <div className="min-w-0">
                    <div className="truncate text-sm">{e.title}</div>
                    <div className="text-xs text-zinc-500">{e.repo} • {e.time}</div>
                  </div>
                  <div className="ml-auto text-xs text-zinc-400">details</div>
                </li>
              ))}
            </ul>
          </Card>

          {/* Runners */}
          <Card title="Actions Runners" dense={dense} className="col-span-1">
            <div className="grid grid-cols-2 gap-3">
              {DUMMY_RUNNERS.map(r=>(
                <div key={r.name} className="rounded-xl bg-zinc-900/60 p-3 ring-1 ring-inset ring-zinc-800/70">
                  <div className="flex items-center justify-between">
                    <div className="truncate text-sm font-semibold">{r.name}</div>
                    <Badge tone={r.status==="busy"?"warn":r.status==="offline"?"bad":"ok"}>{r.status}</Badge>
                  </div>
                  <div className="mt-1 text-xs text-zinc-400">{r.os} • queued: {r.queued}</div>
                  <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-zinc-800">
                    <div className={cls("h-1.5", r.status==="busy"?"bg-amber-400":"bg-emerald-400")} style={{width:`${r.status==="busy"? 70 : r.status==="idle"? 30 : 10}%`}}/>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          {/* Global KPIs */}
          <Card title="Global KPIs" dense={dense} className="col-span-1">
            <div className="grid grid-cols-3 gap-3">
              <StatTile label="Open Issues" value={DUMMY_REPOS.reduce((a,b)=>a+b.issues,0)} />
              <StatTile label="Open PRs" value={DUMMY_REPOS.reduce((a,b)=>a+b.prs,0)} />
              <StatTile label="Avg CI Pass" value={Math.round(DUMMY_REPOS.reduce((a,b)=>a+b.ciPass,0)/DUMMY_REPOS.length)+"%"} change={+3} tone="ok" />
            </div>
            <div className="mt-3 grid grid-cols-3 gap-3">
              <div className="rounded-xl bg-zinc-900/60 p-2 ring-1 ring-inset ring-zinc-800/70"><Spark points={DUMMY_REPOS[0].activity} w={300} h={60} tone="ok"/></div>
              <div className="rounded-xl bg-zinc-900/60 p-2 ring-1 ring-inset ring-zinc-800/70"><Spark points={DUMMY_REPOS[1].activity} w={300} h={60} tone="warn"/></div>
              <div className="rounded-xl bg-zinc-900/60 p-2 ring-1 ring-inset ring-zinc-800/70"><Spark points={DUMMY_REPOS[2].activity} w={300} h={60} tone="bad"/></div>
            </div>
          </Card>

          {/* Long lists to fill space elegantly */}
          <Card title="Recent Activity" dense={dense} className="col-span-2">
            <div className={cls("grid gap-3", "grid-cols-[repeat(auto-fill,minmax(280px,1fr))]")}>
              {Array.from({length:10}).map((_,i)=>(
                <div key={i} className="rounded-xl bg-zinc-900/50 p-3 ring-1 ring-inset ring-zinc-800/70">
                  <div className="flex items-center justify-between">
                    <div className="truncate text-sm font-semibold">feat: module {i+1} improvements</div>
                    <Badge tone={i%3===0?"ok":i%3===1?"warn":"bad"}>{i%3===0?"merged":i%3===1?"running":"failed"}</Badge>
                  </div>
                  <div className="mt-1 flex items-center justify-between text-xs text-zinc-500">
                    <span>orchestrator • dev{i%4+1}</span>
                    <span>11:{(10+i).toString().padStart(2,"0")}</span>
                  </div>
                </div>
              ))}
            </div>
          </Card>

        </div>
      </main>
    </div>
  );
};

export default GithubMegaDashboard;