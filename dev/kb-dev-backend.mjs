import http from "http";
import os   from "os";

const PORT = Number(process.env.PORT || process.env.KB_API_PORT || 8088);
const HOST = process.env.KB_API_HOST || "127.0.0.1";

const server = http.createServer((req,res)=>{
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);
    if (url.pathname === "/health") {
      res.writeHead(200,{"content-type":"application/json","cache-control":"no-store"});
      return res.end(JSON.stringify({ok:true, ts:Date.now(), pid:process.pid, host:os.hostname()}));
    }
    if (url.pathname === "/metrics") {
      res.writeHead(200,{"content-type":"application/json","cache-control":"no-store"});
      return res.end(JSON.stringify({status:"ok", ts:Date.now(), ver:"dev-backend"}));
    }
    if (url.pathname === "/events") {
      res.writeHead(200,{"Content-Type":"text/event-stream","Cache-Control":"no-cache","Connection":"keep-alive","Access-Control-Allow-Origin":"*"});
      const hb = setInterval(()=>{ try{ res.write(`event: ping\ndata: ${Date.now()}\n\n`);}catch{} }, 10000);
      req.on("close",()=> clearInterval(hb));
      res.write(`event: hello\ndata: {"source":"kb-dev","ts":${Date.now()}}\n\n`);
      return;
    }
    if (url.pathname === "/favicon.ico"){ res.statusCode=204; return res.end(); }
    res.statusCode=404; return res.end("not found");
  } catch(e){
    try{ res.statusCode=500; res.end("error"); }catch{}
    console.error("[API] handler error:", e?.stack||e);
  }
});

server.on("error", (e)=> console.error("[API] server error:", e?.stack||e));
process.on("uncaughtException", (e)=> console.error("[API] uncaught:", e?.stack||e));
process.on("unhandledRejection", (e)=> console.error("[API] unhandledRej:", e));

server.listen(PORT, HOST, ()=> console.log("[API] dev backend on", HOST+":"+PORT));
