#requires -Version 7
$ErrorActionPreference='SilentlyContinue'
$ps = 5181,5191,5183,5193
foreach($p in $ps){
  Get-NetTCPConnection -State Listen -LocalPort $p |
    Select-Object -ExpandProperty OwningProcess -Unique |
    ForEach-Object { try{ Stop-Process -Id $_ -Force }catch{} }
}
"🛑 stopped: 5181, 5191, 5183, 5193"
