# AK7 rollback stub (URS 연동 전까지 임시)
function New-AK7RollbackPoint {
  param([string]$Name='good-1')
  [pscustomobject]@{ ok=$true; action='create'; name=$Name; note='stub (URS 연동 전)' }
}
function Restore-AK7RollbackPoint {
  param([string]$Name='good-1',[switch]$WhatIf)
  [pscustomobject]@{ ok=$true; action=$(if($WhatIf){'preview'}else{'restore'}); name=$Name; note='stub (URS 연동 전)'; whatif=$WhatIf.IsPresent }
}

