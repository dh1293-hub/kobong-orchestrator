$ErrorActionPreference = "Stop"
Write-Host "[Pester] bootstrap" -ForegroundColor DarkCyan
$mod = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
if (-not $mod) { Install-Module Pester -Scope CurrentUser -Force -MinimumVersion 5.5.0 -SkipPublisherCheck; $mod = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1 }
Import-Module Pester -RequiredVersion $mod.Version -Force
$tests = Join-Path (Get-Location) "tests"
if (Test-Path $tests) {
  if ($mod.Version.Major -ge 5) { $cfg=[Pester.Configuration]::Default; $cfg.Run.Path=$tests; $cfg.Output.Verbosity="Detailed"; Invoke-Pester -Configuration $cfg }
  else { Invoke-Pester -Script $tests -Output Detailed }
} else { Write-Host "[Pester] tests folder not found — skip." }
