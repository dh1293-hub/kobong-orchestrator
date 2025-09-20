import * as React from "react";
type IconProps = React.SVGProps<SVGSVGElement> & { size?: number | string };
const createIcon = (name: string) => (props: IconProps) => (
  <svg role="img" aria-label={name} width={props.size ?? 24} height={props.size ?? 24} viewBox="0 0 24 24" {...props}>
    <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" />
  </svg>
);export const AlertCircle = createIcon('AlertCircle');
export const ArrowDown = createIcon('ArrowDown');
export const ArrowRight = createIcon('ArrowRight');
export const ArrowUp = createIcon('ArrowUp');
export const Bot = createIcon('Bot');
export const Calendar = createIcon('Calendar');
export const CheckCircle2 = createIcon('CheckCircle2');
export const CircleDot = createIcon('CircleDot');
export const Clock3 = createIcon('Clock3');
export const CloudLightning = createIcon('CloudLightning');
export const GitBranch = createIcon('GitBranch');
export const GitCommit = createIcon('GitCommit');
export const GitGraph = createIcon('GitGraph');
export const GitPullRequest = createIcon('GitPullRequest');
export const GitPullRequestClosed = createIcon('GitPullRequestClosed');
export const Info = createIcon('Info');
export const Layers = createIcon('Layers');
export const LifeBuoy = createIcon('LifeBuoy');
export const Link = createIcon('Link');
export const ListFilter = createIcon('ListFilter');
export const Loader2 = createIcon('Loader2');
export const Lock = createIcon('Lock');
export const Settings = createIcon('Settings');
export const TimerReset = createIcon('TimerReset');
export const TrendingDown = createIcon('TrendingDown');
export const TrendingUp = createIcon('TrendingUp');
export const UploadCloud = createIcon('UploadCloud');
export const Users = createIcon('Users');
const _ns: any = new Proxy({}, { get: (_t, k) => createIcon(String(k)) });
export default _ns;