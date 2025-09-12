#requires -PSEdition Core
#requires -Version 7.0
param(
  [string[]] $WatchPaths,                # default: 'domain'
  [string]   $Filter          = '*.dsl', # 여러개: "*.dsl,*.ps1"
  [switch]   $IncludeSubdirs,
  [int]      $DebounceMs      = 1200,
  [switch]   $NoInitial,
  [switch]   $OpenExplorer,
  [switch]   $NoZip,
  [switch]   $GhUpload,
  [string]   $Tag,
  [string]   $DslFile
)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
Write-Host '[WARN] Watch Mode — CTRL+C 또는 Q로 종료. Enter=즉시 실행' -ForegroundColor DarkYellow

function Get-GitRoot { try { git rev-parse --show-toplevel 2>$null } catch { $null } }
$RepoRoot = $env:HAN_GPT5_ROOT; if (-not $RepoRoot) { $RepoRoot = Get-GitRoot }
if (-not $RepoRoot) { $RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path }
if (-not (Test-Path $RepoRoot)) { throw "PRECONDITION: RepoRoot not found: $RepoRoot" }
$env:HAN_GPT5_ROOT = $RepoRoot; Set-Location $RepoRoot

$AutoProvide = Join-Path $RepoRoot 'scripts/auto-provide.ps1'
if (-not (Test-Path $AutoProvide)) { throw "PRECONDITION: scripts/auto-provide.ps1 not found" }

if (-not $WatchPaths -or $WatchPaths.Count -eq 0) { $WatchPaths = @('domain') }
if (-not $IncludeSubdirs.IsPresent) { $IncludeSubdirs = $true }
if (-not $DslFile) { $DslFile = Join-Path $RepoRoot 'domain/dsl.demo.dsl' }

$Filters = $Filter.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$IgnoreRegex = [regex]'(\.swp$|\.tmp$|~$|\.part$|\.crdownload$|^~\$)'
$TriggerLock = New-Object object
$script:pending = $false
$script:lastEventAt = Get-Date

function Should-Ignore([string]$path) {
  if ([string]::IsNullOrWhiteSpace($path)) { return $true }
  if (Test-Path $path -PathType Container) { return $true }
  if ($IgnoreRegex.IsMatch($path)) { return $true }
  return $false
}
function Mark-Change([string]$why, [string]$path) {
  if (Should-Ignore $path) { return }
  [void][System.Threading.Monitor]::Enter($TriggerLock)
  try { $script:pending = $true; $script:lastEventAt = Get-Date; Write-Host ("[WATCH] {0}: {1}" -f $why, $path) }
  finally { [System.Threading.Monitor]::Exit($TriggerLock) }
}
function Invoke-Pipeline {
  Write-Host "[RUN] auto-provide.ps1" -ForegroundColor Cyan
  $argsList = @()
  if ($OpenExplorer) { $argsList += '-OpenExplorer' }
  if ($NoZip)       { $argsList += '-NoZip' }
  if ($GhUpload)    { $argsList += '-GhUpload' }
  if ($Tag)         { $argsList += @('-Tag', $Tag) }
  if ($DslFile)     { $argsList += @('-DslFile', $DslFile) }
  $psi = @('-NoLogo','-NoProfile','-File', $AutoProvide) + $argsList
  try { & pwsh @psi; if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] auto-provide exit=$LASTEXITCODE" -ForegroundColor Red } else { Write-Host "[PASS] auto-provide done." -ForegroundColor Green } }
  catch { Write-Host "[ERR] $($_.Exception.Message)" -ForegroundColor Red }
}

$watchers = @(); $subs = @()
foreach ($p in $WatchPaths) {
  $full = Resolve-Path $p -ErrorAction SilentlyContinue
  if (-not $full) { Write-Warning "Watch path not found: $p"; continue }
  foreach ($f in $Filters) {
    $w = New-Object System.IO.FileSystemWatcher
    $w.Path = $full.Path
    $w.Filter = $f
    $w.IncludeSubdirectories = [bool]$IncludeSubdirs
    $w.NotifyFilter = [IO.NotifyFilters]::FileName -bor [IO.NotifyFilters]::LastWrite -bor [IO.NotifyFilters]::DirectoryName
    $w.EnableRaisingEvents = $true
    $watchers += $w
    $subs += Register-ObjectEvent -InputObject $w -EventName Changed -Action { Mark-Change 'Changed' $Event.SourceEventArgs.FullPath }
    $subs += Register-ObjectEvent -InputObject $w -EventName Created -Action { Mark-Change 'Created' $Event.SourceEventArgs.FullPath }
    $subs += Register-ObjectEvent -InputObject $w -EventName Renamed -Action { Mark-Change 'Renamed' $Event.SourceEventArgs.FullPath }
    Write-Host ("[ON] Watching: {0} (filter={1}, subdirs={2})" -f $w.Path, $w.Filter, $w.IncludeSubdirectories)
  }
}
if ($watchers.Count -eq 0) { throw "PRECONDITION: no watchers active (check paths/filters)" }

if (-not $NoInitial) { Write-Host "[BOOT] Initial pipeline run..." -ForegroundColor DarkCyan; Invoke-Pipeline }

Write-Host "[READY] Watching for changes. Press ENTER to run now, 'Q' to quit." -ForegroundColor DarkYellow
try {
  while ($true) {
    Start-Sleep -Milliseconds 200
    if ([Console]::KeyAvailable) {
      $key = [Console]::ReadKey($true)
      if ($key.Key -eq 'Enter') { Mark-Change 'Manual' 'console:enter' }
      elseif ($key.Key -eq 'Q') { Write-Host "[EXIT] Quit requested (Q)." -ForegroundColor DarkYellow; break }
    }
    $doRun = $false
    [void][System.Threading.Monitor]::Enter($TriggerLock)
    try { if ($script:pending) { $elapsed = (Get-Date) - $script:lastEventAt; if ($elapsed.TotalMilliseconds -ge $DebounceMs) { $script:pending = $false; $doRun = $true } } }
    finally { [System.Threading.Monitor]::Exit($TriggerLock) }
    if ($doRun) { Invoke-Pipeline }
  }
} finally {
  foreach ($s in $subs) { Unregister-Event -SourceIdentifier $s.Name -ErrorAction SilentlyContinue }
  foreach ($w in $watchers) { $w.EnableRaisingEvents = $false; $w.Dispose() }
  Write-Host "[CLEAN] Watchers disposed." -ForegroundColor DarkGray
}
