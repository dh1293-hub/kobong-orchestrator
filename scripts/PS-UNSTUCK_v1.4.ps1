$ErrorActionPreference='Stop'
Set-Location 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor'
try {
  '9' | Set-Content '.\logs\unstuck.exit' -Encoding ascii

  # ====== BUILD (TypeScript) ======
  & node .\node_modules\typescript\lib\tsc.js -p .\tsconfig.json 2>&1 |
    Tee-Object -FilePath '.\logs\unstuck_20250911-020625.log' -Append | Out-Null
  if ($LASTEXITCODE -ne 0) { '2' | Set-Content '.\logs\unstuck.exit'; exit 2 }

  # ====== BRIDGE (ESM↔CJS) ======
  $js  = Join-Path $PWD 'dist\app\bootstrap.js'
  $cjs = Join-Path $PWD 'dist\app\bootstrap.cjs'
  if (Test-Path $js) {
    if (-not (Test-Path $cjs)) { Copy-Item $js $cjs -Force }
    $content = Get-Content $js -Raw
    if ($content -notmatch 'createRequire\(') {
@'
/// ESM wrapper (UNSTUCK v1.4)
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
require('./bootstrap.cjs');
'@ | Set-Content -Path $js -Encoding UTF8
    }
  }

  # ====== TESTS (최소 세트: unit + contract) ======
  & node .\node_modules\vitest\vitest.mjs run tests/unit tests/contract --reporter=dot 2>&1 |
    Tee-Object -FilePath '.\logs\unstuck_20250911-020625.log' -Append | Out-Null
  if ($LASTEXITCODE -ne 0) { '3' | Set-Content '.\logs\unstuck.exit'; exit 3 }

  '0' | Set-Content '.\logs\unstuck.exit'
  exit 0
} catch {
  "$(.Exception.Message)" | Tee-Object -FilePath '.\logs\unstuck_20250911-020625.log' -Append | Out-Null
  '1' | Set-Content '.\logs\unstuck.exit'
  exit 1
}
