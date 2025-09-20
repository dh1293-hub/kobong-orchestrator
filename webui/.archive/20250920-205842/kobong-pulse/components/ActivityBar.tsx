import * as React from "react";
export function ActivityBar({ items }:{ items:{label:string; value:number; tone:"emerald"|"sky"|"amber"|"rose"|"violet"}[] }) {
  const total = items.reduce((a,b)=>a+b.value,0) || 1;
  return (
    <div className="h-8 w-full overflow-hidden rounded-md border border-neutral-800 bg-neutral-950/60 flex">
      {items.map((it)=>(
        <div key={it.label}
          className={
            "h-full relative " +
            (it.tone==="emerald" ? "bg-emerald-600/80" :
             it.tone==="sky"     ? "bg-sky-600/80"     :
             it.tone==="amber"   ? "bg-amber-500/80"   :
             it.tone==="rose"    ? "bg-rose-600/80"    : "bg-violet-600/80")
          }
          style={{ width: `${(it.value/total)*100}%`}}
          title={`${it.label}: ${it.value}`}
        >
          <span className="absolute inset-0 bg-gradient-to-t from-white/5 to-transparent" />
        </div>
      ))}
    </div>
  );
}