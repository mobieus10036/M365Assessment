# Microsoft 365 Best Practices Reference

This document provides comprehensive best practices for Microsoft 365 security, compliance, and configuration.

## Table of Contents
- [Security](#security)
- [Compliance](#compliance)
- [Exchange Online](#exchange-online)
- [SharePoint & OneDrive](#sharepoint--onedrive)
- [Microsoft Teams](#microsoft-teams)
- [Licensing & Governance](#licensing--governance)

---

## Security

### Multi-Factor Authentication (MFA)
- **Requirement**: 100% MFA adoption for all users
- **Implementation**: Use Conditional Access policies, not per-user MFA
- **Recommended Methods**: 
  - Microsoft Authenticator app (preferred)
  - FIDO2 security keys for high-value accounts
  - Windows Hello for Business
- **Avoid**: SMS/Phone call (vulnerable to SIM swapping)

### Conditional Access
- **Minimum Policies**:
  1. Require MFA for all users
  2. Block legacy authentication
  3. Require compliant/hybrid joined devices for administrators
  4. Require MFA from untrusted locations
  5. Block high-risk sign-ins

### Privileged Accounts
- **Global Administrator**: Limit to 2-5 emergency access accounts
- **Best Practices**:
  - Use dedicated cloud-only admin accounts (admin@domain.onmicrosoft.com)
  - Never use admin accounts for email/daily work
  - Implement Privileged Identity Management (PIM) for just-in-time access
  - Require phishing-resistant MFA (FIDO2, Windows Hello)

### Legacy Authentication
- **Action**: Block all legacy authentication protocols
- **Rationale**: Legacy auth bypasses MFA and modern security controls
- **Timeline**: 
  1. Identify apps using legacy auth (Sign-in logs)
  2. Migrate to modern auth
  3. Enable Conditional Access block policy

---

## Compliance

### Data Loss Prevention (DLP)
- **Required Policies**:
  - Financial data (credit cards, bank accounts)
  - Personal data (SSN, passport numbers)
  - Health records (HIPAA if applicable)
  - Custom business-critical data
- **Coverage**: Enable across Exchange, SharePoint, OneDrive, Teams
- **Actions**: Block sharing, notify users, generate alerts

### Retention Policies
- **Minimum Requirements**:
  - Email: 7 years (regulatory compliance)
  - SharePoint/OneDrive: Based on data classification
  - Teams: Match email retention
- **Best Practice**: Separate policies for different data types

### Sensitivity Labels
- **Recommended Taxonomy**:
  - Public
  - Internal
  - Confidential
  - Highly Confidential
- **Features**: Encryption, watermarks, access restrictions
- **Auto-labeling**: Enable for known sensitive content patterns

---

## Exchange Online

### Email Security
- **Required**:
  - Anti-spam and anti-malware (EOP - included)
  - Safe Attachments (Defender for Office 365)
  - Safe Links (Defender for Office 365)
  - Anti-phishing policies
- **Advanced**: Impersonation protection, mailbox intelligence

### Email Authentication
- **SPF**: Add TXT record: `v=spf1 include:spf.protection.outlook.com -all`
- **DKIM**: Enable for all custom domains
- **DMARC**: Start with `p=none` for monitoring, progress to `p=reject`
- **Rationale**: Prevents email spoofing and phishing

### Mailbox Auditing
- **Requirement**: Enable for all mailboxes
- **Command**: `Set-OrganizationConfig -AuditDisabled $false`
- **Retention**: 90 days (default), up to 1 year with E5
- **Use Cases**: Forensics, compliance, insider threat detection

---

## SharePoint & OneDrive

### External Sharing
- **Recommended Level**: "Existing external users only" (most restrictive while allowing B2B)
- **Anonymous Links**: Require expiration (30 days max)
- **Default Link Type**: "Specific people" (not "Anyone with the link")
- **Guest Re-sharing**: Disable

### Access Reviews
- **Frequency**: Quarterly for sites with external users
- **Scope**: Review permissions, remove stale access
- **Automation**: Use Microsoft Entra access reviews

### Sensitivity Labels for Sites
- **Implementation**: Apply labels to classify sites
- **Benefits**: Automatic external sharing restrictions, encryption policies
- **Examples**: 
  - Public: External sharing allowed
  - Confidential: Only internal users

---

## Microsoft Teams

### Guest Access
- **Allow**: Yes (for collaboration)
- **Restrictions**: 
  - Disable guest access to specific apps
  - Limit guest file sharing capabilities
  - Require approval for adding guests

### Meeting Security
- **Lobby Settings**: Require for external participants
- **Recording**: Restrict to authorized users
- **Transcription**: Enable with appropriate retention policies
- **Anonymous Join**: Disable for sensitive teams

### External Access (Federation)
- **Allow**: For authorized domains only
- **Chat Controls**: Enable message deletion and editing restrictions

---

## Licensing & Governance

### License Optimization
- **Monitor**: Inactive users (90+ days without sign-in)
- **Action**: Reclaim licenses monthly
- **Right-sizing**: Match license SKUs to actual feature usage

### Lifecycle Management
- **User Onboarding**: Automated provisioning via HR integration
- **Offboarding**: Immediate license reclamation, mailbox conversion
- **Retention**: Convert mailboxes to shared or litigation hold

### Monitoring & Alerts
- **Required Alerts**:
  - Admin role changes
  - Mailbox rule creation (potential compromise)
  - Bulk file sharing/downloads
  - Failed MFA attempts
- **Tools**: Microsoft Purview, Defender XDR, Sentinel

---

## Additional Resources

### Microsoft Documentation
- [Microsoft 365 Security](https://learn.microsoft.com/microsoft-365/security/)
- [Compliance Documentation](https://learn.microsoft.com/microsoft-365/compliance/)
- [Security Baselines](https://learn.microsoft.com/security/benchmark/azure/baselines/microsoft-365-security-baseline)

### Security Frameworks
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365)
- [Zero Trust Architecture](https://learn.microsoft.com/security/zero-trust/)

---

**Last Updated**: November 2025
**Toolkit Version**: 3.0
