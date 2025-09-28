# APPLY IN SHELL
#requires -Version 7.0
param(
  [string]$Repo = "D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator",
  [switch]$ConfirmApply
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'; $PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Append-LinesIfMissing([string]$Path,[string[]]$Lines){
  New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
  if (-not (Test-Path $Path)) { Set-Content -Path $Path -Value ($Lines -join "`n") -Encoding utf8; return }
  $existing = Get-Content -Path $Path -ErrorAction SilentlyContinue
  $append = @()
  foreach($l in $Lines){ if ($existing -notcontains $l) { $append += $l } }
  if ($append.Count -gt 0) { Add-Content -Path $Path -Value ($append -join "`n") -Encoding utf8 }
}

function Ensure-GitPolicies {
  param([string]$Repo)
  $gitignore = Join-Path $Repo ".gitignore"
  $gi = @(
    "# kobong-orchestrator (auto)",
    "webui/node_modules/",
    "node_modules/",
    "webui/.env*",
    ".env*",
    "backups/",
    ".rollbacks/",
    ".gpt5.spawn.*",
    ".kobong/.acl-backups/",
    ".kobong/patches.pending.txt",
    ".git/hooks/",
    "dist/","build/","coverage/","out/","target/","bin/","obj/",
    ".DS_Store","Thumbs.db",".vscode/",".idea/"
  )
  Append-LinesIfMissing -Path $gitignore -Lines $gi

  $gitattrib = Join-Path $Repo ".gitattributes"
  $ga = @(
    "* text=auto eol=lf",
    "*.ps1 text eol=lf",
    "*.cmd text eol=crlf"
  )
  Append-LinesIfMissing -Path $gitattrib -Lines $ga
}

function Remove-Legacy-OpenPS7 {
  param([string]$Repo)
  $globs = @("scripts/g5/open-ps7-strong-*.cmd")
  foreach($g in $globs){
    $files = Get-ChildItem -Path (Join-Path $Repo $g) -File -ErrorAction SilentlyContinue
    foreach($f in $files){
      try{
        attrib -R $f.FullName 2>$null; Unblock-File -LiteralPath $f.FullName 2>$null
        # 워킹트리 삭제 + 인덱스 제거(추적 중이면)
        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
        $rel = [IO.Path]::GetRelativePath($Repo, $f.FullName).Replace('\','/')
        git -C $Repo rm -f --ignore-unmatch -- "$rel" 1>$null 2>$null
        Write-Host "[-] removed $rel"
      } catch { Write-Host "[warn] skip $($f.Name): $($_.Exception.Message)" -ForegroundColor Yellow }
    }
  }
}

# ── 시작
$Repo = (Resolve-Path $Repo).Path
Push-Location $Repo
try {
  # 1) 정책파일 확보(.gitignore/.gitattributes)
  Ensure-GitPolicies -Repo $Repo

  # 2) 레거시 .cmd 정리(요청사항: open-ps7-strong-*.cmd 제거)
  Remove-Legacy-OpenPS7 -Repo $Repo

  # 3) 스테이징(무시목록을 먼저 확정했으니 add -A 해도 안전)
  #    단, webui/node_modules, backups, .rollbacks 등은 .gitignore로 제외됨
  git add -A

  # 4) CRLF↔LF 재정규화 (정책 반영)
  git add --renormalize . 2>$null

  # 5) 상태 요약 보여주기
  Write-Host "`n--- STAGED SUMMARY ---" -ForegroundColor Cyan
  git status -s

  if (-not $ConfirmApply) {
    Write-Host "`n[PLAN] 위 변경이 커밋/푸시 대상입니다. 적용하려면 -ConfirmApply 또는 `$env:CONFIRM_APPLY='true'`." -ForegroundColor Yellow
    exit 0
  }

  # 6) 커밋(변경 없으면 스킵)
  $diff = git diff --cached --name-only
  if ([string]::IsNullOrWhiteSpace($diff)) {
    Write-Host "[SKIP] 스테이징된 변경이 없습니다."
    exit 0
  }
  git commit -m "chore: curate repo (ignore node_modules/env; add workflows/hooks/webui/docs; normalize EOL)"
  git push
  Write-Host "`n[OK] 커밋/푸시 완료." -ForegroundColor Green
}
finally {
  Pop-Location
}
