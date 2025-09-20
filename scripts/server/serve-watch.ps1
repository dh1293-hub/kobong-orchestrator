#requires -Version 7.0
param([int]$Port=8000,[string]$BindHost='127.0.0.1',[int]$IntervalSec=2,[switch]$NoClear)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

$base="http://$BindHost`:$Port"
$frames=@('|','/','-','\'); $i=0

function Try-GET([string]$url){
  $sw=[Diagnostics.Stopwatch]::StartNew()
  try {
    # IWR로 항상 StatusCode 확보, 오류도 예외 없이 통과
    $res = Invoke-WebRequest -Uri $url -TimeoutSec 2 -MaximumRedirection 0 -SkipHttpErrorCheck
    $sw.Stop()
    $ok = ($res.StatusCode -ge 200 -and $res.StatusCode -lt 300)
    $data = $null
    try {
      if ($res.Content) { $data = $res.Content | ConvertFrom-Json -ErrorAction Stop }
    } catch { $data = $null }
    return @{ ok=$ok; ms=$sw.ElapsedMilliseconds; code=$res.StatusCode; data=$data }
  } catch {
    $sw.Stop()
    return @{ ok=$false; ms=$sw.ElapsedMilliseconds; code=$null; err=$_.Exception.Message }
  }
}

function Draw(){
  $h=Try-GET "$base/healthz"
  $r=Try-GET "$base/readyz"
  $l=Try-GET "$base/livez"
  $mOk=$false
  try{ $mw=Invoke-WebRequest -Uri "$base/metrics" -TimeoutSec 2 -ErrorAction Stop; $mOk=($mw.StatusCode -ge 200 -and $mw.StatusCode -lt 300) }catch{ $mOk=$false }
  $listeners=0; try{ $listeners=(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Measure-Object).Count }catch{}
  if(-not $NoClear){ Clear-Host }
  $spin=$frames[$i % $frames.Length]; $i++
  $ts=(Get-Date).ToString('HH:mm:ss')
  Write-Host ("KO Serve — WATCH {0}  [{1}]  base={2}" -f $spin,$ts,$base) -ForegroundColor Cyan
  Write-Host ("  healthz : {0} ({1} ms) code={2}" -f ($h.ok ? 'OK' : 'DOWN'), $h.ms, ($h.code ?? 200)) -ForegroundColor ($h.ok ? 'Green' : 'Red')
  Write-Host ("  readyz  : {0} ({1} ms) code={2}" -f ($r.ok ? 'OK' : 'DOWN'), $r.ms, ($r.code ?? 200)) -ForegroundColor ($r.ok ? 'Green' : 'Red')
  Write-Host ("  livez   : {0} ({1} ms) code={2}" -f ($l.ok ? 'OK' : 'DOWN'), $l.ms, ($l.code ?? 200)) -ForegroundColor ($l.ok ? 'Green' : 'Red')
  Write-Host ("  metrics : {0}" -f ($mOk ? 'OK' : 'DOWN')) -ForegroundColor ($mOk ? 'Green' : 'Yellow')
  Write-Host ("  port    : listeners={0}" -f $listeners)
  Write-Host "  hotkeys : [Q]uit  [R]estart  [C]lear logs  [T]ail error" -ForegroundColor DarkGray
}

[Console]::TreatControlCAsInput = $true
try {
  while($true){
    Draw
    $until=(Get-Date).AddSeconds($IntervalSec)
    while((Get-Date) -lt $until){
      if([Console]::KeyAvailable){
        $k=[Console]::ReadKey($true)
        switch($k.Key){
          'Q' { return }
          'R' {
            try{
              $ctl = Join-Path (Split-Path -Parent $PSScriptRoot) 'serve-control.ps1'
              if(Test-Path $ctl){
                Start-Job -ScriptBlock { param($ctl,$p,$h) & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $ctl -Action restart -Port $p -BindHost $h } -ArgumentList $ctl,$Port,$BindHost | Out-Null
              }
            }catch{}
          }
          'C' {
            try{
              $logs = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'logs\serve'
              Get-ChildItem $logs -Filter 'prod-*.*.log' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }catch{}
          }
          'T' {
            try{
              $logs = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'logs\serve'
              $e = Get-ChildItem $logs -Filter 'prod-*.err.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
              if($e){ Start-Process pwsh -ArgumentList @('-NoLogo','-NoProfile','-Command',"Get-Content -Path `"$($e.FullName)`" -Wait -Tail 80") -WindowStyle Normal | Out-Null }
            }catch{}
          }
        }
      }
      Start-Sleep -Milliseconds 120
    }
  }
} finally {
  [Console]::TreatControlCAsInput = $false
}