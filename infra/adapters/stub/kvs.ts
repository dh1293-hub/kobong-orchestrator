import { KeyValueStorePort } from "../../../domain/ports/kvs";
import { createJsonlLogger } from "../../logging/jsonlLogger";

const log = createJsonlLogger({ defaultModule: "infra.stub.kvs" }).with({ module: "infra.stub.kvs" });

export class InMemoryKVS implements KeyValueStorePort {
  private store = new Map<string, { value: unknown; expiresAt?: number }>();

  async get<T = unknown>(key: string): Promise<T | undefined> {
    const rec = this.store.get(key);
    const now = Date.now();
    if (!rec) return undefined;
    if (rec.expiresAt && rec.expiresAt < now) {
      this.store.delete(key);
      return undefined;
    }
    await log.log({ module: "infra.stub.kvs", level: "DEBUG", action: "kvs.get", message: "hit", meta: { key } });
    return rec.value as T;
  }

  async set<T = unknown>(key: string, value: T, ttlSec?: number): Promise<void> {
    const expiresAt = ttlSec ? Date.now() + ttlSec * 1000 : undefined;
    this.store.set(key, { value, expiresAt });
    await log.log({ module: "infra.stub.kvs", level: "DEBUG", action: "kvs.set", message: "ok", meta: { key, ttlSec } });
  }

  async del(key: string): Promise<void> {
    this.store.delete(key);
    await log.log({ module: "infra.stub.kvs", level: "DEBUG", action: "kvs.del", message: "ok", meta: { key } });
  }
}

