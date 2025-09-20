import * as React from "react";
export function StatCard(props: { label:string; value:number|string; tone:"emerald"|"sky"|"amber"|"rose"|"violet"; children?:React.ReactNode }) {
  const tone = {
    emerald: "from-emerald-500/15 to-emerald-400/5 ring-emerald-500/30",
    sky:     "from-sky-500/15 to-sky-400/5 ring-sky-500/30",
    amber:   "from-amber-500/15 to-amber-400/5 ring-amber-500/30",
    rose:    "from-rose-500/15 to-rose-400/5 ring-rose-500/30",
    violet:  "from-violet-500/15 to-violet-400/5 ring-violet-500/30"
  }[props.tone];
  return (
    <div className={"relative h-full rounded-2xl border border-neutral-800 bg-neutral-900/60 p-4 ring-1 ring-inset "+tone+" shadow-[0_0_0_1px_#262626,0_10px_40px_-12px_rgba(16,185,129,.25)]"}>
      <div className="text-xs text-neutral-400">{props.label}</div>
      <div className="mt-1 text-2xl font-semibold">{props.value}</div>
      <div className="mt-2">{props.children}</div>
      <div className="pointer-events-none absolute inset-0 rounded-2xl bg-gradient-to-br from-white/3 via-transparent to-transparent opacity-20" />
    </div>
  );
}