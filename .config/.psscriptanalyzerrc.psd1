@{
  # 프로젝트 특성상 과민 룰은 제외하고, 핵심 룰만 Error 단계로 별도 실행에서 체크
  # 이 파일은 참고용이며, 실제 Error/Warning 구분은 워크플로에서 두 번 실행으로 분리
  ExcludeRules = @(
    'PSAvoidUsingWriteHost'          # 로그/진행상태에 사용 가능
  )
}