# Reporting DSL v0.1 (초안)

규칙(줄 단위, 대소문자 무시):
- `REPORT <source>`
- `FIELDS <name>[, <name> ...]`
- `FORMAT csv|json`
- (선택) `LIMIT <n>`
- (선택) `SORT <field> (asc|desc)`  // 1개만 허용(초안)

예)
REPORT demo
FIELDS id, name, amount
FORMAT csv
LIMIT 100
