#requires -Version 7.0
param([string]$Root,[string]$RelPath)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$Repo=(Resolve-Path ($Root ?? "." )).Path; $abs=Join-Path $Repo ($RelPath -replace '/','\')
$bak=Join-Path $Repo ('.kobong\.acl-backups\' + ($RelPath -replace '[\\/:\*\?\"<>\|]','_') + '.sddl.txt')
if (Test-Path $bak){ $sddl=Get-Content -LiteralPath $bak -Raw -Encoding utf8; $acl=New-Object System.Security.AccessControl.FileSecurity; $acl.SetSecurityDescriptorSddlForm($sddl); Set-Acl -LiteralPath $abs -AclObject $acl }
try { (Get-Item -LiteralPath $abs).Attributes = ((Get-Item -LiteralPath $abs).Attributes -band (-bnot [IO.FileAttributes]::ReadOnly)) } catch {}
Write-Host "[OK] Unprotected: $RelPath"