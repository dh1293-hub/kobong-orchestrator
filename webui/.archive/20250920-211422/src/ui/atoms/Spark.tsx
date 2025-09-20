import React from "react";

export default function Spark({points,height=32}:{points:number[];height?:number}){
  const w=Math.max(80,(points?.length||8)*10);
  const min=Math.min(...(points??[0]));
  const max=Math.max(...(points??[1]));
  const pts=(points??[]).map((v,i)=>{
    const x=(i/Math.max(points.length-1,1))*w;
    const y=height-((v-min)/Math.max(max-min,1))*height;
    return `${x},${y}`;
  }).join(' ');
  return (
    <svg viewBox={`0 0 ${w} ${height}`} height={height} className="w-full">
      <polyline points={pts} fill="none" stroke="currentColor" strokeWidth={2}/>
    </svg>
  );
}