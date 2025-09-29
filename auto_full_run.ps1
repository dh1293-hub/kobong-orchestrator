# 레포 루트에서 실행
$F = ".\auto_full_run.ps1"
$S = Get-Content $F -Raw

$New = @'
function Open-InBrowser([string]$PathToHtml){
  if(!(Test-Path $PathToHtml)){ Log "[WARN] 파일 없음: $PathToHtml"; return }
  $full = (Resolve-Path $PathToHtml).Path
  $url  = "file:///$($full -replace '\\','/')"

  # 1) Chrome 우선 (시스템/로컬 설치 모두 탐색)
  $chromeCands = @(
    Join-Path ${env:ProgramFiles}     "Google\Chrome\Application\chrome.exe",
    Join-Path ${env:ProgramFiles(x86)}"Google\Chrome\Application\chrome.exe",
    Join-Path ${env:LOCALAPPDATA}     "Google\Chrome\Application\chrome.exe"
  ) | Where-Object { $_ -and (Test-Path $_) }

  if($UseChrome -and $chromeCands){
    $chrome = $chromeCands[0]
    try {
      # 공백 경로 안전: 호출 연산자 & 사용
      & $chrome $url | Out-Null
      Log "[OPEN] Chrome → $url"
      return
    } catch {
      Log "[WARN] Chrome 직접 실행 실패: $($_.Exception.Message)"
      try {
        Start-Process -FilePath $chrome -ArgumentList @($url) -WorkingDirectory (Split-Path $chrome) | Out-Null
        Log "[OPEN] Chrome(Start-Process) → $url"
        return
      } catch {
        Log "[WARN] Chrome Start-Process 실패: $($_.Exception.Message)"
      }
    }
  }

  # 2) Edge 폴백
  $edge = @(
    Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe",
    Join-Path ${env:ProgramFiles}      "Microsoft\Edge\Application\msedge.exe"
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if($edge){
    try { & $edge $url | Out-Null; Log "[OPEN] Edge → $url"; return } catch {}
    try { Start-Process -FilePath $edge -ArgumentList @($url) -WorkingDirectory (Split-Path $edge) | Out-Null; Log "[OPEN] Edge(Start-Process) → $url"; return } catch {}
  }

  # 3) 시스템 기본 앱 (HTML 연계)
  try { Start-Process -FilePath $full | Out-Null; Log "[OPEN] 기본 앱(file path) → $full"; return } catch {}

  # 4) 최종 폴백: cmd의 start 사용
  try { Start-Process -FilePath "cmd.exe" -ArgumentList @("/c","start","",$url) -WindowStyle Hidden | Out-Null; Log "[OPEN] cmd start → $url"; return } catch {
    Log "[ERROR] 어떤 방법으로도 브라우저를 열지 못했습니다: $($_.Exception.Message)"
  }
}
'@

# 기존 Open-InBrowser 블록 교체
$S = $S -replace 'function\s+Open-InBrowser\([^\}]+\}\s*\}', $New
Set-Content $F -Value $S -Encoding UTF8
Write-Host "[OK] Open-InBrowser 함수가 강인 버전으로 교체되었습니다."


