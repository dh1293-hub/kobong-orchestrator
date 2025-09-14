#requires -Version 7.0
param([string]$Name='Alice',[int]$Count=3)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
for($i=1;$i -le $Count;$i++){
  Write-Host ("[{0}/{1}] Hello, {2}!" -f $i,$Count,$Name)
  Start-Sleep -Milliseconds 50
}