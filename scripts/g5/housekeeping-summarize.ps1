#requires -Version 7.0
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.Encoding]::UTF8

$log = Join-Path (Get-Location) 'logs/apply-log.jsonl'
if (-not (Test-Path $log)) {
  $md = "# Housekeeping Summary`n`n_No logs found (dry-run produced no file)._"
  if ($env:GITHUB_STEP_SUMMARY) { $md | Out-File $env:GITHUB_STEP_SUMMARY -Encoding utf8 -NoNewline } else { Write-Host $md }
  exit 0
}

$lines = Get-Content $log -ErrorAction Stop
$recs = @()
foreach ($ln in $lines) {
  try { $recs += ($ln | ConvertFrom-Json) } catch { }
}
if (-not $recs) {
  $md = "# Housekeeping Summary`n`n_Log file present but no valid JSON lines._"
  if ($env:GITHUB_STEP_SUMMARY) { $md | Out-File $env:GITHUB_STEP_SUMMARY -Encoding utf8 -NoNewline } else { Write-Host $md }
  exit 0
}

$latestTrace = $recs | Sort-Object timestamp -Descending | Select-Object -First 1 -ExpandProperty traceId
$house = $recs | Where-Object {$_.module -eq 'housekeeping-weekly'}
$git   = $recs | Where-Object {$_.module -eq 'git' -and $_.action -eq 'branch-prune-quiet'}

$applied = ($house + $git) | Where-Object {$_.outcome -in 'APPLY','APPLIED'} | Measure-Object | Select-Object -ExpandProperty Count
$preview = ($house + $git) | Where-Object {$_.outcome -eq 'PREVIEW'} | Measure-Object | Select-Object -ExpandProperty Count
$errors  = $recs | Where-Object {$_.level -eq 'ERROR'}

$md = @()
$md += "# Housekeeping Summary"
$md += ""
$md += "- Records: $($recs.Count)"
$md += "- Applied: $applied · Preview: $preview"
$md += "- Latest trace: `$latestTrace`"
if ($errors) {
  $md += ""
  $md += "## Errors"
  $errors | Select-Object -First 5 | ForEach-Object {
    $md += "- `$( $_.timestamp )` **$($_.module)/$($_.action)** — $($_.message)"
  }
}
$md += ""
$md += "## Recent Events"
($recs | Sort-Object timestamp -Descending | Select-Object -First 10 |
  ForEach-Object { "- `$( $_.timestamp )` **$($_.module)/$($_.action)** `[$($_.outcome)]` — $($_.message)" }) | ForEach-Object { $md += $_ }

$mdStr = ($md -join "`n")
# step summary
if ($env:GITHUB_STEP_SUMMARY) { $mdStr | Out-File $env:GITHUB_STEP_SUMMARY -Encoding utf8 -NoNewline } else { Write-Host $mdStr }
# save for PR comment
$mdStr | Out-File 'housekeeping-summary.md' -Encoding utf8 -NoNewline