<#
.SYNOPSIS
    Tests license assignment and optimization opportunities.

.DESCRIPTION
    Identifies inactive licensed users, unused licenses, and opportunities
    for license optimization and cost savings.

.PARAMETER Config
    Configuration object containing license thresholds.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Author: M365 Assessment Toolkit
    Version: 1.0
#>

function Test-LicenseOptimization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing license optimization opportunities..."

        # Get all users with licenses
        $licensedUsers = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, AssignedLicenses, SignInActivity |
                         Where-Object { $_.AssignedLicenses.Count -gt 0 }

        if ($null -eq $licensedUsers -or @($licensedUsers).Count -eq 0) {
            return [PSCustomObject]@{
                CheckName = "License Optimization"
                Category = "Licensing"
                Status = "Info"
                Severity = "Info"
                Message = "No licensed users found"
                Details = @{}
                Recommendation = "Verify Microsoft Graph permissions"
                DocumentationUrl = "https://learn.microsoft.com/microsoft-365/commerce/licenses/subscriptions-and-licenses"
                RemediationSteps = @()
            }
        }

        $totalLicensedUsers = @($licensedUsers).Count

        # Check for inactive users (based on last sign-in)
        $inactiveDaysThreshold = if ($Config.Licensing.InactiveDaysThreshold) {
            $Config.Licensing.InactiveDaysThreshold
        } else { 90 }

        $cutoffDate = (Get-Date).AddDays(-$inactiveDaysThreshold)
        $inactiveUsers = @()

        foreach ($user in $licensedUsers) {
            $lastSignIn = $null
            
            if ($user.SignInActivity.LastSignInDateTime) {
                $lastSignIn = [DateTime]$user.SignInActivity.LastSignInDateTime
            }

            if ($null -eq $lastSignIn -or $lastSignIn -lt $cutoffDate) {
                $inactiveUsers += $user.UserPrincipalName
            }
        }

        $inactiveCount = $inactiveUsers.Count
        $inactivePercentage = if ($totalLicensedUsers -gt 0) {
            [math]::Round(($inactiveCount / $totalLicensedUsers) * 100, 1)
        } else { 0 }

        # Determine status
        $status = "Pass"
        $severity = "Low"

        if ($inactivePercentage -gt 15) {
            $status = "Warning"
            $severity = "Medium"
        }
        elseif ($inactivePercentage -gt 25) {
            $status = "Fail"
            $severity = "High"
        }

        $message = "$inactiveCount inactive licensed users ($inactivePercentage%) - not signed in for $inactiveDaysThreshold+ days"

        return [PSCustomObject]@{
            CheckName = "License Optimization"
            Category = "Licensing"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                TotalLicensedUsers = $totalLicensedUsers
                InactiveUsers = $inactiveCount
                InactivePercentage = $inactivePercentage
                InactiveDaysThreshold = $inactiveDaysThreshold
                SampleInactiveUsers = ($inactiveUsers | Select-Object -First 10) -join ', '
            }
            Recommendation = if ($status -ne "Pass") {
                "Review inactive licensed users and reclaim unused licenses. Consider offboarding inactive accounts."
            } else {
                "License utilization is good. Continue monitoring for inactive users monthly."
            }
            DocumentationUrl = "https://learn.microsoft.com/microsoft-365/commerce/licenses/subscriptions-and-licenses"
            RemediationSteps = @(
                "1. Export list of inactive licensed users"
                "2. Verify if users are truly inactive or on leave"
                "3. Remove licenses from inactive accounts"
                "4. Consider account deactivation/deletion for former employees"
                "5. Implement automated license reclamation process"
                "6. Review license usage reports monthly"
                "7. Right-size license SKUs based on actual usage"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "License Optimization"
            Category = "Licensing"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess license optimization: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Verify Microsoft Graph permissions: User.Read.All, AuditLog.Read.All"
            DocumentationUrl = "https://learn.microsoft.com/microsoft-365/commerce/licenses/subscriptions-and-licenses"
            RemediationSteps = @()
        }
    }
}
