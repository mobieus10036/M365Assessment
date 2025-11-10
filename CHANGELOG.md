# Changelog

All notable changes to the M365 Assessment Toolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-11-10

### 🎉 Major Release - Code Quality & Consistency Update

### Changed
- **BREAKING**: Replaced all `Write-Host` calls with `Write-Information` for better pipeline compatibility
- Updated all version numbers to 3.0.0 across all modules for consistency
- Improved error messages with actionable guidance and support links
- Standardized author attribution across all files

### Added
- VERSION file to track releases
- CHANGELOG.md for version tracking
- SECURITY.md with beginner-friendly security reporting guidelines
- CODE_OF_CONDUCT.md for community standards
- GitHub Copilot acknowledgment in all files and documentation
- Proper repository links in all module headers

### Fixed
- Inconsistent version numbering (was v1.0 in code, v3.0 in README)
- Output formatting improvements for better readability
- Error handling now provides GitHub issues link for support

### Security
- Updated LICENSE with proper copyright attribution
- Added clear security reporting process
- Documented read-only nature of assessment operations

---

## [2.0.0] - 2025-11-09

### Added
- DNS validation for SPF and DMARC records (Test-SPFDKIMDmarc.ps1)
- Real-time domain email authentication checks
- Per-domain CSV export for email authentication status

### Changed
- Enhanced email security assessment with actual DNS lookups

---

## [1.0.0] - Initial Release

### Added
- Initial release of M365 Assessment Toolkit
- Security assessment modules (MFA, Conditional Access, Privileged Accounts, Legacy Auth)
- Exchange security checks (Email security, SPF/DKIM/DMARC)
- License optimization analysis
- Multiple report formats (HTML, JSON, CSV)
- Comprehensive documentation

### Notes
- SharePoint and Teams modules disabled due to PowerShell 7+ compatibility issues
- Compliance modules present but may have limited functionality

---

## Future Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for planned features and improvements.

---

**Note**: This project is created with assistance from GitHub Copilot.
