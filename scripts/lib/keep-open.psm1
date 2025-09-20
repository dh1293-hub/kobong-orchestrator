#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

function Invoke-KeepOpenIfNeeded {
  [CmdletBinding()]
  param([string]$Reason = '', [switch]$Force)
  try {
    # 1) 탐색기 더블클릭으로 열린 콘솔인지 탐지
    $pp = Get-CimInstance Win32_Process -Filter ("ProcessId={0}" -f $pid)
    $ppid = $pp.ParentProcessId
    $pname = (Get-Process -Id $ppid -ErrorAction SilentlyContinue).ProcessName
    $byExplorer = @('explorer','explorer.exe') -contains (($pname ?? '')).ToLower()
    # 2) 환경변수로 강제 홀드할 수도 있음(KOBONG_HOLD_SHELL=1)
    $shouldHold = $Force -or $byExplorer -or ($env:KOBONG_HOLD_SHELL -eq '1')
    if ($shouldHold) {
      [Console]::WriteLine('')
      [Console]::WriteLine("[HOLD] $Reason — Press Enter to close ...")
      [void](Read-Host)
    }
  } catch {
    # 홀드 실패는 무시
  }
}

if ($ExecutionContext.SessionState.Module) {
  Export-ModuleMember -Function Invoke-KeepOpenIfNeeded
}