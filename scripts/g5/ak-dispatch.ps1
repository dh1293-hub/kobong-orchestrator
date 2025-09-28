param(
  [Parameter(Mandatory=$true)][string]$Command,
  [Parameter(Mandatory=$true)][string]$Sha,
  [Parameter(Mandatory=$true)][string]$Pr
)

if (-not $env:GH_TOKEN -and $env:GITHUB_TOKEN) { $env:GH_TOKEN = $env:GITHUB_TOKEN }

function Write-AKLog([string]$level, [string]$action, [string]$message) {
  $logPath = Join-Path (Get-Location) "logs/ak7.jsonl"
  New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null
  $obj = [pscustomobject]@{timestamp=(Get-Date).ToString("s");level=$level;action=$action;message=$message}
  $obj | ConvertTo-Json -Compress | Out-File -FilePath $logPath -Append -Encoding utf8
}

Write-AKLog "INFO" "dispatch" "cmd=$Command pr=$Pr sha=$Sha"

$map = @{
  "scan"    = "ak-scan.ps1"
  "test"    = "ak-test.ps1"
  "rewrite" = "ak-rewrite.ps1"
  "fixloop" = "ak-fixloop.ps1"
}

if (-not $map.ContainsKey($Command)) {
  Write-AKLog "ERROR" "dispatch" "unknown command: $Command"
  throw "unknown command: $Command"
}

$target = Join-Path $PSScriptRoot $map[$Command]
if (-not (Test-Path $target)) {
  Write-AKLog "WARN" "dispatch" "$target missing; creating stub"
  @"
param([string]$Sha,[string]$Pr)
`$log = Join-Path (Get-Location) "logs/ak7.jsonl"
`$line = (@{ timestamp=(Get-Date).ToString("s"); level="INFO"; action="$($Command)"; message="stub run pr=$Pr sha=$Sha" } | ConvertTo-Json -Compress)
New-Item -ItemType Directory -Force -Path (Split-Path `$log) | Out-Null
`$line | Out-File -FilePath `$log -Append -Encoding utf8
Write-Host "[$Command] stub completed."
"@ | Out-File -FilePath $target -Encoding utf8 -Force
}

. $target -Sha $Sha -Pr $Pr
