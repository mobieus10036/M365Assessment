# SharePoint Module Integration - Quick Reference

## Overview
The SharePoint assessment module has been re-enabled and redesigned to align with the M365 Assessment Toolkit's architecture while incorporating best practices from the original M365-ODSP-Assessment.ps1 script.

## What Changed

### 1. Main Script Updates (`Start-M365Assessment.ps1`)
- **Re-enabled SharePoint** in ValidateSet parameter options
- **Updated Get-ModulesToRun()** to include SharePoint in 'All' modules
- **Added SharePoint connection** logic in Connect-M365Services()
- **Registered module** in Invoke-AssessmentModules()

### 2. New Assessment Module (`modules\SharePoint\Test-SharePointConfiguration.ps1`)
Comprehensive SharePoint and OneDrive assessment covering:

#### Tenant-Level Checks (10 checks)
1. **Tenant External Sharing** - Evaluates SharingCapability setting
2. **Default Sharing Link Type** - Checks if default is 'Internal'
3. **Anonymous Links** - Validates 'Anyone' links are disabled
4. **Guest Invitation Verification** - Ensures email matching is enabled
5. **Everyone Claim Visibility** - Checks if 'Everyone' is hidden
6. **Legacy Authentication** - Confirms legacy auth is disabled
7. **Malware Download Protection** - Validates infected file blocking
8. **OneDrive Default Quota** - Reports storage quota (informational)
9. **Conditional Access** - Checks unmanaged device policies
10. **OneDrive Retention Policy** - Validates deleted user retention period

#### Site-Level Checks (3 checks)
11. **Site Collection Inventory** - Total site count (informational)
12. **Sites with External Sharing** - Identifies sites with external sharing
13. **Locked/Read-Only Sites** - Reports restricted sites (informational)

#### OneDrive Checks (3 checks)
14. **OneDrive Site Count** - Total OneDrive sites (informational)
15. **Inactive OneDrive Sites** - Identifies stale OneDrive sites (90+ days)
16. **OneDrive External Sharing** - OneDrive sites with external sharing

**Total: 16 comprehensive checks**

### 3. Configuration Updates (`config\assessment-config.json`)
Enhanced SharePoint configuration with new thresholds:
```json
{
  "SharePoint": {
    "ExternalSharingLevel": "ExternalUserSharingOnly",
    "RequireAnonymousLinksExpire": true,
    "AnonymousLinkExpirationDays": 30,
    "InactiveDaysThreshold": 90,
    "LegacyAuthAllowed": false,
    "RequireAcceptingAccountMatch": true,
    "ShowEveryoneClaim": false,
    "DisallowInfectedFileDownload": true,
    "MinOrphanedOneDriveRetentionDays": 365
  }
}
```

## Usage Examples

### Run SharePoint Assessment Only
```powershell
.\Start-M365Assessment.ps1 -Modules SharePoint
```

### Run Full Assessment (Including SharePoint)
```powershell
.\Start-M365Assessment.ps1
# or explicitly
.\Start-M365Assessment.ps1 -Modules All
```

### Run Multiple Modules
```powershell
.\Start-M365Assessment.ps1 -Modules Security,Exchange,SharePoint
```

## Output Formats

Results are integrated into all existing report formats:
- **HTML Report** - Visual dashboard with status indicators
- **CSV Export** - Tabular data for Excel analysis
- **JSON Export** - Structured data for API integration

## Result Object Structure

Each check returns a standardized object:
```powershell
[PSCustomObject]@{
    CheckName        = "Check Name"
    Category         = "SharePoint"
    Status           = "Pass|Fail|Warning|Info"
    Severity         = "Critical|High|Medium|Low|Info"
    Message          = "Human-readable finding"
    Details          = @{} # Hashtable with metrics
    Recommendation   = "What to do about it"
    DocumentationUrl = "Microsoft Learn reference"
    RemediationSteps = @() # Step-by-step fix instructions
}
```

## Prerequisites

### Required Module
- **Microsoft.Online.SharePoint.PowerShell** (v16.0.0+)
  - Auto-installs if missing during assessment
  - Manual install: `Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser`

### Required Permissions
- **SharePoint Administrator** role in Microsoft 365
- Permissions to run `Connect-SPOService` and `Get-SPOTenant`

## Key Features

### ✅ Enhanced Error Handling
- Graceful failures with informative messages
- Module availability checks
- Connection validation before running checks

### ✅ Microsoft Best Practices Alignment
- Based on Microsoft Secure Score recommendations
- References to Microsoft Learn documentation
- Zero Trust security principles

### ✅ Comprehensive Coverage
- Tenant-wide policy assessment
- Site collection governance
- OneDrive lifecycle management
- External sharing risk analysis

### ✅ Actionable Remediation
- PowerShell commands to fix issues
- Step-by-step remediation guides
- Direct links to Microsoft documentation

## Comparison with Original Script

| Feature | Original M365-ODSP-Assessment.ps1 | New Test-SharePointConfiguration.ps1 |
|---------|-----------------------------------|--------------------------------------|
| **Output Format** | CSV files + Markdown report | Integrated HTML/CSV/JSON reports |
| **Error Handling** | Basic try-catch | Comprehensive with fallbacks |
| **Result Structure** | Custom per check | Standardized PSCustomObject |
| **Remediation Guidance** | Markdown findings | Structured steps + commands |
| **Integration** | Standalone script | Part of toolkit architecture |
| **Checks** | 10+ settings + inventory | 16 checks with severity levels |
| **Documentation** | Inline comments | Full Microsoft Learn links |

## Troubleshooting

### SharePoint Module Not Found
```powershell
Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force
```

### Connection Failed
```powershell
# Manually connect to verify credentials
Connect-SPOService -Url https://yourtenant-admin.sharepoint.com
```

### Permission Denied
- Verify you have **SharePoint Administrator** role
- Check in Azure AD: Roles and administrators → SharePoint Administrator

## Next Steps

### Optional Enhancements
1. **Add DLP Policy Checks** - Integrate with Microsoft Purview
2. **Sensitivity Label Validation** - Check label application
3. **Site Access Reviews** - Permission audit automation
4. **Power BI Dashboard** - Historical trend analysis
5. **Automated Remediation** - Azure Logic Apps integration

## References

- [SharePoint Online Security Best Practices](https://learn.microsoft.com/sharepoint/security-best-practices)
- [External Sharing Overview](https://learn.microsoft.com/sharepoint/external-sharing-overview)
- [OneDrive Retention and Deletion](https://learn.microsoft.com/onedrive/retention-and-deletion)
- [Control Access from Unmanaged Devices](https://learn.microsoft.com/sharepoint/control-access-from-unmanaged-devices)
- [Microsoft Secure Score](https://learn.microsoft.com/microsoft-365/security/mtp/microsoft-secure-score)

---

**Version:** 3.0.0  
**Created:** November 10, 2025  
**Project:** M365 Assessment Toolkit  
**Repository:** https://github.com/mobieus10036/M365Assessment
