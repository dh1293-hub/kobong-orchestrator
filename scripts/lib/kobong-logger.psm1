#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
function New-KobongTrace { [guid]::NewGuid().ToString() }
function Write-KobongLog {
  [CmdletBinding()]
  param(
    [ValidateSet('INFO','ERROR','DEBUG')] [string]$Level = 'INFO',
    [string]$Module = 'orchestrator',
    [string]$Action = 'run',
    [string]$InputHash = '',
    [ValidateSet('SUCCESS','FAILURE','DRYRUN')] [string]$Outcome = 'SUCCESS',
    [int]$DurationMs = 0,
    [string]$ErrorCode = '',
    [string]$Message = '',
    [string]$TraceId
  )
  if (-not $TraceId) { $TraceId = New-KobongTrace }
  $root = try { (& git rev-parse --show-toplevel 2>$null) } catch { (Get-Location).Path }
  $logDir = Join-Path $root 'logs'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $log = Join-Path $logDir 'apply-log.jsonl'
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; traceId=$TraceId; module=$Module; action=$Action;
    inputHash=$InputHash; outcome=$Outcome; durationMs=$DurationMs; errorCode=$ErrorCode; message=$Message
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
  return $TraceId
}
Export-ModuleMember -Function Write-KobongLog,New-KobongTrace

# --- XP(Experience) helpers ---
function Get-KobongStatePath {
  $root = try { (& git rev-parse --show-toplevel 2>$null) } catch { (Get-Location).Path }
  $dir = Join-Path $root '.kobong/state'
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Join-Path $dir 'experience.json'
}
function Read-KobongExperience {
  $p = Get-KobongStatePath
  if (Test-Path $p) {
    try { return (Get-Content -Raw -LiteralPath $p | ConvertFrom-Json -AsHashtable) } catch {}
  }
  return @{ version=1; totalFixes=0; xp=0; sinceLastSave=0; lastUpdated=(Get-Date).ToString('o') }
}
function Write-KobongExperience {
  param([hashtable]$State)
  $State['lastUpdated'] = (Get-Date).ToString('o')
  $p = Get-KobongStatePath
  $dir = Split-Path -Parent $p
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $tmp = Join-Path $dir '.experience.json.tmp'
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($tmp, ($State | ConvertTo-Json -Depth 5), $utf8)
  Move-Item $tmp $p -Force
  return $p
}
function Add-KobongFixExperience {
  [CmdletBinding()]
  param([int]$Count=1,[int]$Threshold=5)
  $s = Read-KobongExperience
  $s.totalFixes += $Count
  $s.sinceLastSave += $Count
  $added=0
  while ($s.sinceLastSave -ge $Threshold) { $s.xp += 1; $s.sinceLastSave -= $Threshold; $added++ }
  $p = Write-KobongExperience $s
  if (Get-Command Write-KobongLog -ErrorAction SilentlyContinue) {
     $msg = "exp: +$Count fix(es); +$added xp (threshold=$Threshold); totalFixes=$($s.totalFixes); xp=$($s.xp)"
     Write-KobongLog -Level INFO -Module 'xp' -Action 'add-fix' -Outcome 'SUCCESS' -Message $msg | Out-Null
  }
  [pscustomobject]@{ path=$p; totalFixes=$s.totalFixes; xp=$s.xp; pending=$s.sinceLastSave; addedXp=$added }
}
function Reset-KobongExperience {
  $s=@{ version=1; totalFixes=0; xp=0; sinceLastSave=0; lastUpdated=(Get-Date).ToString('o') }
  $p = Write-KobongExperience $s
  if (Get-Command Write-KobongLog -ErrorAction SilentlyContinue) {
     Write-KobongLog -Level INFO -Module 'xp' -Action 'reset' -Outcome 'SUCCESS' -Message 'experience reset' | Out-Null
  }
  [pscustomobject]@{ path=$p; totalFixes=0; xp=0; pending=0 }
}
function Show-KobongExperience {
  $s = Read-KobongExperience
  [pscustomobject]@{ totalFixes=$s.totalFixes; xp=$s.xp; pending=$s.sinceLastSave; lastUpdated=$s.lastUpdated; version=$s.version; path=(Get-KobongStatePath) }
}
# --- end XP helpers ---

Export-ModuleMember -Function Write-KobongLog,New-KobongTrace,Add-KobongFixExperience,Reset-KobongExperience,Show-KobongExperience

function Write-KobongFix {
  [CmdletBinding()]
  param(
    [string]$Module='orchestrator',
    [string]$Action='fix',
    [string]$Message='fix applied',
    [int]$Count=1,
    [int]$Threshold=5
  )
  $tid = Write-KobongLog -Level INFO -Module $Module -Action $Action -Outcome SUCCESS -Message $Message
  $res = Add-KobongFixExperience -Count $Count -Threshold $Threshold
  [pscustomobject]@{ TraceId=$tid; TotalFixes=$res.totalFixes; XP=$res.xp; AddedXp=$res.addedXp; Pending=$res.pending }
}
Export-ModuleMember -Function Write-KobongFix
