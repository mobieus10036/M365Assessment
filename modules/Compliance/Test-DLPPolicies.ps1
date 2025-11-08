<#
.SYNOPSIS
    Tests Data Loss Prevention (DLP) policy configuration.

.DESCRIPTION
    Evaluates DLP policy presence, coverage, and effectiveness across
    Exchange, SharePoint, OneDrive, and Teams.

.PARAMETER Config
    Configuration object containing DLP requirements.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Author: M365 Assessment Toolkit
    Version: 1.0
#>

function Test-DLPPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing DLP policy configuration..."

        # Get DLP compliance policies
        $dlpPolicies = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue

        if ($null -eq $dlpPolicies) {
            return [PSCustomObject]@{
                CheckName = "Data Loss Prevention Policies"
                Category = "Compliance"
                Status = "Fail"
                Severity = "High"
                Message = "No DLP policies found in tenant"
                Details = @{ TotalPolicies = 0; EnabledPolicies = 0 }
                Recommendation = "Implement DLP policies to protect sensitive data"
                DocumentationUrl = "https://learn.microsoft.com/purview/dlp-learn-about-dlp"
                RemediationSteps = @(
                    "1. Navigate to Microsoft Purview compliance portal"
                    "2. Go to Data loss prevention > Policies"
                    "3. Create policies using templates (Financial, Privacy, Custom)"
                    "4. Configure policy scope (Exchange, SharePoint, OneDrive, Teams)"
                    "5. Test policies before enforcement"
                )
            }
        }

        $totalPolicies = @($dlpPolicies).Count
        $enabledPolicies = @($dlpPolicies | Where-Object { $_.Enabled -eq $true })
        $enabledCount = $enabledPolicies.Count

        # Check workload coverage
        $hasExchange = $dlpPolicies | Where-Object { $null -ne $_.ExchangeLocation }
        $hasSharePoint = $dlpPolicies | Where-Object { $null -ne $_.SharePointLocation }
        $hasOneDrive = $dlpPolicies | Where-Object { $null -ne $_.OneDriveLocation }
        $hasTeams = $dlpPolicies | Where-Object { $null -ne $_.TeamsLocation }

        $workloadCoverage = @()
        if ($hasExchange) { $workloadCoverage += "Exchange" }
        if ($hasSharePoint) { $workloadCoverage += "SharePoint" }
        if ($hasOneDrive) { $workloadCoverage += "OneDrive" }
        if ($hasTeams) { $workloadCoverage += "Teams" }

        # Determine status
        $requireDLP = if ($null -ne $Config.Compliance.DLPPoliciesRequired) {
            $Config.Compliance.DLPPoliciesRequired
        } else { $true }

        $status = "Pass"
        $severity = "Low"
        $issues = @()

        if ($requireDLP -and $totalPolicies -eq 0) {
            $status = "Fail"
            $severity = "High"
            $issues += "No DLP policies configured"
        }
        elseif ($enabledCount -eq 0) {
            $status = "Fail"
            $severity = "High"
            $issues += "No enabled DLP policies"
        }
        elseif ($workloadCoverage.Count -lt 4) {
            $status = "Warning"
            $severity = "Medium"
            $missingWorkloads = @('Exchange', 'SharePoint', 'OneDrive', 'Teams') | 
                                Where-Object { $_ -notin $workloadCoverage }
            $issues += "Limited workload coverage. Missing: $($missingWorkloads -join ', ')"
        }

        $message = "$enabledCount enabled DLP policies found"
        if ($workloadCoverage.Count -gt 0) {
            $message += " covering: $($workloadCoverage -join ', ')"
        }
        if ($issues.Count -gt 0) {
            $message += ". Issues: $($issues -join '; ')"
        }

        return [PSCustomObject]@{
            CheckName = "Data Loss Prevention Policies"
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
                "Implement comprehensive DLP policies across all workloads (Exchange, SharePoint, OneDrive, Teams)"
            } else {
                "DLP policies are configured. Review and test policies regularly."
            }
            DocumentationUrl = "https://learn.microsoft.com/purview/dlp-learn-about-dlp"
            RemediationSteps = @(
                "1. Access Microsoft Purview compliance portal"
                "2. Create DLP policies for sensitive data types"
                "3. Enable policies across Exchange, SharePoint, OneDrive, and Teams"
                "4. Configure policy actions (block, notify, allow override)"
                "5. Test in simulation mode before enforcement"
                "6. Review DLP alerts and reports regularly"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "Data Loss Prevention Policies"
            Category = "Compliance"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess DLP policies: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure Exchange Online PowerShell is connected with appropriate permissions"
            DocumentationUrl = "https://learn.microsoft.com/purview/dlp-learn-about-dlp"
            RemediationSteps = @()
        }
    }
}
