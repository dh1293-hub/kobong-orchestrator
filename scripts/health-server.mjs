import http from "node:http";
import { URL } from "node:url";

const PORT = Number(process.env.PORT || 8080);
const startedAt = Date.now();

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (req.method === "GET" && url.pathname === "/health") {
    const body = JSON.stringify({ status: "ok", ready: true, uptimeSec: Math.floor((Date.now() - startedAt) / 1000) });
    res.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
    res.end(body);
    return;
  }
  if (req.method === "GET" && url.pathname === "/live") {
    res.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
    res.end("live");
    return;
  }
  res.writeHead(404, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify({ status: "not_found" }));
});

server.on("clientError", (err, socket) => { try { socket.end("HTTP/1.1 400 Bad Request\r\n\r\n"); } catch {} });
server.on("error", (err) => { console.error("[health] server error:", err?.message || err); process.exitCode = 1; });

server.listen(PORT, "0.0.0.0", () => {
  console.log(`[health] listening on http://localhost:${PORT}/health (pid=${process.pid})`);
  console.log(JSON.stringify({ timestamp: new Date().toISOString(), module: "app", action: "bootstrap", outcome: "ok" }));
});

function gracefulExit(code=0){ try { server.close(()=>process.exit(code)); } catch { process.exit(code); } }
process.on("SIGINT", ()=>gracefulExit(0));
process.on("SIGTERM",()=>gracefulExit(0));

