#requires -Version 7.0
param([string]$Root,[string]$RelPath)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
$Repo=(Resolve-Path ($Root ?? "." )).Path; $abs=Join-Path $Repo ($RelPath -replace '/','\')
$acl=Get-Acl -LiteralPath $abs
$me=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value; $users='S-1-5-32-545'
function T($a,$s){$sid=[Security.Principal.SecurityIdentifier]::new($s); foreach($x in $a.Access){ $sid2=$null; if($x.IdentityReference -is [Security.Principal.SecurityIdentifier]){$sid2=$x.IdentityReference}else{try{$sid2=$x.IdentityReference.Translate([Security.Principal.SecurityIdentifier])}catch{}} if($sid2 -and $sid2.Value -eq $sid.Value -and $x.AccessControlType -eq 'Deny' -and ($x.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Delete)){return $true}} return $false}
foreach($sidStr in @($me,$users)){ if(-not (T $acl $sidStr)){ $sid=[Security.Principal.SecurityIdentifier]::new($sidStr); $rule=New-Object System.Security.AccessControl.FileSystemAccessRule($sid,[System.Security.AccessControl.FileSystemRights]::Delete,'None','None','Deny'); $null=$acl.AddAccessRule($rule) } }
Set-Acl -LiteralPath $abs -AclObject $acl
try { (Get-Item -LiteralPath $abs).Attributes = ((Get-Item -LiteralPath $abs).Attributes -bor [IO.FileAttributes]::ReadOnly) } catch {}
Write-Host "[OK] Protected: $RelPath"