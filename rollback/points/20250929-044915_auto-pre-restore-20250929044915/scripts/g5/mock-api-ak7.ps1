param([int]$Port=5192,[string]$UiRoot="")
$ErrorActionPreference="Stop"
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

function CT($p){ switch -regex ([IO.Path]::GetExtension($p).ToLowerInvariant()){
  "\.html$"{"text/html; charset=utf-8"} "\.js$"{"application/javascript; charset=utf-8"}
  "\.css$"{"text/css; charset=utf-8"}  "\.json$"{"application/json; charset=utf-8"}
  "\.svg$"{"image/svg+xml"} "\.png$"{"image/png"} "\.jpe?g$"{"image/jpeg"} "\.ico$"{"image/x-icon"}
  default{"application/octet-stream"} } }
function WStr([IO.Stream]$st,[string]$status="200 OK",[string]$ctype="application/json; charset=utf-8",[string]$body=""){
  $b=[Text.Encoding]::UTF8.GetBytes($body)
  $h="HTTP/1.1 "+$status+"`r`nContent-Type: "+$ctype+"`r`nContent-Length: "+$b.Length+"`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Headers: *`r`nAccess-Control-Allow-Methods: *`r`nConnection: close`r`n`r`n"
  $hb=[Text.Encoding]::ASCII.GetBytes($h); $st.Write($hb,0,$hb.Length); if($b.Length){ $st.Write($b,0,$b.Length) } $st.Flush()
}
function WBin([IO.Stream]$st,[string]$status,[string]$ctype,[byte[]]$bytes){
  $h="HTTP/1.1 "+$status+"`r`nContent-Type: "+$ctype+"`r`nContent-Length: "+$bytes.Length+"`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Headers: *`r`nAccess-Control-Allow-Methods: *`r`nConnection: close`r`n`r`n"
  $hb=[Text.Encoding]::ASCII.GetBytes($h); $st.Write($hb,0,$hb.Length); if($bytes.Length){ $st.Write($bytes,0,$bytes.Length) } $st.Flush()
}
function WHdrSSE([IO.Stream]$st){
  $h="HTTP/1.1 200 OK`r`nContent-Type: text/event-stream; charset=utf-8`r`nCache-Control: no-cache`r`nAccess-Control-Allow-Origin: *`r`nConnection: keep-alive`r`n`r`n"
  $hb=[Text.Encoding]::ASCII.GetBytes($h); $st.Write($hb,0,$hb.Length); $st.Flush()
}
function WLine([IO.Stream]$st,[string]$line){ $b=[Text.Encoding]::UTF8.GetBytes($line+"`r`n"); $st.Write($b,0,$b.Length); $st.Flush() }
function ReadFull([IO.Stream]$st,[int]$len){ $buf=New-Object byte[] $len; $off=0; while($off -lt $len){ $n=$st.Read($buf,$off,($len-$off)); if($n -le 0){ break } $off+=$n } $buf }

$AK7_Events=New-Object System.Collections.ArrayList; $AK7_Max=200; $AK7_Eid=1
function EV([string]$name,[hashtable]$obj){ try{
  $obj["ts"]=[DateTime]::UtcNow.ToString("o"); $obj["event"]=$name; $obj["id"]=$AK7_Eid
  $null=$AK7_Events.Add($obj); if($AK7_Events.Count -gt $AK7_Max){ $drop=$AK7_Events.Count-$AK7_Max; if($drop -gt 0){ $AK7_Events.RemoveRange(0,$drop) } }
  $script:AK7_Eid++
}catch{} }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$rbFile = Join-Path $here 'ak7-rollback.ps1'; if(Test-Path $rbFile){ . $rbFile }

try{
  $lis=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
  $lis.Server.SetSocketOption([Net.Sockets.SocketOptionLevel]::Socket,[Net.Sockets.SocketOptionName]::ReuseAddress,$true)
  $lis.Start()
}catch{ Write-Host "[AK7] 포트 바인딩 실패: $Port"; throw }
Write-Host "[AK7] server http://localhost:$Port  UI-Root=$UiRoot"

function MapUi([string]$u){
  if(-not $UiRoot){ return $null }
  $p=$u.Split("?")[0]
  if($p -eq "/ui" -or $p -eq "/ui/"){ $p="/ui/AUTO-Kobong-Han.html" }
  if($p.StartsWith("/ui/")){
    $rel=$p.Substring(4).TrimStart("/")
    $cand = Join-Path $UiRoot $rel
    try{
      $full=(Resolve-Path -LiteralPath $cand -ErrorAction Stop).Path
      $root=(Resolve-Path -LiteralPath $UiRoot -ErrorAction Stop).Path
      if($full.ToLower().StartsWith($root.ToLower())){ return $full }
    }catch{}
  }
  return $null
}

