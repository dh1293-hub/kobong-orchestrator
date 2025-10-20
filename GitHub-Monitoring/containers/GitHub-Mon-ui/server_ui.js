
// containers/GitHub-Mon-ui/server_ui.js — 정적 UI 서빙(5199)
const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = process.env.PORT || 5199;
const ROOT = process.env.ROOT || path.resolve(__dirname, "../../webui");

function send(res, code, type, buf){ res.writeHead(code, {'content-type': type}); res.end(buf); }
function guessType(p){
  if (p.endsWith(".html")) return "text/html; charset=utf-8";
  if (p.endsWith(".css")) return "text/css";
  if (p.endsWith(".js")) return "application/javascript";
  if (p.endsWith(".png")) return "image/png";
  return "application/octet-stream";
}

http.createServer((req,res)=>{
  let filePath = path.join(ROOT, req.url.replace(/\?.*$/,'').replace(/\/+$/,'') || "/GitHub-Monitoring-Min.html");
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()){
    filePath = path.join(filePath, "GitHub-Monitoring-Min.html");
  }
  fs.readFile(filePath, (err, data)=>{
    if (err){ res.writeHead(404); res.end("Not Found"); return; }
    send(res, 200, guessType(filePath), data);
  });
}).listen(PORT, ()=>console.log(`[GHMON-UI] serving ${ROOT} on :${PORT}`));
