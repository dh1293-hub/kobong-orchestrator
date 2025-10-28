@{
  ExcludeRules = @(
    # 필요시 임시 제외할 규칙들 나열
    # 'PSAvoidUsingWrite-Host'
  )
  Rules = @{
    PSAvoidUsingInvokeExpression       = @{ Severity = 'Error' }   # 강하게 유지
    PSAvoidUsingPlainTextForPassword   = @{ Severity = 'Error' }   # 강하게 유지
    PSUseSupportsShouldProcess         = @{ Severity = 'Error' }   # 강하게 유지
    PSUseApprovedVerbs                 = @{ Severity = 'Warning' } # 경고로 완화
    PSUseBOMForUnicodeEncodedFile      = @{ Severity = 'Warning' } # 경고로 완화
  }
}
