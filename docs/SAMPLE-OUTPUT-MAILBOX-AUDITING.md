# Sample Output - Mailbox Auditing Enhancement

## Console Output Example

```
[10:35:42] Running assessment modules: Security, Exchange, Licensing

  ┌─ Exchange Assessment ────────────────────────────────
    → Running Test-EmailSecurity...
      [Pass] Anti-spam policies configured
    → Running Test-SPFDKIMDmarc...
      [Pass] SPF, DKIM, and DMARC records configured
    → Running Test-MailboxAuditing...
      [Warning] Mailbox auditing: 90.9% enabled (sampled 100 mailboxes, 9 without auditing). Non-compliant (sample): user1@contoso.com, user2@contoso.com, user3@contoso.com, user4@contoso.com, user5@contoso.com (and 4 more...)
  └─────────────────────────────────────────────────────────

[10:35:48] Generating assessment reports...
  ✓ JSON report: e:\Dev\M365Assessment\reports\M365Assessment_20241109_103548.json
  ✓ CSV report: e:\Dev\M365Assessment\reports\M365Assessment_20241109_103548.csv
  ✓ Non-compliant mailboxes CSV: e:\Dev\M365Assessment\reports\M365Assessment_20241109_103548_NonCompliantMailboxes.csv
  ℹ   → 9 mailbox(es) without auditing exported
  ✓ HTML report: e:\Dev\M365Assessment\reports\M365Assessment_20241109_103548.html

╔══════════════════════════════════════════════════════════════════════╗
║                    Assessment Complete! ✓                            ║
╚══════════════════════════════════════════════════════════════════════╝

Execution Time: 2m 15s
Total Checks: 8
```

---

## HTML Report Preview

### Summary Section
```
┌─────────────────────────────────────────────────────────────────┐
│ 🔒 Microsoft 365 Tenant Assessment Report                       │
│ Tenant: Contoso Ltd | Assessment Date: 2024-11-09 10:35:48     │
├─────────────────────────────────────────────────────────────────┤
│ Total Checks: 8  | Passed: 6  | Failed: 0  | Warnings: 2       │
│ Compliance Score: 75.0%                                         │
└─────────────────────────────────────────────────────────────────┘
```

### Assessment Results Table (Mailbox Auditing Row)
```
┌──────────────────────┬──────────┬─────────┬──────────┬──────────────────────────────────────────┐
│ Check Name           │ Category │ Status  │ Severity │ Finding                                  │
├──────────────────────┼──────────┼─────────┼──────────┼──────────────────────────────────────────┤
│ Mailbox Auditing     │ Exchange │ Warning │ Medium   │ Mailbox auditing: 90.9% enabled          │
│                      │          │         │          │ (sampled 100 mailboxes, 9 without        │
│                      │          │         │          │ auditing)                                │
│                      │          │         │          │                                          │
│                      │          │         │          │ 🚨 Non-Compliant Mailboxes (9):          │
│                      │          │         │          │ • user1@contoso.com - John Smith         │
│                      │          │         │          │ • user2@contoso.com - Jane Doe           │
│                      │          │         │          │ • user3@contoso.com - Bob Johnson        │
│                      │          │         │          │ • user4@contoso.com - Alice Williams     │
│                      │          │         │          │ • user5@contoso.com - Charlie Brown      │
│                      │          │         │          │ • user6@contoso.com - Diana Prince       │
│                      │          │         │          │ • user7@contoso.com - Edward Norton      │
│                      │          │         │          │ • user8@contoso.com - Fiona Apple        │
│                      │          │         │          │ • user9@contoso.com - George Martin      │
└──────────────────────┴──────────┴─────────┴──────────┴──────────────────────────────────────────┘
```

---

## CSV Export: M365Assessment_20241109_103548_NonCompliantMailboxes.csv

