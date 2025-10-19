# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param([int]$Port = 5192)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$r = Invoke-WebRequest -Uri "http://localhost:$Port/api/ghmon/health" -UseBasicParsing -TimeoutSec 3
($r.Content | ConvertFrom-Json) | Format-List
