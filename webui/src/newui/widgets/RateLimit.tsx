import * as React from "react";
import { Card } from "../components/Card";
import type { DashboardData } from "../lib/github";

export default function RateLimit({data}:{data:DashboardData}){
  const r = data.ratelimit; const total=r.used+r.remaining; const pct = Math.round((r.used/Math.max(total,1))*100);
  return (
    <Card title="API Rate Limit">
      <div className="text-sm text-zinc-400 mb-2">used {r.used} / {total} (reset {new Date(r.resetAt).toLocaleTimeString()})</div>
      <div className="h-2 rounded-full overflow-hidden bg-zinc-800">
        <div className="h-full bg-gradient-to-r from-emerald-500 to-violet-500" style={{width: pct+'%'}}/>
      </div>
    </Card>
  )
}