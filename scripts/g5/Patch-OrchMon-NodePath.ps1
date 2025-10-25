# Patch-OrchMon-NodePath.ps1 — 두 파일의 Get-NodePath를 표준화(ProgramFiles 우선)
$Files = @(
  'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\scripts\g5\Install-OrchMon-AutoStart.ps1',
  'D:\ChatGPT5_AI_Link\dosc\Kobong-Orchestrator-VIP\scripts\g5\Run-OrchMon-5183-5193.ps1'
)

$NewGetNode = @'
function Get-NodePath{
  $cands = @(
    (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'nodejs\node.exe'),
    'node.exe','node'
  )
  foreach($p in $cands){
    $cmd = Get-Command $p -ErrorAction SilentlyContinue
    if($cmd){ return $cmd.Source }
  }
  return $null
}
'@

foreach($f in $Files){
  if(Test-Path $f){
    $bak = "$f.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
    Copy-Item $f $bak -Force
    $src = Get-Content -Raw -LiteralPath $f
    # 기존 Get-NodePath 블록을 새 정의로 교체(없으면 맨 위에 추가)
    if($src -match 'function\s+Get-NodePath\s*\{[\s\S]*?\}'){
      $src = [regex]::Replace($src,'function\s+Get-NodePath\s*\{[\s\S]*?\}',$NewGetNode,1)
    }else{
      $src = $NewGetNode + "`r`n" + $src
    }
    Set-Content -LiteralPath $f -Value $src -Encoding UTF8
    Write-Host "[OK] Patched → $f  (backup: $bak)"
  }else{
    Write-Host "[SKIP] not found: $f"
  }
}
