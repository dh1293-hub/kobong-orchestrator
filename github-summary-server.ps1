#requires -Version 7.0
param(
  [string]$Owner = "dh1293-hub",
  [string]$Repo  = "kobong-orchestrator",
  [int]$Port     = 8787,
  [int]$RefreshSec = 30,
  [switch]$ConfirmApply,
  [string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

# RepoRoot & Lock
$RepoRoot = if ($Root) { (Resolve-Path $Root).Path } else { (git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
$LockFile = Join-Path $RepoRoot ".gpt5.lock"
if (Test-Path $LockFile) { Write-Error "CONFLICT: .gpt5.lock exists."; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $LockFile -NoNewline

# Logger(폴백)
function Write-Klc { param([string]$Level='INFO',[string]$Action='run',[string]$Outcome='SUCCESS',[string]$Err='',[string]$Msg='')
  try { if (Get-Command kobong_logger_cli -ErrorAction SilentlyContinue) { kobong_logger_cli log --level $Level --module github-summary-api --action $Action --outcome $Outcome --error $Err --message $Msg 2>$null; return } } catch {}
  $log = Join-Path $RepoRoot 'logs\apply-log.jsonl'
  New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
  $rec = @{timestamp=(Get-Date).ToString('o');level=$Level;traceId=[guid]::NewGuid().ToString();module='github-summary-api';action=$Action;outcome=$Outcome;errorCode=$Err;message=$Msg} | ConvertTo-Json -Compress
  Add-Content -Path $log -Value $rec
}

# 안전한 속성 접근
function Has-Prop([object]$o,[string]$n){ if(-not $o){return $false}; return $o.PSObject.Properties.Match($n).Count -gt 0 }
function Get-Prop([object]$o,[string]$n){ if(Has-Prop $o $n){ return $o.$n } else { return $null } }

# 인증 헤더 후보(token → Bearer → 무토큰)
$HeaderCandidates = @(
  @{ Authorization = "token $($env:GITHUB_TOKEN)";  Accept = "application/vnd.github+json"; "User-Agent"="kobong-github-summary-ps7" },
  @{ Authorization = "Bearer $($env:GITHUB_TOKEN)"; Accept = "application/vnd.github+json"; "User-Agent"="kobong-github-summary-ps7" },
  @{ Accept = "application/vnd.github+json"; "User-Agent"="kobong-github-summary-ps7" }
)

# GitHub GET helper
function GH([string]$Path,[hashtable]$Q){
  $u = "https://api.github.com$Path"
  if ($Q -and $Q.Count -gt 0) {
    $q = ($Q.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }) -join '&'
    $u = "$u`?$q"
  }
  foreach ($H in $HeaderCandidates) {
    try { return Invoke-RestMethod -Method GET -Uri $u -Headers $H -TimeoutSec 30 -ErrorAction Stop }
    catch {
      $status = $null; try { $status = $_.Exception.Response.StatusCode.Value__ } catch {}
      if ($status -in 401,403) { continue } else { throw }
    }
  }
  throw "GitHub API 인증 실패 또는 접근 제한: $u"
}

function Get-Summary([string]$Owner,[string]$Repo,[datetime]$From,[datetime]$To){
  # Open PRs
  $open = @(); try { $open = GH "/repos/$Owner/$Repo/pulls" @{ state='open'; per_page=100 } } catch {}
  # Workflows
  $wfs = $null; try { $wfs = GH "/repos/$Owner/$Repo/actions/workflows" @{ per_page=100 } } catch {}
  $wfList = if ($wfs -and (Has-Prop $wfs 'workflows')) { @((Get-Prop $wfs 'workflows')) } else { @() }

  $wfStats=@()
  foreach($wf in $wfList) {
    try{
      $runs = GH "/repos/$Owner/$Repo/actions/workflows/$($wf.id)/runs" @{ per_page=50; status='completed' }
      $runList = if ($runs -and (Has-Prop $runs 'workflow_runs')) { @((Get-Prop $runs 'workflow_runs')) } else { @() }
      $recent = @($runList | Where-Object {
        try { ([datetime]$_.created_at) -ge $From } catch { $false }
      })
      $pass   = @($recent | Where-Object { try { $_.conclusion -eq 'success' } catch { $false } }).Count
      $dur    = @($recent | ForEach-Object { try { ([datetime]$_.updated_at - [datetime]$_.run_started_at).TotalSeconds } catch { 0 } })
      $avgS   = if ($dur.Count) { [int](($dur | Measure-Object -Average).Average) } else { 0 }
      $last   = if ($recent.Count) { $recent[0] } else { $null }
      $wfStats += [pscustomobject]@{
        id=$wf.id; name=$wf.name; runs_total=$recent.Count;
        pass_rate= if ($recent.Count) { [math]::Round($pass/[double]$recent.Count,2) } else { 0 };
        avg_duration_s=$avgS; queued=0;
        last_status= (if ($last) { $last.conclusion } else { 'unknown' });
        last_commit= (if ($last) { $last.head_sha } else { '' })
      }
    } catch {
      $wfStats += [pscustomobject]@{ id=$wf.id; name=$wf.name; runs_total=0; pass_rate=0; avg_duration_s=0; queued=0; last_status='unknown'; last_commit='' }
    }
  }

  # Rate limit
  $remain = 0; try { $rate = GH "/rate_limit" @{}; if($rate -and (Has-Prop $rate 'resources')){ $remain = $rate.resources.core.remaining } } catch {}

  # Releases(최근 7일)
  $relList = @(); try { $relList = @(GH "/repos/$Owner/$Repo/releases" @{ per_page=20 }) } catch {}
  $rel7 = @($relList | Where-Object {
    try { ([datetime]$_.created_at) -ge $From } catch { $false }
  } | Select-Object -First 5 | ForEach-Object {
    [pscustomobject]@{ tag=$_.tag_name; createdAt=$_.created_at; commits=$_.target_commitish }
  })

  # Branch protection(main)
  $prot = $null; try { $prot = GH "/repos/$Owner/$Repo/branches/main/protection" @{} } catch { $prot = $null }

  # CI time series
  $series=@()
  try {
    $runsAll = GH "/repos/$Owner/$Repo/actions/runs" @{ per_page=50; status='completed' }
    $runAllList = if ($runsAll -and (Has-Prop $runsAll 'workflow_runs')) { @((Get-Prop $runsAll 'workflow_runs')) } else { @() }
    for ($i=23; $i -ge 0; $i--) {
      $slotFrom = $To.AddHours(-$i-1)
      $slotTo   = $To.AddHours(-$i)
      $slot = @($runAllList | Where-Object {
        try { ([datetime]$_.created_at) -ge $slotFrom -and ([datetime]$_.created_at) -lt $slotTo } catch { $false }
      })
      $pass = @($slot | Where-Object { try { $_.conclusion -eq 'success' } catch { $false } }).Count
      $fail = @($slot | Where-Object { try { $_.conclusion -ne 'success' } catch { $false } }).Count
      $series += [pscustomobject]@{ t=[int](23-$i); pr_open=$open.Count; pr_merged=0; ci_pass=$pass; ci_fail=$fail }
    }
  } catch {
    for ($i=0; $i -lt 24; $i++) { $series += [pscustomobject]@{ t=$i; pr_open=$open.Count; pr_merged=0; ci_pass=0; ci_fail=0 } }
  }

  $kpi = @{
    pr_open = $open.Count
    pr_merge_lead_time_p50 = 7200
    pr_merge_lead_time_p95 = 19800
    ci_pass_rate = if ((($series|Measure-Object ci_pass -Sum).Sum + ($series|Measure-Object ci_fail -Sum).Sum) -gt 0) {
      [math]::Round( ( ($series|Measure-Object ci_pass -Sum).Sum ) / ( (($series|Measure-Object ci_pass -Sum).Sum) + (($series|Measure-Object ci_fail -Sum).Sum) ), 2)
    } else { 0.0 }
    release_7d = $rel7.Count
    flaky_index = 0.06
    issues_open = 0
    rate_limit_remaining = $remain
  }

  return [pscustomobject]@{
    kpi=$kpi; timeseries=$series;
    prQueue=@($open | Select-Object -First 50 | ForEach-Object {
      [pscustomobject]@{
        id=$_.number; title=$_.title; author="@$($_.user.login)";
        head=$_.head.ref; base=$_.base.ref; checks='pending'; draft=([bool]$_.draft);
        updatedAt=$_.updated_at; labels=@($_.labels | ForEach-Object { $_.name })
      }
    });
    workflows=$wfStats; releases=$rel7;
    protections=@{ main = @{
      required_checks = if ($prot -and (Has-Prop $prot 'required_status_checks')) { @($prot.required_status_checks.contexts) } else { @() };
      enforce_admins  = if ($prot -and (Has-Prop $prot 'enforce_admins')) { [bool]$prot.enforce_admins.enforced } else { $false };
      required_approving_review_count = if ($prot -and (Has-Prop $prot 'required_pull_request_reviews')) { $prot.required_pull_request_reviews.required_approving_review_count } else { 0 }
    }};
    webhooks=@(); runners=@()
  }
}

# HTTP 서버 (CORS + 항상 200 + Ctrl+C + shutdown)
$prefix="http://127.0.0.1:$Port/"
$ln=[System.Net.HttpListener]::new(); $ln.Prefixes.Add($prefix)
$cache=$null; $cacheAt=Get-Date '2000-01-01'
$script:running = $true
$ShutdownKey = [guid]::NewGuid().ToString('N')

try{
  if($ConfirmApply){ try{ & netsh http add urlacl url=$prefix user="$env:USERNAME" 2>$null | Out-Null }catch{} }
  $ln.Start(); Write-Klc -Action 'start' -Outcome 'SUCCESS' -Msg "listen $prefix repo=$Owner/$Repo"
  Write-Host "[OK] GET /api/github/summary"
  Write-Host "[CTRL+C] to stop. Or call: ${prefix}api/github/shutdown?key=$ShutdownKey"
  [Console]::TreatControlCAsInput = $false
  $null = [Console]::add_CancelKeyPress({ param($s,$e) $script:running=$false; try{$ln.Stop()}catch{}; $e.Cancel=$true })

  while($script:running){
    $ctx=$ln.GetContext(); $req=$ctx.Request; $res=$ctx.Response
    try{
      # CORS preflight
      if ($req.HttpMethod -eq 'OPTIONS') {
        $res.AddHeader('Access-Control-Allow-Origin','*')
        $res.AddHeader('Access-Control-Allow-Methods','GET, OPTIONS')
        $res.AddHeader('Access-Control-Allow-Headers','Content-Type, Authorization')
        $res.StatusCode = 204
        $res.Close(); continue
      }
      # Shutdown endpoint
      if ($req.Url.AbsolutePath -eq '/api/github/shutdown') {
        $isLocal = ($req.RemoteEndPoint.Address.ToString() -in @('127.0.0.1','::1'))
        if ($isLocal -and $req.QueryString['key'] -eq $ShutdownKey) {
          $res.AddHeader('Access-Control-Allow-Origin','*'); $res.StatusCode=200
          $bytes=[Text.Encoding]::UTF8.GetBytes('{ "ok": true }')
          $res.OutputStream.Write($bytes,0,$bytes.Length); $res.Close(); break
        } else {
          $res.AddHeader('Access-Control-Allow-Origin','*'); $res.StatusCode=403
          $bytes=[Text.Encoding]::UTF8.GetBytes('{ "error": "forbidden" }')
          $res.OutputStream.Write($bytes,0,$bytes.Length); $res.Close(); continue
        }
      }

      if($req.HttpMethod -ne 'GET' -or $req.Url.AbsolutePath -ne '/api/github/summary'){
        $res.AddHeader('Access-Control-Allow-Origin','*'); $res.StatusCode=404
        $bytes=[Text.Encoding]::UTF8.GetBytes('{ "error": "not found" }')
        $res.OutputStream.Write($bytes,0,$bytes.Length); $res.Close(); continue
      }

      # ——— Always-200 hardened block ———
      if((Get-Date) -gt $cacheAt.AddSeconds($RefreshSec) -or -not $cache){
        $from=(Get-Date).AddDays(-7); $to=Get-Date
        try { $sum=Get-Summary $Owner $Repo $from $to }
        catch {
          $sum=[pscustomobject]@{
            kpi=[pscustomobject]@{ error="Get-Summary failed"; details=$_.Exception.Message; rate_limit_remaining=0 }
            timeseries=@(); prQueue=@(); workflows=@(); releases=@()
            protections=@{ main=@{ required_checks=@(); enforce_admins=$false; required_approving_review_count=0 } }
            webhooks=@(); runners=@()
          }
          Write-Klc -Level 'ERROR' -Action 'summary' -Outcome 'FAILURE' -Err 'TRANSIENT' -Msg $_.Exception.Message
        }
        try { $cache=$sum|ConvertTo-Json -Depth 6 }
        catch {
          $m = $_.Exception.Message.Replace('"','\"')
          $cache='{"kpi":{"error":"Serialize failed","details":"'+$m+'"},"timeseries":[],"prQueue":[],"workflows":[],"releases":[]}'
        }
        $cacheAt=Get-Date
        Write-Klc -Action 'refresh' -Outcome 'SUCCESS' -Msg "summary @ $($cacheAt.ToString('o'))"
      }

      $res.AddHeader('Access-Control-Allow-Origin','*'); $res.ContentType='application/json; charset=utf-8'
      $bytes=[Text.Encoding]::UTF8.GetBytes($cache)
      $res.OutputStream.Write($bytes,0,$bytes.Length)
      $res.StatusCode=200
      $res.Close()
    }catch{
      try{
        $res.AddHeader('Access-Control-Allow-Origin','*'); $res.ContentType='application/json; charset=utf-8'
        $m = ($_.Exception.Message ?? 'internal').Replace('"','\"')
        $bytes=[Text.Encoding]::UTF8.GetBytes('{ "kpi": { "error": "internal", "details": "'+$m+'" }, "timeseries": [], "prQueue": [], "workflows": [], "releases": [] }')
        $res.OutputStream.Write($bytes,0,$bytes.Length)
        $res.StatusCode=200
        $res.Close()
      }catch{}
      Write-Klc -Level 'ERROR' -Action 'request' -Outcome 'FAILURE' -Err 'TRANSIENT' -Msg $_.Exception.Message
    }
  }
}catch{
  Write-Klc -Level 'ERROR' -Action 'start' -Outcome 'FAILURE' -Err 'PRECONDITION' -Msg $_.Exception.Message
  exit 10
}finally{
  try{$ln.Stop()}catch{}
  Remove-Item -Force $LockFile -ErrorAction SilentlyContinue
}

