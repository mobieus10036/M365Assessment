<# 
.SYNOPSIS
  Lightweight M365 OneDrive/SharePoint posture assessment (Mobieus Labs default).

.OUTPUTS
  TenantSettings.csv, Sites.csv, OneDriveSites.csv, Findings.md

.NOTES
  Requires: Microsoft.Online.SharePoint.PowerShell (installs if missing)
#>

[CmdletBinding()]
param(
  # Defaulted to your tenant short name
  [Parameter(Mandatory=$false)]
  [string]$TenantName = "mobieuslabs",

  [Parameter(Mandatory=$false)]
  [string]$OutputPath = (Join-Path -Path (Get-Location) -ChildPath "ODSP-Assessment")
)

function Ensure-Module {
  param([string]$Name,[string]$MinVersion="16.0.0")
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    Write-Host "Installing module $Name ..." -ForegroundColor Yellow
    Install-Module $Name -Scope CurrentUser -Force -MinimumVersion $MinVersion -ErrorAction Stop
  }
  Import-Module $Name -ErrorAction Stop
}

function New-Folder { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null } }

function Write-Finding { param([ref]$Sb,[string]$Line) $Sb.Value.AppendLine($Line) | Out-Null }

try {
  $ErrorActionPreference = "Stop"
  New-Folder -Path $OutputPath
  Ensure-Module -Name "Microsoft.Online.SharePoint.PowerShell"

  $adminUrl = "https://$TenantName-admin.sharepoint.com"
  Write-Host "Connecting to $adminUrl ..." -ForegroundColor Cyan
  Connect-SPOService -Url $adminUrl

  Write-Host "Collecting tenant settings..." -ForegroundColor Cyan
  $tenant = Get-SPOTenant

  $tenantRow = [PSCustomObject]@{
    RetrievedOn                               = (Get-Date).ToString("s")
    SharingCapability                         = $tenant.SharingCapability
    DefaultSharingLinkType                    = $tenant.DefaultSharingLinkType
    DefaultSharingLinkScope                   = $tenant.DefaultSharingLinkScope
    FileAnonymousLinkType                     = $tenant.FileAnonymousLinkType
    FolderAnonymousLinkType                   = $tenant.FolderAnonymousLinkType
    RequireAcceptingAccountMatchInvitedAccount= $tenant.RequireAcceptingAccountMatchInvitedAccount
    ShowEveryoneClaim                         = $tenant.ShowEveryoneClaim
    ShowAllUsersClaim                         = $tenant.ShowAllUsersClaim
    LegacyAuthProtocolsEnabled                = $tenant.LegacyAuthProtocolsEnabled
    DisallowInfectedFileDownload              = $tenant.DisallowInfectedFileDownload
    OneDriveStorageQuotaGB                    = if ($tenant.OneDriveStorageQuota) { [math]::Round($tenant.OneDriveStorageQuota/1GB,2) } else { $null }
    OrphanedPersonalSitesRetentionPeriodDays  = $tenant.OrphanedPersonalSitesRetentionPeriod
    ConditionalAccessPolicy                   = $tenant.ConditionalAccessPolicy
  }
  $tenantCsvPath = Join-Path $OutputPath "TenantSettings.csv"
  $tenantRow | Export-Csv -NoTypeInformation -Path $tenantCsvPath

  Write-Host "Inventorying SharePoint sites (incl. personal)..." -ForegroundColor Cyan
  $sites = Get-SPOSite -Limit All -IncludePersonalSite $true -Detailed

  $siteRows = $sites | Select-Object `
    Url, Owner, Template, Title, LockState, SharingCapability,
    StorageQuota, StorageUsageCurrent, LastContentModifiedDate, ExternalSharing
  $sitesCsvPath = Join-Path $OutputPath "Sites.csv"
  $siteRows | Export-Csv -NoTypeInformation -Path $sitesCsvPath

  $now = Get-Date
  $staleThreshold = $now.AddDays(-90)
  $oneDriveSites = $sites | Where-Object { $_.Template -like "SPSPERS*" } | ForEach-Object {
    [PSCustomObject]@{
      Url                      = $_.Url
      Owner                    = $_.Owner
      LastContentModifiedDate  = $_.LastContentModifiedDate
      StorageUsageMB           = $_.StorageUsageCurrent
      LockState                = $_.LockState
      SharingCapability        = $_.SharingCapability
      Inactive90Days           = if ($_.LastContentModifiedDate -lt $staleThreshold) { $true } else { $false }
    }
  }
  $odCsvPath = Join-Path $OutputPath "OneDriveSites.csv"
  $oneDriveSites | Export-Csv -NoTypeInformation -Path $odCsvPath

  $sb = New-Object System.Text.StringBuilder
  Write-Finding ([ref]$sb) "# M365 OneDrive/SharePoint Assessment (mobieuslabs)"
  Write-Finding ([ref]$sb) ""
  Write-Finding ([ref]$sb) "Generated: $(Get-Date -Format u)"
  Write-Finding ([ref]$sb) ""
  Write-Finding ([ref]$sb) "## Tenant Posture (high-impact settings)"
  Write-Finding ([ref]$sb) "- **SharingCapability**: $($tenant.SharingCapability)"
  Write-Finding ([ref]$sb) "- **DefaultSharingLinkType**: $($tenant.DefaultSharingLinkType)"
  Write-Finding ([ref]$sb) "- **DefaultSharingLinkScope**: $($tenant.DefaultSharingLinkScope)"
  Write-Finding ([ref]$sb) "- **Anyone link types**: File=$($tenant.FileAnonymousLinkType), Folder=$($tenant.FolderAnonymousLinkType)"
  Write-Finding ([ref]$sb) "- **Require account match**: $($tenant.RequireAcceptingAccountMatchInvitedAccount)"
  Write-Finding ([ref]$sb) "- **ShowEveryoneClaim/ShowAllUsersClaim**: $($tenant.ShowEveryoneClaim)/$($tenant.ShowAllUsersClaim)"
  Write-Finding ([ref]$sb) "- **LegacyAuthProtocolsEnabled**: $($tenant.LegacyAuthProtocolsEnabled)"
  Write-Finding ([ref]$sb) "- **Block malware downloads**: $($tenant.DisallowInfectedFileDownload)"
  Write-Finding ([ref]$sb) "- **OneDrive default quota (GB)**: $([string]$tenantRow.OneDriveStorageQuotaGB)"
  Write-Finding ([ref]$sb) "- **Orphaned OneDrive retention (days)**: $($tenant.OrphanedPersonalSitesRetentionPeriod)"
  Write-Finding ([ref]$sb) ""

  Write-Finding ([ref]$sb) "### Quick risk hints"
  if ($tenant.LegacyAuthProtocolsEnabled) {
    Write-Finding ([ref]$sb) "- ⚠️ **Legacy auth is enabled**. Consider disabling."
  } else { Write-Finding ([ref]$sb) "- ✅ Legacy auth disabled." }

  if ($tenant.FileAnonymousLinkType -eq "None" -and $tenant.FolderAnonymousLinkType -eq "None") {
    Write-Finding ([ref]$sb) "- ✅ ‘Anyone’ links disabled (files & folders)."
  } else {
    Write-Finding ([ref]$sb) "- ⚠️ ‘Anyone’ links permitted (File: $($tenant.FileAnonymousLinkType), Folder: $($tenant.FolderAnonymousLinkType))."
  }

  if ($tenant.DefaultSharingLinkType -ne "Internal") {
    Write-Finding ([ref]$sb) "- ⚠️ Default link type is **$($tenant.DefaultSharingLinkType)** (recommend **Internal**)."
  } else { Write-Finding ([ref]$sb) "- ✅ Default link type is Internal." }

  if (-not $tenant.RequireAcceptingAccountMatchInvitedAccount) {
    Write-Finding ([ref]$sb) "- ⚠️ Invite acceptance account matching is OFF."
  }

  Write-Finding ([ref]$sb) ""
  Write-Finding ([ref]$sb) "## Site Inventory Highlights"
  $totalSites = ($sites | Measure-Object).Count
  $groupSites = ($sites | Where-Object { $_.Template -like "GROUP*" } | Measure-Object).Count
  $teamSites  = ($sites | Where-Object { $_.Template -like "STS*" } | Measure-Object).Count
  $oneDrives  = ($oneDriveSites | Measure-Object).Count
  $locked     = ($sites | Where-Object { $_.LockState -ne "Unlock" -and $_.LockState } | Measure-Object).Count
  Write-Finding ([ref]$sb) "- Total sites: $totalSites (Team: $teamSites, M365 Group: $groupSites, OneDrive: $oneDrives)"
  Write-Finding ([ref]$sb) "- Locked/Read-only sites: $locked"
  Write-Finding ([ref]$sb) ""
  Write-Finding ([ref]$sb) "### External Sharing by Site (top 20 by most permissive)"
  $shareOrder = @("Anyone","ExternalUserSharingOnly","ExistingExternalUserSharingOnly","Disabled","Undefined")
  $topExternal = $sites | Sort-Object {
      $idx = $shareOrder.IndexOf([string]$_.SharingCapability)
      if ($idx -lt 0) { 99 } else { $idx }
    }, @{Expression="LastContentModifiedDate";Descending=$true} | Select-Object Url, Owner, SharingCapability, LastContentModifiedDate -First 20
  foreach ($s in $topExternal) {
    Write-Finding ([ref]$sb) "- $($s.SharingCapability): $($s.Url) (Owner: $($s.Owner); LastModified: $($s.LastContentModifiedDate))"
  }

  Write-Finding ([ref]$sb) ""
  Write-Finding ([ref]$sb) "## OneDrive Activity (stale > 90 days)"
  $stale = $oneDriveSites | Where-Object { $_.Inactive90Days -eq $true }
  if ($stale.Count -gt 0) {
    foreach ($o in ($stale | Sort-Object LastContentModifiedDate | Select-Object -First 50)) {
      Write-Finding ([ref]$sb) "- $($o.Url) (Owner: $($o.Owner); LastModified: $($o.LastContentModifiedDate))"
    }
    Write-Finding ([ref]$sb) ""
    Write-Finding ([ref]$sb) "> Consider lifecycle cleanup, retention review, and license reclamation for long-inactive OneDrives."
  } else { Write-Finding ([ref]$sb) "- ✅ No OneDrives appear inactive for 90+ days." }

  Write-Finding ([ref]$sb) ""
  Write-Finding ([ref]$sb) "## Files written"
  Write-Finding ([ref]$sb) "- $tenantCsvPath"
  Write-Finding ([ref]$sb) "- $sitesCsvPath"
  Write-Finding ([ref]$sb) "- $odCsvPath"

  $mdPath = Join-Path $OutputPath "Findings.md"
  [IO.File]::WriteAllText($mdPath, $sb.ToString(), [System.Text.Encoding]::UTF8)

  Write-Host "`n✅ Assessment complete."
  Write-Host "Output folder: $OutputPath" -ForegroundColor Green
  Write-Host " - Tenant settings: $tenantCsvPath"
  Write-Host " - All sites:       $sitesCsvPath"
  Write-Host " - OneDrive sites:  $odCsvPath"
  Write-Host " - Findings (MD):   $mdPath`n"

} catch {
  Write-Error $_.Exception.Message
  if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) {
    Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkGray
  }
  exit 1
}
