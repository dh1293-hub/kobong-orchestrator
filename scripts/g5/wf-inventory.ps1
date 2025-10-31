# scripts/g5/wf-inventory.ps1
# 친절한 주석: 목적/용도/보안/출력 위치
# - 목적: 리포의 모든 GitHub Actions 워크플로(YAML) 자동 수집→요약→_inventory 저장
# - 사용법:
#     pwsh -NoProfile -File scripts/g5/wf-inventory.ps1 -Repo dh1293-hub/kobong-orchestrator -Ref main
# - 출력: _inventory/workflows.csv, _inventory/workflows.json (멱등)
# - 보안: 읽기 전용(zipball). 토큰 있으면 헤더로 사용(속도↑).
param(
  [string]$Repo = "dh1293-hub/kobong-orchestrator",
  [string]$Ref  = "main"
)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'

$root = (Get-Location).Path
$inv  = Join-Path $root "_inventory"
$tmp  = Join-Path $env:RUNNER_TEMP "wfscan"; if (-not $env:RUNNER_TEMP) { $tmp = Join-Path $env:TEMP "wfscan" }
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; New-Item $tmp -ItemType Directory|Out-Null
New-Item $inv -ItemType Directory -Force|Out-Null

$zipUrl = "https://api.github.com/repos/$Repo/zipball/$Ref"
$zip    = Join-Path $tmp "src.zip"
$h=@{}; if ($env:GH_TOKEN) { $h['Authorization']="Bearer $env:GH_TOKEN"; $h['X-GitHub-Api-Version']='2022-11-28' }
Invoke-WebRequest -Uri $zipUrl -OutFile $zip -Headers $h

$unz = Join-Path $tmp "unz"; Expand-Archive -Path $zip -DestinationPath $unz
$files = Get-ChildItem -Path $unz -Recurse -Filter *.yml | ? { $_.FullName -match "\\.github\\workflows\\.+\.yml$" }

$rows = foreach($f in $files){
  $t = Get-Content $f.FullName -Raw
  $name = if($t -match "^\s*name\s*:\s*(.+)$"){ $Matches[1].Trim() } else { "(no name)" }
  $onBlock = [string]::Join(" ", ($t -split "`n" | ?{$_ -match '^\s*on\s*:'} .. ($t -split "`n").Count))  # 러프 추출
  $has = @{
    dispatch = $t -match 'workflow_dispatch'
    pr       = $t -match '(^|\n)\s*(pull_request|pull_request_target)\s*:'
    push     = $t -match '(^|\n)\s*push\s*:'
    issuecmt = $t -match 'issue_comment'
    sched    = $t -match 'schedule\s*:'
    release  = $t -match '(^|\n)\s*release\s*:'
    repoDisp = $t -match 'repository_dispatch'
  }
  $perm = if($t -match '^\s*permissions\s*:\s*(.+)$'){ $Matches[1].Trim() } else { "(default)" }
  $conc = if($t -match '^\s*concurrency\s*:\s*(.+)$'){ $Matches[1].Trim() } else { "" }
  [pscustomobject]@{
    file = $f.FullName.Substring($unz.Length+1).Replace('\','/')
    name = $name
    on   = ($onBlock -replace '\s+',' ').Trim()
    permissions = $perm
    concurrency = $conc
    has_workflow_dispatch = $has.dispatch
    has_pull_request      = $has.pr
    has_push              = $has.push
    has_issue_comment     = $has.issuecmt
    has_schedule          = $has.sched
    has_release           = $has.release
    has_repository_dispatch = $has.repoDisp
  }
}

$csv = Join-Path $inv "workflows.csv"
$json= Join-Path $inv "workflows.json"
$rows | Sort-Object file | Export-Csv -NoTypeInformation -Path $csv
$rows | ConvertTo-Json -Depth 4 | Set-Content -Path $json
"생성됨: $csv", "생성됨: $json"
