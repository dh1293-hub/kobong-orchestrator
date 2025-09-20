import * as React from "react";
export function MiniBar({ data, w=120, h=36 }:{data:number[];w?:number;h?:number}) {
  const max=Math.max(...data,1), bw=w/data.length;
  return (<svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
    {data.map((v,i)=><rect key={i} x={i*bw+1} y={h-(v/max)*h} width={Math.max(1,bw-2)} height={(v/max)*h} fill="hsl(142 72% 45%)" rx={1}/>)}
  </svg>);
}