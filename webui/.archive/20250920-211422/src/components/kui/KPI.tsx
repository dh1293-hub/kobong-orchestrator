import * as React from "react";
export function KPI({ label, value, delta, good = true }: { label: string; value: React.ReactNode; delta?: string; good?: boolean; }) {
  return (
    <div className="glass rounded-xl px-4 py-3 flex items-center justify-between">
      <div>
        <div className="text-[11px] uppercase tracking-wide text-white/60">{label}</div>
        <div className="text-xl font-bold">{value}</div>
      </div>
      {delta && (
        <div className={"text-xs font-semibold px-2 py-1 rounded-md " + (good ? "bg-emerald-500/15 text-emerald-300" : "bg-rose-500/15 text-rose-300")}>
          {delta}
        </div>
      )}
    </div>
  );
}