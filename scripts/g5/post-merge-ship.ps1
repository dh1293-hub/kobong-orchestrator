#requires -Version 7.0
# post-merge-ship.ps1 — 안정판 v1.1.1a
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$root=(git rev-parse --show-toplevel 2>$null) ?? (Get-Location).Path
$root=(Resolve-Path $root).Path
$DateTag=(Get-Date -Format 'yyyy.MM.dd-HHmm')
$Branch =(git rev-parse --abbrev-ref HEAD).Trim()

function Run-PwshFile([string]$path,[string[]]$args){
  if(!(Test-Path $path)){ Write-Warning "missing: $path"; return $false }
  & pwsh -NoProfile -File $path @args
  if($LASTEXITCODE -ne 0){ Write-Warning "exit $LASTEXITCODE: $path"; return $false }
  return $true
}

# 1) 컨텍스트/인벤토리
Run-PwshFile (Join-Path $root 'scripts/g5/make-g5-context.ps1')          @('-Mode','MOCK') | Out-Null
Run-PwshFile (Join-Path $root 'scripts/g5/update-docs-and-inventory.ps1') @()               | Out-Null

# 2) 변경물 커밋(있을 때만)
$adds=@()
foreach($g in @('.kobong/context/context-latest.txt',
                '.kobong/context/context-latest.json',
                '_inventory/inventory.csv',
                '_inventory/inventory.json',
                '_inventory/inventory_hashes.csv')){
  $p=Join-Path $root $g; if(Test-Path $p){ $adds += $g }
}
if($adds.Count -gt 0){
  git add $adds
  git commit -m "chore(ship): context+inventory refresh after merge ($DateTag)" 2>$null; if($LASTEXITCODE){}
}

# 3) 태그/푸시(태그는 항상)
$Tag="v1.1.1-apply-patches+$DateTag"
git tag -a $Tag -m "apply-patches.ps1 hotfix baked (null-canon guard)" 2>$null; if($LASTEXITCODE){}
git push origin $Branch
git push origin $Tag

# 4) 스모크(헬스)
try{ Invoke-RestMethod http://localhost:5191/health | Out-Host }catch{ Write-Warning $_.Exception.Message }
try{ Invoke-RestMethod http://localhost:5193/health | Out-Host }catch{ Write-Warning $_.Exception.Message }

Write-Host "`n[ship] done: $Tag"
