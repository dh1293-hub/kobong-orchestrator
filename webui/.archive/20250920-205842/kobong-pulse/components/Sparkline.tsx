import * as React from "react";
export function Sparkline({ points, className }: { points:number[]; className?:string }) {
  const h = 40, w = 140;
  const max = Math.max(...points), min = Math.min(...points);
  const norm = (v:number)=> (max-min===0? 0.5 : (v-min)/(max-min));
  const d = points.map((v,i)=>{
    const x = (i/(points.length-1))*w;
    const y = h - norm(v)*h;
    return (i===0? "M":"L")+x+" "+y;
  }).join(" ");
  return (
    <svg className={className??""} viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
      <path d={d} fill="none" stroke="currentColor" strokeOpacity="0.9" strokeWidth="2"/>
      <defs><linearGradient id="glow" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="currentColor" stopOpacity="0.35"/><stop offset="100%" stopColor="currentColor" stopOpacity="0"/></linearGradient></defs>
      <path d={d + ` L ${w} ${h} L 0 ${h} Z`} fill="url(#glow)" />
    </svg>
  );
}