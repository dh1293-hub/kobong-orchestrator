import * as React from "react";
export function Heatmap({ rows, cols, values }: { rows:string[]; cols:string[]; values:number[][] }) {
  return (
    <div className="overflow-auto">
      <table className="w-full text-xs">
        <thead>
          <tr>
            <th className="sticky left-0 bg-neutral-900/80 text-left p-2">Workflow \\ Repo</th>
            {cols.map(c=> <th key={c} className="p-2 text-neutral-400">{c}</th>)}
          </tr>
        </thead>
        <tbody>
          {rows.map((r,ri)=>(
            <tr key={r} className="border-t border-neutral-800">
              <td className="sticky left-0 bg-neutral-900/80 p-2 font-medium text-neutral-300">{r}</td>
              {cols.map((c,ci)=>{
                const v = values[ri][ci];
                const clr = v>=0.8 ? "bg-emerald-600" : v>=0.5 ? "bg-emerald-500/70" : v>=0.2 ? "bg-amber-500/70" : "bg-rose-600/80";
                return <td key={c} className="p-1"><div className={"h-5 rounded-sm " + clr} title={`${r} @ ${c} : ${Math.round(v*100)}%`} /></td>;
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}