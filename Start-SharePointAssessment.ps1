<#
.SYNOPSIS
    Runs SharePoint-only assessment in a clean session.

.DESCRIPTION
    This script runs ONLY the SharePoint assessment module in an isolated session
    to avoid authentication conflicts with other M365 modules.

.EXAMPLE
    .\Start-SharePointAssessment.ps1

.NOTES
    Use this script when running the full assessment fails due to SharePoint auth issues.
    Results will be saved to the reports folder.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot 'reports'),
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'config\assessment-config.json')
)

Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SharePoint Online Assessment (Standalone)              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝`n" -ForegroundColor White

# Load configuration
if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    Write-Host "✓ Configuration loaded" -ForegroundColor Green
} else {
    Write-Warning "Config file not found, using defaults"
    $config = [PSCustomObject]@{ SharePoint = @{} }
}

# Import SharePoint module
try {
    if (-not (Get-Module -ListAvailable -Name "Microsoft.Online.SharePoint.PowerShell")) {
        Write-Host "Installing SharePoint module..." -ForegroundColor Yellow
        Install-Module -Name "Microsoft.Online.SharePoint.PowerShell" -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module "Microsoft.Online.SharePoint.PowerShell" -DisableNameChecking -ErrorAction Stop
    Write-Host "✓ SharePoint module loaded" -ForegroundColor Green
} catch {
    Write-Error "Failed to load SharePoint module: $_"
    exit 1
}

# Connect to Microsoft Graph (needed for tenant info only)
try {
    Write-Host "`nConnecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome -ErrorAction Stop
    
    $org = Get-MgOrganization | Select-Object -First 1
    $tenantName = ($org.VerifiedDomains | Where-Object { $_.IsInitial -eq $true }).Name -replace "\.onmicrosoft\.com$", ""
    
    Write-Host "✓ Connected to Graph" -ForegroundColor Green
    Write-Host "  Tenant: $($org.DisplayName)" -ForegroundColor Gray
} catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    exit 1
}

# Connect to SharePoint
try {
    Write-Host "`nConnecting to SharePoint Online..." -ForegroundColor Cyan
    $adminUrl = "https://$tenantName-admin.sharepoint.com"
    Write-Host "  URL: $adminUrl" -ForegroundColor Gray
    
    Connect-SPOService -Url $adminUrl -ErrorAction Stop
    Write-Host "✓ Connected to SharePoint Online" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to SharePoint: $_"
    exit 1
}

# Run SharePoint assessment
try {
    Write-Host "`nRunning SharePoint assessment..." -ForegroundColor Cyan
    
    $assessmentScript = Join-Path $PSScriptRoot "modules\SharePoint\Test-SharePointConfiguration.ps1"
    if (-not (Test-Path $assessmentScript)) {
        throw "SharePoint assessment script not found: $assessmentScript"
    }
    
    . $assessmentScript
    $results = Test-SharePointConfiguration -Config $config
    
    Write-Host "✓ Assessment complete: $($results.Count) checks performed" -ForegroundColor Green
} catch {
    Write-Error "Assessment failed: $_"
    exit 1
}

# Generate reports
try {
    Write-Host "`nGenerating reports..." -ForegroundColor Cyan
    
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $baseFilename = "SharePointAssessment_$timestamp"
    
    # JSON Report
    $jsonPath = Join-Path $OutputPath "$baseFilename.json"
    $results | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding UTF8
    Write-Host "✓ JSON report: $jsonPath" -ForegroundColor Green
    
    # CSV Report
    $csvPath = Join-Path $OutputPath "$baseFilename.csv"
    $results | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "✓ CSV report: $csvPath" -ForegroundColor Green
    
    # Summary
    $passed = ($results | Where-Object { $_.Status -eq 'Pass' }).Count
    $failed = ($results | Where-Object { $_.Status -eq 'Fail' }).Count
    $warnings = ($results | Where-Object { $_.Status -eq 'Warning' }).Count
    
    Write-Host "`n╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║               Assessment Complete!                       ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`nResults Summary:" -ForegroundColor Cyan
    Write-Host "  ✓ Passed:   $passed" -ForegroundColor Green
    Write-Host "  ✗ Failed:   $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Gray" })
    Write-Host "  ⚠ Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Gray" })
    Write-Host "`nReports saved to: $OutputPath`n" -ForegroundColor White
    
} catch {
    Write-Error "Failed to generate reports: $_"
} finally {
    # Cleanup
    try {
        Disconnect-SPOService -ErrorAction SilentlyContinue
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    } catch {}
}
