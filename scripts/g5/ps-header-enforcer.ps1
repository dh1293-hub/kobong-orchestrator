#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root='.')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
Set-Location $RepoRoot
$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

$sw=[Diagnostics.Stopwatch]::StartNew()
$trace=[guid]::NewGuid().ToString()
$logFile = Join-Path $RepoRoot 'logs/apply-log.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $logFile) | Out-Null
function Log($lvl,$act,$msg,$outcome='OK',$code=0) {
  $rec=@{timestamp=(Get-Date).ToString('o');level=$lvl;traceId=$trace;module='ps7-enforcer';action=$act;inputHash='';outcome=$outcome;durationMs=$sw.ElapsedMilliseconds;errorCode=$code;message=$msg}|ConvertTo-Json -Compress
  Add-Content -Path $logFile -Value $rec
}

try {
  $files = Get-ChildItem -Recurse -Filter *.ps1 |
           Where-Object { $_.FullName -notmatch '\\.githooks\\' }

  $fixes = @()
  foreach ($f in $files) {
    $raw = Get-Content -Raw $f.FullName
    $orig = $raw

    # 1) #requires -Version 7.0 없으면 맨 위에 삽입
    if ($raw -notmatch '(?m)^\s*#requires\s+-Version\s+7\.0\b') {
      $raw = "#requires -Version 7.0`n" + $raw
    }

    # 2) param 블록 없으면 기본 param 추가(빈 파라미터)
    if ($raw -notmatch '(?ms)^\s*param\s*\(') {
      $raw = ( "#requires -Version 7.0`nparam()`n" + ($raw -replace '^\s*#requires[^\n]*\n','') )
    }

    # 3) Set-StrictMode -Version Latest 없으면 param 바로 아래에 삽입
    if ($raw -notmatch '(?m)^\s*Set-StrictMode\s+-Version\s+Latest\b') {
      $raw = $raw -replace '(?ms)^(?<head>\s*#requires[^\n]*\n\s*param\s*\([^\)]*\)\s*)','${head}Set-StrictMode -Version Latest`n$ErrorActionPreference=''Stop''`n$PSDefaultParameterValues[''*:Encoding'']=''utf8''`n'
    }

    if ($raw -ne $orig) {
      $fixes += [pscustomobject]@{Path=$f.FullName; BeforeLen=$orig.Length; AfterLen=$raw.Length }
      if ($ConfirmApply) {
        $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
        $bak = "$($f.FullName).bak-$ts"
        Copy-Item $f.FullName $bak
        $tmp = "$($f.FullName).tmp-$ts"
        $raw | Out-File $tmp -Encoding utf8 -NoNewline
        Move-Item -Force $tmp $f.FullName
      }
    }
  }

  if ($fixes.Count -eq 0) {
    Write-Host "[INFO] no files needed changes"
    Log 'INFO' 'scan' 'no changes'
    exit 0
  }

  # 요약 출력
  $fixes | ForEach-Object { "{0}" -f $_.Path } | Write-Host

  if ($ConfirmApply) {
    Log 'INFO' 'apply' ("fixed="+$fixes.Count)
    Write-Host "`n[OK] applied fixes to $($fixes.Count) files"
  } else {
    Log 'INFO' 'preview' ("would-fix="+$fixes.Count) 'PREVIEW'
    Write-Host "`n[PREVIEW] would fix $($fixes.Count) files. Set `"$env:CONFIRM_APPLY='true'`" and pass -ConfirmApply to apply."
  }
  exit 0
} catch {
  Log 'ERROR' 'run' $_.Exception.Message 'FAILURE' 13
  Write-Error $_.Exception.Message
  exit 13
} finally {
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}