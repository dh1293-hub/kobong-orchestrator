#requires -Version 7
$ErrorActionPreference='SilentlyContinue'
5183,5193 | % {
  Get-NetTCPConnection -State Listen -LocalPort $_ |
    Select -Expand OwningProcess -Unique | % { Stop-Process -Id $_ -Force }
}
"🛑 ORCH stopped: 5183, 5193"
