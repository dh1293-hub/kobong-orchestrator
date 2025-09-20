import React from "react"
function cx(...xs:(string|false|null|undefined)[]){ return xs.filter(Boolean).join(" ") }
const Pill:React.FC<{tone:"ok"|"run"|"queue"|"fail"|"muted"; children:React.ReactNode}> = ({tone,children}) => {
  const map:any={ ok:"text-emerald-300 border-emerald-500/30 bg-emerald-500/10", run:"text-sky-300 border-sky-500/30 bg-sky-500/10",
    queue:"text-gray-300 border-gray-500/30 bg-gray-500/10", fail:"text-rose-300 border-rose-500/30 bg-rose-500/10", muted:"text-gray-300 border-white/10 bg-white/5" }
  return <span className={cx("text-[11px] px-2 py-0.5 rounded-full border",map[tone])}>{children}</span>
}
const Card:React.FC<{title:string; sub?:string; right?:React.ReactNode; span?:string; tall?:boolean; children:React.ReactNode}>
= ({title,sub,right,children,span="md:col-span-4",tall=false}) => (
  <section className={cx("group relative rounded-2xl border border-white/5 bg-[#121418] shadow-xl ring-1 ring-white/5 hover:ring-emerald-400/20 transition","p-4 md:p-5 col-span-12", span, tall && "row-span-2")}>
    <header className="mb-3 flex items-start justify-between gap-4">
      <div>{sub && <div className="text-xs tracking-widest text-gray-400">{sub}</div>}<h2 className="text-lg md:text-xl font-semibold text-gray-100">{title}</h2></div>
      <div className="shrink-0">{right}</div>
    </header>
    <div className="text-gray-200">{children}</div>
  </section>
)
const KPI:React.FC<{label:string; value:string; delta?:string; hint?:string}>
= ({label,value,delta,hint}) => (
  <div className="rounded-2xl bg-[#151821] border border-white/5 p-4 md:p-5 shadow-lg">
    <div className="text-[11px] uppercase tracking-widest text-gray-400">{label}</div>
    <div className="mt-1 flex items-baseline gap-2">
      <strong className="text-2xl md:text-3xl font-semibold text-gray-100">{value}</strong>
      {delta && <span className={cx("text-[11px] px-2 py-0.5 rounded-full border",
        delta.startsWith("+")?"text-emerald-300 border-emerald-500/30 bg-emerald-500/10":"text-rose-300 border-rose-500/30 bg-rose-500/10")}>{delta}</span>}
    </div>
    {hint && <div className="text-xs text-gray-400">{hint}</div>}
  </div>
)
const Sparkline:React.FC<{points:number[]; h?:number; aria?:string}>
= ({points,h=36,aria="trend"}) => {
  if (!points?.length) return null
  const max=Math.max(...points), min=Math.min(...points)
  const n=(v:number)=> max===min?0:(v-min)/(max-min)
  const w=Math.max(64, points.length*8)
  const d=points.map((v,i)=>`${i?"L":"M"} ${i*(w/(points.length-1))} ${h-n(v)*h}`).join(" ")
  const up=points.at(-1)! >= points[0]
  return (<svg viewBox={`0 0 ${w} ${h}`} width="100%" height={h} role="img" aria-label={aria} className="overflow-visible">
    <defs><linearGradient id="g" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor={up?"#34d399":"#fb7185"} stopOpacity="0.45"/><stop offset="100%" stopColor={up?"#34d399":"#fb7185"} stopOpacity="0"/></linearGradient></defs>
    <path d={d} fill="none" stroke={up?"#34d399":"#fb7185"} strokeWidth="2"/>
    <path d={`${d} L ${w} ${h} L 0 ${h} Z`} fill="url(#g)" opacity="0.15"/>
  </svg>)
}
const data = {
  kpi:{ repos:{value:"12",delta:"+1",hint:"tracked"}, prsOpen:{value:"34",delta:"+5",hint:"open PRs"},
    ciPass:{value:"96.8%",delta:"+0.4%",hint:"last 24h"}, issues:{value:"78",delta:"-6",hint:"open issues"},
    release:{value:"v0.1.36",delta:"+1",hint:"24h"}, runners:{value:"7/8",delta:"-1",hint:"online"} },
  trends:{ prs:[8,11,9,12,13,18,15,21,19,17], ci:[82,90,86,92,94,93,96,97,94,98], issues:[66,68,67,69,70,74,72,71,77,78] },
  repos:Array.from({length:8}).map((_,i)=>({name:`repo-${i+1}`, stars: 10+i*3, prs:(i*2+3)%17, issues:(i*7+4)%39 })),
  prs:Array.from({length:9}).map((_,i)=>({ id: 140+i, title:`feat: module ${i+1}`, author:i%2?'hanminsu':'gpt5-bot', repo:'dh1293-hub/kobong-orchestrator', age:`${(i*7)%48}h`,
    checks:['lint','test','build'].map((n,j)=>(['ok','run','fail'][(i+j)%3])) })),
  issues:Array.from({length:9}).map((_,i)=>({ id: 220+i, title:`bug: case ${i+1}`, repo:'kobong-orchestrator', labels:[i%3?'P2':'P1', i%2?'bug':'needs-triage'], age:`${(i*11)%96}h` })),
  runs:Array.from({length:8}).map((_,i)=>({ id:`#${3100+i}`, wf:i%2?'Unit Tests':'Release Smoke', repo:'kobong-orchestrator',
    status:['success','queued','running','failed'][i%4], dur:[185,92,310,44][i%4], ts:`${(10+i)%24}:0${i%6}` })),
  alerts:Array.from({length:8}).map((_,i)=>({ id:`AL-${300+i}`, type:['Dependabot','Secret','CodeQL'][i%3], sev:['low','medium','high'][i%3], title:['lodash CVE','token leaked?','tainted data'][i%3], age:`${2+i}d` })),
  webhooks:Array.from({length:6}).map((_,i)=>({ dest:['/events','/metrics','/audit'][i%3], code:[200,202,500,410][i%4], lat:[85,120,240,60][i%4] })),
  runners:Array.from({length:6}).map((_,i)=>({ name:`runner-${i+1}`, os:i%2?'windows':'ubuntu', busy:(i%3)===0, q:['short','long','default'][i%3] })),
  timeline:Array.from({length:12}).map((_,i)=>({ t:`오늘 ${(9+i)%24}:0${i%6}`, kind:['PR','CI','Issue','Deploy'][i%4], text:['opened PR #142','ci passed @main','issue labeled P2','released v0.1.36'][i%4], corr:`trace-${1000+i}` }))
}
const Table:React.FC<{cols:string[], rows:React.ReactNode[][]}> = ({cols,rows}) => (
  <div className="rounded-xl overflow-hidden border border-white/5">
    <div className="bg-[#0f1115]/60 backdrop-blur px-3 py-2 flex items-center justify-between"><div className="flex gap-3 text-xs text-gray-400">{cols.map((c,i)=><span key={i} className="min-w-16">{c}</span>)}</div></div>
    <ul className="divide-y divide-white/5">
      {rows.map((r,ri)=>(
        <li key={ri} className="px-3 py-3 grid grid-cols-12 items-center gap-2 hover:bg-white/2">
          {r.map((cell,ci)=><div key={ci} className={cx("col-span-12 md:col-span-3 text-sm text-gray-200", ci===0 && "md:col-span-5", ci===r.length-1 && "md:col-span-2 text-right")}>{cell}</div>)}
        </li>
      ))}
    </ul>
  </div>
)
const Header:React.FC=()=>(
  <div className="flex items-center justify-between py-4">
    <div><div className="text-xs uppercase tracking-widest text-gray-400">KOBONG OBSERVABILITY</div>
      <h1 className="text-2xl md:text-3xl font-extrabold bg-gradient-to-r from-gray-100 via-gray-200 to-gray-400 bg-clip-text text-transparent">KO • Nebula Tailwind Only</h1></div>
    <div className="flex items-center gap-3"><span className="text-xs text-gray-400 hidden md:inline">Asia/Seoul</span><span className="text-xs text-gray-400">{new Date().toLocaleTimeString()}</span></div>
  </div>
)
const KPIRow:React.FC=()=>(
  <div className="grid grid-cols-12 gap-3 md:gap-4">
    <div className="col-span-12 md:col-span-2"><KPI label="Repos" value={data.kpi.repos.value} delta={data.kpi.repos.delta} hint={data.kpi.repos.hint}/></div>
    <div className="col-span-12 md:col-span-2"><KPI label="Open PRs" value={data.kpi.prsOpen.value} delta={data.kpi.prsOpen.delta} hint={data.kpi.prsOpen.hint}/></div>
    <div className="col-span-12 md:col-span-2"><KPI label="CI Pass" value={data.kpi.ciPass.value} delta={data.kpi.ciPass.delta} hint={data.kpi.ciPass.hint}/></div>
    <div className="col-span-12 md:col-span-2"><KPI label="Issues" value={data.kpi.issues.value} delta={data.kpi.issues.delta} hint={data.kpi.issues.hint}/></div>
    <div className="col-span-12 md:col-span-2"><KPI label="Release" value={data.kpi.release.value} delta={data.kpi.release.delta} hint={data.kpi.release.hint}/></div>
    <div className="col-span-12 md:col-span-2"><KPI label="Runners" value={data.kpi.runners.value} delta={data.kpi.runners.delta} hint={data.kpi.runners.hint}/></div>
  </div>
)
const Trends:React.FC=()=>(
  <div className="grid grid-cols-12 gap-3 md:gap-4">
    <Card title="CI Pass Trend" sub="최근 10회" span="md:col-span-4" right={<span className="text-xs text-gray-400">p95 ≥ 95%</span>}><Sparkline points={data.trends.ci}/></Card>
    <Card title="Open PRs" sub="최근 10일" span="md:col-span-4"><Sparkline points={data.trends.prs}/></Card>
    <Card title="Open Issues" sub="최근 10일" span="md:col-span-4"><Sparkline points={data.trends.issues}/></Card>
  </div>
)
const Repos:React.FC=()=>(
  <Card title="Repos Overview" sub="별 · PR · 이슈" span="md:col-span-6">
    <ul className="grid grid-cols-12 gap-3">
      {data.repos.map(r=>(
        <li key={r.name} className="col-span-12 md:col-span-6 xl:col-span-4 rounded-xl bg-[#151821] border border-white/5 p-3">
          <div className="text-sm font-medium text-gray-100">{r.name}</div>
          <div className="mt-1 text-xs text-gray-400">★ {r.stars} · PR {r.prs} · Issues {r.issues}</div>
        </li>
      ))}
    </ul>
  </Card>
)
const PRs:React.FC=()=>(
  <Card title="PR Queue" sub="체크/나이/리포" span="md:col-span-6">
    <Table cols={["PR","Checks","Age","Repo"]} rows={
      data.prs.map(pr=>[
        <div className="flex flex-col md:flex-row md:items-center gap-1 md:gap-3">
          <span className="text-emerald-300">#{pr.id}</span>
          <span className="text-gray-200 line-clamp-1">{pr.title}</span>
          <span className="text-xs text-gray-400">{pr.author}</span>
        </div>,
        <div className="flex gap-2">{pr.checks.map((s,i)=><Pill key={i} tone={s==='ok'?'ok':s==='run'?'run':s==='fail'?'fail':'muted'}>{s}</Pill>)}</div>,
        <span className="text-gray-300">{pr.age}</span>,
        <span className="text-gray-400">{pr.repo}</span>
      ])
    }/>
  </Card>
)
const Issues:React.FC=()=>(
  <Card title="Issues Triage" sub="라벨/우선순위" span="md:col-span-5">
    <ul className="divide-y divide-white/5">
      {data.issues.map(i=>(
        <li key={i.id} className="py-3 flex items-center gap-3">
          <span className="w-16 text-xs text-gray-400">#{i.id}</span>
          <div className="min-w-0 flex-1">
            <div className="text-sm text-gray-200 truncate">{i.title}</div>
            <div className="text-xs text-gray-400">{i.repo}</div>
          </div>
          <div className="flex gap-2">{i.labels.map((l:any,ix:number)=><Pill key={ix} tone={l==='P1'?'fail':'muted'}>{l}</Pill>)}</div>
          <span className="text-xs text-gray-400 w-16 text-right">{i.age}</span>
        </li>
      ))}
    </ul>
  </Card>
)
const Runs:React.FC=()=>(
  <Card title="Actions / CI Runs" sub="최근 실행" span="md:col-span-7">
    <ul className="divide-y divide-white/5">
      {data.runs.map(r=>(
        <li key={r.id} className="py-3 grid grid-cols-12 gap-3 items-center">
          <span className="col-span-2 text-xs text-gray-400">{r.id}</span>
          <div className="col-span-6 min-w-0">
            <div className="text-sm text-gray-200 truncate">{r.wf}</div>
            <div className="text-xs text-gray-400">{r.repo} • {r.ts}</div>
          </div>
          <div className="col-span-2"><Pill tone={r.status==='success'?'ok':r.status==='running'?'run':r.status==='queued'?'queue':'fail'}>{r.status}</Pill></div>
          <span className="col-span-2 text-right text-xs text-gray-400">{r.dur}s</span>
        </li>
      ))}
    </ul>
  </Card>
)
const Alerts:React.FC=()=>(
  <Card title="Security & Quality Alerts" sub="GitHub Alerts" span="md:col-span-4">
    <ul className="grid grid-cols-12 gap-3">
      {data.alerts.map(a=>(
        <li key={a.id} className="col-span-12 md:col-span-6 xl:col-span-4 rounded-xl bg-[#151821] border border-white/5 p-3">
          <div className="flex items-center justify-between"><span className="text-xs text-gray-400">{a.type}</span><Pill tone={a.sev==='high'?'fail':a.sev==='medium'?'run':'muted'}>{a.sev}</Pill></div>
          <div className="mt-1 text-sm text-gray-200 line-clamp-2">{a.title}</div>
          <div className="mt-1 text-[11px] text-gray-400">{a.age}</div>
        </li>
      ))}
    </ul>
  </Card>
)
const Infra:React.FC=()=>(
  <Card title="Runners & Webhooks Health" sub="호스트/큐/지연" span="md:col-span-8">
    <div className="grid grid-cols-12 gap-3">
      <div className="col-span-12 md:col-span-6 rounded-xl bg-[#151821] border border-white/5 p-3">
        <div className="text-xs text-gray-400 mb-2">Self-hosted Runners</div>
        <ul className="space-y-2">
          {data.runners.map(r=>(
            <li key={r.name} className="flex items-center justify-between">
              <div className="text-sm text-gray-200">{r.name} <span className="text-xs text-gray-400">({r.os})</span></div>
              <div className="flex items-center gap-2"><Pill tone={r.busy?'run':'ok'}>{r.busy?'busy':'idle'}</Pill><span className="text-xs text-gray-400">{r.q}</span></div>
            </li>
          ))}
        </ul>
      </div>
      <div className="col-span-12 md:col-span-6 rounded-xl bg-[#151821] border border-white/5 p-3">
        <div className="text-xs text-gray-400 mb-2">Webhooks</div>
        <ul className="space-y-2">
          {data.webhooks.map((w,ix)=>(
            <li key={ix} className="flex items-center justify-between">
              <div className="text-sm text-gray-200">{w.dest}</div>
              <div className="flex items-center gap-3"><span className="text-xs text-gray-400">{w.lat}ms</span><Pill tone={(w.code===200||w.code===202)?'ok':'fail'}>{w.code}</Pill></div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  </Card>
)
const Timeline:React.FC=()=>(
  <Card title="KO · GitHub Timeline" sub="최근 이벤트" span="md:col-span-12">
    <ul className="grid grid-cols-12 gap-3">
      {data.timeline.map(ev=>(
        <li key={ev.corr} className="col-span-12 md:col-span-6 xl:col-span-4 2xl:col-span-3 rounded-xl bg-[#151821] border border-white/5 p-3">
          <div className="flex items-center justify-between"><span className="text-xs text-gray-400">{ev.t}</span><span className="text-[11px] px-2 py-0.5 rounded-full border border-white/10 text-gray-300">{ev.kind}</span></div>
          <div className="mt-1 text-sm text-gray-200 truncate">{ev.text}</div>
          <div className="mt-1 text-[11px] text-gray-400">{ev.corr}</div>
        </li>
      ))}
    </ul>
  </Card>
)
const Chrome:React.FC<{children:React.ReactNode}>=({children})=>(
  <div className="min-h-screen w-screen bg-[#0b0d11] text-gray-200"><div className="mx-auto max-w-[1920px] px-4 md:px-6">{children}</div></div>
)
const App:React.FC=()=>(
  <Chrome>
    <Header/><KPIRow/>
    <div className="mt-4 grid grid-cols-12 gap-3 md:gap-4 auto-rows-[minmax(160px,auto)] md:auto-rows-[minmax(200px,auto)] grid-flow-dense">
      <Trends/><Repos/><PRs/><Issues/><Runs/><Alerts/><Infra/><Timeline/>
    </div>
    <footer className="pt-4 pb-8 text-[11px] text-gray-500">© kobong-orchestrator • Nebula Tailwind Only • Dark Gray</footer>
  </Chrome>
)
export default App
