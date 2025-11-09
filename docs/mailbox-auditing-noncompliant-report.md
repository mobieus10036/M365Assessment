# Mailbox Auditing Non-Compliant Report Feature

## Overview

The M365 Assessment Toolkit now identifies specific mailboxes where auditing is disabled and includes them in detailed reports for easy remediation.

## What's Included

### Enhanced Assessment Module

**File**: `modules/Exchange/Test-MailboxAuditing.ps1`

The mailbox auditing check now:
- ✅ Captures detailed information about non-compliant mailboxes
- ✅ Includes UserPrincipalName, DisplayName, PrimarySmtpAddress, and WhenCreated
- ✅ Shows sample of non-compliant mailboxes in the main report message
- ✅ Provides actionable recommendations based on findings

### Report Output Formats

#### 1. **HTML Report** (Enhanced)
- Non-compliant mailboxes displayed inline with the check result
- Shows up to 20 mailboxes directly in the report
- Formatted list with UPN and Display Name
- Indicates if more mailboxes exist beyond the displayed limit

#### 2. **JSON Report** (Full Details)
- Complete array of all non-compliant mailboxes
- Full details: UPN, DisplayName, PrimarySmtpAddress, WhenCreated, AuditEnabled status
- Perfect for programmatic processing or automation

#### 3. **CSV Reports** (Separate File)
- Main assessment report: `M365Assessment_YYYYMMDD_HHMMSS.csv`
- **NEW**: Non-compliant mailboxes: `M365Assessment_YYYYMMDD_HHMMSS_NonCompliantMailboxes.csv`
- Easy to import into Excel or other tools
- Ready for bulk remediation scripts

## Report Structure

### Assessment Result Object

```powershell
[PSCustomObject]@{
    CheckName = "Mailbox Auditing"
    Category = "Exchange"
    Status = "Pass" | "Warning" | "Fail"
    Severity = "Low" | "Medium" | "High"
    Message = "Descriptive message with sample of non-compliant mailboxes"
    Details = @{
        OrgAuditDisabled = $false
        SampledMailboxes = 100
        AuditEnabledMailboxes = 95
        AuditDisabledMailboxes = 5
        AuditPercentage = 95.0
        NonCompliantCount = 5
    }
    NonCompliantMailboxes = @(
        @{
            UserPrincipalName = "user@contoso.com"
            DisplayName = "John Doe"
            PrimarySmtpAddress = "user@contoso.com"
            WhenCreated = "2024-01-15T10:30:00Z"
            AuditEnabled = $false
        },
        # ... more mailboxes
    )
    Recommendation = "Enable auditing for 5 mailbox(es)..."
    DocumentationUrl = "https://learn.microsoft.com/purview/audit-mailboxes"
    RemediationSteps = @(...)
}
```

## Status Thresholds

| Percentage Enabled | Status  | Severity | Action Required |
|-------------------|---------|----------|-----------------|
| ≥ 90%            | Pass    | Low      | Optional - Enable remaining mailboxes |
| 85-89%           | Warning | Medium   | Recommended - Enable missing mailboxes |
| < 85%            | Fail    | High     | Critical - Enable mailbox auditing immediately |
| Org-level disabled | Fail  | High     | Critical - Enable at organization level |

## Remediation Workflow

### Automated Remediation

Use the included `Enable-MailboxAuditing.ps1` script:

```powershell
# 1. Run assessment
.\Start-M365Assessment.ps1

# 2. Review the reports
# - Check HTML report for overview
# - Review NonCompliantMailboxes.csv for details

# 3. Preview remediation (dry run)
.\Enable-MailboxAuditing.ps1 -WhatIf

# 4. Apply remediation
.\Enable-MailboxAuditing.ps1

# 5. Verify results
Get-EXOMailbox -ResultSize Unlimited | 
    Where-Object { -not $_.AuditEnabled } | 
    Select-Object UserPrincipalName, DisplayName, AuditEnabled
```

### Manual Remediation

#### Option 1: Enable Organization-Wide Default
```powershell
# Enable auditing by default for all mailboxes
Set-OrganizationConfig -AuditDisabled $false

# This is the recommended approach for complete coverage
```

#### Option 2: Bulk Enable from CSV
```powershell
# Import the non-compliant mailboxes CSV
$mailboxes = Import-Csv ".\reports\M365Assessment_20241109_120000_NonCompliantMailboxes.csv"

# Enable auditing for each mailbox
$mailboxes | ForEach-Object {
    Set-Mailbox -Identity $_.UserPrincipalName -AuditEnabled $true
    Write-Host "✓ Enabled auditing for $($_.UserPrincipalName)" -ForegroundColor Green
}
```

