import * as React from "react";

type IconProps = React.SVGProps<SVGSVGElement> & { size?: number | string };

// --- primitives ---
const S = { sw: 2, cap: 'round' as const, join: 'round' as const };

function P(p: React.SVGProps<SVGPathElement>) { return <path fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join} {...p}/>; }
function L(p: React.SVGProps<SVGLineElement>) { return <line stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join} {...p}/>; }
function C(p: React.SVGProps<SVGCircleElement>) { return <circle fill="none" stroke="currentColor" strokeWidth={S.sw} {...p}/>; }
function G(p: React.SVGProps<SVGGElement>) { return <g fill="none" stroke="currentColor" strokeWidth={S.sw} strokeLinecap={S.cap} strokeLinejoin={S.join} {...p}/>; }
function R(p: React.SVGProps<SVGRectElement>) { return <rect fill="none" stroke="currentColor" strokeWidth={S.sw} rx={2} {...p}/>; }

const createIcon = (name: string) => (props: IconProps) => (
  <svg role="img" aria-label={name} width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props} />
);

// --- concrete icons (hand-tuned to resemble lucide) ---
export const AlertCircle = (props: IconProps) => (
  <svg role="img" aria-label="AlertCircle" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="12" cy="12" r="10"/><L x1="12" y1="8" x2="12" y2="12"/><C cx="12" cy="16" r="1" stroke="currentColor" />
  </svg>
);

export const ArrowRight = (props: IconProps) => (
  <svg role="img" aria-label="ArrowRight" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <L x1="5" y1="12" x2="19" y2="12"/><P d="M12 5l7 7-7 7"/>
  </svg>
);
export const ArrowUp = (props: IconProps) => (
  <svg role="img" aria-label="ArrowUp" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <L x1="12" y1="19" x2="12" y2="5"/><P d="M5 12l7-7 7 7"/>
  </svg>
);
export const ArrowDown = (props: IconProps) => (
  <svg role="img" aria-label="ArrowDown" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <L x1="12" y1="5" x2="12" y2="19"/><P d="M19 12l-7 7-7-7"/>
  </svg>
);

export const Bot = (props: IconProps) => (
  <svg role="img" aria-label="Bot" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <R x="5" y="9" width="14" height="10" rx="2"/><C cx="9" cy="14" r="1"/><C cx="15" cy="14" r="1"/><L x1="12" y1="5" x2="12" y2="3"/><C cx="12" cy="3" r="1"/>
  </svg>
);

export const Calendar = (props: IconProps) => (
  <svg role="img" aria-label="Calendar" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <R x="3" y="4" width="18" height="18" rx="2"/><L x1="16" y1="2" x2="16" y2="6"/><L x1="8" y1="2" x2="8" y2="6"/><L x1="3" y1="10" x2="21" y2="10"/>
  </svg>
);

export const CheckCircle2 = (props: IconProps) => (
  <svg role="img" aria-label="CheckCircle2" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="12" cy="12" r="10"/><P d="M9 12l2 2 4-5"/>
  </svg>
);

export const CircleDot = (props: IconProps) => (
  <svg role="img" aria-label="CircleDot" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="12" cy="12" r="10"/><C cx="12" cy="12" r="2"/>
  </svg>
);

export const Clock3 = (props: IconProps) => (
  <svg role="img" aria-label="Clock3" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="12" cy="12" r="10"/><P d="M12 7v5l4 0"/>
  </svg>
);

export const CloudLightning = (props: IconProps) => (
  <svg role="img" aria-label="CloudLightning" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <P d="M17.5 19a4.5 4.5 0 0 0 0-9 5.5 5.5 0 0 0-10.5 1A4 4 0 0 0 7 19Z"/><P d="M13 11l-2 3h3l-2 3"/>
  </svg>
);

export const GitBranch = (props: IconProps) => (
  <svg role="img" aria-label="GitBranch" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="6" cy="6" r="2"/><C cx="6" cy="18" r="2"/><C cx="18" cy="6" r="2"/><P d="M8 6h6"/><P d="M6 8v8"/>
  </svg>
);

export const GitCommit = (props: IconProps) => (
  <svg role="img" aria-label="GitCommit" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <L x1="3" y1="12" x2="9" y2="12"/><C cx="12" cy="12" r="3"/><L x1="15" y1="12" x2="21" y2="12"/>
  </svg>
);

export const GitGraph = (props: IconProps) => (
  <svg role="img" aria-label="GitGraph" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="6" cy="6" r="2"/><C cx="6" cy="12" r="2"/><C cx="18" cy="18" r="2"/><P d="M6 8v2a4 4 0 0 0 4 4h4"/>
  </svg>
);

export const Loader2 = (props: IconProps) => (
  <svg role="img" aria-label="Loader2" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="12" cy="12" r="9" strokeOpacity="0.25"/><P d="M21 12a9 9 0 0 1-9 9" />
  </svg>
);

export const Plus = (props: IconProps) => (
  <svg role="img" aria-label="Plus" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <L x1="12" y1="5" x2="12" y2="19"/><L x1="5" y1="12" x2="19" y2="12"/>
  </svg>
);

export const Search = (props: IconProps) => (
  <svg role="img" aria-label="Search" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <C cx="11" cy="11" r="7"/><L x1="21" y1="21" x2="16.65" y2="16.65"/>
  </svg>
);

export const Settings = (props: IconProps) => (
  <svg role="img" aria-label="Settings" width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <P d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"/>
    <P d="M19.4 15a1 1 0 0 0 .2-1.1l-1-1.7a7.9 7.9 0 0 0 0-1.4l1-1.7a1 1 0 0 0-.2-1.1l-1.1-1.1a1 1 0 0 0-1.1-.2l-1.7 1a7.9 7.9 0 0 0-1.4 0l-1.7-1a1 1 0 0 0-1.1.2L9 5.3a1 1 0 0 0-.2 1.1l1 1.7a7.9 7.9 0 0 0 0 1.4l-1 1.7a1 1 0 0 0 .2 1.1l1.1 1.1a1 1 0 0 0 1.1.2l1.7-1a7.9 7.9 0 0 0 1.4 0l1.7 1a1 1 0 0 0 1.1-.2Z"/>
  </svg>
);

// fallback: any unknown name → generic circle icon
const _ns: any = new Proxy({}, { get: (_t, k) => createIcon(String(k)) });
export default _ns;
export const GitPullRequest = createIcon('GitPullRequest');
export const GitPullRequestClosed = createIcon('GitPullRequestClosed');
export const Info = createIcon('Info');
export const Layers = createIcon('Layers');
export const LifeBuoy = createIcon('LifeBuoy');
export const Link = createIcon('Link');
export const ListFilter = createIcon('ListFilter');
export const Lock = createIcon('Lock');
export const TimerReset = createIcon('TimerReset');
export const TrendingDown = createIcon('TrendingDown');
export const TrendingUp = createIcon('TrendingUp');
export const UploadCloud = createIcon('UploadCloud');
export const Users = createIcon('Users');
