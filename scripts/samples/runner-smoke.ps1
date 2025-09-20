#requires -Version 7.0
param(
  [Parameter(Position=0)][string]$Name="Kobong",
  [Parameter(Position=1)][int]$N=2
)
1..$N | ForEach-Object {
  "{0:o} hello, {1} #{2}" -f (Get-Date), $Name, $_
  Start-Sleep -Milliseconds 50
}
