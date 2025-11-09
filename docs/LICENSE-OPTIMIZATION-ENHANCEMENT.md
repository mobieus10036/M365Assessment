# License Optimization Enhancement - Summary

## Overview
Enhanced the `Test-LicenseOptimization` module to identify and report specific inactive licensed users, following the same pattern as the mailbox auditing enhancement.

## Changes Made

### 1. Test-LicenseOptimization.ps1
**Enhanced to capture detailed inactive user information:**

- **Added InactiveMailboxes array** containing:
  - `UserPrincipalName` - User's email address
  - `DisplayName` - User's display name  
  - `LastSignInDate` - Last sign-in (yyyy-MM-dd or "Never")
  - `DaysSinceLastSignIn` - Days since last activity (or "N/A")
  - `AccountEnabled` - Whether account is active/disabled
  - `LicenseCount` - Number of assigned licenses

- **Enhanced status messages** to include sample inactive users inline
- **Updated recommendations** to reference the detailed CSV export
- **Improved remediation steps** with specific guidance on reviewing inactive users

### 2. Start-M365Assessment.ps1
**Updated to export and display inactive mailboxes:**

#### Export-Results Function
- Added CSV export for inactive mailboxes: `*_InactiveMailboxes.csv`
- Displays count of exported inactive users in console output
- Generates separate file only when inactive users are detected

#### Export-HTMLReport Function
- Added inline display of up to 20 inactive licensed users
- Shows last sign-in date with color coding ("Never" in red)
- Displays days since last activity
- Indicates when more users exist beyond display limit
- Maintains existing non-compliant mailboxes display

## Report Output

### CSV Export: `M365Assessment_YYYYMMDD_HHMMSS_InactiveMailboxes.csv`
```csv
UserPrincipalName,DisplayName,LastSignInDate,DaysSinceLastSignIn,AccountEnabled,LicenseCount
john.doe@contoso.com,John Doe,2024-05-15,178,True,2
jane.smith@contoso.com,Jane Smith,Never,N/A,True,3
```

### HTML Report Display
Shows inline list with formatted details:
- ⚠️ Inactive Licensed Users (15):
  - `user@contoso.com` - Display Name | Last: 2024-05-15 (178 days ago)
  - `user2@contoso.com` - Display Name | Last: **Never** (N/A days ago)

### JSON Export
Complete structured data with all inactive user details in the `InactiveMailboxes` array.

## Status Thresholds

| Inactive % | Status  | Severity | Message |
|-----------|---------|----------|---------|
| ≤ 15%     | Pass    | Low      | Good license utilization |
| 16-25%    | Warning | Medium   | Review inactive users |
| > 25%     | Fail    | High     | Significant license waste |

Default threshold: **90 days** of inactivity (configurable in assessment-config.json)

## Usage

### Run Assessment
```powershell
.\Start-M365Assessment.ps1 -Modules Licensing
```

### Output Generated
1. **Main Report**: `M365Assessment_YYYYMMDD_HHMMSS.html`
2. **Summary CSV**: `M365Assessment_YYYYMMDD_HHMMSS.csv`
3. **Inactive Users**: `M365Assessment_YYYYMMDD_HHMMSS_InactiveMailboxes.csv` (if any found)
4. **Full Details**: `M365Assessment_YYYYMMDD_HHMMSS.json`

### Review Results
- Open HTML report for visual overview
- Check `*_InactiveMailboxes.csv` for complete list
- Share with HR/management for review before taking action

## Important Notes

### ⚠️ REPORTING ONLY - NO AUTOMATED REMOVAL
This enhancement **ONLY REPORTS** inactive users. It does **NOT**:
- ❌ Remove any licenses
- ❌ Disable any accounts
- ❌ Make any changes to user accounts
- ❌ Take any automated actions

All actions are manual and require explicit administrator intervention after reviewing the reports.

### Next Steps (Manual Process)
1. **Review the report** - Check inactive users list
2. **Validate with HR/managers** - Confirm users are truly inactive
3. **Manual license removal** - Use M365 Admin Center or PowerShell:
   ```powershell
   # Example: Manually remove licenses (requires admin action)
   Set-MgUserLicense -UserId "user@contoso.com" -RemoveLicenses @("SkuId")
   ```
4. **Document actions** - Keep audit trail of license changes
5. **Repeat monthly** - Regular monitoring for optimization

## Required Permissions

Microsoft Graph API scopes needed:
- `User.Read.All` - Read user information
- `AuditLog.Read.All` - Read sign-in activity
- `Directory.Read.All` - Read directory data

## Configuration

Edit `config/assessment-config.json` to customize:
```json
{
  "Licensing": {
    "InactiveDaysThreshold": 90,
    "MinimumLicenseUtilization": 85
  }
}
```

## Benefits

✅ **Visibility** - Clear identification of inactive licensed users
✅ **Cost Optimization** - Identify potential license savings
✅ **Data Export** - Easy-to-share CSV for stakeholder review  
✅ **Actionable** - Direct list of users requiring review
✅ **Safe** - Read-only reporting, no automated changes
✅ **Auditable** - Complete tracking of inactive users
✅ **Configurable** - Adjustable inactivity threshold

## Files Modified

1. `modules/Licensing/Test-LicenseOptimization.ps1` - Enhanced assessment logic
2. `Start-M365Assessment.ps1` - Updated report generation and HTML display

---

**Status:** ✅ Complete - Reporting Only (No Automation)
**Version:** 3.1
**Date:** November 9, 2025
