#requires -Version 7.0
param([switch]$Force)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$WebUi = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$Freeze= Join-Path $WebUi '.ui-freeze.json'
if(-not (Test-Path $Freeze)){ Write-Error "freeze file missing: $Freeze"; exit 10 }
$doc = Get-Content -Raw -Encoding utf8 $Freeze | ConvertFrom-Json
$errors=@()
foreach($e in $doc.files){
  $p = Join-Path $WebUi $e.path
  if(-not (Test-Path $p)){ $errors += "MISSING: $($e.path)"; continue }
  $h = (Get-FileHash -Algorithm SHA256 -Path $p).Hash.ToLowerInvariant()
  if($h -ne $e.sha256){ $errors += "CHANGED: $($e.path)" }
}
if($errors.Count){
  if($Force -or $env:KOBONG_UI_ALLOW_EDIT -eq '1'){
    Write-Warning ("UI FREEZE DRIFT (allowed):`n - " + ($errors -join "`n - ")); exit 0
  } else {
    Write-Error ("UI FREEZE VIOLATION:`n - " + ($errors -join "`n - ")); exit 11
  }
} else {
  Write-Host "[OK] UI snapshot verified"
}

# >>> GPT5 AUTO-BASELINE 20250920-202118
$FreezeHashes = @{
  'src\index.css' = '312834fb5a2b1d8e7c2efe8ac2d144d6849300aef40b7e59a2cb57d95bd6876b';
  'src\lib\github.ts' = '7ff20b69f68385eccb2ad407a05f7bd9326fec45fde2788b73f1b80ac950a609';
  'src\main.tsx' = 'b4ba345f47c5b728455ac97599b9afc81561b486569bd448a38b4df19baf5d74';
  'src\ui\atoms\Icon.tsx' = '1ce12a2bc357c97cea2eb83e267080d275628de3586d0f8c59618c89b785a5bb';
  'src\ui\atoms\Spark.tsx' = 'bfbd04ed6e2558867d651d048e690de4fc3a67dca7def5f1be735f69effdf300';
  'src\ui\GithubOpsDashboard.tsx' = '53779de0e04f364a70a64b711f75a638d21b27d5e8f4aba3aac97006b889711f';
  'tailwind.config.ts' = 'f72cdb2884ee40e218cdbb5cb96aa9c39f3ef25249622e21c6f258c8b004d964';
}
# <<< GPT5 AUTO-BASELINE

# >>> GPT5 AUTO-FILELIST 20250920-202118
$FreezeFiles = @(
  'src\index.css',
  'src\lib\github.ts',
  'src\main.tsx',
  'src\ui\atoms\Icon.tsx',
  'src\ui\atoms\Spark.tsx',
  'src\ui\GithubOpsDashboard.tsx',
  'tailwind.config.ts'
)
# <<< GPT5 AUTO-FILELIST