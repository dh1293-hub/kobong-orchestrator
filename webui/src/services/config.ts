export const GH_BASE = import.meta.env.VITE_GH_BRIDGE_BASE ?? 'http://localhost:8088';
export const GH_PREFIX_ENV = import.meta.env.VITE_GH_PREFIX ?? '';
export const GH_PREFIX_CANDIDATES = [GH_PREFIX_ENV, '/github', '/api/github', '/gh', '']
  .filter((v, i, a) => v !== undefined && v !== null && a.indexOf(v) === i);
export const GH_FALLBACK_BASES = [GH_BASE, 'https://api.github.com']
  .filter((v, i, a) => !!v && a.indexOf(v) === i);
export const DEFAULT_OWNER = import.meta.env.VITE_DEFAULT_OWNER ?? 'dh1293-hub';
export const DEFAULT_REPO  = import.meta.env.VITE_DEFAULT_REPO  ?? 'kobong-orchestrator';

export const GH_TOKEN = import.meta.env.VITE_GH_TOKEN as string | undefined;

