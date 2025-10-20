# APPLY IN SHELL — ORCHMON Shells host-run on port 5188 (no VS Build Tools)
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Repo = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP',
  [int]$Port = 5188
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# 0) Paths
$AppDir = Join-Path $Repo 'containers\orch-shells'
$LogDir = Join-Path $Repo 'logs'
New-Item -ItemType Directory -Force -Path $AppDir,$LogDir | Out-Null

# 1) Node portable (18 LTS)
$NodeHome = 'D:\tools\node18'
if(-not (Test-Path $NodeHome)){
  $Zip = Join-Path ([IO.Path]::GetTempPath()) 'node-18.20.5-win-x64.zip'
  $Url = 'https://nodejs.org/dist/v18.20.5/node-v18.20.5-win-x64.zip'
  Write-Host "[DL] $Url"
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Zip
  Expand-Archive $Zip -DestinationPath (Split-Path $NodeHome) -Force
  Rename-Item (Join-Path (Split-Path $NodeHome) 'node-v18.20.5-win-x64') $NodeHome -Force
}
$env:PATH = "$NodeHome;$env:PATH"
& "$NodeHome\node.exe" -v
& "$NodeHome\npm.cmd" -v

# 2) package.json (node-pty → optionalDependencies)
$pkg = Join-Path $AppDir 'package.json'
@'
{
  "name": "orch-shells-host",
  "private": true,
  "version": "1.0.0",
  "dependencies": {
    "ws": "^8.18.0"
  },
  "optionalDependencies": {
    "node-pty": "^1.0.0"
  }
}
'@ | Set-Content -Encoding UTF8 -LiteralPath $pkg

# 3) server.js (node-pty 없어도 동작)
$server = Join-Path $AppDir 'server.js'
@'
const http = require("http");
const url  = require("url");
const { spawn } = require("child_process");
const os   = require("os");
const WebSocket = require("ws");
const PORT = Number(process.env.PORT || 5188);
const HTTP_PREFIX = "/api/orchmon";
const WS_PATH = "/api/orchmon/shell";
const ROLES = new Set(["input","server","vserver","aux","extra"]);
function j(res, code, obj){
  const body = Buffer.from(JSON.stringify(obj));
  res.writeHead(code, {
    "Content-Type":"application/json; charset=utf-8",
    "Access-Control-Allow-Origin":"*",
    "Access-Control-Allow-Headers":"*",
    "Access-Control-Allow-Methods":"GET,POST,OPTIONS"
  }); res.end(body);
}
const srv = http.createServer((req,res)=>{
  const u = url.parse(req.url, true);
  if(req.method==="OPTIONS") return j(res,204,{});
  if(req.method==="GET" && u.pathname==="/health"){
    return j(res,200,{ ok:true, service:"orchmon", mode:"DEV", uptimeSec:process.uptime(), ts:new Date().toISOString() });
  }
  if(req.method==="GET" && u.pathname===`${HTTP_PREFIX}/info`){
    const ips = Object.values(os.networkInterfaces()).flat().filter(Boolean).map(n=>n.address).filter(a=>/\d+\.\d+\.\d+\.\d+/.test(a));
    return j(res,200,{ host:os.hostname(), ip:ips, ports:{api:PORT}, mode:"DEV" });
  }
  if(req.method==="POST" && u.pathname.startsWith(`${HTTP_PREFIX}/action/`)){
    const action = decodeURIComponent(u.pathname.split("/").pop() || "");
    return j(res,200,{ ok:true, code:0, action, traceId:`t-${Date.now()}` });
  }
  return j(res,404,{ ok:false, code:404, message:"not found" });
});
const wss = new WebSocket.Server({ noServer:true });
let PTY=null; try{ PTY=require("node-pty"); }catch{ PTY=null; }
function openSession(role){
  const shell = process.env.PWSH || "pwsh";
  const fallback = process.platform==="win32" ? "powershell" : "bash";
  if(PTY){
    try{
      const pty = PTY.spawn(shell,["-NoLogo"],{ name:"xterm-color", cols:120, rows:32, cwd:process.cwd() });
      return { write:d=>pty.write(d), kill:()=>pty.kill(), onData:cb=>pty.on("data",cb), banner:`[${role}] ${shell} (pty)` };
    }catch(e){}
  }
  const ch = spawn(fallback,["-NoLogo"],{ stdio:["pipe","pipe","pipe"] });
  return {
    write:d=>ch.stdin.write(d),
    kill:()=>ch.kill(),
    onData:cb=>{ ch.stdout.on("data",d=>cb(d.toString())); ch.stderr.on("data",d=>cb(d.toString())); },
    banner:`[${role}] ${fallback} (pipe)`
  };
}
srv.on("upgrade",(req,sock,head)=>{
  const u = url.parse(req.url,true);
  if(u.pathname!==WS_PATH){ sock.destroy(); return; }
  const role = (u.query.role||"").toString();
  if(!ROLES.has(role)){ sock.destroy(); return; }
  wss.handleUpgrade(req,sock,head,(ws)=>wss.emit("connection",ws,role));
});
wss.on("connection",(ws,role)=>{
  const s = openSession(role);
  ws.send(`\r\n${s.banner}\r\nPowerShell$ `);
  s.onData(d=>{ if(ws.readyState===1) ws.send(d); });
  ws.on("message",m=>s.write(m.toString()));
  ws.on("close",()=>s.kill());
});
srv.listen(PORT,()=>console.log(`[ORCHMON] http://localhost:${PORT} — WS ${WS_PATH}`));
'@ | Set-Content -Encoding UTF8 -LiteralPath $server

# 4) 깨끗한 설치(옵셔널 빌드 전부 무시)
Push-Location $AppDir
try{
  if(Test-Path 'node_modules'){ Remove-Item -Recurse -Force 'node_modules' }
  & "$NodeHome\npm.cmd" install --no-audit --no-fund --no-optional
  if($LASTEXITCODE){ throw "npm install failed: $LASTEXITCODE" }
} finally { Pop-Location }

# 5) 이전 호스트 서버 중지
$pidFile = Join-Path $LogDir 'orchmon-host.pid'
if(Test-Path $pidFile){ try{ $old = Get-Content -Raw $pidFile; Stop-Process -Id [int]$old -ErrorAction SilentlyContinue }catch{} }

# 6) 서버 실행(백그라운드, 포트=5188)
$ps = Start-Process -FilePath "$NodeHome\node.exe" -ArgumentList "server.js" -WorkingDirectory $AppDir -WindowStyle Hidden -PassThru
$ps.Id | Set-Content -Encoding ascii -LiteralPath $pidFile
Write-Host "[OK] started host server PID=$($ps.Id) → http://localhost:$Port"

# 7) 헬스 체크(재시도)
$ok=$false
1..10 | ForEach-Object {
  Start-Sleep -Milliseconds 400
  try{
    $c = (Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/health").Content
    if($c -match '"ok"\s*:\s*true'){ $ok=$true; Write-Host $c; break }
  }catch{}
}
if(-not $ok){ Write-Host "[WARN] /health 응답 없음 — 백그라운드는 기동됨" }

Write-Host "[DONE] host server @ $Port"
