import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
const LEVEL_ORDER = { DEBUG: 10, INFO: 20, WARN: 30, ERROR: 40 };
function ensureDir(filePath) {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir))
        fs.mkdirSync(dir, { recursive: true });
}
function redactPII(value) {
    const redactEmail = (s) => s.replace(/([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\.[A-Za-z]{2,})/g, "***@***");
    const redactPhone = (s) => s.replace(/\+?\d[\d\s-]{7,}\d/g, "[REDACTED_PHONE]");
    if (typeof value === "string")
        return redactPhone(redactEmail(value));
    if (Array.isArray(value))
        return value.map(redactPII);
    if (value && typeof value === "object") {
        const out = {};
        for (const [k, v] of Object.entries(value))
            out[k] = redactPII(v);
        return out;
    }
    return value;
}
function toISO() {
    return new Date().toISOString();
}
function sha256(obj) {
    const json = JSON.stringify(obj ?? "");
    return crypto.createHash("sha256").update(json).digest("hex");
}
export function createJsonlLogger(opts) {
    const filePath = opts?.filePath ?? process.env.LOG_FILE ?? "logs/app.log";
    const minLevel = opts?.level ?? (process.env.LOG_LEVEL || "INFO");
    const defaultModule = opts?.defaultModule ?? "unknown";
    ensureDir(filePath);
    async function appendLine(line) {
        await fs.promises.appendFile(filePath, line + "\n", { encoding: "utf8" });
    }
    function shouldLog(level) {
        return LEVEL_ORDER[level] >= LEVEL_ORDER[minLevel];
    }
    const base = { module: defaultModule };
    const logger = {
        async log(event) {
            const ts = toISO();
            const traceId = event.traceId || crypto.randomUUID();
            const out = {
                timestamp: ts,
                level: event.level,
                traceId,
                module: event.module ?? base.module,
                action: event.action,
                inputHash: event.inputHash,
                outcome: event.outcome,
                durationMs: event.durationMs,
                errorCode: event.errorCode,
                message: event.message,
                meta: redactPII(event.meta)
            };
            if (!out.inputHash && out.meta && "input" in out.meta) {
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                try {
                    out.inputHash = sha256(out.meta.input);
                }
                catch { /* noop */ }
            }
            if (shouldLog(out.level)) {
                await appendLine(JSON.stringify(out));
            }
        },
        with(scope) {
            const scoped = createJsonlLogger({
                filePath,
                level: minLevel,
                defaultModule: scope.module ?? base.module
            });
            return {
                ...scoped,
                log: (e) => scoped.log({ ...e, traceId: scope.traceId ?? e.traceId })
            };
        }
    };
    return logger;
}
