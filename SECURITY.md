# Security Policy

## 🔒 Reporting Security Issues

If you discover a security vulnerability in this project, please help us keep everyone safe!

### How to Report

**Please don't create a public GitHub issue for security problems.**

Instead, please:
1. **Email me directly** or use GitHub's private vulnerability reporting feature
2. Or **create a private security advisory** in the GitHub "Security" tab

### What to Include

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Any suggestions for fixing it (if you have ideas)

### What Happens Next

- I'll respond within a few days (I'm learning too, so please be patient!)
- We'll work together to understand and fix the issue
- Once fixed, I'll credit you in the release notes (if you'd like)

## 🛡️ Security Best Practices for Users

When using this assessment toolkit:

1. **Test first** - Always test on a non-production/demo tenant before using on your real tenant
2. **Protect reports** - The generated reports contain sensitive information about your Microsoft 365 tenant
3. **Use least privilege** - Use Global Reader role instead of Global Admin when possible
4. **Keep modules updated** - Regularly update the PowerShell modules: `Update-Module -Name Microsoft.Graph*`
5. **Review the code** - Feel free to review the scripts before running them (they're read-only)

## 📋 What This Tool Does (and Doesn't Do)

✅ **This tool ONLY reads** your tenant configuration  
❌ **This tool NEVER modifies** your tenant settings  
✅ **All operations are read-only** assessments  
❌ **No data is sent to external services** (except Microsoft APIs)

## 🤝 Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.x     | ✅ Yes (current)   |
| < 3.0   | ❌ No longer supported |

## 📞 Questions?

If you're not sure whether something is a security issue or just a bug, feel free to reach out anyway. Better safe than sorry!

---

*Note: As this is a personal/learning project, response times may vary. Thank you for your understanding and for helping make this project better!*
