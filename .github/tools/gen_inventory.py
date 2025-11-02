# -*- coding: utf-8 -*-
"""
gen_inventory.py
용도:
  - 저장소의 .github/workflows/*.yml(yaml)을 스캔해 메타데이터를 수집,
    _inventory/workflows/inventory.json, inventory.csv 로 저장합니다.
특징:
  - YAML 파싱 실패 시 "__parse_error__" 필드에 원인 기록(전체 실패 방지)
  - 트리거/권한/컨커런시/잡 요약을 추출 → 모니터링 UI가 바로 소비 가능한 스키마
실행:
  - CI: inventory-ci.yml에서 `python3 .github/tools/gen_inventory.py`
  - 로컬: 저장소 루트에서 같은 명령 실행 가능(파이썬3 + pyyaml 필요)
"""

import os, sys, json, yaml, glob, csv, datetime

def safe_load(path: str):
    """YAML 파싱(안전). 실패해도 dict 반환하여 파이프라인 전체는 계속 진행."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        return {"__parse_error__": f"{type(e).__name__}: {e}"}

def to_list(x):
    """트리거 표현 통일(단일/리스트/딕셔너리 → 리스트)"""
    if x is None: return []
    if isinstance(x, list): return x
    return [x]

def main():
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    root = ".github/workflows"

    # 대상 워크플로 파일 찾기
    files = sorted(
        glob.glob(os.path.join(root, "**", "*.yml"), recursive=True)
        + glob.glob(os.path.join(root, "**", "*.yaml"), recursive=True)
    )

    items = []
    for path in files:
        data = safe_load(path)
        wf_name = data.get("name")
        on = data.get("on", {})
        triggers = list(on.keys()) if isinstance(on, dict) else to_list(on)

        perms = data.get("permissions", {}) or {}
        conc  = data.get("concurrency", {}) or {}
        jobs  = data.get("jobs", {}) or {}

        # 잡 요약(주요 파라미터만 추림)
        job_summ = []
        if isinstance(jobs, dict):
            for jname, job in jobs.items():
                if not isinstance(job, dict):
                    continue
                job_summ.append({
                    "job": jname,
                    "runs_on": job.get("runs-on"),
                    "timeout": job.get("timeout-minutes"),
                    "uses": job.get("uses")
                })

        items.append({
            "path": path.replace("\\", "/"),
            "workflow": wf_name,
            "triggers": triggers,
            "permissions": perms,
            "concurrency": conc,
            "jobs": job_summ,
            "__parse_error__": data.get("__parse_error__")  # 실패 시 메시지 보존
        })

    # 출력 폴더/파일 경로
    dest = os.path.join("_inventory", "workflows")
    os.makedirs(dest, exist_ok=True)
    json_path = os.path.join(dest, "inventory.json")
    csv_path  = os.path.join(dest, "inventory.csv")

    # JSON 문서(스키마 고정)
    doc = {
        "schema": "kobong.inventory.workflows",
        "schema_version": "1.0.0",
        "generated_at": datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        "generated_by": "inventory-ci",
        "repo": repo,
        "count": len(items),
        "workflows": items
    }

    # JSON 저장(가독성 ↑)
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)

    # CSV 저장(간단 필드 선별)
    rows = []
    for w in doc["workflows"]:
        rows.append({
            "path": w.get("path",""),
            "workflow": w.get("workflow",""),
            "triggers": ",".join(w.get("triggers") or []),
            "permissions.keys": ",".join(sorted((w.get("permissions") or {}).keys())),
            "concurrency.group": str((w.get("concurrency") or {}).get("group","")),
            "concurrency.cancel": str((w.get("concurrency") or {}).get("cancel-in-progress","")),
            "jobs.count": str(len(w.get("jobs") or [])),
            "parse_error": str(w.get("__parse_error__") or "")
        })
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        hdr = ["path","workflow","triggers","permissions.keys","concurrency.group",
               "concurrency.cancel","jobs.count","parse_error"]
        writer = csv.DictWriter(f, fieldnames=hdr)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {json_path} and {csv_path}")

if __name__ == "__main__":
    sys.exit(main())
