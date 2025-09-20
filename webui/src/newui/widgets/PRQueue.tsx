import * as React from "react";
import { Card } from "../components/Card";
import type { DashboardData } from "../lib/github";

export default function PRQueue({data}:{data:DashboardData}){
  return (
    <Card title="PR Queue" right={<span className="badge">{data.prs.length} open</span>} className="row-span-2">
      <div className="space-y-2">
        {data.prs.map(pr=>(
          <div key={pr.id} className="flex items-center gap-3">
            <div className="shrink-0 w-8 h-8 rounded-full bg-zinc-800 grid place-items-center text-xs">{pr.author.slice(0,2).toUpperCase()}</div>
            <div className="min-w-0">
              <div className="truncate text-sm">{pr.title}</div>
              <div className="text-[11px] text-zinc-400">{pr.ageH}h • {pr.labels.join(", ")} {pr.draft? "• draft": ""}</div>
            </div>
            <div className="ml-auto">
              <span className="pill pill-ok">review</span>
            </div>
          </div>
        ))}
      </div>
    </Card>
  )
}