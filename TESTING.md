# Local Testing Guide

## ✅ Pre-Flight Checks (COMPLETED)

- [x] PowerShell 7+ installed
- [x] All required modules installed
- [x] Script syntax is valid
- [x] Configuration file is valid JSON
- [x] All 14 assessment modules present

## 🧪 Testing Scenarios

### Scenario 1: Syntax Validation (No M365 Connection)
**Purpose**: Verify scripts load without errors

```powershell
# Test each module loads correctly
$modules = Get-ChildItem .\modules -Recurse -Filter *.ps1
foreach ($module in $modules) {
    Write-Host "Testing: $($module.Name)" -ForegroundColor Cyan
    . $module.FullName
    $functionName = $module.BaseName
    if (Get-Command $functionName -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ Function $functionName loaded" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Function $functionName NOT found" -ForegroundColor Red
    }
}
```

### Scenario 2: Dry Run (Mock Data)
**Purpose**: Test report generation without real M365 connection

```powershell
# Create mock assessment results
$mockResults = @(
    [PSCustomObject]@{
        CheckName = "Test Check 1"
        Category = "Security"
        Status = "Pass"
        Severity = "Low"
        Message = "This is a test finding"
        Details = @{ TestData = "Value" }
        Recommendation = "No action needed"
        DocumentationUrl = "https://example.com"
        RemediationSteps = @("Step 1", "Step 2")
    },
    [PSCustomObject]@{
        CheckName = "Test Check 2"
        Category = "Compliance"
        Status = "Fail"
        Severity = "High"
        Message = "This is a failing test"
        Details = @{ TestData = "Value" }
        Recommendation = "Fix this issue"
        DocumentationUrl = "https://example.com"
        RemediationSteps = @("Step 1", "Step 2")
    }
)

# Export to JSON
$mockResults | ConvertTo-Json -Depth 10 | Out-File .\reports\test-output.json

# Export to CSV
$mockResults | Select-Object CheckName, Category, Status, Severity, Message | 
    Export-Csv .\reports\test-output.csv -NoTypeInformation

Write-Host "✓ Mock reports generated in .\reports\" -ForegroundColor Green
```

### Scenario 3: Test Against Real M365 Tenant (RECOMMENDED)
**Purpose**: Full end-to-end test with actual M365 connection

**IMPORTANT**: Use a TEST/DEV tenant if available, NOT production initially!

#### Option A: Run Full Assessment
```powershell
# Run complete assessment
.\Start-M365Assessment.ps1 -Verbose

# This will:
# 1. Prompt for M365 authentication
# 2. Connect to Microsoft Graph, Exchange Online, Teams, SharePoint
# 3. Run all 14 assessment modules
# 4. Generate HTML, JSON, and CSV reports
```

#### Option B: Run Specific Modules Only (Safer for First Test)
```powershell
# Test just Security modules
.\Start-M365Assessment.ps1 -Modules Security -OutputFormat HTML -Verbose

# Test just one module
.\Start-M365Assessment.ps1 -Modules Licensing -Verbose
```

#### Option C: Run Without Re-Authentication (If Already Connected)
```powershell
# First, manually connect to services
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
Connect-ExchangeOnline

# Then run assessment without re-auth
.\Start-M365Assessment.ps1 -NoAuth -Verbose
```

## 📊 Expected Outputs

After running assessment, check `.\reports\` folder for:

1. **HTML Report** - `M365Assessment_YYYYMMDD_HHMMSS.html`
   - Open in browser
   - Verify dashboard shows statistics
   - Check color coding (Pass=Green, Fail=Red, Warning=Yellow)
   - Click documentation links (should open Microsoft Learn)

2. **JSON Report** - `M365Assessment_YYYYMMDD_HHMMSS.json`
   - Validate JSON is well-formed
   - Check all fields are populated
   - Useful for programmatic analysis

3. **CSV Report** - `M365Assessment_YYYYMMDD_HHMMSS.csv`
   - Open in Excel
   - Verify all checks are listed
   - Useful for tracking remediation

## 🐛 Troubleshooting Common Issues

### Issue 1: Module Import Errors
```powershell
# If you see "command not found" errors
Import-Module Microsoft.Graph.Authentication -Force
Import-Module ExchangeOnlineManagement -Force
```

### Issue 2: Authentication Failures
```powershell
# Clear cached credentials and re-authenticate
Disconnect-MgGraph
Disconnect-ExchangeOnline -Confirm:$false
.\Start-M365Assessment.ps1
```

### Issue 3: Permission Errors
**Symptoms**: "Insufficient privileges" or "Access denied"

**Solution**: Ensure your account has one of these roles:
- Global Reader (minimum recommended)
- Security Reader
- Compliance Administrator
- Global Administrator

### Issue 4: Script Execution Policy
```powershell
# If scripts won't run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## ✅ Validation Checklist

After running assessment, verify:

- [ ] Script completed without fatal errors
- [ ] HTML report opens in browser
- [ ] Report shows tenant name and date
- [ ] Dashboard statistics are populated
- [ ] All enabled modules show results
- [ ] Pass/Fail/Warning counts are reasonable
- [ ] Documentation links work
- [ ] JSON file is valid (can be parsed)
- [ ] CSV opens in Excel correctly

## 🎯 Test Scenarios by Experience Level

### Beginner Test (5 minutes)
```powershell
# Just verify syntax and help
Get-Help .\Start-M365Assessment.ps1 -Examples
.\Install-Prerequisites.ps1
```

### Intermediate Test (15 minutes)
```powershell
# Test one module against real tenant
.\Start-M365Assessment.ps1 -Modules Security -OutputFormat HTML
# Review the HTML report
```

### Advanced Test (30 minutes)
```powershell
# Full assessment with custom config
.\Start-M365Assessment.ps1 -ConfigPath .\config\assessment-config.json -Verbose
# Review all report formats
# Compare results against Microsoft Secure Score
```

## 📝 Test Results Template

After testing, document your findings:

**Date**: _______________  
**Tester**: _______________  
**Tenant Type**: [ ] Test/Dev [ ] Production  

**Test Results**:
- Prerequisites Installation: [ ] Pass [ ] Fail  
- Script Syntax Validation: [ ] Pass [ ] Fail  
- M365 Authentication: [ ] Pass [ ] Fail  
- Assessment Execution: [ ] Pass [ ] Fail  
- HTML Report Generation: [ ] Pass [ ] Fail  
- JSON Report Generation: [ ] Pass [ ] Fail  
- CSV Report Generation: [ ] Pass [ ] Fail  

**Issues Found**: _______________________________________

**Recommendations**: _______________________________________

## 🚀 Next Steps After Testing

1. **Review findings** in the HTML report
2. **Prioritize remediation** based on Severity (Critical > High > Medium > Low)
3. **Use remediation guides** in `docs/remediation-guides/`
4. **Re-run assessment** after implementing fixes
5. **Schedule regular assessments** (monthly recommended)

---

**Pro Tip**: For production use, create a scheduled task to run assessments monthly and email reports to security team!
