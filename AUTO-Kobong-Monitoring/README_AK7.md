# AK7 WebUI Refactor Pack

This pack converts the existing `AUTO-Kobong-Monitoring/webui` to **AK7-only** naming and endpoints.

## Highlights
- Unified **AK7** variable names (`window.AK7_API_BASE`, `AK7_FORCE_OFFLINE`).
- Default endpoints switched to **/api/ak7** (DEV=5181, MOCK=5191).
- Boot sequence loads **ak7-net-override** first, so any legacy `/api/orchmon` calls are automatically rewritten.
- New **ak7-bus-auto.js** replaces `orch-bus-auto.js`.
- `overview-cards.js` and `settings-pane.js` updated to AK7.
- New `AK7-Monitoring.html` as the main page.

## Important Files
- `webui/AK7-Monitoring.html` — open this in your browser.
- `webui/public/booster/ak7-config.js` — central AK7 base injection and echo.
- `webui/public/booster/ak7-net-override.js` — fetch/SSE/WebSocket rewrite guard.
- `webui/public/booster/ak7-bus-auto.js` — AK7 event bus (SSE) auto connector.
- `Deploy-AK7-WebUI.ps1` — one-click safe deploy (makes a backup).

## How to Use
1. Back up current `webui` (the deploy script does it automatically).
2. Copy `webui` folder from this pack over your existing `webui`.
3. Open `AK7-Monitoring.html`.
4. In **Settings** tab, set `API Base` to your target:
   - DEV: `http://localhost:5181/api/ak7`
   - MOCK: `http://localhost:5191/api/ak7`
5. Confirm **Overview** LEDs turn green and **Messages** start streaming (SSE).

## 404 Guard
- All buttons/features check `GET /health` first and will disable gracefully if the server is down.
- `ak7-net-override.js` also normalizes relative/absolute URLs to prevent `404` due to wrong host/port.

## Rollback
- Use the backup folder the deploy script created (e.g. `webui_backup_YYYYMMDD_HHMMSS`) to restore.
