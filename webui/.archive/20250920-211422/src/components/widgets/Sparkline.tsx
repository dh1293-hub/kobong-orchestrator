import * as React from "react";
export function Sparkline({ data, w=120, h=36, fill=false }: { data:number[]; w?:number; h?:number; fill?:boolean }) {
  const max = Math.max(...data,1), min = Math.min(...data,0);
  const pts = data.map((v,i)=>[ (i/(data.length-1))*w, h - ((v-min)/(max-min||1))*h ]);
  const d = pts.map((p,i)=>(i?"L":"M")+p[0].toFixed(2)+","+p[1].toFixed(2)).join(" ");
  const fillD = `M0,${h} `+d+` L ${w},${h} Z`;
  return (<svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
    {fill && <path d={fillD} fill="currentColor" opacity="0.15" />}
    <path d={d} fill="none" stroke="currentColor" strokeWidth="2" />
  </svg>);
}