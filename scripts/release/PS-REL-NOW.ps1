param(
  [string]$Bump = $env:REL_BUMP_LEVEL  # patch|minor|major or empty
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding           = New-Object System.Text.UTF8Encoding($false)
$env:LC_ALL = "C.UTF-8"; $env:LANG = "C.UTF-8"

function Assert-Cmd($n){ if(-not(Get-Command $n -ErrorAction SilentlyContinue)){ throw "missing tool: $n" } }
Assert-Cmd git; Assert-Cmd gh; Assert-Cmd node

# repo root
$ROOT = (git rev-parse --show-toplevel).Trim()
Set-Location ($ROOT -replace '/', '\')
Write-Host ("[info] repo: {0}" -f (Get-Location).Path)

# optional bump & tag
if ($Bump) {
  Write-Host ("[info] standard-version --release-as {0}" -f $Bump)
  npx standard-version --release-as $Bump
  git push --follow-tags origin $(git rev-parse --abbrev-ref HEAD)
}

# ensure latest tag
git fetch --all --tags --prune | Out-Null
$tag = (git describe --tags --abbrev=0).Trim()
if ([string]::IsNullOrWhiteSpace($tag)) { throw "no tag. run with -Bump patch|minor|major to create one." }
Write-Host ("[info] tag: {0}" -f $tag)

# generate notes via ACL
New-Item -ItemType Directory -Force -Path .\out\release_notes | Out-Null
$notesPath = node .\scripts\acl\release-notes.mjs --tag=$tag
if (-not (Test-Path $notesPath)) { throw "notes not found: $notesPath" }
Write-Host ("[info] notes: {0}" -f $notesPath)

# normalize helper
function Normalize([string]$s) {
  if ($null -eq $s) { return "" }
  $t = $s -replace "`r",""
  $t = [regex]::Replace($t, "\s+$", "")
  return $t + "`n"
}
$localN = Normalize (Get-Content $notesPath -Raw)

# ensure release exists (via API if missing)
$repoSlug = (git config --get remote.origin.url) -replace '.*github.com[:/]', '' -replace '\.git$',''
$release = $null
try { $release = gh api "repos/$repoSlug/releases/tags/$tag" | ConvertFrom-Json } catch {}

if (-not $release) {
  Write-Host "[info] release not found → creating via API"
  $payload = @{
    tag_name    = $tag
    name        = ("gpt5-conductor {0}" -f $tag)
    body        = $localN
    draft       = $false
    prerelease  = $false
    make_latest = "true"
  } | ConvertTo-Json -Compress
  $tmpCreate = Join-Path $env:TEMP ("rel_create_{0}.json" -f ($tag -replace '[^\w\.-]','_'))
  [IO.File]::WriteAllText($tmpCreate, $payload, [System.Text.UTF8Encoding]::new($false))
  $release = gh api --method POST "repos/$repoSlug/releases" --input "$tmpCreate" | ConvertFrom-Json
  Write-Host ("[info] created release id={0}" -f $release.id)
} else {
  Write-Host "[info] release exists"
}

# patch exact body (normalized, UTF-8 no BOM)
$patchJson = @{ body = $localN } | ConvertTo-Json -Compress
$tmpPatch  = Join-Path $env:TEMP ("rel_patch_{0}.json" -f ($tag -replace '[^\w\.-]','_'))
[IO.File]::WriteAllText($tmpPatch, $patchJson, [System.Text.UTF8Encoding]::new($false))
gh api --method PATCH "repos/$repoSlug/releases/$($release.id)" --input "$tmpPatch" | Out-Null

# verify
$rel2    = gh api "repos/$repoSlug/releases/tags/$tag" | ConvertFrom-Json
$remoteN = Normalize $rel2.body
if ($localN -eq $remoteN) {
  Write-Host "`nPASS release body equals notes."
} else {
  Write-Host "`nFAIL release body differs; open web to check: gh release view $tag --web"
}
Write-Host ("`nDONE tag: {0}" -f $tag)
Write-Host ("open: gh release view {0} --web" -f $tag)