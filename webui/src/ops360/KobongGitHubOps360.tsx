import * as React from "react";
import { Card } from "./kui/Card";
import { KPI } from "./kui/KPI";
import { Sparkline } from "./kui/Sparkline";
import { TinyBars } from "./kui/TinyBars";
import { IcPR, IcIssue, IcRun, IcClock, IcAlert, IcBranch, IcStar } from "./kui/Icon";

type RepoSummary = {
  name: string; stars: number; forks: number; watchers: number; openPRs: number; openIssues: number;
  successRate: number; leadTimeH: number; mttrH: number; releases: number; runsToday: number;
};
type Run = { id: string; wf: string; branch: string; status: "success"|"running"|"failed"|"queued"; durMin: number; startedAt: string; };
type PR = { id: number; title: string; author: string; branch: string; ageH: number; checks: "pass"|"pending"|"fail"; };
type Issue = { id: number; title: string; labels: string[]; ageD: number; severity?: "low"|"med"|"high"; };

const demo = {
  summary: { name: "kobong-orchestrator", stars: 312, forks: 47, watchers: 28, openPRs: 9, openIssues: 23, successRate: 0.86, leadTimeH: 14, mttrH: 3.2, releases: 24, runsToday: 31 } as RepoSummary,
  trendBuilds: [22,26,25,29,31,28,35,34,38,36,40,44],
  trendPRs:    [6,5,7,8,9,7,8,10,9,11,10,9],
  trendIssues: [24,23,25,22,21,23,20,19,22,23,21,20],
  runs: [
    { id:"r112", wf:"CI", branch:"main", status:"success", durMin:7,  startedAt:"09:41" },
    { id:"r113", wf:"E2E",branch:"develop", status:"running", durMin:22, startedAt:"09:36" },
    { id:"r114", wf:"Release", branch:"main", status:"queued", durMin:0,  startedAt:"09:33" },
    { id:"r115", wf:"Lint", branch:"feature/ui",status:"failed", durMin:2,  startedAt:"09:30" },
  ] as Run[],
  prs: [
    { id:482, title:"feat: add GH ops dashboard", author:"alice", branch:"feature/ops-ui", ageH:5, checks:"pending" },
    { id:479, title:"fix(ci): windows path bug",  author:"bob",   branch:"fix/win-path", ageH:11, checks:"pass" },
    { id:471, title:"refactor: service layer",    author:"kim",   branch:"refactor/svc",  ageH:28, checks:"fail" },
    { id:468, title:"docs: api usage",            author:"lee",   branch:"docs/api",      ageH:33, checks:"pass" },
  ] as PR[],
  issues: [
    { id:901, title:"Job flakiness on Node 20",  labels:["ci","flaky"], ageD:2, severity:"med" },
    { id:887, title:"UI: overflow in table",     labels:["ui"],        ageD:5, severity:"low" },
    { id:860, title:"Security: npm audit high",  labels:["security"],  ageD:1, severity:"high" },
    { id:842, title:"Perf: slow build on win",   labels:["perf","win"],ageD:7, severity:"med" },
  ] as Issue[]
};

function Badge({ children, intent = "muted" }: { children: React.ReactNode; intent?: "success"|"danger"|"muted"|"warn" }) {
  const map = {
    success: "bg-emerald-500/15 text-emerald-300 border border-emerald-400/20",
    danger:  "bg-rose-500/15 text-rose-300 border border-rose-400/20",
    warn:    "bg-amber-500/15 text-amber-300 border border-amber-400/20",
    muted:   "bg-white/5 text-white/70 border border-white/10",
  } as const;
  return <span className={"px-2 py-0.5 rounded-md text-xs " + map[intent]}>{children}</span>;
}
function Progress({ value }: { value: number }) {
  return (
    <div className="h-2 w-full rounded-full bg-white/10 overflow-hidden">
      <div className="h-full bg-gradient-to-r from-emerald-400 via-teal-300 to-cyan-300" style={{ width: `${Math.max(0, Math.min(100, value*100))}%` }}/>
    </div>
  );
}

