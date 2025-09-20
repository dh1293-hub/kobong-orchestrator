import * as React from "react";
export function StatCard({title,subtitle,metric,delta,children,glow=false}:{title:string;subtitle?:string;metric?:string;delta?:string;children?:React.ReactNode;glow?:boolean;}){
  return (
    <div className={`relative rounded-2xl border border-zinc-800/60 bg-zinc-900/60 ${glow?'ring-1 ring-emerald-500/30 shadow-[0_0_80px_-30px_rgba(16,185,129,0.6)]':''}`}>
      <div className="p-4 md:p-5">
        <div className="flex items-center justify-between gap-3">
          <div>
            <div className="text-zinc-300 text-sm">{title}</div>
            {subtitle && <div className="text-zinc-500 text-xs">{subtitle}</div>}
          </div>
          {metric && <div className="text-2xl font-semibold text-zinc-100">{metric}</div>}
        </div>
        {delta && <div className={`mt-1 text-xs ${delta.startsWith('+')?'text-emerald-400':'text-rose-400'}`}>{delta}</div>}
        {children && <div className="mt-4">{children}</div>}
      </div>
    </div>
  );
}
export function Badge({children}:{children:React.ReactNode}){
  return <span className="inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[11px] border-zinc-700 text-zinc-300 bg-zinc-800/70">{children}</span>;
}