<#
.SYNOPSIS
    Fix SharePoint module dependency conflicts and test connection.

.DESCRIPTION
    This script must be run in a FRESH PowerShell session (no other modules loaded).
    It will ensure SharePoint module is properly installed and test the connection.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$TenantName = "mobieuslabs"  # Change if needed
)

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SharePoint Module Dependency Fix & Connection Test      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Check if other M365 modules are already loaded
$loadedModules = Get-Module Microsoft.Graph*, ExchangeOnlineManagement, Microsoft.Online.SharePoint*
if ($loadedModules) {
    Write-Warning "Other M365 modules are already loaded in this session:"
    $loadedModules | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Yellow }
    Write-Host "`nThis will cause dependency conflicts!" -ForegroundColor Red
    Write-Host "`nPlease:" -ForegroundColor Yellow
    Write-Host "  1. Close this PowerShell window" -ForegroundColor White
    Write-Host "  2. Open a NEW PowerShell window" -ForegroundColor White
    Write-Host "  3. Run: .\Fix-SharePointModule.ps1`n" -ForegroundColor White
    exit 1
}

Write-Host "✓ Clean session detected (no conflicting modules loaded)`n" -ForegroundColor Green

# Step 1: Check current installation
Write-Host "[1/5] Checking SharePoint module installation..." -ForegroundColor Cyan
$currentModule = Get-Module Microsoft.Online.SharePoint.PowerShell -ListAvailable | Select-Object -First 1
if ($currentModule) {
    Write-Host "  Current version: $($currentModule.Version)" -ForegroundColor White
    Write-Host "  Location: $($currentModule.ModuleBase)" -ForegroundColor DarkGray
} else {
    Write-Host "  No version installed" -ForegroundColor Yellow
}

# Step 2: Check available version
Write-Host "`n[2/5] Checking PowerShell Gallery for latest version..." -ForegroundColor Cyan
try {
    $latestModule = Find-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    Write-Host "  Latest version: $($latestModule.Version) (Published: $($latestModule.PublishedDate.ToString('yyyy-MM-dd')))" -ForegroundColor White
    
    if ($currentModule -and $currentModule.Version -eq $latestModule.Version) {
        Write-Host "  ✓ You have the latest version" -ForegroundColor Green
    } else {
        Write-Host "  → Update available" -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Could not check PowerShell Gallery: $_"
}
}
# Step 3: Reinstall module (even if latest version, to fix any corruption)
Write-Host "`n[3/5] Reinstalling SharePoint module..." -ForegroundColor Cyan
try {
    # Uninstall all versions first
    $allVersions = Get-InstalledModule Microsoft.Online.SharePoint.PowerShell -AllVersions -ErrorAction SilentlyContinue
    if ($allVersions) {
        Write-Host "  Removing existing versions..." -ForegroundColor Yellow
        foreach ($ver in $allVersions) {
            Uninstall-Module Microsoft.Online.SharePoint.PowerShell -RequiredVersion $ver.Version -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Install fresh copy
    Write-Host "  Installing fresh copy from PowerShell Gallery..." -ForegroundColor Yellow
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    Write-Host "  ✓ Installation complete" -ForegroundColor Green
}
catch {
    Write-Error "Failed to reinstall module: $_"
    exit 1
}

# Step 4: Import and verify
Write-Host "`n[4/5] Testing module import..." -ForegroundColor Cyan
try {
    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    Write-Host "  ✓ Module imported successfully" -ForegroundColor Green
    
    # Check loaded assemblies
    $identityClient = [System.AppDomain]::CurrentDomain.GetAssemblies() | 
        Where-Object { $_.FullName -like "*Microsoft.Identity.Client,*" } | 
        Select-Object -First 1
    
    if ($identityClient) {
        Write-Host "  ✓ Microsoft.Identity.Client version: $($identityClient.GetName().Version)" -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to import module: $_"
    exit 1
}

# Step 5: Test connection
Write-Host "`n[5/5] Testing SharePoint Online connection..." -ForegroundColor Cyan
$adminUrl = "https://$TenantName-admin.sharepoint.com"
Write-Host "  Connecting to: $adminUrl" -ForegroundColor White
Write-Host "  (You may be prompted to authenticate...)" -ForegroundColor DarkGray

try {
    Connect-SPOService -Url $adminUrl -ErrorAction Stop
    Write-Host "  ✓ Successfully connected to SharePoint Online!" -ForegroundColor Green
    
    # Get tenant info as proof
    $tenant = Get-SPOTenant -ErrorAction Stop
    Write-Host "`n  Tenant Information:" -ForegroundColor Cyan
    Write-Host "    Sharing Capability: $($tenant.SharingCapability)" -ForegroundColor White
    Write-Host "    OneDrive Storage Quota: $([math]::Round($tenant.OneDriveStorageQuota/1024,2)) GB" -ForegroundColor White
    
    Disconnect-SPOService -ErrorAction SilentlyContinue
    Write-Host "`n  ✓ Disconnected from SharePoint" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to SharePoint: $_"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Verify tenant name is correct: $TenantName" -ForegroundColor White
    Write-Host "  - Ensure you have SharePoint Administrator role" -ForegroundColor White
    Write-Host "  - Check if tenant URL is: $adminUrl" -ForegroundColor White
    exit 1
}

# Success summary
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              ✓ SharePoint Module Fixed!                  ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Restart VS Code completely (close all windows)" -ForegroundColor White
Write-Host "  2. Open VS Code fresh" -ForegroundColor White
Write-Host "  3. Run: .\Start-M365Assessment.ps1" -ForegroundColor White
Write-Host "`nThe SharePoint module should now work without conflicts!`n" -ForegroundColor Green
