import * as React from "react";
import { Card } from "../components/Card";
import type { DashboardData } from "../lib/github";

export default function Security({data}:{data:DashboardData}){
  const s = data.security;
  const toTone = (n:number)=> n===0? "pill-ok" : n<3? "pill-warn":"pill-err";
  return (
    <Card title="Security Alerts">
      <div className="grid grid-cols-3 gap-3">
        <div className={"pill text-center "+toTone(s.dependabot)}>Dependabot {s.dependabot}</div>
        <div className={"pill text-center "+toTone(s.codeQL)}>CodeQL {s.codeQL}</div>
        <div className={"pill text-center "+toTone(s.secretScan)}>Secrets {s.secretScan}</div>
      </div>
    </Card>
  )
}