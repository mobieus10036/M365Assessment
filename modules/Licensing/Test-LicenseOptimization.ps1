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
                InactiveMailboxes = @()
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
        $inactiveMailboxes = @()

        foreach ($user in $licensedUsers) {
            $lastSignIn = $null
            $daysSinceLastSignIn = 'N/A'
            
            if ($user.SignInActivity.LastSignInDateTime) {
                $lastSignIn = [DateTime]$user.SignInActivity.LastSignInDateTime
                $daysSinceLastSignIn = [Math]::Round(((Get-Date) - $lastSignIn).TotalDays, 0)
            }

            if ($null -eq $lastSignIn -or $lastSignIn -lt $cutoffDate) {
                $inactiveMailboxes += [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    DisplayName = $user.DisplayName
                    LastSignInDate = if ($lastSignIn) { $lastSignIn.ToString('yyyy-MM-dd') } else { 'Never' }
                    DaysSinceLastSignIn = $daysSinceLastSignIn
                    AccountEnabled = $user.AccountEnabled
                    LicenseCount = $user.AssignedLicenses.Count
                }
            }
        }

        $inactiveCount = $inactiveMailboxes.Count
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
        
        # Add sample of inactive mailboxes to message
        if ($inactiveCount -gt 0 -and $inactiveCount -le 10) {
            $sampleList = ($inactiveMailboxes | ForEach-Object { 
                "$($_.UserPrincipalName) (Last: $($_.LastSignInDate))" 
            }) -join ", "
            $message += ". Examples: $sampleList"
        }
        elseif ($inactiveCount -gt 10) {
            $sampleList = ($inactiveMailboxes | Select-Object -First 5 | ForEach-Object { 
                "$($_.UserPrincipalName) (Last: $($_.LastSignInDate))" 
            }) -join ", "
            $message += ". Examples: $sampleList (and $($inactiveCount - 5) more...)"
        }

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
            }
            InactiveMailboxes = $inactiveMailboxes
            Recommendation = if ($status -ne "Pass") {
                "Review $inactiveCount inactive licensed user(s) and consider reclaiming unused licenses. See InactiveMailboxes list in JSON/CSV report for details."
            } else {
                "License utilization is good. Continue monitoring for inactive users monthly."
            }
            DocumentationUrl = "https://learn.microsoft.com/microsoft-365/commerce/licenses/subscriptions-and-licenses"
            RemediationSteps = @(
                "1. Review InactiveMailboxes CSV export for complete list"
                "2. Verify if users are truly inactive (check for leave, contractors, etc.)"
                "3. Coordinate with HR/managers before removing licenses"
                "4. For confirmed inactive: Remove licenses to reduce costs"
                "5. For terminated employees: Follow offboarding process"
                "6. Implement automated license reclamation policies"
                "7. Review license usage reports monthly for ongoing optimization"
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
            InactiveMailboxes = @()
            Recommendation = "Verify Microsoft Graph permissions: User.Read.All, AuditLog.Read.All"
            DocumentationUrl = "https://learn.microsoft.com/microsoft-365/commerce/licenses/subscriptions-and-licenses"
            RemediationSteps = @()
        }
    }
}
