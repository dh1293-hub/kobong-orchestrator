import * as React from "react";
import { HeaderBar } from "./components/Header";
import Overview from "./widgets/Overview";
import Workflows from "./widgets/Workflows";
import PRQueue from "./widgets/PRQueue";
import Issues from "./widgets/Issues";
import Releases from "./widgets/Releases";
import Security from "./widgets/Security";
import RateLimit from "./widgets/RateLimit";
import { makeFakeData, type DashboardData } from "./lib/github";

export default function AppDashboard(){
  const [org,setOrg] = React.useState("kobong-labs");
  const [repo,setRepo] = React.useState("orchestrator");
  const [range,setRange] = React.useState("24h");
  const [data,setData] = React.useState<DashboardData>(makeFakeData());

  // fake live updates
  React.useEffect(()=>{
    const t = setInterval(()=> setData(makeFakeData()), 5000);
    return ()=>clearInterval(t);
  },[]);

  return (
    <div className="min-h-screen">
      <HeaderBar org={org} repo={repo} onOrg={setOrg} onRepo={setRepo} range={range} onRange={setRange} />
      <main className="mx-auto max-w-[1800px] p-6 space-y-4">
        <div className="auto-grid">
          <Overview data={data} />
          <Workflows data={data} />
          <PRQueue data={data} />
          <Issues data={data} />
          <Releases data={data} />
          <Security data={data} />
          <RateLimit data={data} />
        </div>
      </main>
    </div>
  );
}