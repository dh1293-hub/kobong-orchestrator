import * as React from "react";
import { Card } from "../components/Card";
import type { DashboardData } from "../lib/github";

export default function Releases({data}:{data:DashboardData}){
  return (
    <Card title="Releases">
      <div className="space-y-2">
        {data.releases.map((r,i)=>(
          <div key={i} className="flex items-center justify-between">
            <div className="text-sm">{r.tag}</div>
            <div className="text-xs text-zinc-400">{new Date(r.publishedAt).toLocaleString()}</div>
            <div className={"pill "+(r.prerelease? "pill-warn":"pill-ok")}>{r.prerelease? "pre" : "stable"}</div>
          </div>
        ))}
      </div>
    </Card>
  )
}