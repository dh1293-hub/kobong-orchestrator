#requires -Version 7.0
param(
  [Parameter(Mandatory)][string]$Root,
  [Parameter(Mandatory)][string]$AppFile,
  [string]$ServerDir = 'server',
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# ── Repo & Lock ────────────────────────────────────────────────────────────────
$RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? (Resolve-Path $Root).Path
$AppPath  = Join-Path $RepoRoot $AppFile
$SrvPath  = Join-Path $RepoRoot $ServerDir
if (!(Test-Path $AppPath)) { Write-Error "App file not found: $AppPath"; exit 10 }
if (!(Test-Path $SrvPath)) { Write-Error "Server dir not found: $SrvPath"; exit 10 }

$LockFile = Join-Path $RepoRoot '.gpt5.lock'
if (Test-Path $LockFile) { Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -Encoding utf8 -NoNewline

function Write-JsonLog {
  param([string]$Level='INFO',[string]$Action='auto-wire',[string]$Outcome='INFO',[string]$Message='',[string]$Code='')
  $log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{
    timestamp=(Get-Date).ToString('o'); level=$Level; traceId=[guid]::NewGuid().ToString();
    module='g5-autowire'; action=$Action; outcome=$Outcome; errorCode=$Code; message=$Message
  } | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

try {
  # ── 1) 라우터 스캔 ───────────────────────────────────────────────────────────
  $pyFiles = Get-ChildItem -Path $SrvPath -Recurse -Include *.py -File |
             Where-Object { $_.FullName -notmatch '\\\.venv\\|\\__pycache__\\' }
  $rx = '^\s*(?<name>[A-Za-z_]\w*)\s*=\s*APIRouter\s*\('
  $routers = @()
  foreach($f in $pyFiles){
    $hits = Select-String -Path $f.FullName -Pattern $rx -AllMatches -CaseSensitive
    foreach($m in $hits){
      $name = $m.Matches[0].Groups['name'].Value
      $rel = Resolve-Path $f.FullName | ForEach-Object { $_.Path.Substring($SrvPath.Length).TrimStart('\') }
      $module = 'server.' + ($rel -replace '\\','.') -replace '\.py$',''
      $routers += [pscustomobject]@{ name=$name; module=$module; file=$f.FullName }
    }
  }
  if(-not $routers){ Write-JsonLog -Level ERROR -Outcome FAILURE -Code 'NO_ROUTERS' -Message "no APIRouter found under $SrvPath"; exit 10 }

  # ── 2) 별칭 전략(동명 router 충돌 방지) ───────────────────────────────────────
  function Get-Alias([string]$name,[string]$module){
    if ($name -ne 'router') { return $name }
    $suffix = ($module -replace '^server\.','') -replace '[^A-Za-z0-9_]', '_'
    return "router_$suffix"
  }
  $items = $routers | ForEach-Object {
    [pscustomobject]@{
      name   = $_.name
      module = $_.module
      alias  = Get-Alias $_.name $_.module
      file   = $_.file
    }
  } | Sort-Object module,name -Unique

  # ── 3) App 파일 로드 & 앵커 ──────────────────────────────────────────────────
  $text = Get-Content -LiteralPath $AppPath -Raw -Encoding utf8
  if (-not ($text -match '(?m)^\s*from\s+fastapi\s+import\s+FastAPI\s*$')) {
    $text = "from fastapi import FastAPI`n" + $text
  }
  $appMatch = [regex]::Match($text,'(?m)^(?<indent>\s*)app\s*=\s*FastAPI\([^\)]*\)\s*$')
  if (-not $appMatch.Success) { Write-JsonLog -Level ERROR -Outcome FAILURE -Code 'NO_APP' -Message 'app = FastAPI(...) not found'; exit 10 }
  $indent = $appMatch.Groups['indent'].Value

  # ── 4) Import/Include 계획(idempotent) ───────────────────────────────────────
  $plannedImports  = New-Object System.Collections.Generic.List[string]
  $plannedIncludes = New-Object System.Collections.Generic.List[string]

  foreach($it in $items){
    $needAlias = $it.alias -ne $it.name
    $impLine   = if($needAlias){"from $($it.module) import $($it.name) as $($it.alias)"} else {"from $($it.module) import $($it.name)"}
    $incLine   = "${indent}app.include_router($($it.alias))"

    # import: 이미 alias로 있으면 skip, 'from X import router'만 있으면 alias로 교체
    if ($text -match "(?m)^\s*from\s+$([regex]::Escape($it.module))\s+import\s+.*\b$([regex]::Escape($it.alias))\b\s*$") {
      # ok
    } elseif ($needAlias -and ($text -match "(?m)^\s*from\s+$([regex]::Escape($it.module))\s+import\s+.*\b$([regex]::Escape($it.name))\b\s*$")) {
      # replace to alias
      $text = [regex]::Replace($text, "(?m)^\s*from\s+$([regex]::Escape($it.module))\s+import\s+([^\r\n]*)\b$([regex]::Escape($it.name))\b([^\r\n]*)\s*$",
        { param($m) "from $($it.module) import $($it.name) as $($it.alias)" }, 1)
    } else {
      if (-not ($text -match "(?m)^\s*$([regex]::Escape($impLine))\s*$")) {
        $plannedImports.Add($impLine)
      }
    }

    # include: alias 기준으로 없으면 추가
    if (-not ($text -match "(?m)^\s*app\.include_router\(\s*$([regex]::Escape($it.alias))\s*\)\s*$")) {
      $plannedIncludes.Add($incLine)
    }
  }

  # ── 5) 미리보기/적용 ──────────────────────────────────────────────────────────
  Write-Host "`n[SCAN] routers:" -ForegroundColor Cyan
  $items | ForEach-Object { "{0} ← {1}  (alias: {2})" -f $_.name,$_.module,$_.alias } | Write-Host

  Write-Host "`n[PLAN] imports:" -ForegroundColor Cyan
  if($plannedImports.Count){ $plannedImports | Write-Host } else { '(none)' | Write-Host }

  Write-Host "`n[PLAN] include_router:" -ForegroundColor Cyan
  if($plannedIncludes.Count){ $plannedIncludes | Write-Host } else { '(none)' | Write-Host }

  if (-not $ConfirmApply) {
    Write-Host "`nDRY-RUN: set `$env:CONFIRM_APPLY='true' or pass -ConfirmApply to apply." -ForegroundColor Yellow
    Write-JsonLog -Outcome 'DRYRUN' -Message "imports=$($plannedImports.Count) includes=$($plannedIncludes.Count)"
    return
  }

  $backup = "$AppPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  Copy-Item -LiteralPath $AppPath -Destination $backup -Force

  # imports: import 블록(파일 상단) 뒤에 삽입
  if($plannedImports.Count){
    if ($text -match '^(?<head>(?:\s*(?:from\s+\S+\s+import\s+.*|import\s+.*)\r?\n)+)'){
      $text = [regex]::Replace($text,'^(?<head>(?:\s*(?:from\s+\S+\s+import\s+.*|import\s+.*)\r?\n)+)',
        { param($m) $m.Groups['head'].Value + ($plannedImports -join "`n") + "`n" },1)
    } else {
      $text = ($plannedImports -join "`n") + "`n" + $text
    }
  }

  # includes: 앵커 다음 줄에 삽입
  if($plannedIncludes.Count){
    $pos = $appMatch.Index + $appMatch.Length
    $text = $text.Insert($pos, "`n" + ($plannedIncludes -join "`n"))
  }

  $tmp = "$AppPath.$([guid]::NewGuid().ToString('n')).tmp"
  $text | Out-File -LiteralPath $tmp -Encoding utf8 -NoNewline
  Move-Item -LiteralPath $tmp -Destination $AppPath -Force

  Write-JsonLog -Outcome 'SUCCESS' -Message "wired imports=$($plannedImports.Count) includes=$($plannedIncludes.Count); backup=$(Split-Path -Leaf $backup)"
  Write-Host "`n[APPLIED] imports=$($plannedImports.Count) includes=$($plannedIncludes.Count) — backup: $backup" -ForegroundColor Green
}
catch {
  Write-JsonLog -Outcome 'FAILURE' -Level 'ERROR' -Code 'LOGIC' -Message $_.Exception.Message
  throw
}
finally {
  Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
  Read-Host "`n끝! Enter 를 누르면 창을 닫습니다"
}