```csv
UserPrincipalName,DisplayName,PrimarySmtpAddress,WhenCreated,AuditEnabled
user1@contoso.com,John Smith,user1@contoso.com,2024-01-15T10:30:00Z,False
user2@contoso.com,Jane Doe,user2@contoso.com,2024-02-20T14:22:00Z,False
user3@contoso.com,Bob Johnson,user3@contoso.com,2024-03-10T09:15:00Z,False
user4@contoso.com,Alice Williams,user4@contoso.com,2024-04-05T11:45:00Z,False
user5@contoso.com,Charlie Brown,user5@contoso.com,2024-05-18T08:30:00Z,False
user6@contoso.com,Diana Prince,user6@contoso.com,2024-06-22T16:20:00Z,False
user7@contoso.com,Edward Norton,user7@contoso.com,2024-07-11T13:10:00Z,False
user8@contoso.com,Fiona Apple,user8@contoso.com,2024-08-30T10:05:00Z,False
user9@contoso.com,George Martin,user9@contoso.com,2024-09-14T15:50:00Z,False
```

---

## JSON Export (Excerpt)

```json
{
  "CheckName": "Mailbox Auditing",
  "Category": "Exchange",
  "Status": "Warning",
  "Severity": "Medium",
  "Message": "Mailbox auditing: 90.9% enabled (sampled 100 mailboxes, 9 without auditing). Non-compliant (sample): user1@contoso.com, user2@contoso.com, user3@contoso.com, user4@contoso.com, user5@contoso.com (and 4 more...)",
  "Details": {
    "OrgAuditDisabled": false,
    "SampledMailboxes": 100,
    "AuditEnabledMailboxes": 91,
    "AuditDisabledMailboxes": 9,
    "AuditPercentage": 90.9,
    "NonCompliantCount": 9
  },
  "NonCompliantMailboxes": [
    {
      "UserPrincipalName": "user1@contoso.com",
      "DisplayName": "John Smith",
      "PrimarySmtpAddress": "user1@contoso.com",
      "WhenCreated": "2024-01-15T10:30:00Z",
      "AuditEnabled": false
    },
    {
      "UserPrincipalName": "user2@contoso.com",
      "DisplayName": "Jane Doe",
      "PrimarySmtpAddress": "user2@contoso.com",
      "WhenCreated": "2024-02-20T14:22:00Z",
      "AuditEnabled": false
    }
    // ... 7 more mailboxes
  ],
  "Recommendation": "Enable auditing for 9 mailbox(es). See NonCompliantMailboxes list in JSON/CSV report for details.",
  "DocumentationUrl": "https://learn.microsoft.com/purview/audit-mailboxes",
  "RemediationSteps": [
    "1. Connect to Exchange Online PowerShell",
    "2. For organization-wide: Set-OrganizationConfig -AuditDisabled $false",
    "3. For specific mailboxes: Set-Mailbox -Identity user@domain.com -AuditEnabled $true",
    "4. Bulk enable from CSV: Import-Csv report.csv | ForEach-Object { Set-Mailbox -Identity $_.UserPrincipalName -AuditEnabled $true }",
    "5. Verify auditing: Get-Mailbox -ResultSize Unlimited | Where-Object { -not $_.AuditEnabled }",
    "6. Review audit logs in Microsoft Purview compliance portal"
  ]
}
```

---

## Remediation Script Output

### Running the remediation script:

