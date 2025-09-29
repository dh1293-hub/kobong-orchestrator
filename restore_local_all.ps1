#requires -PSEdition Core
#requires -Version 7.0
param([string]$Root="D:\ChatGPT5_AI_Link\dosc\kobong-orchestrator")
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
$Apply = ($env:CONFIRM_APPLY -eq 'true')

function LogKLC([string]$lvl='INFO',[string]$action='restore-all',[string]$outcome='DRYRUN',[string]$msg=''){
  try{
    if(Get-Command kobong_logger_cli -ErrorAction SilentlyContinue){
      & kobong_logger_cli log --level $lvl --module 'restore' --action $action --outcome $outcome --message $msg 2>$null; return
    }
  }catch{}
  $log = Join-Path $Root 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec=@{timestamp=(Get-Date).ToString('o');level=$lvl;module='restore';action=$action;outcome=$outcome;message=$msg}|ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

if(-not (Test-Path -LiteralPath $Root)){ throw "루트가 없어요: $Root" }
Push-Location $Root
try{
  # 0) 잠금 & 환경 점검
  $lock='.gpt5.lock'; if(Test-Path $lock){ throw "CONFLICT: $lock 존재" }
  'locked ' + (Get-Date -Format o) | Out-File $lock -NoNewline
  $gitOk = (Get-Command git -ErrorAction SilentlyContinue) -ne $null -and (Test-Path '.git')

  # 1) Git 추적 파일 복구(삭제된 것만 HEAD로 되살림; 수정본은 건드리지 않음)
  $restoredGit=@()
  if($gitOk){
    $deleted = & git ls-files --deleted | Where-Object { $_ }
    foreach($rel in $deleted){
      if($Apply){ & git restore --source=HEAD --worktree -- "$rel" | Out-Null }
      $restoredGit += $rel
    }
    LogKLC -msg ("git 복구 대상 {0}건" -f $restoredGit.Count)
  }

  # 2) URS(.rollbacks / GOOD)에서 복구 (Git에 없거나 미추적이던 파일 포함)
  function Find-URS([string]$rel){
    # 최신 .rollbacks 아래 동일 파일명 후보
    $name=[IO.Path]::GetFileName($rel)
    Get-ChildItem -LiteralPath $Root -Filter "$name*" -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match '\\\.rollbacks\\' } |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
  }
  function Restore-URS([string]$rel){
    $abs = Join-Path $Root $rel
    if(Test-Path $abs){ return $false }
    $cand = Find-URS $rel
    if($cand){
      New-Item -ItemType Directory -Force -Path (Split-Path $abs) | Out-Null
      $tmp = $abs + '.tmp'
      Get-Content -LiteralPath $cand.FullName -Raw -Encoding UTF8 | Set-Content -LiteralPath $tmp -Encoding UTF8
      if($Apply){ Move-Item -LiteralPath $tmp -Destination $abs -Force } else { Remove-Item $tmp -Force }
      return $true
    }
    return $false
  }

  # 2-a) 중요 경로 우선 복구(세 모듈 webui 폴더 전체)
  $targets = @(
    'AUTO-Kobong\webui',
    'GitHub-Moniteoling\webui',
    'Orchestrator-Moniteoling\webui'
  )
  $ursRestored=@()
  foreach($t in $targets){
    if(Test-Path $t){
      # 비어있다면 과거 html을 .rollbacks에서 찾아 복원 시도
      $need = Get-ChildItem -LiteralPath $t -Filter *.html -ErrorAction SilentlyContinue
      if(-not $need){
        foreach($name in @('AUTO-Kobong-Han.html','GitHub-Moniteoling-Min.html','Orchestrator-Moniteoling-Su.html')){
          $rel = Join-Path $t $name
          if(Restore-URS $rel){ $ursRestored += $rel }
        }
      }
    } else {
      # 폴더 자체가 없으면 만들어두고 핵심 html 이름들 탐색 복원
      New-Item -ItemType Directory -Force -Path $t | Out-Null
      foreach($name in @('AUTO-Kobong-Han.html','GitHub-Moniteoling-Min.html','Orchestrator-Moniteoling-Su.html')){
        $rel = Join-Path $t $name
        if(Restore-URS $rel){ $ursRestored += $rel }
      }
    }
  }
  LogKLC -msg ("URS 복구 {0}건" -f $ursRestored.Count)

  # 3) 스켈레톤(최후 폴백) 생성 — 아직도 핵심 HTML이 없으면 생성
  function Ensure-Skeleton([string]$dir,[string]$file,[string]$ns,[int]$port,[string]$bridge){
    $abs = Join-Path $dir $file
    if(Test-Path $abs){ return $false }
    $html = @"
<!doctype html><html lang="ko"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>${ns} 모니터</title>
<style>body{background:#0B0F12;color:#E6F1FF;font:16px/1.6 system-ui} .wrap{max-width:1100px;margin:32px auto;padding:16px}
.row{display:flex;flex-wrap:wrap;gap:12px;margin-bottom:16px}.btn{min-width:140px;padding:14px 16px;border:1px solid #334155;border-radius:12px;background:#10151A;color:#E6F1FF}
.btn:focus{outline:3px solid #22D3EE}#messages{border:1px solid #22303c;border-radius:12px;padding:12px}</style></head><body>
<div class="wrap"><h1>${ns} 콘솔</h1><div class="row">
<button class="btn" data-act="next">다음 단계</button>
<button class="btn" data-act="stop">중단</button>
<button class="btn" data-act="fix-preview">Fix 미리보기</button>
<button class="btn" data-act="fix-apply">Fix 적용</button>
<button class="btn" data-act="good">Mark Good</button>
<button class="btn" data-act="rollback">Rollback</button>
<button class="btn" data-act="shell-open">셸 열기</button>
<button class="btn" data-act="logs-export">로그 Export</button>
</div><section id="messages"></section></div>
<script>window.${ns}_API_BASE='http://localhost:${port}/api/${ns.ToLower()}';</script>
<script src="${bridge}"></script>
<script>(function(){const m=document.getElementById('messages');function toast(t){const p=document.createElement('div');p.textContent='[fallback] '+t;m.prepend(p)}
document.querySelectorAll('[data-act]').forEach(b=>b.addEventListener('click',()=>toast(b.dataset.act+' (브릿지 미설치)'))); toast('브릿지 미설치 — Fallback 모드');})();</script>
</body></html>
"@
    if($Apply){ $html | Set-Content -LiteralPath $abs -Encoding UTF8 }
    return $true
  }

  $skel=@()
  $skel += (Ensure-Skeleton (Join-Path $Root 'AUTO-Kobong\webui') 'AUTO-Kobong-Han.html' 'AK7' 5181 'ak7-bridge.js')
  $skel += (Ensure-Skeleton (Join-Path $Root 'GitHub-Moniteoling\webui') 'GitHub-Moniteoling-Min.html' 'GHMON' 5182 'ghmon-bridge.js')
  $skel += (Ensure-Skeleton (Join-Path $Root 'Orchestrator-Moniteoling\webui') 'Orchestrator-Moniteoling-Su.html' 'ORCHMON' 5183 'orchmon-bridge.js')
  $skelCount = ($skel | Where-Object { $_ }) .Count
  if($skelCount){ LogKLC -msg ("스켈레톤 생성 {0}건" -f $skelCount) }

  # 4) 요약 출력
  Write-Host "`n== 복구 요약 =="
  Write-Host ("Git 추적 복구: {0}건" -f $restoredGit.Count)
  Write-Host ("URS(.rollbacks) 복구: {0}건" -f $ursRestored.Count)
  Write-Host ("스켈레톤 생성: {0}건" -f $skelCount)
  if(-not $Apply){
    Write-Host "`n[안내] 실제 반영하려면:"
    Write-Host '  $env:CONFIRM_APPLY="true"; pwsh -File .\restore_local_all.ps1'
  }

} finally {
  if(Test-Path $lock){ Remove-Item $lock -Force -ErrorAction SilentlyContinue }
  Pop-Location
}
