import http from "node:http";

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 8080;

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    const body = JSON.stringify({ status: "ok", timestamp: new Date().toISOString() });
    res.writeHead(200, { "content-type": "application/json; charset=utf-8" });
    res.end(body);
  } else {
    res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    res.end("not found");
  }
});

server.listen(PORT, () => {
  console.log(`[health] listening on http://localhost:${PORT}/health (pid=${process.pid})`);
});