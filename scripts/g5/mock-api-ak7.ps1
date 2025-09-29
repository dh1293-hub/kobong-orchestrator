# AK7/GH mock API (듀얼 포트 지원)
#requires -PSEdition Core
#requires -Version 7.0
param([int]$Port=5192,[string]$Bind='localhost')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:Encoding']='utf8'
Add-Type -AssemblyName System.Net.HttpListener
$prefix = "http://{0}:{1}/" -f $Bind, $Port
$hl = [System.Net.HttpListener]::new(); $hl.Prefixes.Add($prefix)
try { $hl.Start() } catch {
  Write-Error "리스너 시작 실패: $($_.Exception.Message)`n관리자 권한 또는 URLACL 필요할 수 있음: `n netsh http add urlacl url=http://+:$Port/ user=Everyone"
  exit 1
}
Write-Host "[AK7] Mock API listening at $prefix (Ctrl+C 종료)"
Write-Host "  GET  /health     GET  /api/kpi"
Write-Host "  GET  /api/ak7/prefs"
Write-Host "  POST /api/ak7/notify  POST /api/ak7/next"
Write-Host "  GET|POST /api/ak7/(scan|test|fixloop)"
Write-Host "  GET  /api/gh/inbox  /api/gh/prs  /api/gh/checks"
function Send-Json($ctx,$obj,[int]$code=200){
  $res=$ctx.Response; $res.StatusCode=$code; $res.ContentType='application/json; charset=utf-8'
  $json=($obj|ConvertTo-Json -Compress); $buf=[Text.Encoding]::UTF8.GetBytes($json)
  $res.ContentLength64=$buf.Length
  $res.Headers['Access-Control-Allow-Origin']=$ctx.Request.Headers['Origin'] ?? '*'
  $res.Headers['Access-Control-Allow-Methods']='GET,POST,OPTIONS'
  $res.Headers['Access-Control-Allow-Headers']='Content-Type,X-Trace-Id,X-Idempotency-Key'
  $res.OutputStream.Write($buf,0,$buf.Length); $res.OutputStream.Close()
}
while ($hl.IsListening){
  $ctx=$hl.GetContext(); $req=$ctx.Request; $res=$ctx.Response
  $path=$req.Url.AbsolutePath.ToLowerInvariant(); $m=$req.HttpMethod
  if($m -eq 'OPTIONS'){ $res.StatusCode=204; $res.Headers['Access-Control-Allow-Origin']=$req.Headers['Origin'] ?? '*'
    $res.Headers['Access-Control-Allow-Methods']='GET,POST,OPTIONS'
    $res.Headers['Access-Control-Allow-Headers']='Content-Type,X-Trace-Id,X-Idempotency-Key'
    $res.Close(); continue }
  try {
    switch -Regex ($path){
      '^/health$' { Send-Json $ctx @{ ok=$true; service='ak7-mock'; port=$Port; ts=(Get-Date).ToString('o') } }
      '^/api/kpi$' { Send-Json $ctx @{ ok=$true; repo='mock/repo'; openPR=2; failingChecks=1; alerts=0; ts=(Get-Date).ToString('o') } }
      '^/api/ak7/prefs$' { Send-Json $ctx @{ ok=$true; theme='dark'; lang='ko-KR'; version='mock-1' } }
      '^/api/ak7/notify$' {
        $sr=New-Object IO.StreamReader $req.InputStream,([Text.Encoding]::UTF8)
        $json=$sr.ReadToEnd(); $sr.Close(); $data=if($json){$json|ConvertFrom-Json}else{@{}}
        Write-Host "[notify] $($data.level): $($data.msg)"
        Send-Json $ctx @{ ok=$true; received=$data; ts=(Get-Date).ToString('o') }
      }
      '^/api/ak7/next$' { Send-Json $ctx @{ ok=$true; action='next'; ts=(Get-Date).ToString('o'); job='queued' } }
      '^/api/ak7/(scan|test|fixloop)$' {
        $act=($path.Split('/')[-1]); Send-Json $ctx @{ ok=$true; action=$act; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/inbox$' {
        $items=@(
          @{ type='pr';    id=101; title='B-두방: 브릿지 주입'; state='open'; author='kobong-bot'; branch='feature/gh-bridge' },
          @{ type='issue'; id=202; title='UI: LED 카드 정교화'; state='open'; author='hanmins00' }
        ); Send-Json $ctx @{ ok=$true; items=$items; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/prs$' {
        $prs=@(
          @{ number=177; title='fix(ui): safe regex'; state='open'; checks=@(@{name='lint';status='success'},@{name='build';status='pending'}) },
          @{ number=178; title='feat(mon): GH console'; state='draft'; checks=@(@{name='lint';status='success'}) }
        ); Send-Json $ctx @{ ok=$true; prs=$prs; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/checks$' {
        $checks=@(@{name='lint';status='success'},@{name='build';status='pending'},@{name='test';status='queued'})
        Send-Json $ctx @{ ok=$true; checks=$checks; ts=(Get-Date).ToString('o') }
      }
      '^/api/kpi$' {
        Send-Json $ctx @{ ok=$true; repo='mock/repo'; openPR=2; failingChecks=1; alerts=0; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/inbox$' {
        $items = @(
          @{ type='pr';    id=101; title='B-두방: 브릿지 주입';      state='open'; author='kobong-bot'; branch='feature/gh-bridge' },
          @{ type='issue'; id=202; title='UI: LED 카드 정교화';      state='open'; author='hanmins00' }
        )
        Send-Json $ctx @{ ok=$true; items=$items; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/prs$' {
        $prs = @(
          @{ number=177; title='fix(ui): safe regex'; state='open'; checks=@(@{name='lint'; status='success'}, @{name='build'; status='pending'}) },
          @{ number=178; title='feat(mon): GH console'; state='draft'; checks=@(@{name='lint'; status='success'}) }
        )
        Send-Json $ctx @{ ok=$true; prs=$prs; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/checks$' {
        $checks = @(
          @{ name='lint';  status='success' },
          @{ name='build'; status='pending' },
          @{ name='test';  status='queued' }
        )
        Send-Json $ctx @{ ok=$true; checks=$checks; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/simulate$' {
        # POST { checks:'success|pending|failing', openPR:int, failingChecks:int }
        $sr=New-Object IO.StreamReader $req.InputStream,([Text.Encoding]::UTF8)
        $json=$sr.ReadToEnd(); $sr.Close()
        if(-not $script:SIM){ $script:SIM=@{checks='pending';openPR=2;failingChecks=1} }
        if($json){ $data=$json|ConvertFrom-Json; $script:SIM.checks=$data.checks ?? $script:SIM.checks; $script:SIM.openPR=[int]($data.openPR ?? $script:SIM.openPR); $script:SIM.failingChecks=[int]($data.failingChecks ?? $script:SIM.failingChecks) }
        Send-Json $ctx @{ ok=$true; sim=$script:SIM; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/state$' {
        if(-not $script:SIM){ $script:SIM=@{checks='pending';openPR=2;failingChecks=1} }
        Send-Json $ctx @{ ok=$true; sim=$script:SIM; ts=(Get-Date).ToString('o') }
      }
      '^/api/gh/checks$' {
        if(-not $script:SIM){ $script:SIM=@{checks='pending';openPR=2;failingChecks=1} }
        $checks = @(
          @{ name='lint';  status='success' },
          @{ name='build'; status=($script:SIM.checks) },
          @{ name='test';  status=($script:SIM.checks) }
        )
        Send-Json $ctx @{ ok=$true; checks=$checks; ts=(Get-Date).ToString('o') }
      }
      '^/api/kpi$' {
        if(-not $script:SIM){ $script:SIM=@{checks='pending';openPR=2;failingChecks=1} }
        Send-Json $ctx @{ ok=$true; repo='mock/repo'; openPR=$script:SIM.openPR; failingChecks=$script:SIM.failingChecks; alerts=0; ts=(Get-Date).ToString('o') }
      }
      '^/api/ak7/fix-preview$' { Send-Json $ctx @{ ok=$true; action='fix-preview'; ts=(Get-Date).ToString('o') } }
      '^/api/ak7/fix-apply$'   { Send-Json $ctx @{ ok=$true; action='fix-apply';   ts=(Get-Date).ToString('o') } }
      '^/api/ak7/good$'        { Send-Json $ctx @{ ok=$true; action='good';        ts=(Get-Date).ToString('o') } }
      '^/api/ak7/rollback$'    { Send-Json $ctx @{ ok=$true; action='rollback';    ts=(Get-Date).ToString('o') } }
      '^/api/ak7/logs-export$' { Send-Json $ctx @{ ok=$true; action='logs-export'; path='logs/export/mock.zip'; ts=(Get-Date).ToString('o') } }
      '^/api/ak7/stop$'        { Send-Json $ctx @{ ok=$true; action='stop';        ts=(Get-Date).ToString('o') } }
      '^/api/ak7/klc$'         { 
        $log=@(
          @{ ts=(Get-Date).AddSeconds(-3).ToString('o'); level='INFO'; action='scan'; outcome='SUCCESS' },
          @{ ts=(Get-Date).AddSeconds(-2).ToString('o'); level='INFO'; action='test'; outcome='SUCCESS' },
          @{ ts=(Get-Date).AddSeconds(-1).ToString('o'); level='INFO'; action='fixloop'; outcome='SUCCESS' }
        ); Send-Json $ctx @{ ok=$true; logs=$log }
      }
      '^/api/ak7/shells$'      {
        $list=@(
          @{ name='dry-run';   cmd='pwsh -File scripts/g5/apply-patches.ps1' },
          @{ name='apply';     cmd='$env:CONFIRM_APPLY=''true''; pwsh -File scripts/g5/apply-patches.ps1' },
          @{ name='oneclick';  cmd='pwsh -File scripts/g5/b-dubang.ps1' }
        ); Send-Json $ctx @{ ok=$true; shells=$list }
      }
      default {      default {      default {      default { Send-Json $ctx @{ ok=$false; error='not_found'; path=$path } 404 }
    }
  } catch { Send-Json $ctx @{ ok=$false; error='exception'; message=$_.Exception.Message } 500 }
}

