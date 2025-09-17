#requires -Version 7.0
param([string]$Tag, [switch]$ConfirmApply)
Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'
if (-not $Tag) { throw "Specify -Tag vX.Y.Z" }
if ($env:CONFIRM_APPLY -eq 'true') { $ConfirmApply=$true }
$head="docs/readme-badge-$Tag"
$raw=gh pr list --state open --limit 100 --json number,headRefName,url 2>$null
if (-not $raw) { "[OK] no open PRs"; exit 0 }
$open=@($raw | ConvertFrom-Json | Where-Object {$_.headRefName -eq $head} | Sort-Object number)
switch ($open.Count){0{"[OK] no open PRs for $head"; exit 0} 1{"[OK] no duplicates for $head (only #$($open[0].number))"; exit 0}}
$keep=$open[-1]; $dups=$open[0..($open.Count-2)]
"[INFO] keep  → #$($keep.number) $($keep.url)"
foreach($d in $dups){
  "[INFO] close → #$($d.number) $($d.url)"
  if($ConfirmApply){
    gh pr comment $d.number --body ":robot: Superseded by #$($keep.number). Closing duplicate badge PR."
    gh pr close   $d.number
  }
}
