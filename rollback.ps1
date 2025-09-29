# APPLY IN SHELL
#requires -PSEdition Core
#requires -Version 7.0
param(
  [switch]$ConfirmApply,
  [string]$Root,
  [string]$GoodSlot = "-1"
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ---------- KLC ----------
function Write-KLC {
  param(
    [string]$Level='INFO', [string]$Action='rollback-all',
    [ValidateSet('DRYRUN','SUCCESS','FAILURE')]$Outcome='DRYRUN',
    [string]$ErrorCode='', [string]$Message='', [int]$DurationMs=0
  )
  try {
    if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) {
      & kobong_logger_cli log --level $Level --module scripts --action $Action `
        --outcome $Outcome --error $ErrorCode --message $Message `
        --duration-ms $DurationMs 2>$null
      return
    }
  } catch {}
  $repo = Get-Location
  $log = Join-Path $repo 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; traceId=[guid]::NewGuid().ToString();
    module='scripts'; action=$Action; outcome=$Outcome; errorCode=$ErrorCode; message=$Message; durationMs=$DurationMs
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

# ---------- Util ----------
function Get-RepoRoot {
  if ($Root) { return (Resolve-Path $Root).Path }
  try { $r = git rev-parse --show-toplevel 2>$null; if ($r) { return (Resolve-Path $r).Path } } catch {}
  return (Get-Location).Path
}
function Get-Field { param($obj,[string]$name)
  if ($null -eq $obj) { return $null }
  if ($obj -is [hashtable]) { return ($obj.ContainsKey($name) ? $obj[$name] : $null) }
  $p = $obj.PSObject.Properties[$name]; if ($p) { return $p.Value } else { return $null }
}
function Test-MatchAnyLike([string]$s, [string[]]$patterns){
  if(-not $patterns -or $patterns.Count -eq 0){ return $true }
  foreach($p in $patterns){ if($s -like $p){ return $true } }
  return $false
}
function Test-MatchNoneLike([string]$s, [string[]]$patterns){
  if(-not $patterns -or $patterns.Count -eq 0){ return $true }
  foreach($p in $patterns){ if($s -like $p){ return $false } }
  return $true
}

# ---------- Manifest → Targets ----------
function Resolve-ManifestTargets {
  param([string]$Repo,[psobject]$Json)
  $out = @()
  $nsDefault = (Get-Field $Json 'namespace'); if(-not $nsDefault){ $nsDefault = 'default' }

  $arr = @()
  if ($Json.targets) { $arr = @($Json.targets) }
  elseif ($Json.files) { $arr = @($Json.files) }
  else { throw "Rollbackfile.json 에 targets/files 항목이 없습니다." }

  $idx = -1
  foreach($raw in $arr){
    $idx++
    if ($raw -is [string]) { $out += [pscustomobject]@{ rel=$raw; ns=$nsDefault }; continue }

    if ($raw -is [hashtable] -or $raw -is [pscustomobject]) {
      $ns = (Get-Field $raw 'namespace'); if(-not $ns){ $ns = $nsDefault }
      $p = $null
      foreach($k in @('path','rel','relPath','file','target')){
        $v = Get-Field $raw $k; if($v){ $p = [string]$v; break }
      }
      if (-not $p) { $out += [pscustomobject]@{ rel=''; ns=$ns; status='skip'; reason="bad-target-shape#${idx}" }; continue }

      $typ = (Get-Field $raw 'type'); if(-not $typ){ $typ = 'file' }
      if ($typ -eq 'dir') {
        $baseAbs = Resolve-Path (Join-Path $Repo $p) -ErrorAction SilentlyContinue
        if (-not $baseAbs) { $out += [pscustomobject]@{ rel=''; ns=$ns; status='skip'; reason="dir-not-found:$p" }; continue }
        $includes = @(); $inc = Get-Field $raw 'include'; if($inc){ $includes = @($inc) }
        $excludes = @(); $exc = Get-Field $raw 'exclude'; if($exc){ $excludes = @($exc) }

        $files = Get-ChildItem -LiteralPath $baseAbs.Path -Recurse -File -ErrorAction SilentlyContinue
        foreach($f in $files){
          $rel = [IO.Path]::GetRelativePath($Repo, $f.FullName)
          if( (Test-MatchAnyLike $rel $includes) -and (Test-MatchNoneLike $rel $excludes) ){
            $out += [pscustomobject]@{ rel=$rel; ns=$ns }
          }
        }
        continue
      } else {
        $out += [pscustomobject]@{ rel=$p; ns=$ns }; continue
      }
    }

    $out += [pscustomobject]@{ rel=''; ns=$nsDefault; status='skip'; reason="unknown-target-type#${idx}:$($raw.GetType().FullName)" }
  }

  # 여기서 한 번 더 배열화 보장
  return @($out | Where-Object { $_.rel })
}

# ---------- 파일 복원 ----------
function Restore-Target {
  param([string]$Repo,[string]$Rel,[string]$Namespace,[string]$GoodSlot)
  $dest = Join-Path $Repo $Rel
  $nsEff = ($Namespace ? $Namespace : 'default')
  $rbDir = Join-Path $Repo (Join-Path '.rollbacks' $nsEff)
  $name = Split-Path -Leaf $Rel
  $slotN = $GoodSlot.TrimStart('-')
  $goodPath = Join-Path $rbDir ("{0}.good-slot{1}" -f $name, $slotN)

  $src = $null
  if (Test-Path -LiteralPath $goodPath) { $src = $goodPath }
  else {
    $baks = Get-ChildItem -LiteralPath $rbDir -Filter ("{0}.bak-*" -f $name) -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($baks) { $src = $baks[0].FullName }
  }
  if (-not $src) { return [pscustomobject]@{ rel=$Rel; ns=$nsEff; status='skip'; reason='no-good-or-bak' } }

  if (-not $ConfirmApply) { return [pscustomobject]@{ rel=$Rel; ns=$nsEff; status='would-restore'; from=$src } }

  $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
  if (Test-Path -LiteralPath $dest) {
    $redo = Join-Path $rbDir ("{0}.redo-{1}" -f $name,$ts)
    New-Item -ItemType Directory -Force -Path (Split-Path $redo) | Out-Null
    Copy-Item -LiteralPath $dest -Destination $redo -Force
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
  }
  $tmp = "$dest.__tmp__"
  Copy-Item -LiteralPath $src -Destination $tmp -Force
  Move-Item -LiteralPath $tmp -Destination $dest -Force
  return [pscustomobject]@{ rel=$Rel; ns=$nsEff; status='restored'; from=$src }
}

# ---------- Main ----------
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$repo = Get-RepoRoot
Set-Location $repo
$lock = Join-Path $repo '.gpt5.lock'
New-Item -ItemType File -Force -Path $lock | Out-Null

try {
  $manifest = Join-Path $repo 'Rollbackfile.json'
  if (-not (Test-Path -LiteralPath $manifest)) {
    Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -ErrorCode 'PRECONDITION' -Message "Rollbackfile.json not found"
    throw "Rollbackfile.json 을 찾지 못했습니다."
  }
  $json = Get-Content -Raw -LiteralPath $manifest -Encoding UTF8 | ConvertFrom-Json

  # 배열화 강제
  $targets = @((Resolve-ManifestTargets -Repo $repo -Json $json) | Where-Object { $_ })
  if ( @($targets).Count -eq 0 ) {
    Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -ErrorCode 'PRECONDITION' -Message "No valid file targets in manifest"
    throw "Manifest에 유효한 파일 대상이 없습니다."
  }

  $results = foreach($it in $targets){
    Restore-Target -Repo $repo -Rel $it.rel -Namespace $it.ns -GoodSlot $GoodSlot
  }

  # Count 안전 계산
  $ok    = @($results | Where-Object status -eq 'restored').Count
  $would = @($results | Where-Object status -eq 'would-restore').Count
  $skip  = @($results | Where-Object status -eq 'skip').Count

  $sw.Stop()
  if ($ConfirmApply) {
    Write-KLC -Outcome 'SUCCESS' -Message "restored=$ok, skipped=$skip" -DurationMs $sw.ElapsedMilliseconds
    $results | Sort-Object status, rel | Format-Table -AutoSize
    Write-Host "`n[OK] 롤백 완료: restored=$ok, skipped=$skip"
    exit 0
  } else {
    Write-KLC -Outcome 'DRYRUN' -Message "would-restore=$would, skip=$skip" -DurationMs $sw.ElapsedMilliseconds
    $results | Sort-Object status, rel | Format-Table -AutoSize
    Write-Host "`n[DRY-RUN] 적용하려면 ① `$env:CONFIRM_APPLY='true' 후 재실행  또는  ② -ConfirmApply 스위치 추가"
    exit 0
  }
}
catch {
  $sw.Stop()
  if($env:RBK_DEBUG -eq '1'){
    Write-Host "`n[DEBUG] 예외: $($_.Exception.GetType().FullName): $($_.Exception.Message)"
    Write-Host "[DEBUG] StackTrace:`n$($_.ScriptStackTrace)"
  }
  Write-KLC -Level 'ERROR' -Outcome 'FAILURE' -ErrorCode 'Unknown' -Message $_.Exception.Message -DurationMs $sw.ElapsedMilliseconds
  Write-Error $_.Exception.Message
  exit 1
}
finally {
  Remove-Item -LiteralPath $lock -Force -ErrorAction SilentlyContinue
}
