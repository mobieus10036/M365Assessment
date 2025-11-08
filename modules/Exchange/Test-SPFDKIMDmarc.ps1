<#
.SYNOPSIS
    Tests SPF, DKIM, and DMARC email authentication configuration.

.DESCRIPTION
    Validates email authentication records for domain security and
    anti-spoofing protection.

.PARAMETER Config
    Configuration object.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Author: M365 Assessment Toolkit
    Version: 1.0
#>

function Test-SPFDKIMDmarc {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing SPF, DKIM, DMARC configuration..."

        # Get accepted domains
        $domains = Get-AcceptedDomain -ErrorAction SilentlyContinue
        
        if ($null -eq $domains) {
            return [PSCustomObject]@{
                CheckName = "Email Authentication (SPF/DKIM/DMARC)"
                Category = "Exchange"
                Status = "Info"
                Severity = "Info"
                Message = "Unable to retrieve accepted domains"
                Details = @{}
                Recommendation = "Verify Exchange Online connection"
                DocumentationUrl = "https://learn.microsoft.com/defender-office-365/email-authentication-about"
                RemediationSteps = @()
            }
        }

        # Check DKIM configuration
        $dkimConfigs = Get-DkimSigningConfig -ErrorAction SilentlyContinue
        $enabledDkimDomains = @($dkimConfigs | Where-Object { $_.Enabled -eq $true })
        $dkimCount = $enabledDkimDomains.Count

        $totalDomains = @($domains).Count
        $dkimPercentage = if ($totalDomains -gt 0) {
            [math]::Round(($dkimCount / $totalDomains) * 100, 1)
        } else { 0 }

        # Determine status
        $status = "Pass"
        $severity = "Low"
        $issues = @()

        if ($dkimCount -eq 0) {
            $status = "Fail"
            $severity = "High"
            $issues += "DKIM not enabled for any domains"
        }
        elseif ($dkimPercentage -lt 100) {
            $status = "Warning"
            $severity = "Medium"
            $issues += "DKIM not enabled for all domains ($dkimPercentage%)"
        }

        $message = "DKIM enabled for $dkimCount/$totalDomains domains"
        
        # Note: SPF and DMARC are DNS records - can't check directly via PowerShell
        $message += ". Note: SPF and DMARC require DNS validation (manual check recommended)"

        if ($issues.Count -gt 0) {
            $message += ". Issues: $($issues -join '; ')"
        }

        return [PSCustomObject]@{
            CheckName = "Email Authentication (SPF/DKIM/DMARC)"
            Category = "Exchange"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                TotalDomains = $totalDomains
                DKIMEnabledDomains = $dkimCount
                DKIMPercentage = $dkimPercentage
                DomainsWithoutDKIM = @($dkimConfigs | Where-Object { $_.Enabled -ne $true }).Count
            }
            Recommendation = if ($status -ne "Pass") {
                "Enable DKIM for all domains. Verify SPF and DMARC DNS records for each domain."
            } else {
                "DKIM is enabled. Manually verify SPF (TXT record) and DMARC (TXT record) in DNS for all domains."
            }
            DocumentationUrl = "https://learn.microsoft.com/defender-office-365/email-authentication-dkim-configure"
            RemediationSteps = @(
                "SPF: Add TXT record 'v=spf1 include:spf.protection.outlook.com -all' to domain DNS"
                "DKIM: Enable DKIM signing in Exchange admin center for each domain"
                "DKIM: Add CNAME records provided by Microsoft to domain DNS"
                "DMARC: Add TXT record '_dmarc' with policy (start with p=none for monitoring)"
                "Monitor DMARC reports to identify authentication issues"
                "Gradually enforce DMARC policy (p=quarantine, then p=reject)"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "Email Authentication (SPF/DKIM/DMARC)"
            Category = "Exchange"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess email authentication: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure Exchange Online PowerShell is connected"
            DocumentationUrl = "https://learn.microsoft.com/defender-office-365/email-authentication-about"
            RemediationSteps = @()
        }
    }
}
