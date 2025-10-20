const http = require("http");
const url  = require("url");
const os   = require("os");
const { spawn } = require("child_process");
const WebSocket = require("ws");
const iconv = require("iconv-lite");           // ★ cp949 → utf8 디코딩

const PORT = Number(process.env.PORT||5181);
const HTTP_PREFIX = "/api/ak7";
const WS_PATH = "/api/ak7/shell";
const ROLES = new Set(["input","server","vserver","aux","extra"]);
const VERSION = "ak7-mock v2.1 (line-mode+cp949)";

// === SSE timeline ===
let SSE_clients = new Set();
function SSE_emit(ev){
  const line = JSON.stringify(Object.assign({ ts: Date.now() }, ev));
  for (const res of SSE_clients) {
    try { res.write(`data: ${line}\n\n`); } catch { SSE_clients.delete(res); }
  }
}
function SSE_open(res){
  res.writeHead(200, {
    "Content-Type":"text/event-stream",
    "Cache-Control":"no-cache",
    "Connection":"keep-alive",
    "Access-Control-Allow-Origin":"*"
  });
  res.write("retry: 3000\n\n");
  SSE_clients.add(res);
}

function j(res, code, obj){
  const body = Buffer.from(JSON.stringify(obj));
  res.writeHead(code, {
    "Content-Type":"application/json; charset=utf-8",
    "Access-Control-Allow-Origin":"*",
    "Access-Control-Allow-Headers":"*",
    "Access-Control-Allow-Methods":"GET,POST,OPTIONS"
  });
  res.end(body);
}

const srv = http.createServer((req,res)=>{
  const u = url.parse(req.url, true);
  const p = ((u.pathname||"/").replace(/\/+$/,"")) || "/";
  if(req.method==="OPTIONS") return j(res,204,{});

  if(req.method==="GET" && p===HTTP_PREFIX){
    return j(res,200,{ ok:true, version:VERSION, base:true,
      endpoints:["GET /health",`GET ${HTTP_PREFIX}/version`,`GET ${HTTP_PREFIX}/info`,`POST ${HTTP_PREFIX}/action/:action`,`WS ${WS_PATH}?role=`,`SSE ${HTTP_PREFIX}/timeline`,"SSE /timeline (compat)"]});
  }
  if(req.method==="GET" && p===HTTP_PREFIX+"/version") return j(res,200,{ ok:true, version:VERSION });
  if(req.method==="GET" && p==="/health") return j(res,200,{ ok:true, service:"ak7", mode:"MOCK", uptimeSec:process.uptime(), ts:new Date().toISOString(), version:VERSION });

  if(req.method==="GET" && (p===HTTP_PREFIX+"/timeline" || p==="/timeline")){ SSE_open(res); req.on("close",()=>SSE_clients.delete(res)); return; }
  if(req.method==="GET" && p===HTTP_PREFIX+"/info"){
    const ips = Object.values(os.networkInterfaces()).flat().filter(Boolean).map(n=>n.address).filter(a=>/\d+\.\d+\.\d+\.\d+/.test(a));
    return j(res,200,{ host:os.hostname(), ip:ips, ports:{ api: PORT }, mode:"MOCK", version:VERSION });
  }
  if(req.method==="POST" && p.startsWith(HTTP_PREFIX+"/action/")){
    const action = decodeURIComponent(p.split("/").pop() || "");
    SSE_emit({ type:"action", action });
    return j(res,200,{ ok:true, code:0, action, traceId:`t-${Date.now()}` });
  }
  j(res,404,{ ok:false, code:404, message:"not found", path:p });
});

// ===== WS Bridge =====
const wss = new WebSocket.Server({ noServer:true });
let PTY=null; try{ PTY=require("node-pty"); }catch{ PTY=null; }

function openSession(role){
  const shell = process.env.PWSH || "powershell"; // pwsh가 있으면 자동 사용
  const args = ["-NoLogo"];
  if(shell.toLowerCase().includes("powershell")){
    // 한글/UTF-8 출력 보정
    args.push("-NoProfile");
    args.push("-Command");
    args.push("[Console]::InputEncoding=[Text.Encoding]::UTF8; [Console]::OutputEncoding=[Text.Encoding]::UTF8; $Host.UI.RawUI.WindowTitle='ak7'; $PSStyle.OutputRendering='Ansi'; powershell");
  }
  if(PTY){
    try{
      const pty = PTY.spawn(shell, args, { name:"xterm-color", cols:120, rows:32, cwd:process.cwd() });
      return { mode:"pty", write:d=>pty.write(d), kill:()=>pty.kill(), onData:cb=>pty.on("data",cb), banner:`[${role}] ${shell} (pty)` };
    }catch(e){}
  }
  const child = spawn(shell, ["-NoLogo"], { stdio:["pipe","pipe","pipe"] });
  return {
    mode:"pipe",
    write:d=>child.stdin.write(d),
    kill:()=>child.kill(),
    onData:cb=>{
      child.stdout.on("data",buf=>cb(buf));
      child.stderr.on("data",buf=>cb(buf));
    },
    banner:`[${role}] ${shell} (pipe)`
  };
}

srv.on("upgrade",(req, socket, head)=>{
  const u = url.parse(req.url, true);
  const p = ((u.pathname||"/").replace(/\/+$/,"")) || "/";
  if(p!==WS_PATH){ socket.destroy(); return; }
  const role = (u.query.role||"").toString();
  if(!ROLES.has(role)){ socket.destroy(); return; }
  SSE_emit({ type:"ws-open", role });
  wss.handleUpgrade(req, socket, head, (ws)=> wss.emit("connection", ws, role));
});

wss.on("connection", (ws, role)=>{
  const sess = openSession(role);
  ws.send(`\r\n${sess.banner}\r\nPowerShell$ `);
  // ★ cp949 → utf8 디코딩 (실패시 utf8)
  sess.onData(data=>{
    let out="";
    if(Buffer.isBuffer(data)){
      try{ out = iconv.decode(data, "cp949"); } catch{ out = data.toString("utf8"); }
    }else out=String(data);
    if(ws.readyState===1) ws.send(out);
  });
  ws.on("message", msg => sess.write(msg.toString()));
  ws.on("close", ()=> { SSE_emit({ type:"ws-close", role }); sess.kill(); });
});

srv.listen(PORT, ()=> console.log(`[ak7 v2.1] http://localhost:${PORT} — WS ${WS_PATH}`));