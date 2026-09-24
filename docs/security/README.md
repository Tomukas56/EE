# Security Documentation

## 📋 Overview

This folder contains all security-related documentation for the Energy Eniwhere project.

## 📁 Files

### Core Documents
- **[CVE_MANAGEMENT.md](CVE_MANAGEMENT.md)** - Vulnerability management process
  - How to scan for vulnerabilities
  - How to triage and fix findings
  - Reporting and compliance requirements

- **[SECURITY_FIXES.md](SECURITY_FIXES.md)** - Audit trail of fixed vulnerabilities
  - All CVEs fixed with dates, commits, and verification
  - Required for CRA Art. 20 compliance

- **[ACCEPTED_RISKS.md](ACCEPTED_RISKS.md)** - Documented risk acceptances
  - Findings accepted as risks (not immediately fixed)
  - Justifications and mitigation plans

- **[GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)** - GitHub Actions automation setup
  - How to configure automated weekly scans
  - GitHub secrets configuration
  - Workflow troubleshooting

### Related Documents (in parent folders)
- **[../specs/SECURITY_AND_THREATS.md](../specs/SECURITY_AND_THREATS.md)** - Threat model and compliance requirements
- **[../specs/SECURITY_COMPLIANCE.md](../specs/SECURITY_COMPLIANCE.md)** - Full CRA/GDPR/PSD2 compliance matrix

## 🚀 Quick Start

### Run Security Scan
```bash
# From project root
./scripts/scan-cve.sh
```

### View Reports
```bash
# All reports are in docs/sbom/
ls -lh docs/sbom/cve-*.json docs/sbom/cve-*.md

# Human-readable OSV report
cat docs/sbom/cve-osv.md

# Snyk backend findings
cat docs/sbom/cve-snyk-backend.json | jq '.vulnerabilities'
```

### Setup Snyk (Already Configured ✅)
```bash
# Local setup is complete
# Token is in backend/.env (gitignored)

# To run scans locally:
cd backend
SNYK_TOKEN=$(grep SNYK_TOKEN .env | cut -d '=' -f2) ../scripts/scan-cve.sh

# For GitHub Actions automation:
# See GITHUB_ACTIONS_SETUP.md for instructions
```

## 📊 Current Security Status

| Check | Status | Notes |
|-------|--------|-------|
| Dependency CVEs (Backend) | ✅ Clean | 0 high/critical, 94 deps tested (2026-09-24) |
| Dependency CVEs (Mobile) | ✅ Clean | 0 high/critical, 144 pkgs tested (2026-09-24) |
| Snyk Authentication | ✅ Configured | Token added to backend/.env |
| GitHub Actions | ⚠️ Setup pending | Add SNYK_TOKEN to GitHub secrets |
| Outdated Dependencies | ✅ Updated | 20 Flutter + 33 npm packages upgraded |
| Secrets Management | ⚠️ Partial | Google Maps key needs restriction |
| TLS/HTTPS | ❌ Gap | Currently HTTP only (lab environment) |
| Authentication | ❌ Not implemented | JWT + 2FA needed for production |

**Last Scan**: 2026-09-24 11:10 UTC+3
**Next Review**: Weekly (automated, pending GitHub secret setup)
**Scan Tools**: Snyk CLI 1.1307.0 + OSV-Scanner v2.5.0 + npm audit

## 🔧 Common Tasks

### When You Find a CVE

1. **Assess severity** (see CVE_MANAGEMENT.md)
2. **Check for fix**: 
   ```bash
   # Backend
   npm update <package>
   
   # Mobile
   flutter pub upgrade <package>
   ```
3. **Document the fix** in `SECURITY_FIXES.md`
4. **Verify**:
   ```bash
   ./scripts/scan-cve.sh
   ```
5. **Commit with CVE reference**:
   ```bash
   git commit -m "fix: upgrade <package> to fix CVE-YYYY-NNNNN"
   ```

### When You Need to Ignore a Finding

Only if fix is not available or doesn't apply:

1. **Document justification** in `.snyk` or `osv-scanner.toml`
2. **If accepting risk**: Add to `ACCEPTED_RISKS.md`
3. **Set expiry date** (max 6 months for High, 1 year for Medium/Low)
4. **Create tracking ticket**

Example in `.snyk`:
```yaml
ignore:
  'SNYK-JS-PACKAGE-123456':
    - '*':
        reason: 'Dev dependency, not in production'
        expires: '2026-12-31'
```

### When You Deploy

Before each deployment:
```bash
# 1. Run security scan
./scripts/scan-cve.sh

# 2. Generate fresh SBOM
./scripts/generate-sbom.sh

# 3. Verify no critical findings
# If found, fix before deploying
```

## 📖 Compliance

### Cyber Resilience Act (CRA)
- **Art. 14**: Report actively exploited vulnerabilities to CSIRT within 24h
- **Art. 20**: Maintain vulnerability handling documentation ✅
- **Annex I**: Security audit trail ✅

### Evidence for Auditors
All security decisions are documented:
1. **Scan reports**: `docs/sbom/cve-*.json`
2. **Fixes**: `SECURITY_FIXES.md` + git commits
3. **Ignores**: `.snyk` and `osv-scanner.toml` (with reasons)
4. **Accepted risks**: `ACCEPTED_RISKS.md`
5. **Process**: `CVE_MANAGEMENT.md`

## 🆘 Emergency Response

### Critical CVE Discovered

```bash
# 1. Immediate: Stop deployments
# 2. Assess impact (see CVE_MANAGEMENT.md decision tree)
# 3. Apply fix:
npm update <package>  # or flutter pub upgrade
./scripts/scan-cve.sh  # verify

# 4. Emergency deploy if in production
# 5. Document in SECURITY_FIXES.md
# 6. Notify stakeholders
```

### Security Incident
1. Contain the threat
2. Document everything
3. Follow incident response plan (TODO: create dedicated doc)
4. Report to CSIRT if CRA Art. 14 applies

## 📚 External Resources

- [Snyk Documentation](https://docs.snyk.io/)
- [OSV Scanner](https://google.github.io/osv-scanner/)
- [NIST NVD](https://nvd.nist.gov/)
- [CRA Full Text](https://eur-lex.europa.eu/eli/reg/2024/2847)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## 🔄 Maintenance

- **Weekly**: Automated scans (GitHub Actions workflow configured, pending secret setup)
- **Monthly**: Review ACCEPTED_RISKS.md
- **Quarterly**: Full security audit
- **Before release**: Mandatory security gate

**GitHub Actions Status**: ⚠️ Workflow ready, requires `SNYK_TOKEN` secret - see [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)

---

**Questions?** See [CVE_MANAGEMENT.md](CVE_MANAGEMENT.md) for detailed process.
