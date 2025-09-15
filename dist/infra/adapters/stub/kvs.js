import { createJsonlLogger } from "../../logging/jsonlLogger";
const log = createJsonlLogger({ defaultModule: "infra.stub.kvs" }).with({ module: "infra.stub.kvs" });
export class InMemoryKVS {
    store = new Map();
    async get(key) {
        const rec = this.store.get(key);
        const now = Date.now();
        if (!rec)
            return undefined;
        if (rec.expiresAt && rec.expiresAt < now) {
            this.store.delete(key);
            return undefined;
        }
        await log.log({ module: "infra.stub.kvs", level: "DEBUG", action: "kvs.get", message: "hit", meta: { key } });
        return rec.value;
    }
    async set(key, value, ttlSec) {
        const expiresAt = ttlSec ? Date.now() + ttlSec * 1000 : undefined;
        this.store.set(key, { value, expiresAt });
        await log.log({ module: "infra.stub.kvs", level: "DEBUG", action: "kvs.set", message: "ok", meta: { key, ttlSec } });
    }
    async del(key) {
        this.store.delete(key);
        await log.log({ module: "infra.stub.kvs", level: "DEBUG", action: "kvs.del", message: "ok", meta: { key } });
    }
}
