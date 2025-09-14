# Ops Experience Log

## 2025-09-14 14:24 +09:00 — Session log

- **EOL Guard(라인 엔딩) 실패** → *.cmd 포함 전체 **LF 강제 정책 + git add --renormalize**로 해결.
- **PR 자동생성 문자열 보간 이슈** ($cur?expand) → **서식 문자열(-f)**로 안전 조합.
- **PowerShell 삼항 공백 누락** (? :) → 공백 추가하여 구문 오류 제거.
- **Join-Path 뒤 쉼표** → **괄호**로 각 호출 감싸 1호출=1요소 보장.
- **PR 머지 후 rebase 충돌(main)** → **rebase --abort → backup/stash → reset --hard origin/main** 복구.

> 기준: PS7 전용, UTF-8/LF, 원자 교체, DRY-RUN→APPLY, JSONL 로그.