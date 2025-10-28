@{
  # 일단 제외할 룰(점진 정리 목표)
  ExcludeRules = @(
    # 'PSAvoidUsingWrite-Host',      # 필요시 해제
  )

  Rules = @{
    # 강하게 막을 것들
    PSAvoidUsingInvokeExpression       = @{ Severity = 'Error' }
    PSAvoidUsingPlainTextForPassword   = @{ Severity = 'Error' }
    PSUseSupportsShouldProcess         = @{ Severity = 'Error' }

    # 과도한 경고는 경고 수준으로
    PSUseApprovedVerbs                 = @{ Severity = 'Warning' }
    PSUseBOMForUnicodeEncodedFile      = @{ Severity = 'Warning' }
  }
}
