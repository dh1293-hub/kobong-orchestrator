param(
  [string]$Name = "World",
  [int]$Count = 1
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
for ($i=1; $i -le $Count; $i++) {
  Write-Output ("{0} {1}" -f $i, $Name)
}