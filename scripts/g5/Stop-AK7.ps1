#requires -Version 7
$ErrorActionPreference='SilentlyContinue'
5181,5191 | % {
  Get-NetTCPConnection -State Listen -LocalPort $_ |
    Select -Expand OwningProcess -Unique | % { Stop-Process -Id $_ -Force }
}
"🛑 AK7 stopped: 5181, 5191"
