Param(
  [Parameter(Mandatory=$false)]
  [string]$Root = "D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\AUTO-Kobong-Monitoring\webui",
  [switch]$DryRun
)

Write-Host "== AK7 Careful Fix / 5193 cleanup (only for /api/ak7 content) ==" -ForegroundColor Cyan
Write-Host "Root:" $Root

if (!(Test-Path $Root)) { Write-Error "Root path not found: $Root"; exit 1 }

# Backup
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path (Split-Path $Root -Parent) ("webui_backup_"+$stamp)
if (-not $DryRun) {
  Write-Host "Backup -> $backup" -ForegroundColor Yellow
  Copy-Item -Path $Root -Destination $backup -Recurse -Force | Out-Null
} else {
  Write-Host "(DryRun) Backup would be created at $backup" -ForegroundColor DarkYellow
}

# Candidate files (AK7-related only)
$cands = Get-ChildItem -Path $Root -Recurse -File -Include *.html,*.js
$ak7Files = @()
foreach($f in $cands){
  $content = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  if ($null -ne $content -and ($content -match "/api/ak7" -or $content -match "AK7_API_BASE" -or $content -match 'data-svc="ORCHMON"')){
    $ak7Files += $f
  }
}

# Inline JS blocks (payloads are embedded at end of file)
$payloadJson = (Get-Content -Raw -LiteralPath $PSCommandPath) -split '#__PAYLOAD__',2 | Select-Object -Last 1
$payload = $payloadJson | ConvertFrom-Json
$inj1 = "<script>`n" + $payload.port_rewrite_js + "`n</script>"
$inj2 = "<script>`n" + $payload.dom_fix_js + "`n</script>"

$changed = @()

foreach($f in $ak7Files){
  $isHtml = $f.Extension -ieq ".html"
  $raw = Get-Content -LiteralPath $f.FullName -Raw

  $new = $raw

  # AK7 path-specific replacements
  $new = $new -replace "http://localhost:5193/api/ak7","http://localhost:5191/api/ak7"
  $new = $new -replace "http://localhost:5183/api/ak7","http://localhost:5181/api/ak7"

  # Overview labels
  $new = $new -replace "DEV \(5183\)","DEV (5181)"
  $new = $new -replace "MOCK \(5193\)","MOCK (5191)"

  # Service row label
  $new = $new -replace 'data-svc="ORCHMON"','data-svc="AK7"'
  $new = $new -replace '>\s*ORCHMON\s*<','>AK7<'

  # Inject runtime guards if HTML and not already present
  if ($isHtml -and $new -notmatch "KOBO-SENTINEL:AK7_PORT_REWRITE_V1"){
    if ($new -match "</body>"){
      $new = $new -replace "</body>", ("`n<!-- Injected by AK7_CarefulFix: port-rewrite -->`n"+$inj1+"`n<!-- Injected by AK7_CarefulFix: dom-fix -->`n"+$inj2+"`n</body>")
    } else {
      $new = $new + "`n<!-- Injected by AK7_CarefulFix: port-rewrite -->`n"+$inj1+"`n<!-- Injected by AK7_CarefulFix: dom-fix -->`n"+$inj2+"`n"
    }
  }

  if ($new -ne $raw){
    if (-not $DryRun){
      Set-Content -LiteralPath $f.FullName -Value $new -Encoding UTF8
    }
    $changed += $f.FullName
  }
}

Write-Host "Processed files (AK7-likely):" $ak7Files.Count
Write-Host "Changed files:" $changed.Count -ForegroundColor Green
$changed | ForEach-Object { Write-Host "  + $_" }
Write-Host "Done." -ForegroundColor Cyan

