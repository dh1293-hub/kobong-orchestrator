/* eslint-disable @typescript-eslint/no-explicit-any */ // TODO(PS-12.6): type properly
import { appendFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { hrtime } from "node:process";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import { cpus } from "node:os";
const LOG_DIR = "logs";
const LOG_FILE = `${LOG_DIR}/hardening.log`;
function ensureLogDir() {
    if (!existsSync(LOG_DIR))
        mkdirSync(LOG_DIR, { recursive: true });
}
// Simple PII masking: emails + common token patterns
export function maskPII(input) {
    let out = input;
    out = out.replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, "***@***");
    out = out.replace(/\b(sk-[A-Za-z0-9_-]{12,}|bearer\s+[A-Za-z0-9_-]{12,}|token\s*=\s*[A-Za-z0-9_-]{12,})\b/gi, "***");
    out = out.replace(/\b[A-F0-9]{16,}\b/gi, "***");
    return out;
}
function log(level, message, extra = {}) {
    ensureLogDir();
    const now = new Date().toISOString();
    const entry = {
        timestamp: now,
        tz: "Asia/Seoul",
        level,
        traceId: currentTraceId,
        module: "hardening",
        action: extra["action"] ?? null,
        outcome: extra["outcome"] ?? null,
        durationMs: extra["durationMs"] ?? null,
        errorCode: extra["errorCode"] ?? null,
        app: { name: "gpt5-conductor", ver: process.env.npm_package_version ?? null },
        host: { pid: process.pid },
        message: maskPII(message),
    };
    // allow optional metrics fields
    if ("cpuPct" in extra)
        entry.cpuPct = extra["cpuPct"];
    if ("memMB" in extra)
        entry.memMB = extra["memMB"];
    appendFileSync(LOG_FILE, JSON.stringify(entry) + "\n", { encoding: "utf-8" });
}
let currentTraceId = randomUUID();
// ESM "main" detection
const isMain = (() => {
    try {
        const thisFile = fileURLToPath(import.meta.url);
        const argv1 = process.argv[1] ? resolve(process.argv[1]) : "";
        return thisFile === argv1;
    }
    catch {
        return false;
    }
})();
function parseArgs(argv) {
    const args = {};
    argv.forEach((a) => {
        const m = a.match(/^--([^=]+)=(.*)$/);
        if (m)
            args[m[1]] = m[2];
    });
    const num = (k, def) => (args[k] ? Number(args[k]) : def);
    return {
        mode: (args["mode"] ?? "baseline"),
        inject: new Set((args["inject"] ?? "").split(",").filter(Boolean)),
        intervalMs: num("intervalMs", 5000),
        durationMs: num("durationMs", 20000),
    };
}
function probeFilesystem() {
    const testPath = `${LOG_DIR}/_probe_${Date.now()}.txt`;
    writeFileSync(testPath, "probe", { encoding: "utf-8" });
    return { ok: existsSync(testPath), path: testPath };
}
function probeTimer() {
    const t0 = hrtime.bigint();
    for (let i = 0; i < 1e5; i++)
        ; // spin
    const dt = hrtime.bigint() - t0;
    return { ok: dt > 0n, ns: dt };
}
function probeMemory() {
    const rss = process.memoryUsage().rss;
    return { rss };
}
// ---------- 7-B: periodic metrics ----------
function createCpuMeter() {
    let lastCpu = process.cpuUsage();
    let lastT = hrtime.bigint();
    const cores = Math.max(1, cpus().length);
    return () => {
        const curCpu = process.cpuUsage();
        const curT = hrtime.bigint();
        const cpuMicros = (curCpu.user - lastCpu.user) + (curCpu.system - lastCpu.system); // µs
        const wallMicros = Number(curT - lastT) / 1000; // ns -> µs
        lastCpu = curCpu;
        lastT = curT;
        if (wallMicros <= 0)
            return 0;
        const pct = (cpuMicros / wallMicros) * 100 / cores;
        // clamp
        return Math.max(0, Math.min(100, pct));
    };
}
function sampleMetrics(nextCpuPct) {
    const memMB = Math.round((process.memoryUsage().rss / (1024 * 1024)) * 10) / 10;
    const cpuPct = Math.round(nextCpuPct() * 100) / 100;
    return { memMB, cpuPct };
}
async function metrics(intervalMs, durationMs) {
    const meter = createCpuMeter();
    const endAt = Date.now() + Math.max(intervalMs, durationMs);
    log("INFO", "Metrics start", { action: "metrics_start" });
    for (;;) {
        const m = sampleMetrics(meter);
        log("INFO", `metrics cpu=${m.cpuPct}% mem=${m.memMB}MB`, {
            action: "metrics",
            outcome: "ok",
            cpuPct: m.cpuPct,
            memMB: m.memMB,
        });
        const now = Date.now();
        if (now + intervalMs > endAt)
            break;
        await new Promise((r) => setTimeout(r, intervalMs));
    }
    log("INFO", "Metrics done", { action: "metrics_done", outcome: "ok" });
    return 0;
}
// -------------------------------------------
function baseline() {
    const t0 = hrtime.bigint();
    log("INFO", "Baseline start", { action: "baseline_start" });
    const fsr = probeFilesystem();
    log("INFO", `FS probe ok=${fsr.ok} path=${fsr.path}`, { action: "probe_fs", outcome: fsr.ok ? "ok" : "fail" });
    const tim = probeTimer();
    log("INFO", `Timer ns=${tim.ns.toString()}`, { action: "probe_timer", outcome: tim.ok ? "ok" : "fail" });
    const mem = probeMemory();
    log("INFO", `Memory rss=${mem.rss}`, { action: "probe_mem", outcome: "ok" });
    const dMs = Number(hrtime.bigint() - t0) / 1000000;
    log("INFO", "Baseline done", { action: "baseline_done", outcome: "ok", durationMs: Math.round(dMs) });
    return 0;
}
function fault(inject) {
    const t0 = hrtime.bigint();
    log("WARN", "Fault mode start", { action: "fault_start" });
    if (inject.has("pii")) {
        log("INFO", "contact: john.doe@example.com token=sk-ABCDEF1234567890", { action: "inject_pii" });
    }
    if (inject.has("crash")) {
        try {
            throw new Error("Simulated crash");
        }
        catch (e) {
            const dMs = Number(hrtime.bigint() - t0) / 1000000;
            log("ERROR", `Crash: ${String(e?.message ?? e)}`, {
                action: "inject_crash",
                outcome: "fail",
                errorCode: "HARDENING_FAKE_CRASH",
                durationMs: Math.round(dMs),
            });
            return 9; // fatal-like exit for test
        }
    }
    const dMs = Number(hrtime.bigint() - t0) / 1000000;
    log("INFO", "Fault mode done", { action: "fault_done", outcome: "ok", durationMs: Math.round(dMs) });
    return 0;
}
if (isMain) {
    (async () => {
        ensureLogDir();
        const { mode, inject, intervalMs, durationMs } = parseArgs(process.argv.slice(2));
        currentTraceId = randomUUID();
        let code = 0;
        if (mode === "baseline")
            code = baseline();
        else if (mode === "fault")
            code = fault(inject);
        else
            code = await metrics(intervalMs, durationMs);
        process.exit(code);
    })();
}
