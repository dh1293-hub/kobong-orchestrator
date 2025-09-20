# APPLY IN SHELL
#requires -Version 7.0
# (A) 아직 파일이 없으면, 먼저 만들기 — 클립보드→파일
Set-Content -Path .\patched.jsx -Value (Get-Clipboard -Raw) -Encoding utf8

# (B) 만든 파일을 사용해 적용
$Target = 'D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator\webui\src\App.tsx'
$env:CONFIRM_APPLY='true'
.\script.ps1 -PatchedTextPath .\patched.jsx -Target $Target

