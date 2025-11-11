<#
.SYNOPSIS
    Diagnoses SharePoint Online connection issues for M365 Assessment Toolkit.

.DESCRIPTION
    Tests various SharePoint connection scenarios to identify the root cause
    of connection failures. Provides actionable remediation steps.
#>

[CmdletBinding()]
param()

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SharePoint Online Connection Diagnostics              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

#region Step 1: Verify Microsoft Graph Connection & Get Tenant Info

Write-Host "[1/6] Verifying Microsoft Graph connection..." -ForegroundColor Yellow

try {
    $context = Get-MgContext -ErrorAction Stop
    
    if (-not $context) {
        Write-Host "  ✗ Not connected to Microsoft Graph" -ForegroundColor Red
        Write-Host "  → Run: Connect-MgGraph -Scopes 'Organization.Read.All'" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "  ✓ Connected to Microsoft Graph" -ForegroundColor Green
    Write-Host "    Account: $($context.Account)" -ForegroundColor Gray
    
    # Get organization info
    $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
    $initialDomain = ($org.VerifiedDomains | Where-Object { $_.IsInitial -eq $true }).Name
    $tenantShortName = $initialDomain -replace "\.onmicrosoft\.com$", ""
    
    Write-Host "  ✓ Tenant Name: $($org.DisplayName)" -ForegroundColor Green
    Write-Host "    Initial Domain: $initialDomain" -ForegroundColor Gray
    Write-Host "    Tenant ID: $($org.Id)" -ForegroundColor Gray
    Write-Host "    Detected Short Name: $tenantShortName" -ForegroundColor Cyan
}
catch {
    Write-Host "  ✗ Failed to retrieve tenant info: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

#endregion

#region Step 2: Check SharePoint Module

Write-Host "`n[2/6] Checking SharePoint Online Management Shell..." -ForegroundColor Yellow

try {
    $spoModule = Get-Module -ListAvailable -Name "Microsoft.Online.SharePoint.PowerShell" | 
        Sort-Object Version -Descending | 
        Select-Object -First 1
    
    if ($spoModule) {
        Write-Host "  ✓ Module installed: v$($spoModule.Version)" -ForegroundColor Green
        
        # Check for multiple versions
        $allVersions = Get-Module -ListAvailable -Name "Microsoft.Online.SharePoint.PowerShell"
        if ($allVersions.Count -gt 1) {
            Write-Host "  ⚠ Multiple versions detected ($($allVersions.Count))" -ForegroundColor Yellow
            Write-Host "    This can cause conflicts. Consider keeping only latest." -ForegroundColor Gray
        }
        
        # Import module
        Import-Module "Microsoft.Online.SharePoint.PowerShell" -DisableNameChecking -ErrorAction Stop
        Write-Host "  ✓ Module imported successfully" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Module not installed" -ForegroundColor Red
        Write-Host "  → Install: Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser" -ForegroundColor Gray
        exit 1
    }
}
catch {
    Write-Host "  ✗ Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

#endregion

#region Step 3: Check Current User's Roles

Write-Host "`n[3/6] Checking your SharePoint Administrator permissions..." -ForegroundColor Yellow

try {
    $currentUser = Get-MgUser -UserId $context.Account -Property Id,UserPrincipalName,DisplayName -ErrorAction Stop
    
    # Get directory role memberships
    $roleAssignments = Get-MgUserMemberOf -UserId $currentUser.Id -ErrorAction Stop
    
    $adminRoles = @(
        'SharePoint Administrator',
        'SharePoint Service Administrator',
        'Global Administrator',
        'Company Administrator'
    )
    
    $hasSharePointAdmin = $false
    $userRoles = @()
    
    foreach ($assignment in $roleAssignments) {
        if ($assignment.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.directoryRole') {
            $roleName = $assignment.AdditionalProperties['displayName']
            $userRoles += $roleName
            
            if ($roleName -in $adminRoles) {
                $hasSharePointAdmin = $true
            }
        }
    }
    
    if ($hasSharePointAdmin) {
        Write-Host "  ✓ You have SharePoint Administrator permissions" -ForegroundColor Green
        Write-Host "    Your roles: $($userRoles -join ', ')" -ForegroundColor Gray
    }
    else {
        Write-Host "  ✗ Missing SharePoint Administrator role" -ForegroundColor Red
        Write-Host "    Your roles: $($userRoles -join ', ')" -ForegroundColor Gray
        Write-Host "    Required: SharePoint Administrator or Global Administrator" -ForegroundColor Yellow
        Write-Host "`n  → Ask a Global Administrator to grant you SharePoint Administrator role:" -ForegroundColor Gray
        Write-Host "    1. Go to: https://admin.microsoft.com/" -ForegroundColor Gray
        Write-Host "    2. Navigate to: Roles > Role assignments" -ForegroundColor Gray
        Write-Host "    3. Add your account to 'SharePoint Administrator' role" -ForegroundColor Gray
    }
}
catch {
    Write-Host "  ⚠ Could not verify roles: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "    Proceeding with connection test anyway..." -ForegroundColor Gray
}

#endregion

#region Step 4: Test SharePoint Admin URL

Write-Host "`n[4/6] Testing SharePoint admin URL formats..." -ForegroundColor Yellow

$adminUrls = @(
    "https://$tenantShortName-admin.sharepoint.com",
    "https://$($tenantShortName.ToLower())-admin.sharepoint.com"
)

# Add variations if tenant name has special characters
if ($tenantShortName -match '[^a-zA-Z0-9]') {
    $sanitizedName = $tenantShortName -replace '[^a-zA-Z0-9]', ''
    $adminUrls += "https://$sanitizedName-admin.sharepoint.com"
}

foreach ($url in $adminUrls | Select-Object -Unique) {
    Write-Host "  Testing: $url" -ForegroundColor Gray
    
    try {
        # Test with web request (doesn't require authentication)
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -ErrorAction Stop
        Write-Host "    ✓ URL is reachable (HTTP $($response.StatusCode))" -ForegroundColor Green
        $validUrl = $url
        break
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -in @(302, 401, 403)) {
            Write-Host "    ✓ URL exists (requires authentication)" -ForegroundColor Green
            $validUrl = $url
            break
        }
        else {
            Write-Host "    ✗ URL not accessible: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

if (-not $validUrl) {
    Write-Host "`n  ✗ Could not find valid SharePoint admin URL" -ForegroundColor Red
    Write-Host "  → Verify your tenant's SharePoint admin URL manually:" -ForegroundColor Yellow
    Write-Host "    1. Go to: https://admin.microsoft.com/" -ForegroundColor Gray
    Write-Host "    2. Navigate to: Admin centers > SharePoint" -ForegroundColor Gray
    Write-Host "    3. Note the URL in your browser address bar" -ForegroundColor Gray
    exit 1
}

Write-Host "`n  ✓ Detected SharePoint admin URL: $validUrl" -ForegroundColor Cyan

#endregion

#region Step 5: Test Connection to SharePoint

Write-Host "`n[5/6] Attempting connection to SharePoint Online..." -ForegroundColor Yellow
Write-Host "  URL: $validUrl" -ForegroundColor Gray
Write-Host "  (You may be prompted for authentication...)" -ForegroundColor Gray

try {
    # Disconnect any existing sessions first
    try {
        Disconnect-SPOService -ErrorAction SilentlyContinue | Out-Null
    } catch {}
    
    # Connect with explicit URL
    Connect-SPOService -Url $validUrl -ErrorAction Stop
    
    Write-Host "`n  ✓ Successfully connected to SharePoint Online!" -ForegroundColor Green
    
    # Get tenant info as proof
    $tenant = Get-SPOTenant -ErrorAction Stop
    Write-Host "    Tenant Display Name: $($tenant.DisplayName)" -ForegroundColor Gray
    Write-Host "    Sharing Capability: $($tenant.SharingCapability)" -ForegroundColor Gray
    
    Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   ✓ SharePoint Connection Successful!                   ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nℹ️  Update your toolkit to use this URL:" -ForegroundColor Cyan
    Write-Host "   $validUrl`n" -ForegroundColor White
}
catch {
    Write-Host "`n  ✗ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Detailed error analysis
    $errorDetails = $_.Exception
    
    if ($errorDetails.Message -match "400") {
        Write-Host "`n📋 Troubleshooting 400 Bad Request:" -ForegroundColor Yellow
        Write-Host "  1. The tenant name might be incorrect" -ForegroundColor Gray
        Write-Host "  2. Modern authentication may be disabled" -ForegroundColor Gray
        Write-Host "  3. Your account might be in a different tenant" -ForegroundColor Gray
        Write-Host "`n  → Try connecting with explicit credentials:" -ForegroundColor Cyan
        Write-Host "    `$cred = Get-Credential" -ForegroundColor Gray
        Write-Host "    Connect-SPOService -Url $validUrl -Credential `$cred" -ForegroundColor Gray
    }
    elseif ($errorDetails.Message -match "401|403") {
        Write-Host "`n📋 Troubleshooting Authentication/Authorization:" -ForegroundColor Yellow
        Write-Host "  → Your account lacks SharePoint Administrator permissions" -ForegroundColor Gray
        Write-Host "  → Contact your Global Administrator to grant access" -ForegroundColor Gray
    }
    elseif ($errorDetails.Message -match "assembly|DLL|Identity\.Client") {
        Write-Host "`n📋 Troubleshooting Module Dependency Issue:" -ForegroundColor Yellow
        Write-Host "  → Close all PowerShell windows" -ForegroundColor Gray
        Write-Host "  → Run: .\Fix-SharePointModule.ps1" -ForegroundColor Gray
    }
    else {
        Write-Host "`n📋 General Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  → Close all PowerShell sessions and try again" -ForegroundColor Gray
        Write-Host "  → Verify network connectivity to SharePoint Online" -ForegroundColor Gray
        Write-Host "  → Check if MFA/Conditional Access is blocking connection" -ForegroundColor Gray
    }
    
    Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║   ✗ SharePoint Connection Failed                        ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor Red
}
finally {
    # Cleanup
    try {
        Disconnect-SPOService -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}

#endregion

#region Step 6: Summary & Next Steps

Write-Host "`n[6/6] Diagnostic Summary" -ForegroundColor Yellow

$summary = @"

┌─────────────────────────────────────────────────────────┐
│ Detected Configuration:                                 │
├─────────────────────────────────────────────────────────┤
│ Tenant Name:        $($org.DisplayName.PadRight(33)) │
│ Initial Domain:     $($initialDomain.PadRight(33)) │
│ Short Name:         $($tenantShortName.PadRight(33)) │
│ SharePoint URL:     $(($validUrl -replace 'https://','').PadRight(33)) │
│ Module Version:     v$($spoModule.Version.ToString().PadRight(31)) │
└─────────────────────────────────────────────────────────┘

"@

Write-Host $summary -ForegroundColor White

Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. If connection succeeded, update your assessment config" -ForegroundColor White
Write-Host "  2. Run: .\Start-M365Assessment.ps1 -Modules SharePoint" -ForegroundColor White
Write-Host "  3. Check generated reports in: .\reports\`n" -ForegroundColor White

#endregion