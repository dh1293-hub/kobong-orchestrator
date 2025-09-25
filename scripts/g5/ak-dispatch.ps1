#requires -PSEdition Core
#requires -Version 7.0
param(
  [string]$RawComment,
  [string]$Sha,
  [string]$Pr
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RawComment) {
  Write-Host "[AK] no comment body"
  exit 0
}

if ($RawComment -notmatch '/ak\s+([a-z0-9\-]+)(.*)') {
  Write-Host "[AK] '/ak' not found"
  exit 0
}

$cmd  = $matches[1]
$args = ($matches[2] ?? '').Trim()

switch ($cmd) {
  'ping' {
    Write-Host "[AK] command=ping args='$args' sha=$Sha pr=$Pr (stub ok)"
    exit 0
  }
  'scan' {
    Write-Host "[AK] command=scan args='$args' (not-implemented-yet)"
    exit 0
  }
  'test' {
    Write-Host "[AK] command=test args='$args' (not-implemented-yet)"
    exit 0
  }
  default {
    Write-Host "[AK] unknown command='$cmd' args='$args'"
    exit 0
  }
}