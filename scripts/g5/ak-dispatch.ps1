# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$Command,
  [string]$Sha,
  [string]$Pr
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Write-Host "[AK] command=$Command sha=$Sha pr=$Pr"
# TODO: 여기서 실제 KO 실행/라우팅(스캔/테스트/FixLoop/롤백 등) 호출로 확장
