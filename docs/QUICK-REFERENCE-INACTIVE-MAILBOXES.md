# Inactive Mailboxes Quick Reference

## What Gets Reported

### Inactive User Criteria
- Licensed users who haven't signed in for **90+ days** (default threshold)
- Users who have **never signed in** since account creation
- Both enabled and disabled accounts with assigned licenses

### Data Captured Per User
| Field | Description | Example |
|-------|-------------|---------|
| UserPrincipalName | Email address | john.doe@contoso.com |
| DisplayName | Full name | John Doe |
| LastSignInDate | Last successful sign-in | 2024-05-15 or "Never" |
| DaysSinceLastSignIn | Days inactive | 178 or "N/A" |
| AccountEnabled | Account status | True/False |
| LicenseCount | Number of licenses | 2 |

## Report Outputs

### 1. HTML Report
**Location:** `reports/M365Assessment_YYYYMMDD_HHMMSS.html`

Shows up to 20 inactive users inline:
```
⚠️ Inactive Licensed Users (25):
• john.doe@contoso.com - John Doe | Last: 2024-05-15 (178 days ago)
• jane.smith@contoso.com - Jane Smith | Last: Never (N/A days ago)
...and 5 more users (see CSV export)
```

### 2. CSV Export
**Location:** `reports/M365Assessment_YYYYMMDD_HHMMSS_InactiveMailboxes.csv`

Spreadsheet-ready format for:
- Excel analysis
- Stakeholder review
- HR coordination
- Audit documentation

### 3. JSON Export
**Location:** `reports/M365Assessment_YYYYMMDD_HHMMSS.json`

Complete structured data in `InactiveMailboxes` array for:
- Automation/scripting
- Integration with other tools
- Detailed analysis

## Status Indicators

| Inactive Users | Status | Color | Action |
|---------------|--------|-------|--------|
| 0-15% | ✅ Pass | Green | Continue monitoring |
| 16-25% | ⚠️ Warning | Yellow | Review and optimize |
| 26%+ | ❌ Fail | Red | Immediate review needed |

## Common Scenarios

### Scenario 1: User on Leave
**Finding:** User inactive for 120 days
**Action:** Verify with HR, may keep license if returning soon

### Scenario 2: Never Signed In
**Finding:** Account created 6 months ago, never used
**Action:** Likely provisioning error or cancelled hire

### Scenario 3: Terminated Employee
**Finding:** Last sign-in 150 days ago
**Action:** Remove license, follow offboarding process

### Scenario 4: Service Account
**Finding:** Never signed in (expected)
**Action:** May need different license type or exclusion

## Workflow

```
┌─────────────────────────────────────────────────────┐
│ 1. Run Assessment                                   │
│    .\Start-M365Assessment.ps1 -Modules Licensing    │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ 2. Review Reports                                   │
│    • Open HTML for overview                         │
│    • Check CSV for complete list                    │
│    • Filter by DaysSinceLastSignIn                  │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ 3. Validate with Stakeholders                       │
│    • HR: Check employment status                    │
│    • Managers: Confirm user activity                │
│    • IT: Verify service accounts                    │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ 4. Manual Remediation                               │
│    • Remove licenses via M365 Admin Center          │
│    • Document changes for audit                     │
│    • Update asset management systems                │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ 5. Verify Results                                   │
│    .\Start-M365Assessment.ps1 -Modules Licensing    │
│    Confirm reduced inactive user count              │
└─────────────────────────────────────────────────────┘
```

## PowerShell Examples

### View Inactive Users in CSV
```powershell
# Import and filter
$inactive = Import-Csv "reports\*_InactiveMailboxes.csv"

# Never signed in
$neverSignedIn = $inactive | Where-Object { $_.LastSignInDate -eq 'Never' }

# Inactive over 180 days
$veryInactive = $inactive | Where-Object { 
    $_.DaysSinceLastSignIn -ne 'N/A' -and 
    [int]$_.DaysSinceLastSignIn -gt 180 
}

# Disabled accounts
$disabledWithLicenses = $inactive | Where-Object { $_.AccountEnabled -eq 'False' }
```

### Export Filtered Results
```powershell
# Create priority list for management review
$inactive | 
    Where-Object { [int]$_.LicenseCount -gt 2 -and [int]$_.DaysSinceLastSignIn -gt 180 } |
    Sort-Object DaysSinceLastSignIn -Descending |
    Export-Csv "priority-review.csv" -NoTypeInformation
```

### Calculate Potential Savings
```powershell
# Assuming $36/month average per license
$inactive = Import-Csv "reports\*_InactiveMailboxes.csv"
$totalLicenses = ($inactive | Measure-Object -Property LicenseCount -Sum).Sum
$monthlySavings = $totalLicenses * 36
$annualSavings = $monthlySavings * 12

Write-Host "Potential Savings:"
Write-Host "  Inactive licenses: $totalLicenses"
Write-Host "  Monthly: `$$monthlySavings"
Write-Host "  Annual: `$$annualSavings"
```

## Customization

### Change Inactivity Threshold
Edit `config/assessment-config.json`:
```json
{
  "Licensing": {
    "InactiveDaysThreshold": 120
  }
}
```

### Schedule Regular Assessments
```powershell
# Create scheduled task (run monthly)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\M365Assessment\Start-M365Assessment.ps1 -Modules Licensing"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 6AM
Register-ScheduledTask -TaskName "M365 License Assessment" `
    -Action $action -Trigger $trigger -Description "Monthly license optimization check"
```

## Troubleshooting

### Issue: No sign-in data available
**Cause:** SignInActivity requires Azure AD Premium P1/P2
**Solution:** Verify tenant has appropriate licensing

### Issue: All users show "Never"
**Cause:** Audit log retention or permissions issue
**Solution:** Check `AuditLog.Read.All` permission granted

### Issue: Service accounts flagged
**Cause:** Service accounts don't perform interactive sign-ins
**Solution:** Expected behavior, review and document exclusions

## Best Practices

✅ **Do:**
- Run monthly assessments
- Coordinate with HR before license removal
- Document all license changes
- Maintain exclusion list for service accounts
- Review both "Never" and long-inactive users
- Calculate and track cost savings

❌ **Don't:**
- Remove licenses without verification
- Automate license removal without approval workflow
- Ignore accounts that "Never" signed in (could be provisioning errors)
- Remove licenses during busy periods (holidays, fiscal year-end)

## Related Documentation

- [Mailbox Auditing Enhancement](./mailbox-auditing-noncompliant-report.md)
- [Main Assessment Toolkit README](../README.md)
- [Microsoft Licensing Documentation](https://learn.microsoft.com/microsoft-365/commerce/licenses/subscriptions-and-licenses)

---

**Quick Commands**

```powershell
# Run assessment
.\Start-M365Assessment.ps1 -Modules Licensing

# View latest report
Invoke-Item (Get-ChildItem reports\*_InactiveMailboxes.csv | Sort LastWriteTime -Desc | Select -First 1)

# Count inactive users
(Import-Csv (Get-ChildItem reports\*_InactiveMailboxes.csv | Sort LastWriteTime -Desc | Select -First 1 -ExpandProperty FullName)).Count
```
