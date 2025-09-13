# setup-env.ps1 (v2) — safe external tool checks (no StrictMode interference)
# Exit codes: 0 ok, 2 env error
$ErrorActionPreference = 'Stop'
Write-Host '[setup] env check'

function Show-Ver([string]$name, [scriptblock]$cmd) {
  try {
    & $cmd
  } catch {
    Write-Host ('[경고] {0} 확인 실패: {1}' -f $name, $_.Exception.Message) -ForegroundColor DarkYellow
    throw
  }
}

# Node
Show-Ver 'node' { & node -v }
# npm.ps1 대신 npm.cmd 사용 (StrictMode 영향 제거)
Show-Ver 'npm'  { & "C:\Program Files\nodejs\npm.cmd" -v }

# Python & pip
Show-Ver 'python' { & python --version }
Show-Ver 'pip'    { & pip --version }

Write-Host '[ok] tools detected'
exit 0