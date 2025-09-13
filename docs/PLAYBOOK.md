# Error Playbook (Sprint-B seed)

> ?⑥씪 吏꾩떎?먯쿇. ???먮윭 = ??ID = ?ы쁽 ?④퀎/?먯씤/議곗튂/媛?쒕젅???ы븿.

## ERR-TS-PORTS-001
- 吏뺥썑: TS2307 '.../domain/reporting/ports' 紐⑤뱢 ?놁쓬, TS7006 implicit any
- ?먯씤: ports.ts 誘몄젙???대쫫 遺덉씪移?
- 議곗튂: ports.ts ?묒꽦(ReportRequest/ReportResult/ReportEnginePort), ?붿쭊/?쒕퉬?????蹂닿컯, `npx tsc -p tsconfig.build.json`
- 媛?쒕젅?? Contract-first. 鍮뚮뱶 ??怨꾩빟 議댁옱 寃??

## ERR-TS-1343
- 吏뺥썑: "import.meta ??module=es2022|esnext|node16|nodenext ?먯꽌留??덉슜"
- 議곗튂: tsconfig.build.json exclude???대떦 ?뚯씪(?? app/hardening.ts) 異붽?

## ERR-TS-2307
- 吏뺥썑: ?곷?寃쎈줈 紐⑤뱢 紐살갼??
- 議곗튂: include??app/**, domain/**, infra/**, ui/** 紐낆떆, dist ?뺣━ ???щ퉴??

## ERR-NODE-MODULE-NOT-FOUND
- 吏뺥썑: dist/ui/reporting/cli.js ?놁쓬
- 議곗튂: `npx tsc -p tsconfig.build.json` ???뺥솗 寃쎈줈 ?ㅽ뻾

## ERR-INPUT-MISKEY
- 吏뺥썑: 肄섏넄??"name,amount" ??異쒕젰媛믪쓣 吏곸젒 ??댄븨???뚯꽌 ?ㅻ쪟
- 議곗튂: 異쒕젰媛믪? ?낅젰?섏? ?딆쓬(?곕턿??二쇱쓽 臾멸뎄)

