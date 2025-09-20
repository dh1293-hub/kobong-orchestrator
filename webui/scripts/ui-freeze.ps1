#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$WebUi   = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$Targets = @(
  'src\ui\GithubOpsDashboard.tsx',
  'src\ui\atoms\Icon.tsx',
  'src\ui\atoms\Spark.tsx',
  'src\lib\github.ts',
  'src\main.tsx',
  'src\index.css',
  'tailwind.config.ts',
  'vite.config.ts',
  'package.json'
)
$Files = $Targets | ForEach-Object { Join-Path $WebUi $_ }
$miss=@(); foreach($f in $Files){ if(-not (Test-Path $f)){ $miss += $f } }
if($miss.Count){ throw "스냅샷 대상 누락:`n - " + ($miss -join "`n - ") }

$snap=@()
foreach($f in $Files){
  $h  = Get-FileHash -Algorithm SHA256 -Path $f
  $fi = Get-Item $f
  $rel = (Resolve-Path $f).Path.Replace($WebUi + '\','')
  $snap += [ordered]@{
    path   = $rel
    size   = $fi.Length
    mtime  = $fi.LastWriteTimeUtc.ToString('o')
    sha256 = $h.Hash.ToLowerInvariant()
  }
}
$doc = [ordered]@{
  version   = '1'
  createdAt = (Get-Date).ToString('o')
  webui     = (Resolve-Path $WebUi).Path
  files     = $snap
  notes     = 'Auto-generated. Use `npm run ui:freeze` after intentional UI changes.'
} | ConvertTo-Json -Depth 8
$freeze = Join-Path $WebUi '.ui-freeze.json'
$doc | Out-File $freeze -Encoding utf8 -NoNewline
Write-Host "[OK] UI snapshot refreshed → $freeze"