import * as React from "react";
export function Heatmap({ rows, cols, values, w=240, h=120 }:{rows:number;cols:number;values:number[];w?:number;h?:number}) {
  const cw=w/cols,ch=h/rows; const max=Math.max(...values,1);
  return (<svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
    {Array.from({length:rows}).map((_,r)=>
      Array.from({length:cols}).map((_,c)=>{
        const v=values[r*cols+c]??0, t=v/max, L=20+(1-t)*35, H=160-t*60, S=60;
        return <rect key={`${r}-${c}`} x={c*cw} y={r*ch} width={cw-1} height={ch-1} fill={`hsl(${H} ${S}% ${L}%)`} rx={2}/>;
      })
    )}
  </svg>);
}