import * as React from "react";
export type IconProps = React.SVGProps<SVGSVGElement> & { size?: number|string };
const S={sw:2,cap:"round" as const,join:"round" as const};
const svg=(name:string,props:IconProps,children:React.ReactNode)=>
  <svg role="img" aria-label={name} width={props.size??20} height={props.size??20} viewBox="0 0 24 24" {...props}>{children}</svg>;
export const Icon={
  Github:(p:IconProps)=>svg("Github",p,<path d="M12 .5a11.5 11.5 0 0 0-3.64 22.43c.58.11.8-.25.8-.57v-2.06c-3.26.71-3.95-1.57-3.95-1.57-.53-1.36-1.3-1.72-1.3-1.72-1.06-.73.08-.72.08-.72 1.18.08 1.8 1.22 1.8 1.22 1.04 1.79 2.73 1.27 3.4.97.11-.76.41-1.27.74-1.56-2.6-.3-5.34-1.3-5.34-5.77 0-1.28.46-2.33 1.22-3.15-.12-.3-.53-1.51.12-3.15 0 0 1-.32 3.3 1.2a11.4 11.4 0 0 1 6 0c2.3-1.52 3.3-1.2 3.3-1.2.65 1.64.24 2.85.12 3.15.76.82 1.22 1.87 1.22 3.15 0 4.48-2.74 5.47-5.36 5.76.42.36.79 1.06.79 2.14v3.17c0 .31.2.68.8.56A11.5 11.5 0 0 0 12 .5Z" fill="currentColor"/>),
  Branch:(p:IconProps)=>svg("Branch",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><circle cx="6" cy="6" r="2"/><circle cx="6" cy="18" r="2"/><circle cx="18" cy="6" r="2"/><path d="M8 6h5a3 3 0 0 1 3 3v0"/><path d="M6 8v8"/></g>),
  Commit:(p:IconProps)=>svg("Commit",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><line x1="3" y1="12" x2="9" y2="12"/><circle cx="12" cy="12" r="3"/><line x1="15" y1="12" x2="21" y2="12"/></g>),
  PR:(p:IconProps)=>svg("PR",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><circle cx="6" cy="6" r="2"/><circle cx="6" cy="18" r="2"/><path d="M8 7h7a3 3 0 0 1 3 3v8"/><circle cx="18" cy="18" r="2"/></g>),
  Issue:(p:IconProps)=>svg("Issue",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><circle cx="12" cy="12" r="10"/><line x1="12" y1="7" x2="12" y2="13"/><circle cx="12" cy="17" r="1"/></g>),
  Clock:(p:IconProps)=>svg("Clock",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><circle cx="12" cy="12" r="10"/><path d="M12 7v5l4 0"/></g>),
  Check:(p:IconProps)=>svg("Check",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><circle cx="12" cy="12" r="10"/><path d="M9 12l2 2 4-5"/></g>),
  Refresh:(p:IconProps)=>svg("Refresh",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><path d="M20 12a8 8 0 1 1-2.3-5.6"/><path d="M20 4v4h-4"/></g>),
  Search:(p:IconProps)=>svg("Search",p,<g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join}><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></g>)
};
export default Icon;