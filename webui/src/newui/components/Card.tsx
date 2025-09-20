import * as React from "react";

export const Card: React.FC<React.PropsWithChildren<{title?: React.ReactNode; right?: React.ReactNode; className?: string;}>> = ({ title, right, className, children }) => {
  return (
    <section className={"card " + (className ?? "")}>
      {(title || right) && (
        <header className="card-header">
          <div className="card-title">{title}</div>
          <div>{right}</div>
        </header>
      )}
      <div className="card-body">{children}</div>
    </section>
  );
};

export function Stat({label, value, trend}:{label:string; value:React.ReactNode; trend?: "up"|"down"|"flat"}) {
  const tone = trend==="up" ? "text-emerald-400" : trend==="down" ? "text-rose-400" : "text-zinc-400";
  return (
    <div className="flex items-baseline gap-3">
      <div className="text-2xl font-semibold">{value}</div>
      <div className={"text-xs "+tone}>{label}</div>
    </div>
  );
}

export function Sparkline({points, height=42}:{points:number[]; height?:number}) {
  const w = Math.max(80, points.length*10);
  const max = Math.max(...points,1); const min=Math.min(...points,0);
  const norm = (v:number,i:number) => {
    const x = (i/(points.length-1||1))*w;
    const y = height - ((v-min)/(max-min||1))*height;
    return `${x},${y}`;
  };
  const d = points.map(norm).join(" ");
  return (
    <svg className="w-full" viewBox={`0 0 ${w} ${height}`} height={height}>
      <polyline className="spark" points={d} />
    </svg>
  );
}