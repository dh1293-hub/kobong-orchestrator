#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root = ".",
  [int]$IntervalMs = 500,
  [int]$TimeoutSec = 120,
  [int]$InactivitySec = 30
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$RepoRoot = (Resolve-Path -LiteralPath $Root).Path
$Script   = Join-Path $RepoRoot 'scripts/g5/housekeeping-weekly.ps1'
if (-not (Test-Path $Script)) { throw "Not found: $Script" }

$pwsh = (Get-Command pwsh).Source
$args = @('-NoProfile','-ExecutionPolicy','Bypass','-File', $Script, '-Root', $RepoRoot)
if ($ConfirmApply) { $args += '-ConfirmApply' }

# Child process with redirected IO
$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $pwsh
foreach($a in $args){ $psi.ArgumentList.Add($a) }
$psi.WorkingDirectory = $RepoRoot
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
$psi.StandardErrorEncoding  = [Text.UTF8Encoding]::new($false)

$proc = [Diagnostics.Process]::new()
$proc.StartInfo = $psi
$proc.EnableRaisingEvents = $true

# Queues for async output
$stdoutQ = [Collections.Concurrent.ConcurrentQueue[string]]::new()
$stderrQ = [Collections.Concurrent.ConcurrentQueue[string]]::new()
$null = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action { if ($EventArgs.Data) { $stdoutQ.Enqueue($EventArgs.Data) } }
$null = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived  -Action { if ($EventArgs.Data) { $stderrQ.Enqueue($EventArgs.Data) } }

if (-not $proc.Start()) { throw "Failed to start child process." }
$proc.BeginOutputReadLine()
$proc.BeginErrorReadLine()

# Ctrl+C handling
$script:cancelled=$false
$cancelReg = Register-ObjectEvent -InputObject ([Console]) -EventName 'CancelKeyPress' -Action { $script:cancelled = $true }

$spin = @('|','/','-','\'); $i=0
$sw = [Diagnostics.Stopwatch]::StartNew()
$lastActivity = Get-Date
$Log = Join-Path $RepoRoot 'logs/apply-log.jsonl'
$lastLen = (Test-Path $Log) ? (Get-Item $Log).Length : 0
$lastStatusLen = 0

function Flush-Queue($q, [string]$tag) {
  $out=0
  while ($true) {
    [string]$line=$null
    if (-not $q.TryDequeue([ref]$line)) { break }
    if ($line -ne $null) {
      $script:lastActivity = Get-Date
      Write-Host "`r`n[$tag] $line"
      $out++
    }
  }
  return $out
}

try {
  while (-not $proc.HasExited) {
    # Print child outputs if any
    $newOut = Flush-Queue $stdoutQ 'child'
    $newErr = Flush-Queue $stderrQ 'child-err'

    # Log growth?
    if (Test-Path $Log) {
      $len = (Get-Item $Log).Length
      if ($len -gt $lastLen) {
        $last = Get-Content $Log -Tail 1
        $lastActivity = Get-Date
        Write-Host "`r`n[log+] $last"
        $lastLen = $len
      }
    }

    # Status line
    $elapsed = [int]$sw.Elapsed.TotalSeconds
    $status = "{0} elapsed={1}s spin={2}" -f (Get-Date -Format 'HH:mm:ss'), $elapsed, $spin[$i++ % $spin.Length]
    $pad = ' ' * [Math]::Max(0, $lastStatusLen - $status.Length)
    Write-Host -NoNewline "`r$status$pad"
    $lastStatusLen = $status.Length

    Start-Sleep -Milliseconds $IntervalMs

    if ($script:cancelled) {
      try { $proc.Kill() } catch {}
      throw "Cancelled by user (Ctrl+C)."
    }

    if ($TimeoutSec -gt 0 -and $sw.Elapsed.TotalSeconds -ge $TimeoutSec) {
      try { $proc.Kill() } catch {}
      throw "Hard timeout reached ($TimeoutSec s)."
    }

    if ($InactivitySec -gt 0 -and ((Get-Date) - $lastActivity).TotalSeconds -ge $InactivitySec) {
      try { $proc.Kill() } catch {}
      throw "No activity for $InactivitySec s (stdout/stderr/log)."
    }
  }

  # Flush remaining lines
 $null = Flush-Queue $stdoutQ 'child'
 $null = Flush-Queue $stderrQ 'child-err'
  Write-Host "`r`n[exit] code=$($proc.ExitCode)"
  exit $proc.ExitCode
}
finally {
  if ($cancelReg) { Unregister-Event -SourceIdentifier $cancelReg.Name -ErrorAction SilentlyContinue }
  Get-Event | Remove-Event -ErrorAction SilentlyContinue
  if (-not $proc.HasExited) { try { $proc.Kill() } catch {} }
}