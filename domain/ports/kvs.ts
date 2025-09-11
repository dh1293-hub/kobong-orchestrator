export interface KeyValueStorePort {
  get: <T = unknown>(key: string) => Promise<T | undefined>;
  set: <T = unknown>(key: string, value: T, ttlSec?: number) => Promise<void>;
  del: (key: string) => Promise<void>;
}
