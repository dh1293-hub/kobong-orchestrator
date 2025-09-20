#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

if ($args.Count -lt 1) { Write-Error "USAGE: g5runner.ps1 <script> [args ...]"; exit 10 }
$ScriptPath = $args[0]
if (-not (Test-Path -LiteralPath $ScriptPath)) { Write-Error "PRECONDITION: Script not found: $ScriptPath"; exit 10 }
$ScriptArgs = @()
if ($args.Count -gt 1) { $ScriptArgs = $args[1..($args.Count-1)] }

# 절대경로 & 작업디렉터리(파라미터셋 충돌 회피)
try {
  $Full = (Resolve-Path -LiteralPath $ScriptPath | Select-Object -First 1 -ExpandProperty Path)
} catch {
  $Full = [System.IO.Path]::GetFullPath($ScriptPath)
}
$Work = [System.IO.Path]::GetDirectoryName([string]$Full)

# logs
$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$logsDir = Join-Path $RepoRoot 'logs\run'
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$base = [System.IO.Path]::GetFileNameWithoutExtension($Full)
$StdoutPath = Join-Path $logsDir "$($base)-$ts.out.log"
$StderrPath = Join-Path $logsDir "$($base)-$ts.err.log"

# .NET Process → pwsh -File <script> <args...>
$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = 'pwsh'
@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$Full) | ForEach-Object { [void]$psi.ArgumentList.Add($_) }
foreach($a in $ScriptArgs){ [void]$psi.ArgumentList.Add([string]$a) }
$psi.WorkingDirectory = $Work
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
$psi.StandardErrorEncoding  = [Text.UTF8Encoding]::new($false)

$proc = [System.Diagnostics.Process]::new()
$proc.StartInfo = $psi
$null = $proc.Start()

$so = $proc.StandardOutput.ReadToEndAsync()
$se = $proc.StandardError.ReadToEndAsync()
$null = $proc.WaitForExit()

$out = $so.Result; $err = $se.Result
[System.IO.File]::WriteAllText($StdoutPath, $out, [Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($StderrPath, $err, [Text.UTF8Encoding]::new($false))

if ($proc.ExitCode -ne 0) { Write-Error "EXIT $($proc.ExitCode) — logs:`n$StdoutPath`n$StderrPath"; exit 13 }
"OK (exit 0) — logs:`n$StdoutPath`n$StderrPath"
