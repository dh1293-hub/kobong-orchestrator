function Invoke-KobongRunner {
  [CmdletBinding(PositionalBinding=$false)]
  param(
    [Parameter(Mandatory)][string]$ScriptPath,
    [string[]]$ScriptArguments = @(),
    [string]$WorkingDir,
    [int]$TimeoutSec = 600,
    [hashtable]$ExtraEnv = @{},
    [ValidateSet('auto','ps1','python','node','exe')][string]$Mode = 'auto'
  )
  Set-StrictMode -Version Latest
  $ErrorActionPreference='Stop'

  if (-not (Test-Path -LiteralPath $ScriptPath)) { throw "PRECONDITION: ScriptPath not found: $ScriptPath" }
  $Full = (Resolve-Path -LiteralPath $ScriptPath).Path
  $Work = if ($WorkingDir) { $WorkingDir } else { Split-Path -LiteralPath $Full -Parent }

  # 실행기 선택
  $ext = ([IO.Path]::GetExtension($Full) ?? '').ToLowerInvariant()
  $exe = $null
  $argList = [System.Collections.Generic.List[string]]::new()
  function A([string]$s){ [void]$argList.Add($s) }

  switch ($true) {
    { $Mode -eq 'ps1' -or $ext -eq '.ps1' -or ($Mode -eq 'auto' -and $ext -eq '.ps1') } {
      $exe='pwsh'; @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$Full) | ForEach-Object { A $_ }; foreach($a in $ScriptArguments){ A $a }; break
    }
    { $Mode -eq 'python' -or $ext -eq '.py' } { $exe='python'; A $Full; foreach($a in $ScriptArguments){ A $a }; break }
    { $Mode -eq 'node' -or $ext -in @('.mjs','.js') } { $exe='node'; A $Full; foreach($a in $ScriptArguments){ A $a }; break }
    { $Mode -eq 'exe' } { $exe=$Full; foreach($a in $ScriptArguments){ A $a }; break }
    Default { $exe='pwsh'; @('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',$Full) | ForEach-Object { A $_ }; foreach($a in $ScriptArguments){ A $a } }
  }

  # 로그 경로
  $RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
  $logsDir = Join-Path $RepoRoot 'logs\run'; New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $base = [IO.Path]::GetFileNameWithoutExtension($Full)
  $StdoutPath = Join-Path $logsDir "$($base)-$ts.out.log"
  $StderrPath = Join-Path $logsDir "$($base)-$ts.err.log"

  # .NET Process
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $exe
  foreach($a in $argList){ [void]$psi.ArgumentList.Add($a) }
  $psi.WorkingDirectory = $Work
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
  $psi.StandardErrorEncoding  = [Text.UTF8Encoding]::new($false)

  # env
  $keep = @('Path','TEMP','TMP','ComSpec','SystemRoot','USERPROFILE','HOME')
  foreach($k in $keep){
    try { $v=[System.Environment]::GetEnvironmentVariable($k,'Process') } catch { $v=$null }
    if ($v) { $psi.Environment[$k] = $v }
  }
  foreach($k in $ExtraEnv.Keys){ $psi.Environment[$k] = [string]$ExtraEnv[$k] }

  $proc = [System.Diagnostics.Process]::new()
  $proc.StartInfo = $psi
  $null = $proc.Start()

  $so = $proc.StandardOutput.ReadToEndAsync()
  $se = $proc.StandardError.ReadToEndAsync()

  if (-not $proc.WaitForExit([Math]::Max(1,$TimeoutSec)*1000)) {
    try { & taskkill /PID $($proc.Id) /T /F *> $null } catch {}
    $null = $proc.WaitForExit(2000)
  }

  $code = $proc.ExitCode
  $out = $so.Result; $err = $se.Result
  [IO.File]::WriteAllText($StdoutPath, $out, [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText($StderrPath, $err, [Text.UTF8Encoding]::new($false))

  if ($code -ne 0) { Write-Error "EXIT $code — logs:`n$StdoutPath`n$StderrPath"; return }
  "OK (exit 0) — logs:`n$StdoutPath`n$StderrPath"
}
