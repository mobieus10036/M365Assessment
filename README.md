# Microsoft 365 Tenant Assessment Toolkit v3

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive PowerShell-based assessment toolkit for Microsoft 365 tenants, focused on security, compliance, and best practice validation.

## 🎯 Overview

This toolkit performs automated assessments across your Microsoft 365 tenant to identify configuration gaps, security risks, and opportunities for optimization based on Microsoft's best practices and security baselines.

## ✨ Features

- **🔒 Security Assessment**: MFA, Conditional Access, privileged accounts, legacy authentication
- ** Exchange Security**: Anti-spam, anti-malware, SPF/DKIM/DMARC validation
- **💰 License Optimization**: Identify unused licenses and optimization opportunities
- **📊 Multiple Report Formats**: HTML, JSON, and CSV outputs
- **🎨 Color-Coded Results**: Easy-to-read Pass/Fail/Warning indicators
- **📖 Remediation Guidance**: Direct links to Microsoft documentation
- **⚙️ Customizable**: Configure thresholds and checks via JSON

## 🚀 Quick Start

### Prerequisites

- Windows PowerShell 5.1+ or PowerShell 7+
- Microsoft 365 tenant with appropriate admin permissions
- Internet connectivity

### Installation

1. **Clone the repository**:
   ```powershell
   git clone https://github.com/yourusername/m365-tenant-assessment-kit-v3.git
   cd m365-tenant-assessment-kit-v3
   ```

2. **Install required PowerShell modules**:
   ```powershell
   .\Install-Prerequisites.ps1
   ```

3. **Run the assessment**:
   ```powershell
   .\Start-M365Assessment.ps1
   ```

### Required Permissions

The account running the assessment needs the following Microsoft 365 admin roles:
- **Global Reader** (minimum recommended)
- **Security Reader** (for security assessments)
- **Compliance Administrator** (for compliance checks)

Alternatively, **Global Administrator** role provides access to all checks.

## 📋 Assessment Modules

### Security
- ✅ Multi-Factor Authentication enforcement
- ✅ Conditional Access policies
- ✅ Privileged account management
- ✅ Legacy authentication protocols
- ✅ Password protection policies

### Compliance
- ✅ Data Loss Prevention (DLP) policies
- ✅ Retention policies and labels
- ✅ Sensitivity labels
- ✅ Compliance score analysis

### Exchange Online
- ✅ Anti-spam and anti-malware configuration
- ✅ Safe Attachments and Safe Links
- ✅ SPF, DKIM, and DMARC records
- ✅ Mailbox auditing status

### Licensing
- ✅ License assignment efficiency
- ✅ Inactive user identification
- ✅ Optimization recommendations

> **Note**: SharePoint and Teams assessment modules are temporarily disabled in v3.0 due to PowerShell module compatibility issues with PowerShell 7+. These will be re-enabled in a future release once module stability is resolved.

## 📊 Sample Reports

Reports are generated in the `reports/` folder with timestamps:
- `M365Assessment_20250107_143022.html` - Interactive HTML report
- `M365Assessment_20250107_143022.json` - Machine-readable JSON
- `M365Assessment_20250107_143022.csv` - Spreadsheet-compatible CSV

## ⚙️ Configuration

Customize assessment thresholds and behaviors by editing `config/assessment-config.json`:

```json
{
  "Security": {
    "MFAEnforcementThreshold": 95,
    "PrivilegedAccountMFARequired": true,
    "LegacyAuthAllowed": false
  },
  "Licensing": {
    "InactiveDaysThreshold": 90,
    "MinimumLicenseUtilization": 85
  }
}
```

## 🛠️ Advanced Usage

### Run specific modules only:
```powershell
.\Start-M365Assessment.ps1 -Modules Security,Exchange
```

### Export to specific format:
```powershell
.\Start-M365Assessment.ps1 -OutputFormat HTML
```

### Specify custom config:
```powershell
.\Start-M365Assessment.ps1 -ConfigPath .\custom-config.json
```

## 📚 Documentation

- [Best Practices Reference](docs/best-practices-reference.md)
- [Remediation Guides](docs/remediation-guides/)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This toolkit performs **read-only** operations and does not make changes to your Microsoft 365 tenant. Always review findings with your security and compliance teams before implementing changes.

## 🙏 Acknowledgments

- Microsoft Security Best Practices
- Microsoft 365 Security & Compliance Documentation
- Community contributors

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/m365-tenant-assessment-kit-v3/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/m365-tenant-assessment-kit-v3/discussions)

---

**Made with ❤️ for the Microsoft 365 Community**
