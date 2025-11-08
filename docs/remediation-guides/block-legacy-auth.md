# Remediation Guide: Blocking Legacy Authentication

## Problem
Legacy authentication protocols (Basic Auth, POP, IMAP, SMTP AUTH) bypass modern security controls including MFA, leaving the tenant vulnerable to credential-based attacks.

## Impact
- **Security Risk**: Attackers can bypass MFA using stolen credentials
- **Common Attack Vector**: 95%+ of credential stuffing attacks use legacy auth
- **Compliance**: Many frameworks require modern authentication

## Recommended Solution
Block legacy authentication using Conditional Access policies.

## Step-by-Step Remediation

### Phase 1: Discovery (Week 1)
1. **Identify Legacy Auth Usage**
   ```powershell
   # Check sign-in logs for legacy auth attempts
   # Navigate to: Entra ID > Sign-in logs > Add filters
   # Filter: Client App = "Other clients", "Exchange ActiveSync", "POP3", "IMAP4"
   ```

2. **Document Applications and Users**
   - Export list of users using legacy auth
   - Identify applications (often: scanners, printers, older mobile devices)
   - Contact users to plan migration

### Phase 2: Migration (Weeks 2-4)
1. **Update Applications**
   - **Email Clients**: Ensure Outlook 2016+ or mobile apps
   - **Multifunction Devices**: Update firmware to support OAuth 2.0
   - **Custom Apps**: Update to use modern auth (MSAL libraries)
   - **Service Accounts**: Convert to app registrations with certificates

2. **Alternative Solutions**
   - **Scanners/Printers**: Use SMTP relay or direct send
   - **Third-party apps**: Check for OAuth 2.0 support
   - **Legacy systems**: Consider app proxy or connectors

### Phase 3: Policy Implementation (Week 5)
1. **Create Conditional Access Policy**
   - **Name**: "Block Legacy Authentication"
   - **Users**: All users (no exceptions)
   - **Conditions**: 
     - Client apps: Exchange ActiveSync clients, Other clients
   - **Access controls**: Block access
   - **Enable policy**: Report-only (initially)

2. **Test in Report-Only Mode**
   - Monitor for 1-2 weeks
   - Verify no business-critical apps are blocked
   - Address any remaining legacy auth usage

3. **Enable Block Policy**
   - Change from "Report-only" to "On"
   - Monitor sign-in logs for blocked attempts
   - Provide support for affected users

### Phase 4: Communication
1. **Pre-Implementation**
   - Email all users about legacy auth deprecation
   - Provide deadline (4-6 weeks notice)
   - Share migration guides

2. **Post-Implementation**
   - Announce policy activation
   - Provide IT support contact
   - Share troubleshooting resources

## Common Scenarios & Solutions

### Scenario 1: Mobile Email Clients
**Problem**: Users using built-in iPhone/Android mail apps with Basic Auth  
**Solution**: Switch to Outlook mobile app or configure modern auth

### Scenario 2: Multifunction Printers/Scanners
**Problem**: Scan-to-email uses SMTP AUTH  
**Solution**: 
- Option 1: Update firmware to support OAuth 2.0
- Option 2: Use Microsoft 365 Direct Send
- Option 3: Configure SMTP relay

### Scenario 3: Custom Applications
**Problem**: Internal app uses Basic Auth to access Exchange  
**Solution**: Update app to use Microsoft Graph API with OAuth 2.0

### Scenario 4: Service Accounts
**Problem**: Monitoring scripts use service accounts with Basic Auth  
**Solution**: Create app registration with certificate-based authentication

## Validation
After implementation, verify:
- [ ] Conditional Access policy is enabled (not report-only)
- [ ] Sign-in logs show zero successful legacy auth attempts
- [ ] No business disruption reported
- [ ] All critical applications use modern auth

## Monitoring
- Review Sign-in logs weekly for blocked legacy auth attempts
- Alert on persistent blocked attempts (may indicate compromised credentials)
- Track legacy auth usage trend (should be zero)

## Exception Management
**Emergency Exceptions Only**:
- Document business justification
- Set expiration date (max 90 days)
- Require management approval
- Review monthly

## Rollback Plan
If critical issues arise:
1. Change Conditional Access policy to "Report-only"
2. Identify affected systems
3. Implement solutions
4. Re-enable block after 1 week testing

## Support Resources
- [Block Legacy Auth Documentation](https://learn.microsoft.com/entra/identity/conditional-access/block-legacy-authentication)
- [Modern Authentication Setup](https://learn.microsoft.com/exchange/clients-and-mobile-in-exchange-online/enable-or-disable-modern-authentication-in-exchange-online)
- [SMTP Relay Configuration](https://learn.microsoft.com/exchange/mail-flow-best-practices/how-to-set-up-a-multifunction-device-or-application-to-send-email-using-microsoft-365-or-office-365)

## Estimated Time
- **Discovery**: 1 week
- **Migration**: 2-4 weeks
- **Testing**: 1-2 weeks
- **Full Implementation**: 6-8 weeks total

## Cost
- No additional licensing required
- Potential hardware updates for legacy devices

---
**Last Updated**: November 2025
