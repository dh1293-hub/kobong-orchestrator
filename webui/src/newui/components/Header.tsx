import * as React from "react";

export function HeaderBar({org,repo,onOrg,onRepo,range,onRange}:{org:string;repo:string;onOrg:(v:string)=>void;onRepo:(v:string)=>void;range:string;onRange:(v:string)=>void;}) {
  return (
    <div className="sticky top-0 z-10 bg-gradient-to-b from-zinc-900/90 to-zinc-900/40 backdrop-blur border-b border-zinc-800">
      <div className="mx-auto max-w-[1800px] px-6 py-4 flex flex-wrap items-center gap-3">
        <div className="text-lg font-semibold tracking-wide text-zinc-200">
          <span className="text-emerald-400">kobong</span> / GitHub Ops Monitor
        </div>
        <div className="flex-1" />
        <div className="flex items-center gap-2">
          <input className="k-input w-44" placeholder="org" value={org} onChange={e=>onOrg(e.target.value)} />
          <span className="text-zinc-500">/</span>
          <input className="k-input w-56" placeholder="repo" value={repo} onChange={e=>onRepo(e.target.value)} />
          <select className="k-select" value={range} onChange={e=>onRange(e.target.value)}>
            <option value="24h">24h</option>
            <option value="7d">7d</option>
            <option value="30d">30d</option>
          </select>
        </div>
      </div>
    </div>
  );
}