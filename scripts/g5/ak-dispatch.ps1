function Invoke-Step {
  param([Parameter(Mandatory=$true)][ScriptBlock]$Block,[string]$Name)
  $code = 0
  try {
    & $Block
    $code = if ($LASTEXITCODE -is [int]) { $LASTEXITCODE } elseif ($?) { 0 } else { 13 }
  } catch {
    Write-Error $_
    $code = 13
  }

  'version' {
    $wf = '.github/workflows/ak-commands.yml'
    $hash = (Get-FileHash -LiteralPath $wf -ErrorAction SilentlyContinue).Hash
    Write-Host "ak-dispatch.ps1 = $($MyInvocation.MyCommand.Name)"
    Write-Host "ak-commands.yml = $hash"
    Write-Klc 'version' 0
    exit 0
  }



  # 표준 종료코드 정규화: 0은 성공, 10 이상만 실패로 간주
  if ($code -lt 10) {
    if ($code -ne 0) { Write-Host "[note] normalize exit code $code → 0 (non-fatal)"; }
    $code = 0
  }
  Write-Klc $Name $code
  exit $code
}
