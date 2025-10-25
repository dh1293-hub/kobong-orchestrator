# APPLY IN SHELL
#requires -Version 7.0
param([switch]$ConfirmApply,[string]$Root)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply = $true }

function Get-RepoRoot { (& git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path }
$RepoRoot = if ($Root) { (Resolve-Path $Root).Path } else { Get-RepoRoot }

$Html = Join-Path $RepoRoot 'webui\public\sts-kobong-GitHub-min.html'
$Js   = Join-Path $RepoRoot 'webui\public\js\sts-gh-min.js'
if(!(Test-Path $Html) -or !(Test-Path $Js)){ Write-Error "��� Ȯ��: `n$Html`n$Js"; exit 10 }

# ���� ���� ��ƿ ��������������������������������������������������������������������������������������������������������������������������������
$Lock = Join-Path $RepoRoot '.gpt5.lock'
if(Test-Path $Lock){ Write-Error 'CONFLICT: .gpt5.lock exists.'; exit 11 }
"locked $(Get-Date -Format o)" | Out-File $Lock -NoNewline
function Write-Atomic([string]$Path,[string]$Text){
  $dir=Split-Path -Parent $Path
  if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $tmp=Join-Path $dir ('.'+[IO.Path]::GetFileName($Path)+'.tmp')
  [IO.File]::WriteAllText($tmp,$Text,[Text.Encoding]::UTF8)
  if(Test-Path $Path){ Copy-Item $Path ($Path + ".bak-"+(Get-Date).ToString('yyyyMMdd-HHmmss')) -Force }
  Move-Item $tmp $Path -Force
}
function Insert-Before([string]$Text,[string]$Marker,[string]$Snippet){
  $i = $Text.IndexOf($Marker, [StringComparison]::OrdinalIgnoreCase)
  if($i -lt 0){ return $Text + "`n" + $Snippet }
  return $Text.Substring(0,$i) + $Snippet + $Marker + $Text.Substring($i + $Marker.Length)
}
function Insert-AfterTagOpen([string]$Text,[string]$Id,[string]$Snippet){
  $rx = [regex]'(?is)<div[^>]*\bid\s*=\s*"'+[regex]::Escape($Id)+'"[^>]*>'
  $m = $rx.Match($Text); if(-not $m.Success){ return $Text }
  $at = $m.Index + $m.Length
  return $Text.Substring(0,$at) + "`r`n" + $Snippet + $Text.Substring($at)
}

try{
  # ���� 1) HTML ��ġ: ����Ʈ CSS + �г� 2�� ������������������������������������������������������������������������
  $HtmlText = Get-Content -LiteralPath $Html -Raw -Encoding utf8
  $OrigHtmlText = $HtmlText

  if($HtmlText -notmatch 'id="kb-list-style"'){
    $listCss = @(
'  <style id="kb-list-style">',
'    @layer kb-comp {',
'      .kb-list{margin:4px 0 0 0;padding:0;list-style:none;display:flex;flex-direction:column;gap:6px}',
'      .kb-item{display:flex;gap:8px;align-items:center;padding:8px 10px;border:1px solid #2a3558;border-radius:10px;background:#0f1730}',
'      .kb-item a{color:#cfe1ff;text-decoration:none}',
'      .kb-tag{display:inline-block;padding:2px 6px;border-radius:999px;border:1px solid #2a3558;background:#0b1328}',
'      .kb-tag.err{border-color:#7e2d3a}',
'      .kb-tag.warn{border-color:#8a6d2a}',
'      .kb-meta{opacity:.8}',
'    }',
'  </style>'
    ) -join "`n"
    $HtmlText = Insert-Before $HtmlText '</head>' $listCss
  }

  $panelRuns = @(
'          <div class="kb-card kb-span-6" id="kb-panel-runs-failed">',
'            <h3 class="kb-title">Failed Workflow Runs (last 5)</h3>',
'            <ul class="kb-list" id="kb-runs-failed"><li class="kb-item kb-meta">loading��</li></ul>',
'          </div>'
  ) -join "`n"
  $panelPRs = @(
'          <div class="kb-card kb-span-6" id="kb-panel-prs-stale">',
'            <h3 class="kb-title">Stale PRs (7+ days no update)</h3>',
'            <ul class="kb-list" id="kb-prs-stale"><li class="kb-item kb-meta">loading��</li></ul>',
'          </div>'
  ) -join "`n"

  if($HtmlText -match 'id="kb-panels"'){
    if($HtmlText -notmatch 'id="kb-panel-runs-failed"'){ $HtmlText = Insert-AfterTagOpen $HtmlText 'kb-panels' $panelRuns }
    if($HtmlText -notmatch 'id="kb-panel-prs-stale"'){  $HtmlText = Insert-AfterTagOpen $HtmlText 'kb-panels' $panelPRs }
  } else {
    $container = @(
'  <div class="kb-grid kb-mt-12" id="kb-panels">',
$panelRuns,
$panelPRs,
'  </div>'
    ) -join "`n"
    $HtmlText = Insert-Before $HtmlText '</body>' $container
  }

  # ���� 2) JS ��ġ: API_BASE file: ���� + ������ + ȣ�� ��������������������������������������������������
  $JsText = Get-Content -LiteralPath $Js -Raw -Encoding utf8
  $OrigJsText = $JsText

  # 2-1) API_BASE ����(IIFE)
  if($JsText -notmatch 'location\.protocol==="file:"'){
    $apiFix = @(
'var API_BASE=(function(){',
'  var fromLS=localStorage.getItem("KOBONG_API_BASE");',
'  var def=(location.protocol==="file:"?"http://127.0.0.1:8080":(window.location.origin||(window.location.protocol+"//"+window.location.host)));',
'  var base=(window.__KOBONG_API_BASE__||fromLS||def);',
'  if(String(base).startsWith("file:")){ base="http://127.0.0.1:8080"; try{ localStorage.setItem("KOBONG_API_BASE",base) }catch(e){} }',
'  return String(base).replace(/\/+$/,"");',
'})();'
    ) -join "`n"
    if($JsText -match 'var\s+API_BASE'){
      $JsText = [regex]::new('var\s+API_BASE\s*=\s*.*?;','Singleline').Replace($JsText, $apiFix, 1)
    } else { $JsText = $apiFix + "`n" + $JsText }
  }

  # 2-2) ��ƿ(renderList/relTime)
  if($JsText -notmatch 'function\s+renderList\('){
    $utils = @(
'function relTime(t){ try{ var d=new Date(t); var s=(Date.now()-d.getTime())/1000; if(!isFinite(s)) return ""; var m=s/60,h=m/60,dz=h/24; if(s<60)return Math.floor(s)+"s ago"; if(m<60)return Math.floor(m)+"m ago"; if(h<48)return Math.floor(h)+"h ago"; return Math.floor(dz)+"d ago"; }catch(e){ return "" } }',
'function renderList(id, items, map){ var host=document.getElementById(id); if(!host) return; if(!items||items.length===0){ host.innerHTML = ''<li class="kb-item kb-meta">no data</li>''; return } host.innerHTML = items.map(map).join(""); }'
    ) -join "`n"
    $JsText = [regex]::new('function\s+setHtml\([^\)]*\)\s*\{.*?\}\s*','Singleline').Replace($JsText, { param($m) $m.Value + "`n" + $utils + "`n" }, 1)
  }

  # 2-3) �г� ������ (���ø� ���ͷ� ���: PowerShell�� ���ϵ���ǥ�� ����)
  if($JsText -notmatch '__kobongRenderPanels'){
    $renderer = @(
'window.__kobongRenderPanels=function(j){',
'  try{',
'    var runs=(j.workflow_runs||[]).filter(function(r){ var c=String(r.conclusion||"").toLowerCase(); var st=String(r.status||"").toLowerCase(); return ["failure","cancelled","timed_out"].indexOf(c)>=0 || st==="failure"; }).slice(0,5);',
'    renderList("kb-runs-failed", runs, function(r){',
'      var name=r.name||"run"; var url=r.html_url||"#";',
'      var c=String(r.conclusion||"").toLowerCase(); var tag=(c==="failure"?"err":(c? "warn":""));',
'      var when=r.updated_at||r.created_at||null;',
'      return `<li class="kb-item"><span class="kb-tag ${tag}">${(c||"")}</span><a href="${url}" target="_blank" rel="noreferrer">${name}</a><span class="kb-meta">${(when?relTime(when):"")}</span></li>`;',
'    });',
'    var staleCut=Date.now()-7*86400000;',
'    var prs=(j.prs||[]).filter(function(p){ if(String(p.state||"").toLowerCase()!=="open") return false; var u=Date.parse(p.updated_at||p.created_at||""); if(!isFinite(u)) return false; return u<staleCut; }).slice(0,5);',
'    renderList("kb-prs-stale", prs, function(p){',
'      var ttl=p.title||("PR #"+(p.number||"")); var url=p.html_url||"#";',
'      var when=p.updated_at||p.created_at||null;',
'      return `<li class="kb-item"><span class="kb-tag warn">stale</span><a href="${url}" target="_blank" rel="noreferrer">${ttl}</a><span class="kb-meta">${(when?relTime(when):"")}</span></li>`;',
'    });',
'  }catch(e){}',
'};'
    ) -join "`n"
    $JsText = $JsText.TrimEnd() + "`n" + $renderer + "`n"
  }

  # 2-4) ��� ���� �� �г� ���� ȣ��
  if($JsText -match 'setHtml\(\s*[''"]gh-summary[''"].*?\);' -and $JsText -notmatch '__kobongRenderPanels\s*&&'){
    $pattern = '(?is)(setHtml(\s*[''"]gh-summary[''"].*?);)'
    $rx = [regex]::new($pattern)
    $JsText = $rx.Replace($JsText, { param($m) $m.Groups[1].Value + ' try{window.__kobongRenderPanels&&window.__kobongRenderPanels(j);}catch(e){};' }, 1)
  }

  # ���� PLAN / APPLY ����������������������������������������������������������������������������������������������������������������������
  $plan = @()
  $plan += "html-panels:" + [string]([bool]($HtmlText -match 'kb-panel-runs-failed') -and [bool]($HtmlText -match 'kb-panel-prs-stale'))
  $plan += "js-apiFix  :" + [string]([bool]($JsText -match 'location\.protocol==="file:"'))
  $plan += "js-renderer:" + [string]([bool]($JsText -match '__kobongRenderPanels'))
  "[PLAN] " + ($plan -join ' | ') | Write-Host

  if(-not $ConfirmApply){ exit 0 }
  if($HtmlText -ne $OrigHtmlText){ Write-Atomic -Path $Html -Text $HtmlText }
  if($JsText   -ne $OrigJsText  ){ Write-Atomic -Path $Js   -Text $JsText   }

  "[APPLIED] HTML/JS patched" | Write-Host
  exit 0

} catch {
  Write-Error $_.Exception.Message
  exit 13
} finally {
  Remove-Item -Force $Lock -ErrorAction SilentlyContinue
}
