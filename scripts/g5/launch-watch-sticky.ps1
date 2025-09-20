#requires -Version 7.0
param([int]$Port=8000,[string]$BindHost='127.0.0.1')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$env:KOBONG_HOLD_SHELL='1'
& (Join-Path $PSScriptRoot '..\server\serve-control.ps1') -Action watch -Port $Port -BindHost $BindHost
# 워치가 끝나도 창 유지
try { Read-Host '[HOLD] 종료하려면 Enter' } catch {}