while($true){
  try{
    $cli=$lis.AcceptTcpClient(); $st=$cli.GetStream()
    $sr=New-Object IO.StreamReader($st,[Text.Encoding]::ASCII,$false,1024,$true)
    $rq=$sr.ReadLine(); if(-not $rq){ $cli.Close(); continue }
    $p=$rq.Split(" "); $m=$p[0]; $u=$p[1]
    $hdr=@{}; $expect=$false
    while(($h=$sr.ReadLine()) -ne $null -and $h -ne ""){
      $kv=$h.Split(":",2); if($kv.Length -eq 2){ $k=$kv[0].Trim(); $v=$kv[1].Trim(); $hdr[$k]=$v; if($k -ieq "Expect" -and $v -match "100-continue"){ $expect=$true } }
    }
    if($expect){ $hb=[Text.Encoding]::ASCII.GetBytes("HTTP/1.1 100 Continue`r`n`r`n"); $st.Write($hb,0,$hb.Length) }
    $body=""; if($hdr.ContainsKey("Content-Length")){ $len=[int]$hdr["Content-Length"]; if($len -gt 0){ $buf=ReadFull $st $len; $body=[Text.Encoding]::UTF8.GetString($buf) } }
    $up=[uri]::UnescapeDataString($u)

    if($m -eq "OPTIONS"){ WStr $st "204 No Content" "text/plain" ""; $cli.Close(); continue }

    $local = MapUi $up
    if($local){
      if(Test-Path -LiteralPath $local){
        try{ $bytes=[IO.File]::ReadAllBytes($local); WBin $st "200 OK" (CT $local) $bytes }catch{ WStr $st "500 Internal Server Error" "application/json; charset=utf-8" '{"ok":false,"error":"read_error"}' }
      } else { WStr $st "404 Not Found" "application/json; charset=utf-8" '{"ok":false,"error":"ui_not_found"}' }
    }
    elseif($up -eq "/health"){
      WStr $st "200 OK" "application/json; charset=utf-8" (@{ ok=$true; service='ak7'; port=$Port } | ConvertTo-Json -Compress)
    }
    elseif($up -eq "/events"){
      WHdrSSE $st
      foreach($e in $AK7_Events){ try{ WLine $st ("id: "+$e.id); WLine $st "event: log"; WLine $st ("data: "+([Text.Encoding]::UTF8.GetString([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $e -Compress))))) ; WLine $st "" }catch{} }
      try{ WLine $st "event: ping"; WLine $st ("data: {""ts"":"""+[DateTime]::UtcNow.ToString("o")+"""}"); WLine $st "" }catch{}
      try{ $st.Dispose(); $cli.Close() }catch{}
    }
    elseif($up -eq "/api/ak7/prefs"){
      WStr $st "200 OK" "application/json; charset=utf-8" '{"prefs":{"theme":"dark","zoom":1.0,"ok":true}}'
    }
    elseif($up -eq "/api/ak7/notify"){
      $lev="ok"; $msg=""
      try{ if($body){ $j=ConvertFrom-Json -InputObject $body -ErrorAction Stop; if($j.level){ $lev=[string]$j.level }; if($j.msg){ $msg=[string]$j.msg } } }catch{}
      if(-not $msg){ $msg="notification" }
      EV "toast" (@{ level=$lev; msg=$msg })
      $payload = @{ ok=$true; level=$lev; msg=$msg } | ConvertTo-Json -Compress
      WStr $st "200 OK" "application/json; charset=utf-8" $payload
    }
    elseif($up -like "/api/ak7/rollback/create"){
      $name = "auto-"+(Get-Date -Format yyyyMMddHHmmss)
      try{ if($body){ $j=ConvertFrom-Json $body; if($j.name){ $name=[string]$j.name } } }catch{}
      if(Get-Command New-AK7RollbackPoint -ErrorAction SilentlyContinue){
        $res = New-AK7RollbackPoint -Name $name
        WStr $st "200 OK" "application/json; charset=utf-8" ($res | ConvertTo-Json -Compress)
      } else {
        WStr $st "200 OK" "application/json; charset=utf-8" '{"ok":false,"error":"rollback_not_available"}'
      }
    }
    elseif($up -like "/api/ak7/rollback/preview"){
      $name = "last"; try{ if($body){ $j=ConvertFrom-Json $body; if($j.name){ $name=[string]$j.name } } }catch{}
      if(Get-Command Restore-AK7RollbackPoint -ErrorAction SilentlyContinue){
        $res = Restore-AK7RollbackPoint -Name $name -WhatIf
        WStr $st "200 OK" "application/json; charset=utf-8" ($res | ConvertTo-Json -Compress)
      } else {
        WStr $st "200 OK" "application/json; charset=utf-8" '{"ok":false,"error":"rollback_not_available"}'
      }
    }
    elseif($up -like "/api/ak7/rollback/restore"){
      $name = "last"; try{ if($body){ $j=ConvertFrom-Json $body; if($j.name){ $name=[string]$j.name } } }catch{}
      if(Get-Command Restore-AK7RollbackPoint -ErrorAction SilentlyContinue){
        $res = Restore-AK7RollbackPoint -Name $name
        EV "toast" (@{ level="ok"; msg=("rollback restored: "+$name) })
        WStr $st "200 OK" "application/json; charset=utf-8" ($res | ConvertTo-Json -Compress)
      } else {
        WStr $st "200 OK" "application/json; charset=utf-8" '{"ok":false,"error":"rollback_not_available"}'
      }
    }
    elseif($up.StartsWith("/api/ak7/")){
      $act=$up.Substring(9); if($act.StartsWith("/")){ $act=$act.Substring(1) }
      if($act -match "^(scan|test|fixloop)$"){ EV $act (@{ trace=[guid]::NewGuid().ToString(); ok=$true }); EV "toast" (@{ level="ok"; msg=($act+" started") }) }
      WStr $st "200 OK" "application/json; charset=utf-8" (@{ ok=$true; action=$act } | ConvertTo-Json -Compress)
    }
    else{
      WStr $st "404 Not Found" "application/json; charset=utf-8" '{"ok":false,"error":"not_found"}'
    }
    try{ $st.Dispose(); $cli.Close() }catch{}
  }catch{
    try{$st.Dispose()}catch{}; try{$cli.Close()}catch{}
  }
}
