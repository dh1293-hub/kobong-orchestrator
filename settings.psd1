@{
  # 특정 규칙 제외(팀 합의로 단계적 정리)
  ExcludeRules = @(
    'PSAvoidUsingWrite-Host'          # 로컬 도구성 스크립트에서는 허용
  )

  # 규칙별 심각도/옵션 재정의
  Rules = @{
    PSAvoidUsingInvokeExpression       = @{ Severity = 'Error' }   # 동적 실행 금지
    PSAvoidUsingPlainTextForPassword   = @{ Severity = 'Error' }   # 평문 비밀번호 금지
    PSUseSupportsShouldProcess         = @{ Severity = 'Error' }   # 파괴적 명령엔 -WhatIf
    PSUseApprovedVerbs                 = @{ Severity = 'Warning' } # 경고로만
    PSUseBOMForUnicodeEncodedFile      = @{ Severity = 'Warning' } # 팀 선호에 맞게 조정
  }
}