# __PAYLOAD__
{"port_rewrite_js": "/*! KOBO-SENTINEL:AK7_PORT_REWRITE_V1 */\n(function(){\n  try {\n    var AK7_BASE = (window.AK7_API_BASE || '').replace(/\\/$/, '');\n    if (!AK7_BASE) { console.warn(\"[AK7] AK7_API_BASE missing; port-rewrite shim inactive\"); return; }\n    var AK7 = new URL(AK7_BASE, window.location.href);\n    var AK7_ORIGIN = AK7.origin;\n\n    function needsFix(u) {\n      try {\n        var url = new URL(u, window.location.href);\n        if (!/\\/api\\/ak7(\\/|$)/.test(url.pathname)) return false;\n        var p = url.port || (url.protocol === 'https:' ? '443' : '80');\n        return p === '5193' || p === '5183';\n      } catch(e) { return false; }\n    }\n\n    function fixAk7(u) {\n      try {\n        var url = new URL(u, window.location.href);\n        if (!/\\/api\\/ak7(\\/|$)/.test(url.pathname)) return u;\n        var fixed = new URL(url.pathname + url.search + url.hash, AK7_ORIGIN).toString();\n        return fixed;\n      } catch(e) { return u; }\n    }\n\n    var _fetch = window.fetch ? window.fetch.bind(window) : null;\n    if (_fetch) {\n      window.fetch = function(input, init) {\n        try {\n          var url = (typeof input === 'string') ? input : (input && input.url) || '';\n          if (url && needsFix(url)) {\n            var f = fixAk7(url);\n            if (typeof input === 'string') return _fetch(f, init);\n            var req = new Request(f, input);\n            return _fetch(req, init);\n          }\n        } catch(e) {}\n        return _fetch(input, init);\n      };\n    }\n\n    if (window.EventSource) {\n      var _ES = window.EventSource;\n      window.EventSource = function(url, config) {\n        var u = url;\n        try { if (typeof url === 'string' && needsFix(url)) { u = fixAk7(url); } } catch(e) {}\n        return new _ES(u, config);\n      };\n      window.EventSource.prototype = _ES.prototype;\n      window.EventSource.CONNECTING = _ES.CONNECTING;\n      window.EventSource.OPEN = _ES.OPEN;\n      window.EventSource.CLOSED = _ES.CLOSED;\n    }\n\n    if (window.WebSocket) {\n      var _WS = window.WebSocket;\n      window.WebSocket = function(url, protocols) {\n        var u = url;\n        try { if (typeof url === 'string' && needsFix(url)) { u = fixAk7(url); } } catch(e) {}\n        return new _WS(u, protocols);\n      };\n      window.WebSocket.prototype = _WS.prototype;\n    }\n\n    console.log(\"[AK7] port-rewrite shim active, AK7_ORIGIN:\", AK7_ORIGIN);\n  } catch(e) {\n    console.warn(\"AK7 port-rewrite init failed\", e);\n  }\n})();", "dom_fix_js": "/*! KOBO-SENTINEL:AK7_DOM_FIX_V1 */\n(function(){\n  function ready(fn){ if(document.readyState!=='loading'){fn()}else{document.addEventListener('DOMContentLoaded',fn)} }\n\n  function computePorts(){\n    var AK7_BASE = (window.AK7_API_BASE || '').replace(/\\/$/, '');\n    try{\n      var u = new URL(AK7_BASE || window.location.href, window.location.href);\n      var p = u.port || (u.protocol==='https:'?'443':'80');\n      var dev='5181', mock='5191';\n      if (p==='5181'){ dev='5181'; mock='5191'; }\n      if (p==='5191'){ dev='5181'; mock='5191'; }\n      return {dev:dev, mock:mock, api: AK7_BASE || ''};\n    }catch(e){\n      return {dev:'5181', mock:'5191', api: AK7_BASE || ''};\n    }\n  }\n\n  ready(function(){\n    var ports = computePorts();\n\n    try{\n      var tr = document.querySelector('tr[data-svc=\"ORCHMON\"]');\n      if (tr) {\n        tr.setAttribute('data-svc','AK7');\n        var firstTd = tr.querySelector('td');\n        if (firstTd && /ORCHMON/.test(firstTd.textContent)) firstTd.textContent = 'AK7';\n      }\n    }catch(e){}\n\n    try{\n      var card = Array.prototype.find.call(document.querySelectorAll('article.card p'), function(p){\n        return /\ucee8\ud14c\uc774\ub108\\(DEV\\/\\d+\\s*\u00b7\\s*MOCK\\/\\d+\\)/.test(p.textContent || '');\n      });\n      if (card){\n        card.textContent = \"\ucee8\ud14c\uc774\ub108(DEV/\"+ports.dev+\" \u00b7 MOCK/\"+ports.mock+\") \ud5ec\uc2a4, Peers \uc0c1\ud0dc\uace0\uce68 \ubc84\ud2bc \uc81c\uacf5.\";\n      }\n\n      var sApi = document.getElementById('sApi'); if (sApi && ports.api) sApi.textContent = ports.api;\n      var sDev = document.getElementById('sDev');\n      if (sDev){\n        var devLabelTd = sDev.closest('tr').querySelector('td:first-child');\n        if (devLabelTd) devLabelTd.textContent = \"DEV (\"+ports.dev+\")\";\n        var devUrlSpan = sDev.closest('tr').querySelector('span.orch-mono');\n        if (devUrlSpan && /localhost:\\d+/.test(devUrlSpan.textContent)) devUrlSpan.textContent = \"http://localhost:\"+ports.dev;\n      }\n      var sMock = document.getElementById('sMock');\n      if (sMock){\n        var mockLabelTd = sMock.closest('tr').querySelector('td:first-child');\n        if (mockLabelTd) mockLabelTd.textContent = \"MOCK (\"+ports.mock+\")\";\n        var mockUrlSpan = sMock.closest('tr').querySelector('span.orch-mono');\n        if (mockUrlSpan && /localhost:\\d+/.test(mockUrlSpan.textContent)) mockUrlSpan.textContent = \"http://localhost:\"+ports.mock;\n      }\n    }catch(e){}\n\n    console.log(\"[AK7] DOM-fix applied for labels and AK7 row.\");\n  });\n})();"}