<#
.SYNOPSIS
    Tests SharePoint Online and OneDrive for Business security configuration.

.DESCRIPTION
    Evaluates SharePoint tenant settings, external sharing policies, OneDrive governance,
    site permissions, and compliance with Microsoft security best practices.

.PARAMETER Config
    Configuration object containing SharePoint thresholds and requirements.

.OUTPUTS
    Array of PSCustomObjects containing assessment results with status, findings, and recommendations.

.NOTES
    Project: M365 Assessment Toolkit
    Repository: https://github.com/mobieus10036/M365Assessment
    Author: mobieus10036
    Version: 3.0.0
    Created with assistance from GitHub Copilot
    Requires: Microsoft.Online.SharePoint.PowerShell
#>

function Test-SharePointConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    $results = @()

    #region Helper Functions

    function Add-AssessmentResult {
        param(
            [string]$CheckName,
            [string]$Category = "SharePoint",
            [ValidateSet('Pass', 'Fail', 'Warning', 'Info')]
            [string]$Status,
            [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info')]
            [string]$Severity = 'Info',
            [string]$Message,
            [hashtable]$Details = @{},
            [string]$Recommendation = "",
            [string]$DocumentationUrl = "",
            [array]$RemediationSteps = @()
        )
        
        $script:results += [PSCustomObject]@{
            CheckName        = $CheckName
            Category         = $Category
            Status           = $Status
            Severity         = $Severity
            Message          = $Message
            Details          = $Details
            Recommendation   = $Recommendation
            DocumentationUrl = $DocumentationUrl
            RemediationSteps = $RemediationSteps
        }
    }

    function Ensure-SharePointModule {
        try {
            if (-not (Get-Module -ListAvailable -Name "Microsoft.Online.SharePoint.PowerShell")) {
                Write-Verbose "SharePoint Online Management Shell not found. Installing..."
                Install-Module -Name "Microsoft.Online.SharePoint.PowerShell" -Scope CurrentUser -Force -AllowClobber -MinimumVersion "16.0.0" -ErrorAction Stop
            }
            Import-Module "Microsoft.Online.SharePoint.PowerShell" -ErrorAction Stop
            return $true
        }
        catch {
            Write-Error "Failed to load SharePoint module: $($_.Exception.Message)"
            return $false
        }
    }

    #endregion

    try {
        Write-Verbose "Starting SharePoint Online assessment..."

        # Verify SharePoint module is available
        if (-not (Ensure-SharePointModule)) {
            Add-AssessmentResult -CheckName "SharePoint Module" -Status "Fail" -Severity "High" `
                -Message "Failed to load SharePoint Online Management Shell" `
                -Recommendation "Install Microsoft.Online.SharePoint.PowerShell module" `
                -RemediationSteps @("Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser") `
                -DocumentationUrl "https://learn.microsoft.com/powershell/sharepoint/sharepoint-online/connect-sharepoint-online"
            return $results
        }

        # Verify connection to SharePoint
        try {
            $tenant = Get-SPOTenant -ErrorAction Stop
        }
        catch {
            Add-AssessmentResult -CheckName "SharePoint Connection" -Status "Fail" -Severity "High" `
                -Message "Not connected to SharePoint Online: $($_.Exception.Message)" `
                -Recommendation "Ensure Connect-SPOService was called successfully" `
                -RemediationSteps @("Connect-SPOService -Url https://<tenant>-admin.sharepoint.com") `
                -DocumentationUrl "https://learn.microsoft.com/powershell/module/sharepoint-online/connect-sposervice"
            return $results
        }

        #region Tenant-Level Configuration Checks

        # 1. Sharing Capability Assessment
        $sharingCapability = $tenant.SharingCapability
        $desiredSharing = if ($Config.SharePoint.ExternalSharingLevel) { 
            $Config.SharePoint.ExternalSharingLevel 
        } else { 
            "ExternalUserSharingOnly" 
        }

        switch ($sharingCapability) {
            "Disabled" {
                Add-AssessmentResult -CheckName "Tenant External Sharing" -Status "Pass" -Severity "Low" `
                    -Message "External sharing is disabled (most secure)" `
                    -Details @{ SharingCapability = "Disabled" } `
                    -DocumentationUrl "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
            }
            "ExternalUserSharingOnly" {
                Add-AssessmentResult -CheckName "Tenant External Sharing" -Status "Pass" -Severity "Low" `
                    -Message "External sharing limited to existing guests only" `
                    -Details @{ SharingCapability = "ExternalUserSharingOnly" } `
                    -DocumentationUrl "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
            }
            "ExistingExternalUserSharingOnly" {
                Add-AssessmentResult -CheckName "Tenant External Sharing" -Status "Warning" -Severity "Medium" `
                    -Message "External sharing allows new guest invitations" `
                    -Details @{ SharingCapability = "ExistingExternalUserSharingOnly" } `
                    -Recommendation "Consider restricting to 'ExternalUserSharingOnly' if new guests are not needed" `
                    -RemediationSteps @("Set-SPOTenant -SharingCapability ExternalUserSharingOnly") `
                    -DocumentationUrl "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
            }
            "Anyone" {
                Add-AssessmentResult -CheckName "Tenant External Sharing" -Status "Fail" -Severity "Critical" `
                    -Message "External sharing allows 'Anyone' links (least secure)" `
                    -Details @{ SharingCapability = "Anyone"; Recommended = $desiredSharing } `
                    -Recommendation "Disable 'Anyone' links to reduce data exposure risk" `
                    -RemediationSteps @(
                        "Set-SPOTenant -SharingCapability ExternalUserSharingOnly",
                        "Review all sites with anonymous links enabled",
                        "Implement sensitivity labels for external sharing control"
                    ) `
                    -DocumentationUrl "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
            }
        }

        # 2. Default Sharing Link Type
        $defaultLinkType = $tenant.DefaultSharingLinkType
        if ($defaultLinkType -eq "Internal") {
            Add-AssessmentResult -CheckName "Default Sharing Link Type" -Status "Pass" -Severity "Low" `
                -Message "Default link type is 'Internal' (organization only)" `
                -Details @{ DefaultLinkType = "Internal" } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/change-default-sharing-link"
        }
        else {
            Add-AssessmentResult -CheckName "Default Sharing Link Type" -Status "Warning" -Severity "Medium" `
                -Message "Default link type allows external sharing: $defaultLinkType" `
                -Details @{ DefaultLinkType = $defaultLinkType; Recommended = "Internal" } `
                -Recommendation "Set default sharing links to 'Internal' to prevent accidental external sharing" `
                -RemediationSteps @("Set-SPOTenant -DefaultSharingLinkType Internal") `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/change-default-sharing-link"
        }

        # 3. Anonymous Link Configuration
        $fileAnonLink = $tenant.FileAnonymousLinkType
        $folderAnonLink = $tenant.FolderAnonymousLinkType
        
        if ($fileAnonLink -eq "None" -and $folderAnonLink -eq "None") {
            Add-AssessmentResult -CheckName "Anonymous Links" -Status "Pass" -Severity "Low" `
                -Message "'Anyone' links disabled for files and folders" `
                -Details @{ FileAnonymousLinkType = "None"; FolderAnonymousLinkType = "None" } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
        }
        else {
            Add-AssessmentResult -CheckName "Anonymous Links" -Status "Fail" -Severity "High" `
                -Message "'Anyone' links are enabled (high data exposure risk)" `
                -Details @{ FileAnonymousLinkType = $fileAnonLink; FolderAnonymousLinkType = $folderAnonLink } `
                -Recommendation "Disable anonymous ('Anyone') links to prevent uncontrolled data sharing" `
                -RemediationSteps @(
                    "Set-SPOTenant -FileAnonymousLinkType None -FolderAnonymousLinkType None",
                    "Audit existing anonymous links using SharePoint sharing reports",
                    "Educate users on secure sharing practices"
                ) `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off"
        }

        # 4. Guest Invitation Verification
        if ($tenant.RequireAcceptingAccountMatchInvitedAccount) {
            Add-AssessmentResult -CheckName "Guest Invitation Verification" -Status "Pass" -Severity "Low" `
                -Message "Guest invitations require matching email address" `
                -Details @{ RequireAcceptingAccountMatchInvitedAccount = $true } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/what-s-new-in-sharing-in-targeted-release"
        }
        else {
            Add-AssessmentResult -CheckName "Guest Invitation Verification" -Status "Warning" -Severity "Medium" `
                -Message "Guest invitations do not require email verification" `
                -Details @{ RequireAcceptingAccountMatchInvitedAccount = $false } `
                -Recommendation "Enable email verification to ensure invitations go to intended recipients" `
                -RemediationSteps @("Set-SPOTenant -RequireAcceptingAccountMatchInvitedAccount `$true") `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/what-s-new-in-sharing-in-targeted-release"
        }

        # 5. Show Everyone Claim
        if ($tenant.ShowEveryoneClaim -eq $false) {
            Add-AssessmentResult -CheckName "Everyone Claim Visibility" -Status "Pass" -Severity "Low" `
                -Message "'Everyone' claim is hidden (recommended)" `
                -Details @{ ShowEveryoneClaim = $false } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/control-access-from-unmanaged-devices"
        }
        else {
            Add-AssessmentResult -CheckName "Everyone Claim Visibility" -Status "Warning" -Severity "Low" `
                -Message "'Everyone' claim is visible (may lead to oversharing)" `
                -Details @{ ShowEveryoneClaim = $true } `
                -Recommendation "Hide 'Everyone' claim to prevent accidental broad access grants" `
                -RemediationSteps @("Set-SPOTenant -ShowEveryoneClaim `$false") `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/control-access-from-unmanaged-devices"
        }

        # 6. Legacy Authentication
        if ($tenant.LegacyAuthProtocolsEnabled -eq $false) {
            Add-AssessmentResult -CheckName "Legacy Authentication" -Status "Pass" -Severity "Low" `
                -Message "Legacy authentication protocols are disabled" `
                -Details @{ LegacyAuthProtocolsEnabled = $false } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/control-access-from-unmanaged-devices"
        }
        else {
            Add-AssessmentResult -CheckName "Legacy Authentication" -Status "Fail" -Severity "High" `
                -Message "Legacy authentication protocols are enabled (security risk)" `
                -Details @{ LegacyAuthProtocolsEnabled = $true } `
                -Recommendation "Disable legacy authentication to enforce modern auth and MFA" `
                -RemediationSteps @(
                    "Set-SPOTenant -LegacyAuthProtocolsEnabled `$false",
                    "Test application compatibility before disabling",
                    "Review Azure AD sign-in logs for legacy auth usage"
                ) `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/control-access-from-unmanaged-devices"
        }

        # 7. Malware Protection
        if ($tenant.DisallowInfectedFileDownload) {
            Add-AssessmentResult -CheckName "Malware Download Protection" -Status "Pass" -Severity "Low" `
                -Message "Infected file downloads are blocked" `
                -Details @{ DisallowInfectedFileDownload = $true } `
                -DocumentationUrl "https://learn.microsoft.com/microsoft-365/security/office-365-security/anti-malware-protection"
        }
        else {
            Add-AssessmentResult -CheckName "Malware Download Protection" -Status "Fail" -Severity "High" `
                -Message "Infected files can be downloaded (security risk)" `
                -Details @{ DisallowInfectedFileDownload = $false } `
                -Recommendation "Block infected file downloads to prevent malware spread" `
                -RemediationSteps @("Set-SPOTenant -DisallowInfectedFileDownload `$true") `
                -DocumentationUrl "https://learn.microsoft.com/microsoft-365/security/office-365-security/anti-malware-protection"
        }

        # 8. OneDrive Storage Quota
        $oneDriveQuotaGB = if ($tenant.OneDriveStorageQuota) { 
            [math]::Round($tenant.OneDriveStorageQuota / 1024, 2) 
        } else { 
            0 
        }
        
        Add-AssessmentResult -CheckName "OneDrive Default Quota" -Status "Info" -Severity "Info" `
            -Message "Default OneDrive storage quota: $oneDriveQuotaGB GB per user" `
            -Details @{ OneDriveStorageQuotaGB = $oneDriveQuotaGB } `
            -DocumentationUrl "https://learn.microsoft.com/sharepoint/set-default-storage-space"

        # 9. Conditional Access Policy
        $caPolicy = $tenant.ConditionalAccessPolicy
        if ($caPolicy -ne "AllowFullAccess") {
            Add-AssessmentResult -CheckName "Conditional Access for Unmanaged Devices" -Status "Pass" -Severity "Low" `
                -Message "Conditional access policies are enforced: $caPolicy" `
                -Details @{ ConditionalAccessPolicy = $caPolicy } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/control-access-from-unmanaged-devices"
        }
        else {
            Add-AssessmentResult -CheckName "Conditional Access for Unmanaged Devices" -Status "Warning" -Severity "Medium" `
                -Message "No conditional access restrictions for unmanaged devices" `
                -Details @{ ConditionalAccessPolicy = "AllowFullAccess" } `
                -Recommendation "Implement conditional access to limit access from unmanaged devices" `
                -RemediationSteps @(
                    "Set-SPOTenant -ConditionalAccessPolicy AllowLimitedAccess",
                    "Or configure Azure AD Conditional Access policies",
                    "Test with pilot group before broad deployment"
                ) `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/control-access-from-unmanaged-devices"
        }

        # 10. OneDrive Retention for Deleted Users
        $retentionDays = $tenant.OrphanedPersonalSitesRetentionPeriod
        if ($retentionDays -ge 365) {
            Add-AssessmentResult -CheckName "OneDrive Retention Policy" -Status "Pass" -Severity "Low" `
                -Message "Deleted user OneDrive retention: $retentionDays days" `
                -Details @{ OrphanedPersonalSitesRetentionPeriod = $retentionDays } `
                -DocumentationUrl "https://learn.microsoft.com/onedrive/retention-and-deletion"
        }
        else {
            Add-AssessmentResult -CheckName "OneDrive Retention Policy" -Status "Warning" -Severity "Low" `
                -Message "Deleted user OneDrive retention may be too short: $retentionDays days" `
                -Details @{ OrphanedPersonalSitesRetentionPeriod = $retentionDays; Recommended = 365 } `
                -Recommendation "Consider extending retention to at least 365 days for compliance" `
                -RemediationSteps @("Set-SPOTenant -OrphanedPersonalSitesRetentionPeriod 365") `
                -DocumentationUrl "https://learn.microsoft.com/onedrive/retention-and-deletion"
        }

        #endregion

        #region Site-Level Assessment

        Write-Verbose "Retrieving site collection inventory..."
        $sites = Get-SPOSite -Limit All -IncludePersonalSite $true -Detailed
        $totalSites = ($sites | Measure-Object).Count
        
        Add-AssessmentResult -CheckName "Site Collection Inventory" -Status "Info" -Severity "Info" `
            -Message "Total site collections: $totalSites" `
            -Details @{ TotalSites = $totalSites } `
            -DocumentationUrl "https://learn.microsoft.com/sharepoint/sites/site-lifecycle-management"

        # Sites with external sharing enabled
        $externalSharingSites = $sites | Where-Object { 
            $_.SharingCapability -in @('ExternalUserSharingOnly', 'ExistingExternalUserSharingOnly', 'Anyone')
        }
        
        if ($externalSharingSites.Count -gt 0) {
            $externalPercentage = [math]::Round(($externalSharingSites.Count / $totalSites) * 100, 1)
            
            $status = if ($externalPercentage -gt 50) { "Warning" } else { "Info" }
            $severity = if ($externalPercentage -gt 75) { "High" } elseif ($externalPercentage -gt 50) { "Medium" } else { "Low" }
            
            Add-AssessmentResult -CheckName "Sites with External Sharing" -Status $status -Severity $severity `
                -Message "$($externalSharingSites.Count) sites ($externalPercentage%) have external sharing enabled" `
                -Details @{ 
                    SitesWithExternalSharing = $externalSharingSites.Count
                    TotalSites = $totalSites
                    Percentage = $externalPercentage
                } `
                -Recommendation "Review external sharing necessity for each site. Use sensitivity labels for access control." `
                -RemediationSteps @(
                    "Review sites with external sharing: Get-SPOSite | Where-Object { `$_.SharingCapability -ne 'Disabled' }",
                    "Disable for unnecessary sites: Set-SPOSite -Identity <url> -SharingCapability Disabled",
                    "Implement sensitivity labels for automated protection"
                ) `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/external-sharing-overview"
        }
        else {
            Add-AssessmentResult -CheckName "Sites with External Sharing" -Status "Pass" -Severity "Low" `
                -Message "No sites have external sharing enabled" `
                -Details @{ SitesWithExternalSharing = 0 } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/external-sharing-overview"
        }

        # Locked or read-only sites
        $lockedSites = $sites | Where-Object { 
            $_.LockState -ne "Unlock" -and $null -ne $_.LockState 
        }
        
        if ($lockedSites.Count -gt 0) {
            Add-AssessmentResult -CheckName "Locked/Read-Only Sites" -Status "Info" -Severity "Info" `
                -Message "$($lockedSites.Count) site collections have restricted access (locked/read-only)" `
                -Details @{ LockedSites = $lockedSites.Count } `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/manage-lock-status"
        }

        #endregion

        #region OneDrive Assessment

        Write-Verbose "Analyzing OneDrive sites..."
        $oneDriveSites = $sites | Where-Object { $_.Template -like "SPSPERS*" }
        $oneDriveCount = ($oneDriveSites | Measure-Object).Count
        
        Add-AssessmentResult -CheckName "OneDrive Site Count" -Status "Info" -Severity "Info" `
            -Message "Total OneDrive for Business sites: $oneDriveCount" `
            -Details @{ OneDriveSites = $oneDriveCount } `
            -DocumentationUrl "https://learn.microsoft.com/onedrive/onedrive"

        # Inactive OneDrive sites
        $staleThreshold = if ($Config.SharePoint.InactiveDaysThreshold) {
            $Config.SharePoint.InactiveDaysThreshold
        } else {
            90
        }
        
        $staleDate = (Get-Date).AddDays(-$staleThreshold)
        $staleSites = $oneDriveSites | Where-Object { 
            $_.LastContentModifiedDate -and $_.LastContentModifiedDate -lt $staleDate 
        }
        
        if ($staleSites.Count -gt 0) {
            $stalePercentage = [math]::Round(($staleSites.Count / $oneDriveCount) * 100, 1)
            
            $status = if ($stalePercentage -gt 30) { "Warning" } else { "Info" }
            $severity = if ($stalePercentage -gt 50) { "Medium" } else { "Low" }
            
            Add-AssessmentResult -CheckName "Inactive OneDrive Sites" -Status $status -Severity $severity `
                -Message "$($staleSites.Count) OneDrive sites ($stalePercentage%) inactive for $staleThreshold+ days" `
                -Details @{ 
                    InactiveSites = $staleSites.Count
                    TotalOneDriveSites = $oneDriveCount
                    Percentage = $stalePercentage
                    ThresholdDays = $staleThreshold
                } `
                -Recommendation "Review lifecycle policies, retention settings, and consider license reclamation" `
                -RemediationSteps @(
                    "Identify inactive OneDrive sites with report",
                    "Review with HR for departed employees",
                    "Reclaim licenses where appropriate",
                    "Implement OneDrive retention policies"
                ) `
                -DocumentationUrl "https://learn.microsoft.com/onedrive/retention-and-deletion"
        }
        else {
            Add-AssessmentResult -CheckName "Inactive OneDrive Sites" -Status "Pass" -Severity "Low" `
                -Message "No OneDrive sites inactive for $staleThreshold+ days" `
                -Details @{ InactiveSites = 0; ThresholdDays = $staleThreshold } `
                -DocumentationUrl "https://learn.microsoft.com/onedrive/retention-and-deletion"
        }

        # OneDrive sites with external sharing
        $oneDriveExternalSharing = $oneDriveSites | Where-Object { 
            $_.SharingCapability -in @('ExternalUserSharingOnly', 'ExistingExternalUserSharingOnly', 'Anyone')
        }
        
        if ($oneDriveExternalSharing.Count -gt 0) {
            $odSharingPercentage = [math]::Round(($oneDriveExternalSharing.Count / $oneDriveCount) * 100, 1)
            
            Add-AssessmentResult -CheckName "OneDrive External Sharing" -Status "Info" -Severity "Info" `
                -Message "$($oneDriveExternalSharing.Count) OneDrive sites ($odSharingPercentage%) have external sharing enabled" `
                -Details @{ 
                    OneDriveSitesWithExternalSharing = $oneDriveExternalSharing.Count
                    TotalOneDriveSites = $oneDriveCount
                    Percentage = $odSharingPercentage
                } `
                -Recommendation "OneDrive external sharing is user-controlled. Consider tenant-level restrictions if needed." `
                -DocumentationUrl "https://learn.microsoft.com/sharepoint/manage-sharing-settings"
        }

        #endregion

        Write-Verbose "SharePoint assessment completed successfully"
    }
    catch {
        Write-Error "SharePoint assessment error: $($_.Exception.Message)"
        Write-Verbose $_.ScriptStackTrace
        
        Add-AssessmentResult -CheckName "SharePoint Assessment Execution" -Status "Fail" -Severity "High" `
            -Message "Critical error during SharePoint assessment: $($_.Exception.Message)" `
            -Details @{ Error = $_.Exception.Message; StackTrace = $_.ScriptStackTrace } `
            -Recommendation "Review error logs and verify SharePoint Admin permissions" `
            -RemediationSteps @(
                "Verify you have SharePoint Administrator role",
                "Check network connectivity to SharePoint Online",
                "Ensure Microsoft.Online.SharePoint.PowerShell module is up to date"
            )
    }

    return $results
}
