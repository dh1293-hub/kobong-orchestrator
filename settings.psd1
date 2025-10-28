@{
  ExcludeRules = @(
    # 'PSAvoidUsingWrite-Host'
  )
  Rules = @{
    # 강차단
    PSAvoidUsingInvokeExpression       = @{ Severity = 'Error' }
    PSAvoidUsingPlainTextForPassword   = @{ Severity = 'Error' }
    PSUseSupportsShouldProcess         = @{ Severity = 'Error' }

    # 👇 추가 (게이트 친화)
    PSAvoidAssignmentToAutomaticVariable = @{ Severity = 'Warning' }

    # 완화
    PSUseApprovedVerbs                 = @{ Severity = 'Warning' }
    PSUseBOMForUnicodeEncodedFile      = @{ Severity = 'Warning' }
  }
}
