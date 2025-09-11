$ErrorActionPreference='Stop'
Set-Location 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor'
try {
  # 상태 초기값(9 = running)
  '9' | Set-Content 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless.exit' -Encoding ascii

  # TypeScript 컴파일(직행)
  & node .\node_modules\typescript\lib\tsc.js -p .\tsconfig.json 2>&1 | Tee-Object -FilePath 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless_20250911-020242.log' -Append | Out-Null
  if ($LASTEXITCODE -ne 0) { '2' | Set-Content 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless.exit'; exit 2 }

  # ESM↔CJS 브리지 (필요 시)
  $js  = Join-Path $PWD 'dist\app\bootstrap.js'
  $cjs = Join-Path $PWD 'dist\app\bootstrap.cjs'
  if (Test-Path $js) {
    if (-not (Test-Path $cjs)) { Copy-Item $js $cjs -Force }
    $content = Get-Content $js -Raw
    if ($content -notmatch 'createRequire\(') {
@'
/// ESM wrapper (HEADLESS v2.0)
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
require('./bootstrap.cjs');
'@ | Set-Content -Path $js -Encoding UTF8
    }
  }

  # 테스트 실행(직행)
  & node .\node_modules\vitest\vitest.mjs run tests/unit tests/contract tests/e2e --reporter=dot 2>&1 | Tee-Object -FilePath 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless_20250911-020242.log' -Append | Out-Null
  if ($LASTEXITCODE -ne 0) { '3' | Set-Content 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless.exit'; exit 3 }

  '0' | Set-Content 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless.exit'
  exit 0
} catch {
  "$(.Exception.Message)" | Tee-Object -FilePath 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless_20250911-020242.log' -Append | Out-Null
  '1' | Set-Content 'D:\ChatGPT5_AI_Link\dosc\gpt5-conductor\logs\headless.exit'
  exit 1
}
