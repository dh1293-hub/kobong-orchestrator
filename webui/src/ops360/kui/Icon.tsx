import * as React from "react";
type P = React.SVGProps<SVGSVGElement> & { size?: number|string };
const S = { sw: 2, cap: "round" as const, join: "round" as const };
const svg = (name:string, children:React.ReactNode, p:P) => (
  <svg role="img" aria-label={name} width={p.size ?? 18} height={p.size ?? 18} viewBox="0 0 24 24" {...p}>{children}</svg>
);
export const IcBranch = (p:P)=> svg("branch", <>
  <circle cx="6" cy="6" r="2" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <circle cx="6" cy="18" r="2" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <circle cx="18" cy="6" r="2" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <path d="M8 6h6M6 8v8" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}/>
</>, p);
export const IcPR = (p:P)=> svg("pr", <>
  <path d="M6 6v12" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap}/>
  <circle cx="6" cy="6" r="2" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <circle cx="6" cy="18" r="2" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <path d="M10 12h4" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap}/>
  <circle cx="18" cy="12" r="2" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
</>, p);
export const IcIssue = (p:P)=> svg("issue", <>
  <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <line x1="12" y1="8" x2="12" y2="12" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap}/>
  <circle cx="12" cy="16" r="1.2" fill="currentColor" />
</>, p);
export const IcRun = (p:P)=> svg("run", <>
  <rect x="3" y="5" width="18" height="14" rx="2" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <polygon points="10,9 16,12 10,15" fill="currentColor" />
</>, p);
export const IcClock = (p:P)=> svg("clock", <>
  <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <path d="M12 7v5h4" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap}/>
</>, p);
export const IcAlert = (p:P)=> svg("alert", <>
  <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" strokeWidth={S.sw}/>
  <line x1="12" y1="8" x2="12" y2="12" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap}/>
  <circle cx="12" cy="16" r="1.2" fill="currentColor"/>
</>, p);
export const IcStar = (p:P)=> svg("star", <>
  <path d="M12 3l2.9 5.9L21 10l-4.5 4.2L17.8 21 12 17.8 6.2 21l1.3-6.8L3 10l6.1-1.1L12 3z" fill="currentColor"/>
</>, p);