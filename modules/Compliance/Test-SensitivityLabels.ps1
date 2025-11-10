<#
.SYNOPSIS
    Tests sensitivity label configuration and deployment.

.DESCRIPTION
    Evaluates sensitivity label presence, configuration, and usage
    for information protection.

.PARAMETER Config
    Configuration object containing sensitivity label requirements.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Project: M365 Assessment Toolkit
    Repository: https://github.com/mobieus10036/M365Assessment
    Author: mobieus10036
    Version: 3.0.0
    Created with assistance from GitHub Copilot
#>

function Test-SensitivityLabels {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing sensitivity label configuration..."

        # Get sensitivity labels
        $sensitivityLabels = Get-Label -ErrorAction SilentlyContinue

        if ($null -eq $sensitivityLabels) {
            return [PSCustomObject]@{
                CheckName = "Sensitivity Labels"
                Category = "Compliance"
                Status = "Warning"
                Severity = "Medium"
                Message = "No sensitivity labels found in tenant"
                Details = @{ TotalLabels = 0; PublishedLabels = 0 }
                Recommendation = "Configure sensitivity labels for data classification and protection"
                DocumentationUrl = "https://learn.microsoft.com/purview/sensitivity-labels"
                RemediationSteps = @(
                    "1. Navigate to Microsoft Purview compliance portal"
                    "2. Go to Information protection > Labels"
                    "3. Create sensitivity labels (Public, Internal, Confidential, Highly Confidential)"
                    "4. Configure protection settings (encryption, marking, access control)"
                    "5. Publish labels to users via label policies"
                    "6. Enable auto-labeling where appropriate"
                )
            }
        }

        $totalLabels = @($sensitivityLabels).Count
        
        # Get label policies
        $labelPolicies = Get-LabelPolicy -ErrorAction SilentlyContinue
        $totalPolicies = if ($labelPolicies) { @($labelPolicies).Count } else { 0 }
        
        # Check for published/enabled labels
        $publishedLabels = $sensitivityLabels | Where-Object { $_.Disabled -ne $true }
        $publishedCount = @($publishedLabels).Count

        # Check for encryption-enabled labels
        $encryptionLabels = $sensitivityLabels | Where-Object { 
            $_.EncryptionEnabled -eq $true 
        }
        $encryptionCount = @($encryptionLabels).Count

        # Determine status
        $requireLabels = if ($null -ne $Config.Compliance.SensitivityLabelsRequired) {
            $Config.Compliance.SensitivityLabelsRequired
        } else { $true }

        $status = "Pass"
        $severity = "Low"
        $issues = @()

        if ($requireLabels) {
            if ($totalLabels -eq 0) {
                $status = "Warning"
                $severity = "Medium"
                $issues += "No sensitivity labels configured"
            }
            elseif ($totalPolicies -eq 0) {
                $status = "Warning"
                $severity = "Medium"
                $issues += "Labels exist but no label policies published"
            }
            elseif ($publishedCount -eq 0) {
                $status = "Warning"
                $severity = "Medium"
                $issues += "No published/enabled labels"
            }
            elseif ($encryptionCount -eq 0) {
                $status = "Warning"
                $severity = "Low"
                $issues += "No labels with encryption protection configured"
            }
        }

        $message = "$publishedCount sensitivity labels published"
        if ($encryptionCount -gt 0) {
            $message += " ($encryptionCount with encryption)"
        }
        if ($totalPolicies -gt 0) {
            $message += ". $totalPolicies label policies deployed"
        }
        if ($issues.Count -gt 0) {
            $message += ". Issues: $($issues -join '; ')"
        }

        return [PSCustomObject]@{
            CheckName = "Sensitivity Labels"
            Category = "Compliance"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                TotalLabels = $totalLabels
                PublishedLabels = $publishedCount
                EncryptionLabels = $encryptionCount
                LabelPolicies = $totalPolicies
            }
            Recommendation = if ($status -ne "Pass") {
                "Configure and publish sensitivity labels with appropriate protection settings"
            } else {
                "Sensitivity labels are configured. Promote usage and enable auto-labeling for critical data."
            }
            DocumentationUrl = "https://learn.microsoft.com/purview/sensitivity-labels"
            RemediationSteps = @(
                "1. Create sensitivity label taxonomy (Public, Internal, Confidential, etc.)"
                "2. Configure label protection settings (encryption, watermarks, headers)"
                "3. Publish labels to users via label policies"
                "4. Train users on label usage"
                "5. Enable default labeling and mandatory labeling"
                "6. Configure auto-labeling for sensitive content"
                "7. Monitor label usage via reports"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "Sensitivity Labels"
            Category = "Compliance"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess sensitivity labels: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure Exchange Online PowerShell is connected with appropriate permissions"
            DocumentationUrl = "https://learn.microsoft.com/purview/sensitivity-labels"
            RemediationSteps = @()
        }
    }
}
