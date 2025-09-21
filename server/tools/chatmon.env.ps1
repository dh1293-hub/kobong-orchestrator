# KoBong Chat OUTBOUND Monitor env
$env:KOBONG_CHAT_MON = '1'
$env:KOBONG_MON_API  = 'http://127.0.0.1:8094'
# ensure sitecustomize.py auto-load
if (($env:PYTHONPATH ?? '') -notmatch [regex]::Escape('D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator\server')) {
  if ($env:PYTHONPATH) { $env:PYTHONPATH = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator\server;' + $env:PYTHONPATH } else { $env:PYTHONPATH = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator\server' }
}