```powershell
PS> .\Enable-MailboxAuditing.ps1

╔══════════════════════════════════════════════════════════════════════╗
║          Enable Mailbox Auditing - Remediation Script                ║
╚══════════════════════════════════════════════════════════════════════╝

No CSV path specified. Looking for latest non-compliant report...
Found: e:\Dev\M365Assessment\reports\M365Assessment_20241109_103548_NonCompliantMailboxes.csv

Reading non-compliant mailboxes...
Found 9 mailbox(es) without auditing enabled

Checking Exchange Online connection...
✓ Connected to Exchange Online

Mailboxes to enable auditing:
──────────────────────────────────────────────────────────────────────
  • user1@contoso.com - John Smith
  • user2@contoso.com - Jane Doe
  • user3@contoso.com - Bob Johnson
  • user4@contoso.com - Alice Williams
  • user5@contoso.com - Charlie Brown
  • user6@contoso.com - Diana Prince
  • user7@contoso.com - Edward Norton
  • user8@contoso.com - Fiona Apple
  • user9@contoso.com - George Martin
──────────────────────────────────────────────────────────────────────

This will enable mailbox auditing for 9 mailbox(es).
Do you want to proceed? (Y/N): Y

Enabling mailbox auditing...
  ✓ user1@contoso.com
  ✓ user2@contoso.com
  ✓ user3@contoso.com
  ✓ user4@contoso.com
  ✓ user5@contoso.com
  ✓ user6@contoso.com
  ✓ user7@contoso.com
  ✓ user8@contoso.com
  ✓ user9@contoso.com

╔══════════════════════════════════════════════════════════════════════╗
║                         Operation Complete                            ║
╚══════════════════════════════════════════════════════════════════════╝

Results:
  ✓ Successfully enabled: 9
  ✗ Failed: 0

Verification:
  Run this command to verify changes:
  Get-EXOMailbox -ResultSize Unlimited | Where-Object { -not $_.AuditEnabled } | Select-Object UserPrincipalName, DisplayName, AuditEnabled

```

### Running with -WhatIf (dry run):

```powershell
PS> .\Enable-MailboxAuditing.ps1 -WhatIf

╔══════════════════════════════════════════════════════════════════════╗
║          Enable Mailbox Auditing - Remediation Script                ║
╚══════════════════════════════════════════════════════════════════════╝

No CSV path specified. Looking for latest non-compliant report...
Found: e:\Dev\M365Assessment\reports\M365Assessment_20241109_103548_NonCompliantMailboxes.csv

Reading non-compliant mailboxes...
Found 9 mailbox(es) without auditing enabled

Checking Exchange Online connection...
✓ Connected to Exchange Online

Mailboxes to enable auditing:
──────────────────────────────────────────────────────────────────────
  • user1@contoso.com - John Smith
  • user2@contoso.com - Jane Doe
  • user3@contoso.com - Bob Johnson
  • user4@contoso.com - Alice Williams
  • user5@contoso.com - Charlie Brown
  • user6@contoso.com - Diana Prince
  • user7@contoso.com - Edward Norton
  • user8@contoso.com - Fiona Apple
  • user9@contoso.com - George Martin
──────────────────────────────────────────────────────────────────────

Enabling mailbox auditing...
What if: Performing the operation "Enable mailbox auditing" on target "user1@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user2@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user3@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user4@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user5@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user6@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user7@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user8@contoso.com".
What if: Performing the operation "Enable mailbox auditing" on target "user9@contoso.com".
```

---

## Verification After Remediation

```powershell
PS> .\Start-M365Assessment.ps1 -NoAuth

[10:42:15] Running assessment modules: Security, Exchange, Licensing

  ┌─ Exchange Assessment ────────────────────────────────────
    → Running Test-MailboxAuditing...
      [Pass] Mailbox auditing enabled (100.0% of sampled mailboxes)
  └─────────────────────────────────────────────────────────────

[10:42:20] Generating assessment reports...
  ✓ JSON report: e:\Dev\M365Assessment\reports\M365Assessment_20241109_104220.json
  ✓ CSV report: e:\Dev\M365Assessment\reports\M365Assessment_20241109_104220.csv
  ✓ HTML report: e:\Dev\M365Assessment\reports\M365Assessment_20241109_104220.html

Note: No NonCompliantMailboxes.csv generated (all mailboxes compliant)
```

---

## Key Benefits Demonstrated

✅ **Clear Visibility** - Exactly which mailboxes need attention
✅ **Multiple Formats** - HTML (visual), CSV (Excel/scripting), JSON (automation)
✅ **Action-Ready** - Direct list for remediation
✅ **Safe Testing** - WhatIf support for preview
✅ **Progress Tracking** - Success/failure counts
✅ **Verification** - Re-run assessment to confirm fixes
