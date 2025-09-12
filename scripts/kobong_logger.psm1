# kobong_logger v0.1 — robust process logging & classification (no color heuristics)
# Exports: Invoke-KBProc, Remove-AnsiEscapes
function Remove-AnsiEscapes {
  param([string]$s)
  if ($null -eq $s) { return '' }
  return ($s -replace '\x1B\[[0-9;]*[A-Za-z]', '')
}
function Invoke-KBProc {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string[]]$SuppressWarnPatterns = @('^warning:\s+in the working copy of'), # git warning 무시 예
    [string[]]$ErrorPatterns = @('\bfatal\b', '\berror\b', '\bGH00\d+\b', '^X\s') # GH006 등
  )
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $FilePath
  foreach($a in $ArgumentList){ [void]$psi.ArgumentList.Add($a) }
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  $out = Remove-AnsiEscapes $stdout
  $err = Remove-AnsiEscapes $stderr
  $outLines = if ($out) { $out -split "`r?`n" } else { @() }
  $errLines = if ($err) { $err -split "`r?`n" } else { @() }

  # 경고/에러 라인 분류(색상 무시, 내용 기반)
  $warn = @()
  foreach($ln in $errLines){
    if ($SuppressWarnPatterns | Where-Object { $ln -match $_ }) { continue }
    if ($ln -match '(?i)\bwarning\b') { $warn += $ln }
  }
  $hits = @()
  foreach($rx in $ErrorPatterns){
    $hits += @($errLines + $outLines) | Where-Object { $_ -match $rx }
  }
  $hits = $hits | Select-Object -Unique

  $isError = ($p.ExitCode -ne 0) -or ($hits.Count -gt 0)
  [pscustomobject]@{
    ExitCode  = $p.ExitCode
    StdOut    = $out
    StdErr    = $err
    WarnLines = $warn
    ErrLines  = $hits
    IsError   = $isError
  }
}
Export-ModuleMember -Function Invoke-KBProc,Remove-AnsiEscapes
