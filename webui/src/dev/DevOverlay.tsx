import * as React from "react";
type Row = { t: string; m: string };
export default function DevOverlay(){
  const [rows,setRows]=React.useState<Row[]>([{t:"status",m:"DevOverlay mounted"}]);
  React.useEffect(()=>{
    function push(t:string,m:any){
      const msg = (m && (m.stack || m.message)) ? (m.stack || m.message) : String(m);
      setRows(r=>{ const a=[...r,{t, m: msg}]; return a.slice(-12); });
    }
    const onErr = (e: ErrorEvent)=>{ push("error", e.error || e.message); };
    const onRej = (e: PromiseRejectionEvent)=>{ push("unhandledrejection", e.reason); };
    window.addEventListener("error", onErr);
    window.addEventListener("unhandledrejection", onRej);
    return ()=>{
      window.removeEventListener("error", onErr);
      window.removeEventListener("unhandledrejection", onRej);
    };
  },[]);
  const box: React.CSSProperties = {position:"fixed",bottom:8,left:8,background:"rgba(0,0,0,.75)",color:"#fff",fontFamily:"ui-monospace, SFMono-Regular, Menlo, Consolas, monospace",fontSize:12,padding:"8px 10px",borderRadius:8,maxWidth:520,zIndex:9999,whiteSpace:"pre-wrap"};
  return <div style={box}>{rows.map((r,i)=><div key={i}>[ {r.t} ] {r.m}</div>)}</div>;
}