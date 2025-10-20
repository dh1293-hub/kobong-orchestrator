
// containers/GitHub-Mon-shells/server.js
// Windows Node + ws + node-pty 기반 GHMON 모의 API/WS
const http = require('http');
const url = require('url');
const fs = require('fs');
const WebSocket = require('ws');
let pty;
try { pty = require('node-pty'); } catch(e){ pty = null; }

const PORT = process.env.PORT || 5182;
function json(res, code, obj){ res.writeHead(code, {'content-type':'application/json'}); res.end(JSON.stringify(obj)); }

const server = http.createServer((req, res) => {
  const u = url.parse(req.url, true);
  if (req.method==='GET' && u.pathname==='/health'){
    return json(res, 200, { ok:true, service:'ghmon', version:'v1-min' });
  }
  // Actions
  if (req.method==='POST' && u.pathname.startsWith('/api/ghmon/action/')){
    const action = u.pathname.split('/').pop();
    return json(res, 200, { ok:true, action, exitCode: action==='fix-preview'?10:0, traceId: crypto.randomUUID(), anchorHash: (action==='fix-apply') ? 'gh-'+Math.random().toString(36).slice(2,8) : undefined });
  }
  // PR actions (mock)
  if (req.method==='POST' && /^\/api\/ghmon\/prs\/.+\/.+\/\d+\/(approve|request_review|request_changes|merge_or_queue)$/.test(u.pathname)){
    return json(res, 200, { ok:true, exitCode:0, traceId: crypto.randomUUID() });
  }
  // CI actions (mock)
  if ((req.method==='POST' || req.method==='GET') && /^\/api\/ghmon\/actions\/runs\/\d+\/(rerun|rerun_failed|cancel|logs)$/.test(u.pathname)){
    return json(res, 200, { ok:true, exitCode:0, traceId: crypto.randomUUID() });
  }
  // Security batch (mock)
  if (req.method==='POST' && /^\/api\/ghmon\/security\/(create_issues|assign|label|dismiss_with_reason)$/.test(u.pathname)){
    return json(res, 200, { ok:true, exitCode:0, traceId: crypto.randomUUID() });
  }
  json(res, 404, { ok:false, message:'not found' });
});

const wss = new WebSocket.Server({ noServer:true });
server.on('upgrade', (req, socket, head) => {
  const u = url.parse(req.url, true);
  if (u.pathname === '/api/ghmon/shell'){
    wss.handleUpgrade(req, socket, head, (ws) => {
      const role = u.query.role || 'server1';
      if (pty){
        const shell = process.env.SHELL_PATH || 'powershell.exe';
        const term = pty.spawn(shell, ['-NoLogo'], { cols:120, rows:32 });
        term.onData(d => ws.readyState===1 && ws.send(d));
        ws.on('message', m => term.write(m.toString()));
        ws.on('close', () => term.kill());
      } else {
        ws.send(`[mock shell connected:${role}]`);
        ws.on('message', m => ws.send('echo: '+m.toString()));
      }
    });
  } else {
    socket.destroy();
  }
});

server.listen(PORT, () => console.log(`[GHMON] listening on :${PORT}`));
