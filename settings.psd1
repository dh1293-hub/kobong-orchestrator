@{
  ExcludeRules = @(
    # 'PSAvoidUsingWrite-Host',  # 필요시
  )
  Rules = @{
    # 강차단
    PSAvoidUsingInvokeExpression       = @{ Severity = 'Error' }
    PSAvoidUsingPlainTextForPassword   = @{ Severity = 'Error' }
    PSUseSupportsShouldProcess         = @{ Severity = 'Error' }

    # 완화
    PSUseApprovedVerbs                 = @{ Severity = 'Warning' }
    PSUseBOMForUnicodeEncodedFile      = @{ Severity = 'Warning' }
  }
}

