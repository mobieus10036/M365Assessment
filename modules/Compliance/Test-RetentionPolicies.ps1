<#
.SYNOPSIS
    Tests retention policy configuration across workloads.

.DESCRIPTION
    Evaluates retention policy presence and coverage for data governance
    and compliance requirements.

.PARAMETER Config
    Configuration object containing retention requirements.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Author: M365 Assessment Toolkit
    Version: 1.0
#>

function Test-RetentionPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing retention policy configuration..."

        # Get retention policies
        $retentionPolicies = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue

        if ($null -eq $retentionPolicies) {
            return [PSCustomObject]@{
                CheckName = "Retention Policies"
                Category = "Compliance"
                Status = "Warning"
                Severity = "Medium"
                Message = "No retention policies found in tenant"
                Details = @{ TotalPolicies = 0; EnabledPolicies = 0 }
                Recommendation = "Implement retention policies for data governance and compliance"
                DocumentationUrl = "https://learn.microsoft.com/purview/retention"
                RemediationSteps = @(
                    "1. Navigate to Microsoft Purview compliance portal"
                    "2. Go to Data lifecycle management > Retention policies"
                    "3. Create retention policies based on data retention requirements"
                    "4. Apply to appropriate workloads (Exchange, SharePoint, OneDrive, Teams)"
                    "5. Configure retention duration and actions"
                )
            }
        }

        $totalPolicies = @($retentionPolicies).Count
        $enabledPolicies = @($retentionPolicies | Where-Object { $_.Enabled -eq $true })
        $enabledCount = $enabledPolicies.Count

        # Check workload coverage
        $workloadCoverage = @()
        $hasExchange = $retentionPolicies | Where-Object { $null -ne $_.ExchangeLocation }
        $hasSharePoint = $retentionPolicies | Where-Object { $null -ne $_.SharePointLocation }
        $hasOneDrive = $retentionPolicies | Where-Object { $null -ne $_.OneDriveLocation }
        $hasTeams = $retentionPolicies | Where-Object { $null -ne $_.TeamsChannelLocation -or $null -ne $_.TeamsChatLocation }

        if ($hasExchange) { $workloadCoverage += "Exchange" }
        if ($hasSharePoint) { $workloadCoverage += "SharePoint" }
        if ($hasOneDrive) { $workloadCoverage += "OneDrive" }
        if ($hasTeams) { $workloadCoverage += "Teams" }

        # Determine status
        $requireRetention = if ($null -ne $Config.Compliance.RetentionPoliciesRequired) {
            $Config.Compliance.RetentionPoliciesRequired
        } else { $true }

        $status = "Pass"
        $severity = "Low"
        $issues = @()

        if ($requireRetention -and $totalPolicies -eq 0) {
            $status = "Warning"
            $severity = "Medium"
            $issues += "No retention policies configured"
        }
        elseif ($enabledCount -eq 0) {
            $status = "Warning"
            $severity = "Medium"
            $issues += "No enabled retention policies"
        }
        elseif ($workloadCoverage.Count -eq 0) {
            $status = "Warning"
            $severity = "Medium"
            $issues += "Retention policies exist but no workload coverage detected"
        }

        $message = "$enabledCount enabled retention policies found"
        if ($workloadCoverage.Count -gt 0) {
            $message += " covering: $($workloadCoverage -join ', ')"
        }
        if ($issues.Count -gt 0) {
            $message += ". Issues: $($issues -join '; ')"
        }

        return [PSCustomObject]@{
            CheckName = "Retention Policies"
            Category = "Compliance"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                TotalPolicies = $totalPolicies
                EnabledPolicies = $enabledCount
                WorkloadCoverage = $workloadCoverage
                HasExchange = ($null -ne $hasExchange)
                HasSharePoint = ($null -ne $hasSharePoint)
                HasOneDrive = ($null -ne $hasOneDrive)
                HasTeams = ($null -ne $hasTeams)
            }
            Recommendation = if ($status -ne "Pass") {
                "Configure retention policies to meet regulatory and business requirements"
            } else {
                "Retention policies are configured. Review retention periods and coverage regularly."
            }
            DocumentationUrl = "https://learn.microsoft.com/purview/retention"
            RemediationSteps = @(
                "1. Define retention requirements for different data types"
                "2. Create retention policies in Microsoft Purview"
                "3. Apply policies to Exchange, SharePoint, OneDrive, Teams"
                "4. Set appropriate retention periods"
                "5. Configure disposal actions (delete, review)"
                "6. Monitor retention policy compliance"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "Retention Policies"
            Category = "Compliance"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess retention policies: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure Exchange Online PowerShell is connected with appropriate permissions"
            DocumentationUrl = "https://learn.microsoft.com/purview/retention"
            RemediationSteps = @()
        }
    }
}
