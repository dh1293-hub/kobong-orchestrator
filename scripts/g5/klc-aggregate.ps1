--- a/scripts/g5/klc-aggregate.ps1
+++ b/scripts/g5/klc-aggregate.ps1
@@
- param([string]$Mode)
+ param(
+   [ValidateSet('nightly','adhoc')] [string]$Mode = 'nightly',
+   [string]$Root = ''
+ )
+ Set-StrictMode -Version Latest
+ $ErrorActionPreference='Stop'
+ $PSDefaultParameterValues['Out-File:Encoding']='utf8'
+
+ if ([string]::IsNullOrWhiteSpace($Root)) {
+   # GitHub Actions에서도 동작하게: 소스 추출 폴더 또는 워크스페이스
+   $Root = $env:SRC_DIR
+   if ([string]::IsNullOrWhiteSpace($Root)) { $Root = $env:GITHUB_WORKSPACE }
+ }
+ $Root = (Resolve-Path $Root).Path  # ← 배열 방지(항상 단일 문자열)
 
- $logDir = Join-Path $Root 'automation_logs'
+ $logDir = Join-Path -Path $Root -ChildPath 'automation_logs'
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