export default function KobongGitHubOps360() {
  const data = (window as any).__GITHUB_DASH__ ?? demo;
  const s = data.summary as RepoSummary;
  React.useEffect(()=> {
    document.documentElement.classList.add("dark");
    document.body.classList.add("bg-[#0f1216]","text-white");
  },[]);
  return (
    <div className="min-h-screen w-full bg-[#0f1216] text-white">
      {/* Top bar */}
      <div className="sticky top-0 z-40 backdrop-blur-md bg-black/30 border-b border-white/10">
        <div className="mx-auto max-w-[1800px] px-5 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="size-8 rounded-lg bg-gradient-to-br from-emerald-400/70 to-cyan-400/70 shadow-[0_0_20px_rgba(16,185,129,.35)]"/>
            <div>
              <div className="text-sm font-semibold">Kobong GitHub Ops 360</div>
              <div className="text-xs text-white/60">{s.name}</div>
            </div>
            <div className="hidden md:flex items-center gap-4 pl-5 text-xs text-white/70">
              <span className="flex items-center gap-1"><IcStar/> {s.stars}</span>
              <span className="flex items-center gap-1"><IcBranch/> {s.forks}</span>
              <span className="flex items-center gap-1"><IcClock/> MTTR {s.mttrH}h</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input className="text-sm rounded-lg px-3 py-1.5 w-[220px] placeholder:text-white/50 bg-white/5 border border-white/10" placeholder="Quick filter (repo / branch / user)" />
            <button className="px-3 py-1.5 rounded-lg bg-emerald-500/20 text-emerald-200 border border-emerald-500/30 hover:bg-emerald-500/30">Share</button>
          </div>
        </div>
      </div>

      {/* Main grid */}
      <div className="mx-auto max-w-[1800px] px-5 py-5 grid grid-cols-12 gap-4 auto-rows-[minmax(90px,auto)]">
        {/* KPIs */}
        <div className="col-span-12 grid grid-cols-2 md:grid-cols-4 gap-3">
          <KPI label="Build Success" value={`${Math.round(s.successRate*100)}%`} delta="+2.1%" good/>
          <KPI label="Open PRs" value={s.openPRs} delta="+1" good={false}/>
          <KPI label="Open Issues" value={s.openIssues} delta="-3"/>
          <KPI label="Runs Today" value={s.runsToday} delta="+5" good/>
        </div>

        {/* Build trend */}
        <Card title="Build Trend (30d)" subtitle="Success rate & throughput" className="col-span-12 lg:col-span-6">
          <div className="flex items-end gap-6">
            <div className="flex-1"><Sparkline data={data.trendBuilds}/></div>
            <div className="w-[140px]">
              <div className="text-xs text-white/70 mb-1">Success rate</div>
              <Progress value={s.successRate}/>
              <div className="text-[11px] text-white/50 mt-1">Lead time: <b className="text-white/80">{s.leadTimeH}h</b></div>
            </div>
          </div>
        </Card>

        {/* PR trend */}
        <Card title="PR Throughput" subtitle="Opened (last 12w)" className="col-span-12 lg:col-span-3">
          <TinyBars data={data.trendPRs}/>
          <div className="mt-2 text-xs text-white/60">Median PR age <b className="text-white/80">{Math.max(...data.trendPRs) <= 10 ? "8h" : "—"}</b></div>
        </Card>

        {/* Issues trend */}
        <Card title="Issues Open" subtitle="Count (last 12w)" className="col-span-12 lg:col-span-3">
          <TinyBars data={data.trendIssues}/>
          <div className="mt-2 text-xs text-white/60">SLO breach risk <Badge intent="warn">Medium</Badge></div>
        </Card>

        {/* Workflow runs */}
        <Card title="Workflow Runs" subtitle="Live queue & last durations" className="col-span-12 lg:col-span-6">
          <div className="grid grid-cols-2 gap-3 text-sm">
            {demo.runs.map((r:Run)=>(
              <div key={r.id} className="rounded-lg p-3 flex items-center gap-3 bg-white/5 border border-white/10">
                <IcRun/><div className="flex-1">
                  <div className="font-medium">{r.wf} <span className="text-white/50">on</span> <span className="text-emerald-200">{r.branch}</span></div>
                  <div className="text-xs text-white/60">since {r.startedAt} · {r.durMin}m</div>
                </div>
                <div className="w-[100px]"><Progress value={r.status==="success"?1: r.status==="failed"?0.2: r.status==="queued"?0.05: 0.6}/></div>
                <Badge intent={r.status==="failed"?"danger": r.status==="queued"?"muted":"success"}>{r.status}</Badge>
              </div>
            ))}
          </div>
        </Card>

        {/* Open PRs Table */}
        <Card title="Open Pull Requests" subtitle="Checks & freshness" className="col-span-12 lg:col-span-6">
          <div className="overflow-auto">
            <table className="w-full text-sm">
              <thead className="text-white/70 text-xs">
                <tr className="border-b border-white/10">
                  <th className="text-left py-2 font-medium">#</th>
                  <th className="text-left py-2 font-medium">Title</th>
                  <th className="text-left py-2 font-medium">Branch</th>
                  <th className="text-left py-2 font-medium">Age</th>
                  <th className="text-left py-2 font-medium">Checks</th>
                </tr>
              </thead>
              <tbody>
                {demo.prs.map((p:PR)=>(
                  <tr key={p.id} className="border-b border-white/5 hover:bg-white/5">
                    <td className="py-2 text-white/70">#{p.id}</td>
                    <td className="py-2">{p.title} <span className="text-white/50">by {p.author}</span></td>
                    <td className="py-2"><span className="text-emerald-200">{p.branch}</span></td>
                    <td className="py-2">{p.ageH}h</td>
                    <td className="py-2">
                      {p.checks==="pass" && <Badge intent="success">pass</Badge>}
                      {p.checks==="pending" && <Badge intent="warn">pending</Badge>}
                      {p.checks==="fail" && <Badge intent="danger">fail</Badge>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Issues */}
        <Card title="Active Issues" subtitle="Severity · age · labels" className="col-span-12 lg:col-span-5">
          <div className="space-y-2 text-sm">
            {demo.issues.map((i:Issue)=>(
              <div key={i.id} className="flex items-center justify-between rounded-lg px-3 py-2 bg-white/5 border border-white/10">
                <div className="flex items-center gap-2">
                  <IcIssue/>
                  <div>
                    <div className="font-medium">{i.title}</div>
                    <div className="text-xs text-white/60">labels: {i.labels.join(", ")}</div>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-xs text-white/60">{i.ageD}d</span>
                  <Badge intent={i.severity==="high"?"danger": i.severity==="med"?"warn":"muted"}>{i.severity ?? "low"}</Badge>
                </div>
              </div>
            ))}
          </div>
        </Card>

        {/* Release cadence */}
        <Card title="Release Cadence" subtitle="last 12 months" className="col-span-12 lg:col-span-7">
          <div className="grid grid-cols-12 gap-2">
            {new Array(12).fill(0).map((_,i)=> {
              const v = (i%3===0)? 9 : (i%3===1)? 6 : 3;
              return <div key={i} className="h-16 rounded-md flex items-end p-2 bg-white/5 border border-white/10">
                <div className="w-full bg-gradient-to-t from-emerald-400/70 to-cyan-300/70 rounded-sm" style={{ height: `${v*10}%` }}/>
              </div>;
            })}
          </div>
          <div className="text-xs text-white/60 mt-2">Total releases: <b className="text-white/80">{s.releases}</b></div>
        </Card>

        {/* Filler widgets to avoid empty space */}
        <div className="col-span-12 grid grid-cols-1 md:grid-cols-3 gap-3">
          <div className="rounded-xl p-4 bg-white/5 border border-white/10">
            <div className="text-xs text-white/60 mb-2 flex items-center gap-2"><span className="inline-block w-2 h-2 rounded-full bg-emerald-400"></span> Branch Activity</div>
            <TinyBars data={[3,4,6,8,5,3,9,7,8,10,9,6,4,8,11,13]}/>
          </div>
          <div className="rounded-xl p-4 bg-white/5 border border-white/10">
            <div className="text-xs text-white/60 mb-2 flex items-center gap-2"><IcPR/> Merge Time (hrs)</div>
            <Sparkline data={[12,11,14,9,8,10,7,6,8,7,9,8]}/>
          </div>
          <div className="rounded-xl p-4 bg-white/5 border border-white/10">
            <div className="text-xs text-white/60 mb-2 flex items-center gap-2"><IcAlert/> Security/Dependabot</div>
            <div className="flex items-center gap-3">
              <Badge intent="danger">2 high</Badge>
              <Badge intent="warn">4 med</Badge>
              <Badge>7 low</Badge>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}