<#
.SYNOPSIS
    Tests SharePoint Online external sharing configuration.

.DESCRIPTION
    Evaluates external sharing settings for SharePoint and OneDrive
    to ensure appropriate security controls.

.PARAMETER Config
    Configuration object.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Author: M365 Assessment Toolkit
    Version: 1.0
#>

function Test-ExternalSharing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing SharePoint external sharing configuration..."

        $tenant = $null
        if ($script:SharePointConnectionMode -eq 'SPO') {
            $tenant = Get-SPOTenant -ErrorAction SilentlyContinue
        }
        elseif ($script:SharePointConnectionMode -eq 'PnP') {
            try {
                # PnP does not expose Get-SPOTenant directly; attempt to derive via admin settings
                $adminSettings = Get-PnPTenant -ErrorAction SilentlyContinue
                if ($adminSettings) {
                    $tenant = [PSCustomObject]@{
                        SharingCapability = $adminSettings.SharingCapability
                        OneDriveSharingCapability = $adminSettings.OneDriveSharingCapability
                        RequireAnonymousLinksExpireInDays = $adminSettings.RequireAnonymousLinksExpireInDays
                        DefaultSharingLinkType = $adminSettings.DefaultSharingLinkType
                    }
                }
            }
            catch {}
        }

        if ($null -eq $tenant) {
            return [PSCustomObject]@{
                CheckName = "SharePoint External Sharing"
                Category = "SharePoint"
                Status = "Info"
                Severity = "Info"
                Message = "Unable to retrieve SharePoint tenant configuration"
                Details = @{}
                Recommendation = "Ensure SharePoint Online PowerShell is connected"
                DocumentationUrl = "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
                RemediationSteps = @()
            }
        }

    $spSharingCapability = $tenant.SharingCapability
    $odSharingCapability = $tenant.OneDriveSharingCapability
    $requireAnonymousLinksExpire = $tenant.RequireAnonymousLinksExpireInDays -gt 0

        # Determine status based on sharing level
        # ExternalUserAndGuestSharing = Most permissive
        # ExternalUserSharingOnly = Medium
        # ExistingExternalUserSharingOnly = Restrictive
        # Disabled = Most restrictive

        $status = "Pass"
        $severity = "Low"
        $issues = @()

        # Check SharePoint sharing
        if ($spSharingCapability -eq 'ExternalUserAndGuestSharing') {
            $status = "Warning"
            $severity = "Medium"
            $issues += "SharePoint allows anonymous/anyone links (highest risk)"
        }

        # Check OneDrive sharing
        if ($odSharingCapability -eq 'ExternalUserAndGuestSharing') {
            if ($status -eq "Pass") { $status = "Warning" }
            $severity = "Medium"
            $issues += "OneDrive allows anonymous/anyone links (highest risk)"
        }

        # Check anonymous link expiration
        if (-not $requireAnonymousLinksExpire) {
            if ($status -eq "Pass") { $status = "Warning" }
            $issues += "Anonymous links do not have expiration requirement"
        }

        $message = "SharePoint sharing: $spSharingCapability, OneDrive: $odSharingCapability"
        if ($requireAnonymousLinksExpire) {
            $message += ", Anonymous links expire in $($tenant.RequireAnonymousLinksExpireInDays) days"
        }
        if ($issues.Count -gt 0) {
            $message += ". Issues: $($issues -join '; ')"
        }

        return [PSCustomObject]@{
            CheckName = "SharePoint External Sharing"
            Category = "SharePoint"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                SharePointSharingCapability = $spSharingCapability
                OneDriveSharingCapability = $odSharingCapability
                RequireAnonymousLinksExpire = $requireAnonymousLinksExpire
                AnonymousLinkExpirationDays = $tenant.RequireAnonymousLinksExpireInDays
                DefaultSharingLinkType = $tenant.DefaultSharingLinkType
            }
            Recommendation = if ($status -ne "Pass") {
                "Restrict external sharing to appropriate level. Require expiration for anonymous links. Use 'ExistingExternalUserSharingOnly' or more restrictive settings."
            } else {
                "External sharing settings are appropriate. Review regularly and audit sharing activities."
            }
            DocumentationUrl = "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
            RemediationSteps = @(
                "1. Navigate to SharePoint admin center"
                "2. Go to Policies > Sharing"
                "3. Set appropriate external sharing level (recommend: Existing guests)"
                "4. Enable 'Guests must sign in using the same account...' option"
                "5. Require anonymous link expiration (recommend: 30 days)"
                "6. Set default sharing link type to 'Specific people'"
                "7. Monitor external sharing via audit logs"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "SharePoint External Sharing"
            Category = "SharePoint"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess external sharing: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure SharePoint Online PowerShell module is connected"
            DocumentationUrl = "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
            RemediationSteps = @()
        }
    }
}
