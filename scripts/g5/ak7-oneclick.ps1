# APPLY IN SHELL — AK7 모의 서버(5192/5193) + HTML 주입 + 브라우저 2탭 자동 오픈
#requires -PSEdition Core
#requires -Version 7.0
param(
  [int]$PortA = 5192,
  [int]$PortB = 5193,
  [int]$WebPort = 8080,
  [string]$HtmlRel = 'GitHub-Moniteoling/webui/ghmon-sample.html'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'

# 0) 레포 루트
$repo = (git rev-parse --show-toplevel 2>$null); if(-not $repo){ $repo=(Get-Location).Path }

# 1) HTML에 포트 선택 스니펫 주입(영구 반영)
$path = Join-Path $repo $HtmlRel
New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null

$snippet = @'
<script>
(()=>{ const p=new URLSearchParams(location.search).get("api")||"5192";
  window.AK7_API_BASE=`http://localhost:${p}/api/ak7`;
  window.AK7_HEALTH  =`http://localhost:${p}/health`;
  console.log("[AK7] API_BASE =",window.AK7_API_BASE);
})();
</script>
'@

if(-not (Test-Path $path)){
  @"
<!doctype html><html lang="ko"><head><meta charset="utf-8"><title>AK7 Test</title>
<meta name="viewport" content="width=device-width, initial-scale=1"><style>
body{background:#0B0F14;color:#E6F0FF;font-family:system-ui,Segoe UI,Noto Sans KR,Arial,sans-serif;margin:0}
.toolbar{padding:12px;border-bottom:1px solid #121820}
.btn{height:40px;padding:0 12px;border-radius:8px;border:1px solid #65D1FF;background:#121820;color:#E6F0FF;cursor:pointer}
</style></head><body>
<div class="toolbar">
  <button class="btn" data-ak7-action="next">NEXT</button>
  <button class="btn" data-ak7-action="scan">SCAN</button>
  <button class="btn" data-ak7-action="test">TEST</button>
  <button class="btn" data-ak7-action="fixloop">FIXLOOP</button>
</div>
<script>
document.addEventListener('click',async(ev)=>{const el=ev.target.closest('[data-ak7-action]'); if(!el) return;
  ev.preventDefault(); const a=el.getAttribute('data-ak7-action');
  const method=(a==='next'||a==='scan'||a==='test'||a==='fixloop')?'POST':'GET';
  try{
    const res=await fetch(window.AK7_API_BASE+'/'+a,{method,headers:{'Content-Type':'application/json'},
      body: method==='POST'? JSON.stringify({ts:new Date().toISOString(),action:a}):undefined});
    const j=await res.json(); alert(a+' → '+(j.ok?'OK':'ERR'));
  }catch(e){ alert('연결 실패'); }
});
</script>
</body></html>
"@ | Set-Content -LiteralPath $path -Encoding UTF8
}

$html = Get-Content -Raw -LiteralPath $path -Encoding UTF8
if($html -notmatch 'AK7_API_BASE'){
  $bak = "$path.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"; Copy-Item $path $bak -Force
  $rx='(?is)</\s*body\s*>'
  if([regex]::IsMatch($html,$rx)){
    $html = [regex]::Replace($html,$rx,$snippet + '</body>')
  } else {
    $html = $html + "`r`n" + $snippet + "`r`n</body></html>"
  }
  $tmp="$path.tmp"; $html | Out-File -LiteralPath $tmp -Encoding UTF8
  Move-Item $tmp $path -Force
  Write-Host "[OK] HTML 스니펫 주입 완료 → $HtmlRel"
} else {
  Write-Host "[SKIP] HTML에 이미 스니펫 존재 → $HtmlRel"
}

# 2) 모의 서버 2개 백그라운드 기동 (5192/5193)
$pidsFile = Join-Path $repo '.kobong/ak7-oneclick.pids'
New-Item -ItemType Directory -Force -Path (Split-Path $pidsFile) | Out-Null
$procs = @()

foreach($port in @($PortA,$PortB)){
  $proc = Start-Process -PassThru pwsh -ArgumentList '-NoLogo','-NoProfile','-File',(Join-Path $repo 'scripts/g5/mock-api-ak7.ps1'),'-Port',"$port",'-Bind','localhost'
  $procs += $proc
  Start-Sleep -Milliseconds 200
  try {
    Invoke-RestMethod -TimeoutSec 2 -Uri ("http://localhost:{0}/health" -f $port) | Out-Null
    Write-Host "[OK] mock-api-ak7 @ $port"
  } catch {
    Write-Warning "health 실패 @ $port (서버 로그 창 확인)"
  }
}

$procs | ForEach-Object { $_.Id } | Set-Content -LiteralPath $pidsFile -Encoding ascii

# 3) 정적 서버 (HTTP로 열기). python 있으면 활용, 없으면 파일로 오픈.
$rootUrl = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
  $web = Start-Process -PassThru python -ArgumentList '-m','http.server',"$WebPort" -WorkingDirectory $repo
  Write-Host "[OK] static server http://localhost:$WebPort/ (PID=$($web.Id))"
  $rootUrl = "http://localhost:$WebPort/"
} else {
  Write-Warning "python 없음 → file:// 로 엽니다 (브라우저 정책에 따라 통신이 막힐 수 있음)"
}

# 4) 브라우저 2탭 자동 오픈 (5192/5193)
$relUrl = $HtmlRel -replace '\\','/'
if($rootUrl){
  Start-Process ($rootUrl + $relUrl + '?api=' + $PortA)
  Start-Process ($rootUrl + $relUrl + '?api=' + $PortB)
} else {
  $fileUrl = 'file:///' + ($path -replace '\\','/')
  Start-Process ($fileUrl + '?api=' + $PortA)
  Start-Process ($fileUrl + '?api=' + $PortB)
}

Write-Host "`n== 완료 =="
Write-Host "브라우저 2탭이 열렸습니다: ?api=$PortA / ?api=$PortB"
Write-Host "서버 중지: scripts/g5/ak7-stop.ps1 실행"
