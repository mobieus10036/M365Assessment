<#
.SYNOPSIS
    Tests mailbox auditing configuration.

.DESCRIPTION
    Verifies that mailbox auditing is enabled for compliance and
    security monitoring.

.PARAMETER Config
    Configuration object.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Author: M365 Assessment Toolkit
    Version: 1.0
#>

function Test-MailboxAuditing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing mailbox auditing configuration..."

        # Check organization-wide mailbox auditing
        $orgConfig = Get-OrganizationConfig -ErrorAction SilentlyContinue
        
        $auditDisabledByDefault = $orgConfig.AuditDisabled

        # Sample check of mailboxes (first 100)
        $mailboxes = Get-EXOMailbox -ResultSize 100 -Properties AuditEnabled -ErrorAction SilentlyContinue
        
        if ($null -eq $mailboxes) {
            return [PSCustomObject]@{
                CheckName = "Mailbox Auditing"
                Category = "Exchange"
                Status = "Info"
                Severity = "Info"
                Message = "Unable to retrieve mailbox information"
                Details = @{}
                Recommendation = "Verify Exchange Online connection and permissions"
                DocumentationUrl = "https://learn.microsoft.com/purview/audit-mailboxes"
                RemediationSteps = @()
            }
        }

        $totalSampled = @($mailboxes).Count
        $auditEnabled = @($mailboxes | Where-Object { $_.AuditEnabled -eq $true }).Count
        $auditPercentage = if ($totalSampled -gt 0) {
            [math]::Round(($auditEnabled / $totalSampled) * 100, 1)
        } else { 0 }

        # Determine status
        $status = "Pass"
        $severity = "Low"

        if ($auditDisabledByDefault) {
            $status = "Fail"
            $severity = "High"
            $message = "Mailbox auditing is disabled by default at organization level"
        }
        elseif ($auditPercentage -lt 90) {
            $status = "Warning"
            $severity = "Medium"
            $message = "Mailbox auditing: $auditPercentage% enabled (sampled $totalSampled mailboxes)"
        }
        else {
            $message = "Mailbox auditing enabled ($auditPercentage% of sampled mailboxes)"
        }

        return [PSCustomObject]@{
            CheckName = "Mailbox Auditing"
            Category = "Exchange"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                OrgAuditDisabled = $auditDisabledByDefault
                SampledMailboxes = $totalSampled
                AuditEnabledMailboxes = $auditEnabled
                AuditPercentage = $auditPercentage
            }
            Recommendation = if ($status -ne "Pass") {
                "Enable mailbox auditing organization-wide for security and compliance monitoring"
            } else {
                "Mailbox auditing is enabled. Review audit logs regularly for suspicious activity."
            }
            DocumentationUrl = "https://learn.microsoft.com/purview/audit-mailboxes"
            RemediationSteps = @(
                "1. Connect to Exchange Online PowerShell"
                "2. Run: Set-OrganizationConfig -AuditDisabled \$false"
                "3. Verify auditing: Get-OrganizationConfig | Select AuditDisabled"
                "4. For specific mailboxes: Set-Mailbox -Identity user@domain.com -AuditEnabled \$true"
                "5. Review audit logs in Microsoft Purview compliance portal"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "Mailbox Auditing"
            Category = "Exchange"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess mailbox auditing: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure Exchange Online PowerShell is connected"
            DocumentationUrl = "https://learn.microsoft.com/purview/audit-mailboxes"
            RemediationSteps = @()
        }
    }
}
