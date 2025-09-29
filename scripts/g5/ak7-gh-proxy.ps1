param([int]$Port=5192,[string]$Repo="auto")
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$PSDefaultParameterValues['*:Encoding']='utf8'
function J($o){ $o | ConvertTo-Json -Compress }
$root = (git rev-parse --show-toplevel 2>$null); if(-not $root){ $root=(Get-Location).Path }
$logd = Join-Path $root "logs"; New-Item -ItemType Directory -Force -Path $logd | Out-Null
$state= Join-Path $logd  "gh_proxy_state.json"
if($Repo -eq "auto"){
  try{ $url=(git remote get-url origin 2>$null); if($url -match "[:/](?<own>[^/]+)/(?<rep>[^/.]+)(\.git)?$"){ $Repo="$($Matches.own)/$($Matches.rep)" } }catch{}
}
if(-not $Repo -or $Repo -eq "auto"){
  $cfg=Join-Path $root "config\gh_repo.txt"
  if(Test-Path $cfg){ $Repo = (Get-Content -LiteralPath $cfg -Raw).Trim() }
}
if(-not $Repo){ $Repo="owner/repo" }
if(-not (Get-Command gh -ErrorAction SilentlyContinue)){
  Write-Warning "gh CLI 없음 → 로컬 토스트만 기록"
  $now=(Get-Date).ToString("o"); $log=Join-Path $logd "gh_proxy.log";
  ("{0}" -f (J @{ts=$now; repo=$Repo; info="gh not found"})) | Add-Content -LiteralPath $log
  exit 0
}
$since="1970-01-01T00:00:00Z"; if(Test-Path $state){ try{ $obj=Get-Content -LiteralPath $state | ConvertFrom-Json; if($obj.since){ $since=$obj.since } }catch{} }
$api="/repos/"+$Repo+"/issues/comments?since="+[uri]::EscapeDataString($since)+"&per_page=50"
$json = gh api -X GET $api --jq "." 2>$null | ConvertFrom-Json
if(-not $json){ exit 0 }
$handled=@()
foreach($c in $json){
  $body = [string]$c.body
  $id   = [string]$c.id
  $ts   = [string]$c.updated_at
  if($body -match "^\s*/ak\s+(?<cmd>scan|test|fixloop|next)\b"){
    $cmd=$Matches.cmd
    try{
      # 서버가 있으면 notify (없어도 그냥 시도)
      try{ Invoke-RestMethod -Method POST -Uri ("http://localhost:{0}/api/ak7/notify" -f $Port) -ContentType "application/json" -Body (J @{level="ok"; msg=("/ak "+$cmd) }) | Out-Null }catch{}
      if($cmd -in @("scan","test","fixloop")){ try{ Invoke-RestMethod -Uri ("http://localhost:{0}/api/ak7/{1}" -f $Port,$cmd) | Out-Null }catch{} }
      if($cmd -eq "next"){ try{ Invoke-RestMethod -Method POST -Uri ("http://localhost:{0}/api/ak7/next" -f $Port) -ContentType "application/json" -Body (J @{ts=(Get-Date).ToString("o")}) | Out-Null }catch{} }
      $handled += $id
      # 로컬 로그
      ("{0}" -f (J @{ts=(Get-Date).ToString("o"); repo=$Repo; id=$id; cmd=$cmd })) | Add-Content -LiteralPath (Join-Path $logd "gh_proxy.log")
    }catch{}
  }
}
if($json | Measure-Object | % Count){
  $max = ($json | Sort-Object {[DateTime]$_.updated_at} | Select-Object -Last 1).updated_at
  (J @{ since=$max }) | Set-Content -LiteralPath $state
}
