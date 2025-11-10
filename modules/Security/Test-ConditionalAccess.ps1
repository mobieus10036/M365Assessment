<#
.SYNOPSIS
    Tests Conditional Access policy configuration and coverage.

.DESCRIPTION
    Evaluates the presence and effectiveness of Conditional Access policies,
    checking for minimum required policies and coverage of critical scenarios.

.PARAMETER Config
    Configuration object containing Conditional Access requirements.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Project: M365 Assessment Toolkit
    Repository: https://github.com/mobieus10036/M365Assessment
    Author: mobieus10036
    Version: 3.0.0
    Created with assistance from GitHub Copilot
#>

function Test-ConditionalAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing Conditional Access policies..."

        # Get all Conditional Access policies
        $caPolicies = Get-MgIdentityConditionalAccessPolicy -All

        $totalPolicies = $caPolicies.Count
        $enabledPolicies = ($caPolicies | Where-Object { $_.State -eq 'enabled' }).Count
        $reportOnlyPolicies = ($caPolicies | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }).Count
        $disabledPolicies = ($caPolicies | Where-Object { $_.State -eq 'disabled' }).Count

        # Collect enabled policy details for reporting
        $enabledPolicyList = @()
        foreach ($policy in ($caPolicies | Where-Object { $_.State -eq 'enabled' })) {
            $enabledPolicyList += [PSCustomObject]@{
                DisplayName = $policy.DisplayName
                State = $policy.State
                Id = $policy.Id
            }
        }

        # Check for recommended policy types
        $hasMFAPolicy = $caPolicies | Where-Object { 
            $_.GrantControls.BuiltInControls -contains 'mfa' -and $_.State -eq 'enabled' 
        }
        
        $hasBlockLegacyAuth = $caPolicies | Where-Object {
            $_.Conditions.ClientAppTypes -contains 'exchangeActiveSync' -or
            $_.Conditions.ClientAppTypes -contains 'other'
        }

        $hasDeviceCompliancePolicy = $caPolicies | Where-Object {
            $_.GrantControls.BuiltInControls -contains 'compliantDevice' -or
            $_.GrantControls.BuiltInControls -contains 'domainJoinedDevice'
        }

        $hasRiskBasedPolicy = $caPolicies | Where-Object {
            $null -ne $_.Conditions.SignInRiskLevels -or
            $null -ne $_.Conditions.UserRiskLevels
        }

        # Minimum policies threshold
        $minPolicies = if ($Config.Security.MinConditionalAccessPolicies) {
            $Config.Security.MinConditionalAccessPolicies
        } else { 1 }

        # Determine status
        $issues = @()
        
        if ($totalPolicies -eq 0) {
            $status = "Fail"
            $severity = "Critical"
            $issues += "No Conditional Access policies found"
        }
        elseif ($enabledPolicies -eq 0) {
            $status = "Fail"
            $severity = "Critical"
            $issues += "No enabled Conditional Access policies"
        }
        else {
            $status = "Pass"
            $severity = "Low"
            
            if (-not $hasMFAPolicy) {
                $status = "Warning"
                $severity = "High"
                $issues += "No MFA enforcement policy found"
            }
            
            if (-not $hasBlockLegacyAuth) {
                if ($status -eq "Pass") { $status = "Warning" }
                if ($severity -eq "Low") { $severity = "Medium" }
                $issues += "No legacy authentication blocking policy"
            }
            
            if (-not $hasDeviceCompliancePolicy) {
                if ($status -eq "Pass") { $status = "Warning" }
                $issues += "No device compliance policy found"
            }
        }

        $message = "$enabledPolicies enabled policies found"
        if ($issues.Count -gt 0) {
            $message += ". Issues: $($issues -join '; ')"
        }

        $recommendations = @()
        if (-not $hasMFAPolicy) {
            $recommendations += "Create Conditional Access policy requiring MFA for all users"
        }
        if (-not $hasBlockLegacyAuth) {
            $recommendations += "Block legacy authentication protocols"
        }
        if (-not $hasDeviceCompliancePolicy) {
            $recommendations += "Implement device compliance requirements"
        }
        if (-not $hasRiskBasedPolicy) {
            $recommendations += "Consider implementing risk-based access policies"
        }

        return [PSCustomObject]@{
            CheckName = "Conditional Access Policies"
            Category = "Security"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                TotalPolicies = $totalPolicies
                EnabledPolicies = $enabledPolicies
                ReportOnlyPolicies = $reportOnlyPolicies
                DisabledPolicies = $disabledPolicies
                HasMFAPolicy = ($null -ne $hasMFAPolicy)
                HasLegacyAuthBlock = ($null -ne $hasBlockLegacyAuth)
                HasDeviceCompliance = ($null -ne $hasDeviceCompliancePolicy)
                HasRiskBased = ($null -ne $hasRiskBasedPolicy)
                Issues = $issues
            }
            EnabledPolicies = $enabledPolicyList
            Recommendation = if ($recommendations.Count -gt 0) { 
                $recommendations -join ". " 
            } else { 
                "Conditional Access configuration is adequate. Review policies regularly." 
            }
            DocumentationUrl = "https://learn.microsoft.com/entra/identity/conditional-access/overview"
            RemediationSteps = @(
                "1. Navigate to Entra ID > Security > Conditional Access"
                "2. Review the Conditional Access policy templates"
                "3. Create policies for: MFA enforcement, legacy auth blocking, device compliance"
                "4. Test policies in Report-only mode before enabling"
                "5. Monitor policy impact via Sign-in logs"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "Conditional Access Policies"
            Category = "Security"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess Conditional Access: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Verify Microsoft Graph permissions: Policy.Read.All"
            DocumentationUrl = "https://learn.microsoft.com/entra/identity/conditional-access/overview"
            RemediationSteps = @()
        }
    }
}
