import * as React from "react";
export function TinyBars({ data, className = "" }: { data: number[]; className?: string; }) {
  const max = Math.max(...data, 1);
  return (
    <div className={"flex items-end gap-[3px] h-10 " + className}>
      {data.map((v, i) => (
        <div key={i} className="w-[6px] rounded-sm bg-emerald-400/80" style={{ height: `${6 + (v/max)*28}px` }} />
      ))}
    </div>
  );
}