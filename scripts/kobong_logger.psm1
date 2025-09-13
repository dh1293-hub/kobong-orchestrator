# kobong_logger v0.2 — PS5/PS7 compatible (no ArgumentList)
function Remove-AnsiEscapes {
  param([string]$s)
  if ($null -eq $s) { return '' }
  # strip ESC[… letter  + CR carriage-only lines
  $t = ($s -replace '\x1B\[[0-9;]*[A-Za-z]', '')
  return ($t -replace '\r(?!\n)', '') 
}
function Join-KBArgs {
  param([string[]]$Args)
  if (-not $Args) { return '' }
  $qq = '"'
  $out = foreach($a in $Args){
    if ($a -match '[\s"$`^|&<>]') {
      $escaped = $a -replace '"','\"'
      "$qq$escaped$qq"
    } else { $a }
  }
  ($out -join ' ')
}
function Invoke-KBProc {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string[]]$SuppressWarnPatterns = @('^warning:\s+in the working copy of'),
    [string[]]$ErrorPatterns = @('\bfatal\b', '\berror\b', '\bGH00\d+\b', '^X\s')
  )
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $FilePath
  # PS5 호환: Arguments 문자열로 전달
  $psi.Arguments = (Join-KBArgs -Args $ArgumentList)
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute        = $false
  $psi.CreateNoWindow         = $true

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