#### Option 3: Single Mailbox
```powershell
# Enable auditing for a specific mailbox
Set-Mailbox -Identity "user@contoso.com" -AuditEnabled $true
```

## Verification

### Check Organization-Level Setting
```powershell
Get-OrganizationConfig | Select-Object AuditDisabled
# AuditDisabled should be: False
```

### Check Specific Mailbox
```powershell
Get-Mailbox -Identity "user@contoso.com" | 
    Select-Object UserPrincipalName, AuditEnabled
```

### Check All Mailboxes
```powershell
# Get count of mailboxes without auditing
$noAudit = Get-EXOMailbox -ResultSize Unlimited | 
    Where-Object { -not $_.AuditEnabled }

Write-Host "Mailboxes without auditing: $($noAudit.Count)" -ForegroundColor Yellow
```

### Verify Audit Logs are Being Generated
```powershell
# Check recent audit events (requires Exchange Online Management)
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -RecordType ExchangeItem -ResultSize 10
```

## Best Practices

### 1. **Enable Organization-Wide Default**
Always enable auditing at the organization level to ensure new mailboxes are automatically included:
```powershell
Set-OrganizationConfig -AuditDisabled $false
```

### 2. **Regular Monitoring**
- Run the M365 Assessment Toolkit monthly or quarterly
- Monitor for new mailboxes that may have auditing disabled
- Review audit logs regularly for suspicious activity

### 3. **Audit Log Retention**
Configure appropriate audit log retention based on compliance requirements:
```powershell
# E5 license supports up to 10 years retention
# Default is 90 days for most licenses
```

### 4. **Configure Mailbox Audit Actions**
Customize what actions are audited:
```powershell
Set-Mailbox -Identity "user@contoso.com" -AuditOwner @{Add="HardDelete","SoftDelete","Update"}
```

## Troubleshooting

### Issue: NonCompliantMailboxes.csv not generated

**Cause**: All mailboxes have auditing enabled (100% compliance)

**Resolution**: This is expected behavior when there are no non-compliant mailboxes.

---

### Issue: "Unable to retrieve mailbox information"

**Cause**: Exchange Online connection issue or insufficient permissions

**Resolution**:
1. Verify connection: `Get-ConnectionInformation`
2. Reconnect: `Connect-ExchangeOnline`
3. Verify permissions: Ensure account has "View-Only Organization Management" role or higher

---

### Issue: Set-Mailbox fails with "Operation not allowed"

**Cause**: Insufficient permissions to modify mailbox settings

**Resolution**:
- Requires "Organization Management" or "Recipient Management" role
- Some mailboxes (like shared/room mailboxes) may have different requirements

---

### Issue: Mailbox shows AuditEnabled = True but no logs

**Cause**: Audit logging may be enabled but not generating logs

**Resolution**:
1. Check organization config: `Get-OrganizationConfig | Select-Object AuditDisabled`
2. Verify mailbox audit bypass is not enabled: `Get-MailboxAuditBypassAssociation -Identity user@contoso.com`
3. Check unified audit log is enabled: `Get-AdminAuditLogConfig`

## Compliance Considerations

### Regulatory Requirements

Many regulations require mailbox auditing:
- **SOX**: Financial data access must be audited
- **HIPAA**: Healthcare information access requires audit trails
- **GDPR**: Personal data access must be logged
- **ISO 27001**: Information security requires access monitoring
- **PCI DSS**: Payment card data systems need audit logs

### Retention Requirements

Typical retention periods by regulation:
- **SOX**: 7 years
- **HIPAA**: 6 years
- **GDPR**: Varies by data type and purpose
- **General best practice**: At least 90 days, ideally 1+ year

## Additional Resources

- [Microsoft Purview: Enable mailbox auditing](https://learn.microsoft.com/purview/audit-mailboxes)
- [Mailbox auditing in Exchange Online](https://learn.microsoft.com/exchange/security-and-compliance/exchange-auditing-reports/exchange-auditing-reports)
- [Search the audit log](https://learn.microsoft.com/purview/audit-log-search)
- [Manage mailbox auditing](https://learn.microsoft.com/exchange/policy-and-compliance/mailbox-audit-logging/manage-mailbox-audit-logging)

## Support

For issues or questions:
- File an issue on the GitHub repository
- Check the main [README.md](../README.md) for general support information
- Review [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines
