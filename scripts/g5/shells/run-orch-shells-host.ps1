# APPLY IN SHELL — 호스트에서 ORCHMON Shells 서버(5183) 기동
#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$Repo = 'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP',
  [int]$Port = 5183
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# 0) 경로/폴더
$AppDir = Join-Path $Repo 'containers\orch-shells'
$LogDir = Join-Path $Repo 'logs'
New-Item -ItemType Directory -Force -Path $AppDir,$LogDir | Out-Null

# 1) Node 포터블(Windows x64) 설치 — Node 18 LTS (호환성 안정)
$NodeHome = 'D:\tools\node18'
$NodeZip  = Join-Path ([IO.Path]::GetTempPath()) 'node-18.20.5-win-x64.zip'
if(-not (Test-Path $NodeHome)){
  New-Item -ItemType Directory -Force -Path (Split-Path $NodeHome) | Out-Null
  $url = 'https://nodejs.org/dist/v18.20.5/node-v18.20.5-win-x64.zip'
  Write-Host "[DL] $url"
  Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $NodeZip
  Expand-Archive $NodeZip -DestinationPath (Split-Path $NodeHome) -Force
  Rename-Item (Join-Path (Split-Path $NodeHome) 'node-v18.20.5-win-x64') $NodeHome -Force
}
$env:PATH = "$NodeHome;$env:PATH"
& "$NodeHome\node.exe" -v
& "$NodeHome\npm.cmd" -v

# 2) 앱 파일 보증(package.json / server.js 없으면 생성)
$pkg = Join-Path $AppDir 'package.json'
if(-not (Test-Path $pkg)){
  @'
{
  "name": "orch-shells-host",
  "private": true,
  "version": "1.0.0",
  "dependencies": {
    "ws": "^8.18.0",
    "node-pty": "^1.0.0"
  }
}
'@ | Set-Content -Encoding UTF8 -LiteralPath $pkg
}
$server = Join-Path $AppDir 'server.js'
if(-not (Test-Path $server)){
@'
const http = require("http");
const url  = require("url");
const os   = require("os");
const { spawn } = require("child_process");
const WebSocket = require("ws");

const PORT = Number(process.env.PORT || 5183);
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
  });
  res.end(body);
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

// WS Shell bridge
const wss = new (require("ws")).Server({ noServer:true });
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
  const ch = spawn(shell,["-NoLogo"],{ stdio:["pipe","pipe","pipe"] });
  ch.on("error",()=>{ if(process.platform==="win32"){ spawn("powershell",["-NoLogo"]) } });
  return {
    write:d=>ch.stdin.write(d),
    kill:()=>ch.kill(),
    onData:cb=>{ ch.stdout.on("data",d=>cb(d.toString())); ch.stderr.on("data",d=>cb(d.toString())); },
    banner:`[${role}] ${shell} (pipe)`
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
}

# 3) 의존성 설치
Push-Location $AppDir
try{
  & "$NodeHome\npm.cmd" ci --no-audit --no-fund 2>$null; if($LASTEXITCODE){ & "$NodeHome\npm.cmd" install --no-audit --no-fund }
} finally { Pop-Location }

# 4) 5183 포트 점유 정리(있으면)
$cons = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if($cons){ Write-Host "[INFO] Port $Port was in use by PID(s): $($cons.OwningProcess -join ','). Trying to continue..." }

# 5) 서버 실행(백그라운드) + PID 기록
$pidFile = Join-Path $LogDir 'orchmon-host.pid'
if(Test-Path $pidFile){ try{ $old = Get-Content -Raw $pidFile; Stop-Process -Id [int]$old -ErrorAction SilentlyContinue }catch{} }
$ps = Start-Process -FilePath "$NodeHome\node.exe" -ArgumentList "server.js" -WorkingDirectory $AppDir -WindowStyle Hidden -PassThru
$ps.Id | Set-Content -Encoding ascii -LiteralPath $pidFile
Write-Host "[OK] started host server PID=$($ps.Id) → http://localhost:$Port"

# 6) 헬스 체크(재시도)
$ok=$false
1..10 | ForEach-Object {
  Start-Sleep -Milliseconds 400
  try{
    $c = (Invoke-WebRequest -UseBasicParsing "http://localhost:$Port/health").Content
    if($c -match '"ok"\s*:\s*true'){ $ok=$true; Write-Host $c; break }
  }catch{}
}
if(-not $ok){ Write-Host "[WARN] /health에 응답이 없습니다. (백그라운드 프로세스는 기동됨)" }

Write-Host "[DONE] 호스트 서버 준비 완료. UI에서 OFFLINE 해제 후 확인하세요."
