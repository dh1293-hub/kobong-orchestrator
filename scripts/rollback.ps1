param(
  [Parameter(Mandatory=$true)][string]$tag
)
$ErrorActionPreference = "Stop"

function Invoke-Git {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  & git @Args
  $code = $LASTEXITCODE
  if ($code -ne 0) { throw "git $($Args -join ' ') failed (exit $code)" }
}

Invoke-Git fetch --all --tags --prune
Write-Host "⚠️ 태그 롤백 실행: $tag" -ForegroundColor DarkYellow
& git tag -d $tag 2>$null | Out-Null
Invoke-Git push origin ":refs/tags/$tag"
Write-Host "✅ 태그 롤백 완료(원격/로컬): $tag" -ForegroundColor Green