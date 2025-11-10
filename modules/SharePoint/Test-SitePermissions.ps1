<#
.SYNOPSIS
    Tests SharePoint site permissions and access governance.

.DESCRIPTION
    Evaluates site collection permissions and identifies overly permissive
    configurations.

.PARAMETER Config
    Configuration object.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Project: M365 Assessment Toolkit
    Repository: https://github.com/mobieus10036/M365Assessment
    Author: mobieus10036
    Version: 3.0.0
    Created with assistance from GitHub Copilot
#>

function Test-SitePermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing SharePoint site permissions..."

        # Get sample of sites (first 50 for performance)
        $sites = $null
        if ($script:SharePointConnectionMode -eq 'SPO') {
            $sites = Get-SPOSite -Limit 50 -ErrorAction SilentlyContinue
        }
        elseif ($script:SharePointConnectionMode -eq 'PnP') {
            # Use PnP to enumerate tenant sites (exclude OneDrive for speed)
            $sites = Get-PnPTenantSite -IncludeOneDriveSites:$false -ErrorAction SilentlyContinue | Select-Object -First 50
        }

        if ($null -eq $sites -or @($sites).Count -eq 0) {
            return [PSCustomObject]@{
                CheckName = "SharePoint Site Permissions"
                Category = "SharePoint"
                Status = "Info"
                Severity = "Info"
                Message = "No SharePoint sites found or unable to retrieve"
                Details = @{}
                Recommendation = "Verify SharePoint Online connection"
                DocumentationUrl = "https://learn.microsoft.com/sharepoint/sharing-permissions-modern-experience"
                RemediationSteps = @()
            }
        }

    $totalSites = @($sites).Count
    # Normalize property name between SPO and PnP objects
    $sitesWithExternalUsers = @($sites | Where-Object { ($_.SharingCapability) -and ($_.SharingCapability -ne 'Disabled') }).Count

        $message = "$totalSites sites analyzed (sample). External sharing enabled on $sitesWithExternalUsers sites"

        return [PSCustomObject]@{
            CheckName = "SharePoint Site Permissions"
            Category = "SharePoint"
            Status = "Info"
            Severity = "Info"
            Message = $message
            Details = @{
                SitesSampled = $totalSites
                SitesWithExternalSharing = $sitesWithExternalUsers
            }
            Recommendation = "Regularly review site permissions and external sharing. Use access reviews and sensitivity labels."
            DocumentationUrl = "https://learn.microsoft.com/sharepoint/sharing-permissions-modern-experience"
            RemediationSteps = @(
                "1. Review site collection permissions regularly"
                "2. Remove unnecessary external users"
                "3. Use Microsoft Entra access reviews for periodic validation"
                "4. Apply sensitivity labels to classify sites"
                "5. Implement site lifecycle management"
                "6. Monitor sharing activity via audit logs"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "SharePoint Site Permissions"
            Category = "SharePoint"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess site permissions: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure SharePoint Online PowerShell is connected"
            DocumentationUrl = "https://learn.microsoft.com/sharepoint/sharing-permissions-modern-experience"
            RemediationSteps = @()
        }
    }
}
