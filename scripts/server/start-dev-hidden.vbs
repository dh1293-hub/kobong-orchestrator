On Error Resume Next
Dim sh, cmd
Set sh = CreateObject("WScript.Shell")
cmd = "cmd /c " & Chr(34) & pwsh.exe -NoProfile -ExecutionPolicy Bypass -File ""D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator\scripts\server\run-dev.ps1"" -Detach -Reload -Port 8080 -BindAddress 127.0.0.1 & Chr(34)
sh.Run cmd, 0, False