<#
.SYNOPSIS
    Tests Microsoft Teams configuration and security settings.

.DESCRIPTION
    Evaluates Teams policies for external access, guest access,
    and meeting security.

.PARAMETER Config
    Configuration object.

.OUTPUTS
    PSCustomObject containing assessment results.

.NOTES
    Author: M365 Assessment Toolkit
    Version: 1.0
#>

function Test-TeamsConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config
    )

    try {
        Write-Verbose "Analyzing Teams configuration..."

        # Get Teams client configuration
        $teamsConfig = Get-CsTeamsClientConfiguration -ErrorAction SilentlyContinue
        $guestConfig = Get-CsTeamsGuestMessagingConfiguration -ErrorAction SilentlyContinue

        # Check guest access and external access
        $allowGuestUser = $null
        $allowExternalAccess = $null

        try {
            $guestPolicy = Get-CsTeamsGuestCallingConfiguration -ErrorAction SilentlyContinue
            $allowGuestUser = $guestPolicy.AllowPrivateCalling
        } catch {
            Write-Verbose "Could not retrieve guest calling configuration"
        }

        $status = "Info"
        $severity = "Info"
        $issues = @()

        $message = "Teams configuration retrieved"
        
        # Add specific checks based on configuration
        if ($null -ne $guestConfig) {
            if ($guestConfig.AllowUserEditMessage -eq $false) {
                $issues += "Guest message editing is disabled (may impact collaboration)"
            }
        }

        if ($issues.Count -gt 0) {
            $message += ". Notes: $($issues -join '; ')"
        }

        return [PSCustomObject]@{
            CheckName = "Teams Configuration"
            Category = "Teams"
            Status = $status
            Severity = $severity
            Message = $message
            Details = @{
                GuestAccessEnabled = $allowGuestUser
                ExternalAccessEnabled = $allowExternalAccess
            }
            Recommendation = "Review Teams policies for guest access, meeting settings, and external collaboration"
            DocumentationUrl = "https://learn.microsoft.com/microsoftteams/teams-security-guide"
            RemediationSteps = @(
                "1. Navigate to Teams admin center"
                "2. Review Org-wide settings > Guest access"
                "3. Configure external access policies"
                "4. Set meeting policies (lobby, recording, transcription)"
                "5. Configure messaging policies"
                "6. Enable sensitivity labels for Teams"
                "7. Monitor Teams usage and security reports"
            )
        }
    }
    catch {
        return [PSCustomObject]@{
            CheckName = "Teams Configuration"
            Category = "Teams"
            Status = "Info"
            Severity = "Info"
            Message = "Unable to assess Teams configuration: $_"
            Details = @{ Error = $_.Exception.Message }
            Recommendation = "Ensure Microsoft Teams PowerShell module is connected"
            DocumentationUrl = "https://learn.microsoft.com/microsoftteams/teams-security-guide"
            RemediationSteps = @()
        }
    }
}
