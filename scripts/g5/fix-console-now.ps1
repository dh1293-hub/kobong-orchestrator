#requires -Version 7
<#
  fix-console-now.ps1
  - 404 브릿지 파일 경로 보정(복사)
  - ORCHMON WebSocket 호스트 가드 인라인 주입
  - apply-patches.ps1 재주입으로 MODE/BASE 동기화
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (git rev-parse --show-toplevel 2>$null); if(-not $root){ $root = (Get-Location).Path }
$root = (Resolve-Path $root).Path

function Copy-If { param($src,$dstDir,$dstName)
  if(Test-Path $src){
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Copy-Item $src (Join-Path $dstDir $dstName) -Force
    Write-Host "[OK] Copied $(Split-Path $src -Leaf) -> $dstDir\$dstName"
  } else {
    Write-Host "[SKIP] not found: $src"
  }
}

# 1) AK7 브릿지 404 해결: public/booster → webui 루트로 복사
$akWebui = Join-Path $root 'AUTO-Kobong-Monitoring\webui'
Copy-If (Join-Path $akWebui 'public\booster\ak7-bridge.js') $akWebui 'ak7-bridge.js'

# 2) ORCHMON WebSocket 가드 인라인 주입(멱등)
$orchHtml = Get-ChildItem -Path (Join-Path $root 'Orchestrator-Monitoring') -Filter 'Orchestrator-Monitoring-Su.html' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
if($orchHtml){
  $t = Get-Content -Raw -LiteralPath $orchHtml.FullName
  if($t -notmatch '__G5_ws_fix'){
    if($t -notmatch '</body>'){ throw "No </body> tag in $($orchHtml.FullName)" }
    $wsfix = @'
<!-- __G5_ws_fix -->
<script>
(function(){
  var W=window.WebSocket;
  // host가 비면(파일로 열었을 때) ws://:PORT → ws://localhost:PORT 로 보정
  window.WebSocket = function(u,p){
    try{ u=u.replace(/^ws:\/\/:(\d+)\//,'ws://localhost:$1/'); }catch(e){}
    return new W(u,p);
  };
  for (var k in W){ try{ window.WebSocket[k]=W[k]; }catch(e){} }
})();
</script>
'@
    $t = $t -replace '</body>', ($wsfix + "`r`n</body>")
    Set-Content -LiteralPath $orchHtml.FullName -Value $t -NoNewline
    Write-Host "[OK] WS guard injected → $($orchHtml.FullName)"
  } else { Write-Host "[SKIP] WS guard already present" }
} else { Write-Host "[SKIP] Orchestrator-Monitoring-Su.html not found" }

# 3) apply-patches 재주입(기본: DEV/ or 필요 시 MOCK)
$ap = Join-Path $root 'scripts\g5\apply-patches.ps1'
if(Test-Path $ap){
  # 현재 MOCK 모드 쓰시는 흐름이라면 아래 줄의 -Mode MOCK 사용
  try{
    pwsh -NoProfile -File $ap -Mode MOCK
  }catch{
    Write-Warning "apply-patches 실행에 실패했습니다: $($_.Exception.Message)"
  }
}else{
  Write-Warning "apply-patches.ps1 not found at $ap"
}

Write-Host "`n--- Fix completed. Open pages via http://localhost:5181|5182|5183 to avoid file:// host-empty."
