#requires -Version 7.0
param([string]$OutDir)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$RepoRoot = (git rev-parse --show-toplevel 2>$null); if (-not $RepoRoot) { $RepoRoot=(Get-Location).Path }
$ServerRoot = Join-Path $RepoRoot "server"
$Py = Join-Path $ServerRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $Py)) { throw "Python venv not found: $Py" }
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = (Join-Path $RepoRoot "artifacts") }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$jsonOut = Join-Path $OutDir "openapi.json"
$yamlOut = Join-Path $OutDir "openapi.yaml"

# Ensure PYTHONPATH=server (child inherits)
$prepend = $ServerRoot
if ($env:PYTHONPATH -and $env:PYTHONPATH -ne '') { $env:PYTHONPATH = "$prepend;$($env:PYTHONPATH)" } else { $env:PYTHONPATH = $prepend }

$code = @"
import json, sys, os
pp = os.environ.get('PYTHONPATH','')
if pp and pp not in sys.path: sys.path.insert(0, pp)
from ko_app.main import app
schema = app.openapi()
path_json = sys.argv[1]
with open(path_json, 'w', encoding='utf-8') as f:
    json.dump(schema, f, ensure_ascii=False, indent=2)
print('WROTE', path_json)
"@
& $Py -c $code $jsonOut | Write-Host

# YAML (optional)
try {
  $ycode = @"
import sys, json, yaml
data = json.load(open(sys.argv[1], 'r', encoding='utf-8'))
yaml.safe_dump(data, open(sys.argv[2], 'w', encoding='utf-8'), sort_keys=False, allow_unicode=True)
print('WROTE', sys.argv[2])
"@
  & $Py -c $ycode $jsonOut $yamlOut | Write-Host
} catch { Write-Host "[WARN] yaml export skipped (PyYAML missing?)" -ForegroundColor Yellow }