# CVE Management Process

## Overview
This document defines how we handle security vulnerabilities (CVEs) detected by Snyk, OSV-Scanner, and npm audit.

## Scanning Schedule

### Automated Scans
- **Pre-commit**: Run `./scripts/scan-cve.sh` (configured as git hook)
- **Weekly**: Automated GitHub Actions (future)
- **Before release**: Mandatory gate

### Manual Scans
```bash
# Full scan (Snyk + OSV + npm audit)
./scripts/scan-cve.sh

# Override to allow findings (dev testing only)
EE_CVE_ALLOW=1 ./scripts/scan-cve.sh
```

## Vulnerability Triage Process

### 1. Severity Classification
| Severity | Action | Timeline |
|----------|--------|----------|
| **Critical** | Immediate fix | < 24 hours |
| **High** | Priority fix | < 1 week |
| **Medium** | Planned fix | < 1 month |
| **Low** | Backlog | Next sprint |

### 2. Analysis Steps
For each finding:
1. **Verify impact** - Does it affect our usage?
2. **Check exploitability** - Is it exploitable in production?
3. **Review fix** - Is a patch/upgrade available?
4. **Document decision** - Record in `SECURITY_FIXES.md`

### 3. Decision Matrix

```
┌─────────────────────────────────────────────────────────┐
│ Finding Analysis Decision Tree                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Is patch available? ─YES→ Upgrade immediately           │
│         │                                                │
│        NO                                                │
│         ↓                                                │
│ Is workaround available? ─YES→ Apply + Document         │
│         │                                                │
│        NO                                                │
│         ↓                                                │
│ Is it dev-only dependency? ─YES→ Ignore with reason     │
│         │                                                │
│        NO                                                │
│         ↓                                                │
│ Is it false positive? ─YES→ Ignore with reason          │
│         │                                                │
│        NO                                                │
│         ↓                                                │
│ Document risk + Create ticket for vendor                │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Fixing Vulnerabilities

### Option 1: Upgrade Dependency
```bash
# Backend (Node.js)
cd backend
npm update <package-name>
npm audit fix

# Mobile (Flutter)
cd mobile
flutter pub upgrade <package-name>
```

### Option 2: Ignore with Justification
Only use when fix is not available or finding doesn't apply.

**Snyk ignore (.snyk):**
```yaml
ignore:
  'SNYK-JS-PACKAGE-123456':
    - '*':
        reason: 'Dev dependency, not in production bundle'
        expires: '2026-12-31'
```

**OSV ignore (osv-scanner.toml):**
```toml
[[IgnoredVulns]]
id = "GHSA-xxxx-yyyy-zzzz"
reason = "Dev-only dependency, not shipped in APK"
```

### Option 3: Document Accepted Risk
For findings that cannot be fixed immediately:

1. Create ticket in issue tracker
2. Document in `docs/security/ACCEPTED_RISKS.md`
3. Set review date
4. Notify stakeholders

## Documentation Requirements

### After Each Fix
Update `docs/security/SECURITY_FIXES.md`:

```markdown
## [Date] - CVE-YYYY-NNNNN

**Severity**: High
**Package**: package-name@1.2.3
**Fixed in**: package-name@1.2.4
**Action**: Upgraded dependency
**Verification**: Re-ran scan, finding resolved
**Commit**: abc1234
```

### Quarterly Review
1. Review all ignored findings
2. Check for new patches
3. Update expiry dates
4. Archive fixed issues

## Compliance Requirements

### Cyber Resilience Act (CRA)
- **Art. 14**: Report findings to CSIRT within 24h if actively exploited
- **Art. 20**: Maintain vulnerability handling process documentation
- **Annex I**: Keep audit trail of all security decisions

### Evidence Collection
All CVE management activities must be documented:
- Scan reports (automated, saved to `docs/sbom/`)
- Fix commits (reference CVE in commit message)
- Ignore justifications (in `.snyk` and `osv-scanner.toml`)
- Accepted risks (in `ACCEPTED_RISKS.md`)

## Reporting

### Internal Stakeholders
- **Monthly**: CVE summary to project lead
- **On Critical**: Immediate notification

### External (if required)
- **CSIRT**: Art. 14 incidents
- **Customers**: Security advisories (if product is public)

## Tools & Commands

### Generate Reports
```bash
# Full CVE scan with reports
./scripts/scan-cve.sh

# View Snyk web dashboard
snyk monitor  # Requires SNYK_TOKEN
```

### View Current Findings
```bash
# Backend findings
cat docs/sbom/cve-snyk-backend.json | jq '.vulnerabilities'

# Mobile findings  
cat docs/sbom/cve-snyk-mobile.json | jq '.vulnerabilities'

# OSV findings (human-readable)
cat docs/sbom/cve-osv.md
```

## Emergency Response

### Critical CVE Discovered
1. **Immediate** - Stop deployments
2. **< 1 hour** - Assess impact
3. **< 4 hours** - Apply fix or workaround
4. **< 24 hours** - Deploy patched version
5. **< 48 hours** - Document and report

## References
- [Snyk Docs](https://docs.snyk.io/)
- [OSV Scanner](https://google.github.io/osv-scanner/)
- [CRA Text](https://eur-lex.europa.eu/eli/reg/2024/2847)
- [NIST CVE Database](https://nvd.nist.gov/)
