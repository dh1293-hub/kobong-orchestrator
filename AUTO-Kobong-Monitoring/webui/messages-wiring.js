;/* __G5_BRIDGE_CONFIG_v1__ (generated or manual; do not edit HTML) */
(function (w) {
  // 기본값(DEV): 5181/5182/5183 — Set-OrchApi.ps1로 값을 자동 갱신하는 것을 권장
  const defaults = {
    GHMON_BASE:   "http://localhost:5182", // GitHub-Monitoring
    AK7_BASE:     "http://localhost:5181", // AUTO-Kobong (원본 origin; '/api/ak7'는 HTML에서 붙임)
    ORCHMON_BASE: "http://localhost:5183"  // Orchestrator-Monitoring
  };
  // 외부에서 window.__G5_ENDPOINTS가 이미 설정되어 있으면 유지하고,
  // 비어있는 키만 기본값으로 채움
  w.__G5_ENDPOINTS = Object.assign({}, defaults, w.__G5_ENDPOINTS || {});
})(window);
