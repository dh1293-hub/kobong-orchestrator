import * as React from "react";
import { Card, Stat, Sparkline } from "../components/Card";
import type { DashboardData } from "../lib/github";

export default function Overview({data}:{data:DashboardData}) {
  const s = data.summary;
  return (
    <Card title="Overview" right={<div className="flex gap-2">
      <span className="badge">Issues {s.openIssues}</span>
      <span className="badge">PRs {s.openPRs}</span>
    </div>} className="row-span-2">
      <div className="grid grid-cols-4 gap-6">
        <Stat label="Stars" value={s.stars.toLocaleString()} trend="up" />
        <Stat label="Forks" value={s.forks.toLocaleString()} trend="flat" />
        <Stat label="Watchers" value={s.watchers.toLocaleString()} trend="flat" />
        <Stat label="Open PRs" value={s.openPRs} trend="up" />
      </div>
      <div className="mt-6 grid grid-cols-3 gap-6">
        <div>
          <div className="text-xs text-zinc-400 mb-2">Stars (24h)</div>
          <Sparkline points={data.starsTrend}/>
        </div>
        <div>
          <div className="text-xs text-zinc-400 mb-2">Commits (24h)</div>
          <Sparkline points={data.commitsTrend}/>
        </div>
        <div>
          <div className="text-xs text-zinc-400 mb-2">Issues (24h)</div>
          <Sparkline points={data.issuesTrend}/>
        </div>
      </div>
    </Card>
  );
}