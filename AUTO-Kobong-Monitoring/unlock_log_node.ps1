<# 
unlock_log_node.ps1
--------------------
목적: node.exe가 점유 중인 .log 파일을 안전하게 해제

사용 예:
  .\unlock_log_node.ps1 -LogPath "D:\logs\ak7-runtime.log" -HandleExe "C:\Tools\Sysinternals\handle64.exe"
  .\unlock_log_node.ps1 -LogPath "D:\logs\ak7-runtime.log" -ServiceName "AK7-DEV" -GracefulFirst

매개변수:
  -LogPath       : 잠금 해제할 로그 파일 전체 경로 (필수)
  -HandleExe     : Sysinternals handle.exe 경로 (선택; 지정 시 핸들 강제 해제 가능)
  -ServiceName   : node.exe가 Windows 서비스로 구동 중일 때 서비스 이름 (선택; 안전 종료에 사용)
  -GracefulFirst : 먼저 서비스/프로세스 안전 종료를 시도하고, 실패 시 handle.exe로 강제 해제 (기본 True)
  -KillAsLastResort : 최후 수단으로 node.exe 프로세스 강제 종료 허용 (기본 False)
#>

param(
  [Parameter(Mandatory=$true)][string]$LogPath,
  [string]$HandleExe,
  [string]$ServiceName,
  [switch]$GracefulFirst = $true,
  [switch]$KillAsLastResort = $false
)

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){  Write-Host "[ERR ] $m" -ForegroundColor Red }

if (-not (Test-Path $LogPath)){
  Write-Err "LogPath가 존재하지 않습니다: $LogPath"
  exit 1
}

# 1) (선택) 안전 종료 시도: 서비스 → 프로세스
if ($GracefulFirst){
  if ($ServiceName){
    try {
      $svc = Get-Service -Name $ServiceName -ErrorAction Stop
      if ($svc.Status -eq 'Running'){
        Write-Info "서비스 정지 시도: $ServiceName"
        Stop-Service -Name $ServiceName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $svc.WaitForStatus('Stopped','00:00:10')
      }
    } catch { Write-Warn "서비스 조회/정지 실패 또는 서비스 없음: $ServiceName" }
  }

  # 서비스가 아니거나 아직 열려 있을 수 있으니, node.exe 프로세스 중 해당 로그를 사용하는 후보 찾기
  # (핸들 검사 전 단계; 명령행에 프로젝트 경로 단서가 있으면 그 PID만 대상으로 함)
  try{
    $nodeProcs = Get-CimInstance Win32_Process -Filter "Name='node.exe'"
  } catch { $nodeProcs = @() }
  foreach($p in $nodeProcs){
    # 후보 기준: 커맨드라인에 'Kobong' 또는 'AUTO-Kobong-Monitoring' 등의 단서가 포함되면 우선 후보
    if ($p.CommandLine -match 'Kobong|AUTO-Kobong|ak7|orch|5181|5191'){
      Write-Info ("후보 PID {0} {1}" -f $p.ProcessId, $p.CommandLine)
    }
  }
}

# 2) handle.exe가 있으면, 실제 핸들 보유 PID/핸들 값 추출
$handles = @()
if ($HandleExe){
  if (-not (Test-Path $HandleExe)){
    Write-Err "HandleExe 경로가 존재하지 않습니다: $HandleExe"
    $HandleExe = $null
  } else {
    Write-Info "핸들 검사 실행: $HandleExe `"$LogPath`""
    $out = & $HandleExe $LogPath -nobanner 2>$null | Out-String
    if (-not $out){
      Write-Warn "핸들 출력 없음. 관리자 PowerShell로 실행했는지 확인하세요."
    } else {
      # 예시 라인: "node.exe pid: 1234  2F4: File  (RW-)   D:\path\file.log"
      $lines = $out -split "`r?`n"
      $currentPid = $null
      foreach($line in $lines){
        if ($line -match '^\s*([^\s]+)\s+pid:\s*(\d+)'){
          $exe = $matches[1]; $currentPid = [int]$matches[2]
        }
        if ($currentPid -and $line -match '\s+([0-9A-Fa-f]+):\s+File\s+.*'){
          $hval = $matches[1]
          if ($line -match [regex]::Escape($LogPath)){
            $handles += [pscustomobject]@{ PID=$currentPid; Handle=$hval; EXE=$exe; Line=$line.Trim() }
          }
        }
      }
    }
  }
}

if ($handles.Count -eq 0){
  Write-Info "handle.exe로 특정 핸들을 찾지 못했습니다."
} else {
  Write-Info ("잠금 핸들 {0}개 발견" -f $handles.Count)
  $handles | Format-Table -AutoSize
}

# 3) 해제 시나리오
$unlocked = $false
try{
  $fs = [System.IO.File]::Open($LogPath, 'Open', 'ReadWrite', 'None')
  $fs.Close()
  Write-Info "현재 잠금이 감지되지 않습니다."
  $unlocked = $true
} catch {
  Write-Info "파일이 여전히 잠겨 있습니다. 해제 진행합니다."
}

if (-not $unlocked){
  if ($HandleExe -and $handles.Count -gt 0){
    foreach($h in $handles){
      Write-Info ("핸들 강제 종료 시도: PID={0}, Handle={1}" -f $h.PID, $h.Handle)
      & $HandleExe -p $h.PID -c $h.Handle -y | Out-Null
    }
    Start-Sleep -Milliseconds 500
    try{
      $fs = [System.IO.File]::Open($LogPath, 'Open', 'ReadWrite', 'None')
      $fs.Close()
      Write-Info "핸들 강제 종료 후 잠금 해제 성공"
      $unlocked = $true
    } catch {
      Write-Warn "핸들 강제 종료 후에도 잠금이 유지됩니다."
    }
  }

  if (-not $unlocked -and $ServiceName){
    try{
      $svc = Get-Service -Name $ServiceName -ErrorAction Stop
      if ($svc.Status -ne 'Stopped'){
        Write-Info "서비스 재정지/확인: $ServiceName"
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        $svc.WaitForStatus('Stopped','00:00:10')
      }
    } catch { Write-Warn "서비스 정지 재시도 실패: $ServiceName" }
    Start-Sleep -Milliseconds 500
    try{
      $fs = [System.IO.File]::Open($LogPath, 'Open', 'ReadWrite', 'None')
      $fs.Close()
      Write-Info "서비스 정지 후 잠금 해제 성공"
      $unlocked = $true
    } catch {}
  }

  if (-not $unlocked -and $KillAsLastResort){
    # 최후 수단: node.exe 종료
    try{
      $pids = (Get-Process node -ErrorAction SilentlyContinue).Id
      foreach($pid in $pids){
        Write-Warn "최후 수단: node.exe PID=$pid 강제 종료"
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
      }
      Start-Sleep -Milliseconds 500
      $fs = [System.IO.File]::Open($LogPath, 'Open', 'ReadWrite', 'None')
      $fs.Close()
      Write-Info "프로세스 강제 종료 후 잠금 해제 성공"
      $unlocked = $true
    } catch { Write-Err "최후 수단 실패: $($_.Exception.Message)" }
  }
}

if (-not $unlocked){
  Write-Err "잠금 해제 실패. 관리자 권한 PowerShell 실행/올바른 HandleExe 경로/서비스명 확인이 필요합니다."
  exit 2
} else {
  Write-Host "`n=== 잠금 해제 OK ===" -ForegroundColor Green
}
