import * as React from "react";
import { StatCard } from "./components/StatCard";
import { Sparkline } from "./components/Sparkline";
import { Heatmap } from "./components/Heatmap";
import { ActivityBar } from "./components/ActivityBar";
import { mock } from "./mock";

export default function KobongPulseApp() {
  const [org, setOrg] = React.useState("kobong-labs");
  const [range, setRange] = React.useState("7d");
  const data = mock(range);

  return (
    <div className="min-h-screen w-full bg-neutral-950 text-neutral-100 selection:bg-emerald-600/40">
      {/* Top bar */}
      <header className="sticky top-0 z-20 backdrop-blur supports-[backdrop-filter]:bg-neutral-950/70 bg-neutral-950/90 border-b border-neutral-800">
        <div className="mx-auto max-w-[1600px] px-4 py-3 flex items-center gap-3">
          <div className="text-lg md:text-xl font-semibold tracking-tight">
            <span className="text-neutral-400">Kobong</span>
            <span className="mx-1.5">/</span>
            <span className="text-emerald-400">Pulse</span>
          </div>
          <div className="hidden md:flex items-center gap-2">
            <select value={org} onChange={e=>setOrg(e.target.value)}
              className="bg-neutral-900 border border-neutral-800 rounded-md px-2.5 py-1.5 text-sm focus:outline-none focus:ring-2 ring-emerald-600/50">
              {["kobong-labs","open-source","internal"].map(o=> <option key={o} value={o}>{o}</option>)}
            </select>
            <select value={range} onChange={e=>setRange(e.target.value)}
              className="bg-neutral-900 border border-neutral-800 rounded-md px-2.5 py-1.5 text-sm focus:outline-none focus:ring-2 ring-emerald-600/50">
              {["24h","7d","30d","90d"].map(r=> <option key={r} value={r}>{r}</option>)}
            </select>
          </div>
          <div className="ml-auto flex-1 max-w-[520px]">
            <div className="relative">
              <input placeholder="Search repos, PRs, issues, checks…"
                className="w-full bg-neutral-900 border border-neutral-800 rounded-md pl-9 pr-3 py-1.5 text-sm placeholder:text-neutral-500 focus:outline-none focus:ring-2 ring-emerald-600/40"/>
              <svg className="absolute left-2 top-1/2 -translate-y-1/2 h-4 w-4 text-neutral-500" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
            </div>
          </div>
        </div>
      </header>

      {/* Main grid */}
      <main className="mx-auto max-w-[1600px] px-4 py-4 grid grid-cols-12 gap-4">
        {/* Row 1: KPIs */}
        {[
          {label:"Repositories", value:data.kpis.repos, trend:data.trends.repos, tone:"emerald"},
          {label:"Open PRs", value:data.kpis.openPRs, trend:data.trends.prs, tone:"sky"},
          {label:"Open Issues", value:data.kpis.openIssues, trend:data.trends.issues, tone:"amber"},
          {label:"Failed Workflows", value:data.kpis.failed, trend:data.trends.failed, tone:"rose"},
          {label:"Active Contributors", value:data.kpis.contributors, trend:data.trends.contrib, tone:"violet"}
        ].map((k)=>(
          <div key={k.label} className="col-span-12 sm:col-span-6 lg:col-span-3 xl:col-span-2.4">
            <StatCard label={k.label} value={k.value} tone={k.tone}>
              <Sparkline points={k.trend} className="h-10" />
            </StatCard>
          </div>
        ))}

        {/* Row 2: PR Health (LHS) + Events feed (RHS) */}
        <section className="col-span-12 xl:col-span-7 bg-neutral-900/60 border border-neutral-800 rounded-2xl p-4 shadow-[0_0_0_1px_#262626,0_10px_40px_-12px_rgba(16,185,129,.25)]">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-neutral-300">PR Health (last {range})</h3>
            <div className="text-xs text-neutral-500">merge time • review load • churn</div>
          </div>
          <ActivityBar items={data.prHealth}/>
          <div className="mt-4 grid grid-cols-3 gap-3">
            {data.prBreakdown.map((b)=>(
              <div key={b.label} className="bg-neutral-950/60 border border-neutral-800 rounded-xl p-3">
                <div className="text-xs text-neutral-400">{b.label}</div>
                <div className="mt-1 text-lg font-semibold">{b.value}</div>
                <Sparkline points={b.trend} className="h-8 mt-2" />
              </div>
            ))}
          </div>
        </section>

        <section className="col-span-12 xl:col-span-5 bg-neutral-900/60 border border-neutral-800 rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-neutral-300">Recent Events</h3>
            <div className="text-xs text-neutral-500">commits • issues • workflow runs</div>
          </div>
          <div className="max-h-[280px] overflow-auto pr-1 space-y-2">
            {data.events.map((e)=>(
              <div key={e.id} className="group flex items-start gap-3 rounded-xl border border-neutral-800 bg-neutral-950/60 p-3 hover:border-neutral-700">
                <div className="mt-0.5 h-6 w-6 shrink-0 rounded-full bg-gradient-to-br from-emerald-500/60 to-emerald-400/40 ring-1 ring-emerald-500/20" />
                <div className="min-w-0">
                  <div className="text-sm truncate">{e.title}</div>
                  <div className="text-xs text-neutral-500">{e.repo} • {e.when}</div>
                </div>
                <div className="ml-auto text-xs text-neutral-400">{e.type}</div>
              </div>
            ))}
          </div>
        </section>

        {/* Row 3: Workflow Heatmap */}
        <section className="col-span-12 bg-neutral-900/60 border border-neutral-800 rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-neutral-300">Workflow Failures Heatmap</h3>
            <div className="text-xs text-neutral-500">red = failing • green = passing</div>
          </div>
          <Heatmap rows={data.heatmap.rows} cols={data.heatmap.cols} values={data.heatmap.values} />
        </section>

        {/* Row 4: Repos table */}
        <section className="col-span-12 bg-neutral-900/60 border border-neutral-800 rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-neutral-300">Repositories (Top activity)</h3>
            <div className="text-xs text-neutral-500">click a row to open repo</div>
          </div>
          <div className="overflow-auto">
            <table className="w-full text-sm">
              <thead className="text-neutral-400 sticky top-0 bg-neutral-900/80">
                <tr className="[&>th]:py-2 [&>th]:px-2 text-left">
                  <th>Repo</th><th className="text-right">⭐</th><th className="text-right">PRs</th><th className="text-right">Issues</th><th className="text-right">Checks</th><th className="text-right">Activity</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-neutral-800">
                {data.repos.map((r)=>(
                  <tr key={r.name} className="hover:bg-neutral-950/60 cursor-pointer">
                    <td className="py-2 px-2 font-medium text-neutral-200">{r.name}</td>
                    <td className="py-2 px-2 text-right">{r.stars}</td>
                    <td className="py-2 px-2 text-right">{r.prs}</td>
                    <td className="py-2 px-2 text-right">{r.issues}</td>
                    <td className="py-2 px-2 text-right">
                      <span className={"inline-block h-2 w-2 rounded-full " + (r.checks ? "bg-emerald-500" : "bg-rose-500")}></span>
                    </td>
                    <td className="py-2 px-2">
                      <Sparkline points={r.spark} className="h-7" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </div>
  );
}