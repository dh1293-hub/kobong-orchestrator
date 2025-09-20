import * as React from "react";
export function Sparkline({ data, className = "" }: { data: number[]; className?: string; }) {
  const w = 160, h = 42, pad = 4;
  const min = Math.min(...data), max = Math.max(...data);
  const xs = data.map((_, i) => pad + (i*(w-2*pad))/(data.length-1 || 1));
  const ys = data.map(v => h - pad - ((v - min) / ((max - min) || 1)) * (h - 2*pad));
  const d  = xs.map((x, i) => `${i ? "L" : "M"}${x},${ys[i]}`).join(" ");
  return (
    <svg viewBox={`0 0 ${w} ${h}`} className={"w-full h-10 " + className}>
      <path d={d} fill="none" stroke="hsl(var(--accent))" strokeWidth="2"/>
      {xs.length>0 && <circle cx={xs.at(-1)!} cy={ys.at(-1)!} r="2.5" fill="hsl(var(--accent))" />}
    </svg>
  );
}