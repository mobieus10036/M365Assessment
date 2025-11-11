<#
.SYNOPSIS
    Updates the SharePoint Online Management Shell module to resolve dependency conflicts.

.DESCRIPTION
    This script safely updates the Microsoft.Online.SharePoint.PowerShell module
    to the latest version to resolve Microsoft.Identity.Client version conflicts.
    Must be run in a fresh PowerShell session (close VS Code first).

.NOTES
    Run this from a regular PowerShell window (not VS Code integrated terminal)
    with all other PowerShell windows closed.
#>

Write-Host "`n=== SharePoint Module Update Utility ===" -ForegroundColor Cyan
Write-Host "This will update Microsoft.Online.SharePoint.PowerShell to resolve dependency conflicts.`n" -ForegroundColor White

# Check if module is loaded
$loadedModule = Get-Module Microsoft.Online.SharePoint.PowerShell
if ($loadedModule) {
    Write-Warning "SharePoint module is currently loaded. Please:"
    Write-Host "  1. Close ALL PowerShell windows (including VS Code)" -ForegroundColor Yellow
    Write-Host "  2. Open a NEW PowerShell window" -ForegroundColor Yellow
    Write-Host "  3. Run this script again" -ForegroundColor Yellow
    exit 1
}

# Check current version
Write-Host "[1/4] Checking current installation..." -ForegroundColor Cyan
$currentModule = Get-InstalledModule Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue
if ($currentModule) {
    Write-Host "  Current version: $($currentModule.Version)" -ForegroundColor White
} else {
    Write-Host "  No version currently installed" -ForegroundColor White
}

# Uninstall old versions
Write-Host "`n[2/4] Removing old versions..." -ForegroundColor Cyan
$allVersions = Get-InstalledModule Microsoft.Online.SharePoint.PowerShell -AllVersions -ErrorAction SilentlyContinue
if ($allVersions) {
    foreach ($version in $allVersions) {
        try {
            Write-Host "  Removing version $($version.Version)..." -ForegroundColor Yellow
            Uninstall-Module -Name Microsoft.Online.SharePoint.PowerShell -RequiredVersion $version.Version -Force -ErrorAction Stop
            Write-Host "    ✓ Removed" -ForegroundColor Green
        }
        catch {
            Write-Warning "    Could not remove version $($version.Version): $_"
        }
    }
}

# Install latest version
Write-Host "`n[3/4] Installing latest version..." -ForegroundColor Cyan
try {
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    Write-Host "  ✓ Latest version installed" -ForegroundColor Green
}
catch {
    Write-Error "Failed to install: $_"
    exit 1
}

# Verify installation
Write-Host "`n[4/4] Verifying installation..." -ForegroundColor Cyan
$newModule = Get-InstalledModule Microsoft.Online.SharePoint.PowerShell
Write-Host "  ✓ Installed version: $($newModule.Version)" -ForegroundColor Green

# Test import
try {
    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    Write-Host "  ✓ Module imports successfully" -ForegroundColor Green
    Remove-Module Microsoft.Online.SharePoint.PowerShell
}
catch {
    Write-Warning "Module installed but failed to import: $_"
}

Write-Host "`n✅ Update complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Restart VS Code completely" -ForegroundColor White
Write-Host "  2. Run your assessment: .\Start-M365Assessment.ps1" -ForegroundColor White
Write-Host ""
