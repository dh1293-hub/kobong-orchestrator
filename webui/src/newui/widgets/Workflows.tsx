import * as React from "react";
import { Card } from "../components/Card";
import type { DashboardData } from "../lib/github";

const tone = (s:string)=> s==="success" ? "pill-ok" : s==="failed" ? "pill-err" : s==="cancelled" ? "pill-muted" : "pill-warn";

export default function Workflows({data}:{data:DashboardData}){
  return (
    <Card title="Workflow Runs">
      <div className="space-y-2">
        {data.workflows.map((w,i)=>(
          <div key={i} className="flex items-center justify-between gap-3">
            <div className="text-sm">{w.name}</div>
            <div className={"pill "+tone(w.status)}>{w.status.replace("_"," ")}</div>
            <div className="text-xs text-zinc-400">{w.duration}m</div>
            <div className="text-xs text-zinc-500">{new Date(w.startedAt).toLocaleTimeString()}</div>
          </div>
        ))}
      </div>
    </Card>
  )
}