#requires -Version 7.0
param(
  [Parameter(Mandatory)][string]$File,
  [string[]]$Args = @(),
  [string]$WorkingDir,
  [int]$TimeoutSec = 600,
  [hashtable]$Env = @{},
  [switch]$ConfirmApply,
  [switch]$KillTree = $true,
  [ValidateSet('auto','ps1','python','node','exe')][string]$Mode = 'auto'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

if (-not (Test-Path -LiteralPath $File)) { throw "PRECONDITION: File not found: $File" }
$FileFull = (Resolve-Path -LiteralPath $File).Path
$Work = if ($WorkingDir) { $WorkingDir } else { Split-Path -LiteralPath $FileFull -Parent }

# choose runner
$ext = ([IO.Path]::GetExtension($FileFull) ?? '').ToLowerInvariant()
$exe = $null; $argList = [System.Collections.Generic.List[string]]::new()
function AddArg([string]$s){ [void]$argList.Add($s) }
switch ($true) {
  { $Mode -eq 'ps1' -or $ext -eq '.ps1' -or ($Mode -eq 'auto' -and $ext -eq '.ps1') } {
    $exe = 'pwsh'
    @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$FileFull) | ForEach-Object { AddArg $_ }
    foreach($a in $Args){ AddArg $a }; break
  }
  { $Mode -eq 'python' -or $ext -eq '.py' } { $exe = 'python'; AddArg $FileFull; foreach($a in $Args){ AddArg $a }; break }
  { $Mode -eq 'node' -or $ext -in @('.mjs','.js') } { $exe = 'node'; AddArg $FileFull; foreach($a in $Args){ AddArg $a }; break }
  { $Mode -eq 'exe' } { $exe = $FileFull; foreach($a in $Args){ AddArg $a }; break }
  Default { $exe = 'pwsh'; @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$FileFull) | ForEach-Object { AddArg $_ }; foreach($a in $Args){ AddArg $a } }
}

# plan
$plan = "[PLAN] exe=$exe; args=" + ([string]::Join(' ', $argList)) + "; work=" + $Work
if (-not $ConfirmApply) { $plan; exit 0 }

# logs
$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$logsDir = Join-Path $RepoRoot 'logs\run'; New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'; $base = [IO.Path]::GetFileNameWithoutExtension($FileFull)
$StdoutPath = Join-Path $logsDir "$($base)-$ts.out.log"
$StderrPath = Join-Path $logsDir "$($base)-$ts.err.log"

# .NET Process
$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $exe
foreach($a in $argList){ [void]$psi.ArgumentList.Add($a) }  # 안전한 인자 전달
$psi.WorkingDirectory = $Work
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
$psi.StandardErrorEncoding  = [Text.UTF8Encoding]::new($false)

# env (동적)
$keep = @('Path','TEMP','TMP','ComSpec','SystemRoot','USERPROFILE','HOME')
foreach($k in $keep){
  try { $val = [System.Environment]::GetEnvironmentVariable($k,'Process') } catch { $val = $null }
  if ($val) { $psi.Environment[$k] = $val }
}
foreach($k in $Env.Keys){ $psi.Environment[$k] = [string]$Env[$k] }

$proc = [System.Diagnostics.Process]::new()
$proc.StartInfo = $psi
$null = $proc.Start()

# stream → 파일
$so = $proc.StandardOutput.ReadToEndAsync()
$se = $proc.StandardError.ReadToEndAsync()
if (-not $proc.WaitForExit([Math]::Max(1,$TimeoutSec)*1000)) {
  if ($KillTree) { try { & taskkill /PID $($proc.Id) /T /F *> $null } catch {} } else { try { $proc.Kill($true) } catch {} }
  $null = $proc.WaitForExit(2000)
}
$code = $proc.ExitCode
$out = $so.Result; $err = $se.Result
[IO.File]::WriteAllText($StdoutPath, $out, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($StderrPath, $err, [Text.UTF8Encoding]::new($false))

if ($code -ne 0) { Write-Error "EXIT $code — logs:`n$StdoutPath`n$StderrPath"; exit 13 }
"OK (exit 0) — logs:`n$StdoutPath`n$StderrPath"
exit 0
