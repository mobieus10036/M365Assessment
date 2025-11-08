# Contributing to M365 Tenant Assessment Toolkit

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## 🎯 Ways to Contribute

- 🐛 Report bugs and issues
- 💡 Suggest new assessment checks
- 📝 Improve documentation
- 🔧 Submit bug fixes
- ✨ Add new features or modules
- 🧪 Write tests
- 📊 Share assessment results and insights

## 🚀 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```powershell
   git clone https://github.com/YOUR-USERNAME/m365-tenant-assessment-kit-v3.git
   cd m365-tenant-assessment-kit-v3
   ```
3. **Create a branch** for your work:
   ```powershell
   git checkout -b feature/your-feature-name
   ```

## 📋 Development Guidelines

### PowerShell Code Standards

- Use **approved verbs** for function names (Get-, Test-, Set-, etc.)
- Follow **PascalCase** for function names: `Test-MFAConfiguration`
- Use **camelCase** for parameters: `-tenantId`, `-outputPath`
- Include **comment-based help** for all functions
- Use **Write-Verbose** for debugging output
- Use **Write-Warning** for non-critical issues
- Use **Write-Error** for critical failures
- Avoid using **Write-Host** (use Write-Information instead)

### Code Structure

```powershell
<#
.SYNOPSIS
    Brief description of the function.

.DESCRIPTION
    Detailed description of what the function does.

.PARAMETER ParameterName
    Description of the parameter.

.EXAMPLE
    Test-MFAConfiguration -TenantId "contoso.onmicrosoft.com"
    Description of what this example does.

.NOTES
    Author: Your Name
    Date: 2025-11-07
    Version: 1.0
#>
function Test-MFAConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId
    )

    begin {
        Write-Verbose "Starting MFA configuration assessment..."
    }

    process {
        # Implementation here
    }

    end {
        Write-Verbose "MFA configuration assessment complete."
    }
}
```

### Assessment Module Guidelines

Each assessment function should return a standardized object:

```powershell
[PSCustomObject]@{
    CheckName = "MFA Enforcement"
    Category = "Security"
    Status = "Pass" | "Fail" | "Warning" | "Info"
    Severity = "Critical" | "High" | "Medium" | "Low" | "Info"
    Message = "Clear description of the finding"
    Details = @{
        # Additional context
        UsersWithoutMFA = 5
        TotalUsers = 100
        CompliancePercentage = 95
    }
    Recommendation = "Enable MFA for all users"
    DocumentationUrl = "https://learn.microsoft.com/..."
    RemediationSteps = @(
        "Step 1: Navigate to Azure AD"
        "Step 2: Configure Conditional Access"
    )
}
```

### Testing Your Changes

1. **Test locally** against a test tenant (never production first!)
2. **Verify all output formats** (HTML, JSON, CSV)
3. **Check for errors** using PowerShell Script Analyzer:
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
   Invoke-ScriptAnalyzer -Path .\modules\ -Recurse
   ```
4. **Test with different permission levels**

## 📝 Commit Message Guidelines

Use clear, descriptive commit messages:

- ✨ `feat: Add Teams external access assessment`
- 🐛 `fix: Correct MFA percentage calculation`
- 📝 `docs: Update README with new module info`
- 🎨 `style: Format code according to PSScriptAnalyzer`
- ♻️ `refactor: Simplify report generation logic`
- ✅ `test: Add tests for Exchange module`
- ⚡ `perf: Optimize Graph API calls`

## 🔄 Pull Request Process

1. **Update documentation** if needed (README.md, docs/)
2. **Update the changelog** (if applicable)
3. **Ensure all tests pass** and code is analyzed
4. **Create a pull request** with:
   - Clear title describing the change
   - Description of what changed and why
   - Reference to related issues (if any)
   - Screenshots (if UI changes)

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested locally against M365 tenant
- [ ] No PSScriptAnalyzer warnings
- [ ] Documentation updated

## Related Issues
Closes #123
```

## 🐛 Reporting Bugs

When reporting bugs, include:

1. **PowerShell version**: `$PSVersionTable.PSVersion`
2. **Module versions**: Output from `Get-Module -ListAvailable`
3. **Steps to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Error messages** (full stack trace if available)
7. **Screenshots** (if applicable)

## 💡 Suggesting Features

Feature requests should include:

1. **Clear use case**: Why is this needed?
2. **Proposed solution**: How should it work?
3. **Alternatives considered**: Other approaches?
4. **Impact**: Who benefits from this?

## 📖 Documentation

- Keep README.md up to date
- Document all parameters and functions
- Include examples for complex scenarios
- Update best-practices-reference.md for new checks
- Add remediation guides for new findings

## 🔒 Security

- **Never commit credentials** or API keys
- **Never include tenant-specific data** in examples
- **Use placeholders** like `contoso.onmicrosoft.com`
- Report security vulnerabilities privately via email

## ✅ Code Review Checklist

Before submitting, ensure:

- [ ] Code follows PowerShell best practices
- [ ] No hardcoded credentials or secrets
- [ ] Comment-based help is complete
- [ ] Error handling is implemented
- [ ] Verbose/Debug output is appropriate
- [ ] Returns standardized assessment object
- [ ] Documentation is updated
- [ ] No PSScriptAnalyzer warnings
- [ ] Tested in isolated environment

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Your contributions help improve Microsoft 365 security for everyone. We appreciate your time and effort!

## 📧 Questions?

If you have questions, please:
- Open a [GitHub Discussion](https://github.com/yourusername/m365-tenant-assessment-kit-v3/discussions)
- Check existing [Issues](https://github.com/yourusername/m365-tenant-assessment-kit-v3/issues)

---

**Happy Contributing! 🎉**
