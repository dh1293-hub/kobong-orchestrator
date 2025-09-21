import React from "react";
import { getTokenMeta, getCurrentGhEndpoint, resetGhCache, pingBridgeHealth, DEFAULT_OWNER, DEFAULT_REPO } from "../services/github";

export default function StatusPage(){
  const [m,setM] = React.useState<any>(null);
  const [health,setHealth] = React.useState<any>(null);
  const [ts,setTs] = React.useState<string>("");

  async function load(){
    const meta = await getTokenMeta();
    setM(meta); setTs(new Date().toLocaleString());
    if((meta.base||"").includes("localhost") || (meta.base||"").includes("127.0.0.1")){
      setHealth(await pingBridgeHealth());
    } else { setHealth({ ok:false, status:0 }); }
  }
  React.useEffect(()=>{ load(); },[]);

  const endpoint = getCurrentGhEndpoint();
  const rateStr  = m?.rate ? `${m.rate.remaining}/${m.rate.limit}` : "…";
  const scopes   = (m?.scopes?.length ? m.scopes.join(", ") : (m?.present ? "(classic or hidden scopes)" : "—"));

  return (
    <div style={{maxWidth:900,margin:"30px auto",padding:"0 16px",display:"flex",flexDirection:"column",gap:16}}>
      <div style={{display:"flex", alignItems:"center", justifyContent:"space-between"}}>
        <h1 style={{margin:0,fontSize:26}}>Status</h1>
        <div style={{display:"flex",gap:8}}>
          <a href="/github.html" style={{padding:"6px 12px",border:"1px solid #e5e7eb",borderRadius:8,background:"#fff"}}>← GitHub 모니터</a>
          <button onClick={()=>{ resetGhCache(); alert("캐시 비웠습니다."); }} style={{padding:"6px 12px",border:"1px solid #e5e7eb",borderRadius:8,background:"#fff"}}>캐시 비우기</button>
          <button onClick={load} style={{padding:"6px 12px",border:"1px solid #e5e7eb",borderRadius:8,background:"#fff"}}>새로고침</button>
        </div>
      </div>

      <div style={{padding:"10px 12px",border:"1px solid #e5e7eb",borderRadius:10,background:"#fafafa"}}>
        <div style={{fontSize:13,color:"#374151"}}><b>endpoint:</b> {endpoint}</div>
        <div style={{fontSize:13,color:"#374151"}}><b>token present:</b> {String(!!m?.present)}</div>
        <div style={{fontSize:13,color:"#374151"}}><b>user:</b> {m?.user?.login ?? "—"}</div>
        <div style={{fontSize:13,color:"#374151"}}><b>scopes:</b> {scopes}</div>
        <div style={{fontSize:13,color:"#374151"}}><b>rate(core):</b> {rateStr}</div>
        <div style={{fontSize:12,color:"#6b7280"}}>{ts && `업데이트: ${ts}`}</div>
      </div>

      <div style={{padding:"10px 12px",border:"1px solid #e5e7eb",borderRadius:10}}>
        <div style={{fontSize:13,color:"#6b7280",marginBottom:6}}>Bridge Health</div>
        {health?.status ? (
          <div>status: <b>{health.status}</b> — {health?.ok ? "OK" : "NG"}</div>
        ) : <div>로컬 브리지 아님 또는 체크 불가</div>}
      </div>

      <div style={{fontSize:12,color:"#9ca3af"}}>기본 리포: {DEFAULT_OWNER}/{DEFAULT_REPO}</div>
    </div>
  );
}
