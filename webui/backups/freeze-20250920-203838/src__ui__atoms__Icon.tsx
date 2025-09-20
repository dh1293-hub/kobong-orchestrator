import * as React from "react";
export type IconName =
  | "Star" | "Fork" | "Watch" | "PR"
  | "Build" | "Fail" | "Warn" | "Info"
  | "Shield" | "Rocket" | "Search" | "Settings"
  | "Git" | "Branch" | "Commit";

export function Icon({ name, className="", size=20 }: { name: IconName | string; className?: string; size?: number }) {
  const sz = { width: size, height: size };
  const C = (p:any)=> <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth={2} {...p}/>;
  const L = (p:any)=> <line stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" {...p}/>;
  const P = (p:any)=> <path fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" {...p}/>;
  const map: Record<string, JSX.Element> = {
    Star:     (<><P d="M12 3l3 6 6 .9-4.5 4.2 1 6L12 17l-5.5 3.1 1-6L3 9.9 9 9z"/></>),
    Fork:     (<><C/><P d="M6 6v6a6 6 0 0 0 6 6h0M18 6v6"/></>),
    Watch:    (<><P d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" strokeWidth={2}/></> as any),
    PR:       (<><C/><P d="M8 7v6a4 4 0 0 0 4 4h4"/><circle cx="8" cy="7" r="2" fill="none" stroke="currentColor" strokeWidth={2}/><circle cx="16" cy="17" r="2" fill="none" stroke="currentColor" strokeWidth={2}/></>),
    Build:    (<><C/><P d="M4 14h16M4 10h10"/></>),
    Fail:     (<><C/><P d="M8 8l8 8M16 8l-8 8"/></>),
    Warn:     (<><P d="M12 3l9 16H3z"/><P d="M12 9v4"/><circle cx="12" cy="16" r="1" fill="none" stroke="currentColor" strokeWidth={2}/></>),
    Info:     (<><C/><P d="M12 10v6"/><circle cx="12" cy="7" r="1" fill="none" stroke="currentColor" strokeWidth={2}/></>),
    Shield:   (<><P d="M12 3l8 3v6c0 5-4 7-8 9-4-2-8-4-8-9V6z"/></>),
    Rocket:   (<><P d="M12 2c4 2 6 6 6 10v6l-6-2-6 2v-6C6 8 8 4 12 2z"/></>),
    Search:   (<><C/><L x1="21" y1="21" x2="16.5" y2="16.5"/></>),
    Settings: (<><P d="M19.4 15.1l.2-1.1-1-1.7 1-1.7-.2-1.1-1.1-1.1-1.7 1-1.4 0-1.7-1-1.1.2-1.1 1.1 1 1.7 0 1.4-1 1.7 1.1 1.1 1.1-.2 1.7 1 1.4 0 1.7-1 1.1-1.1z"/><circle cx="12" cy="12" r="3.5" fill="none" stroke="currentColor" strokeWidth={2}/></>),
    Git:      (<><P d="M5 5l14 14"/><circle cx="7" cy="7" r="2" fill="none" stroke="currentColor" strokeWidth={2}/><circle cx="17" cy="17" r="2" fill="none" stroke="currentColor" strokeWidth={2}/></>),
    Branch:   (<><circle cx="6" cy="6" r="2" fill="none" stroke="currentColor" strokeWidth={2}/><circle cx="6" cy="18" r="2" fill="none" stroke="currentColor" strokeWidth={2}/><circle cx="18" cy="6" r="2" fill="none" stroke="currentColor" strokeWidth={2}/><P d="M8 6h6M6 8v8"/></>),
    Commit:   (<><L x1="3" y1="12" x2="9" y2="12"/><circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" strokeWidth={2}/><L x1="15" y1="12" x2="21" y2="12"/></>)
  };
  return (
    <svg className={className} viewBox="0 0 24 24" {...sz} role="img" aria-label={String(name)}>
      {map[String(name)] ?? <C/>}
    </svg>
  );
}
export default Icon;