import * as React from "react";
import { Card, Sparkline } from "../components/Card";
import type { DashboardData } from "../lib/github";

export default function Issues({data}:{data:DashboardData}){
  return (
    <Card title="Issues Trend" right={<span className="badge">open {data.issuesOpen.length}</span>}>
      <Sparkline points={data.issuesTrend}/>
      <div className="mt-4 grid grid-cols-2 gap-3">
        {data.issuesOpen.slice(0,6).map(i=>(
          <div key={i.id} className="text-sm truncate">{i.title} <span className="text-[11px] text-zinc-500">• {i.ageH}h</span></div>
        ))}
      </div>
    </Card>
  )
}