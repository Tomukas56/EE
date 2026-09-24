# Security Fixes Log

This file tracks all security vulnerabilities fixed in the project.

**Purpose**: CRA compliance (Art. 20) - maintain audit trail of vulnerability handling.

## Format
```markdown
## [YYYY-MM-DD] - CVE/GHSA/SNYK ID

**Severity**: Critical/High/Medium/Low
**Component**: backend/mobile/infra
**Package**: package-name@vulnerable-version
**Vulnerability**: Brief description
**Fixed in**: package-name@patched-version OR "Workaround applied"
**Action**: Upgraded/Patched/Workaround/Configuration change
**Verification**: How we confirmed the fix
**Commit**: Git commit hash
**References**: Links to CVE, GitHub advisory, etc.
```

---

## [2026-09-24] - No Critical Findings

**Scan Date**: 2026-09-24
**Scanned by**: Snyk (authenticated) + OSV-Scanner + npm audit
**Backend**: ✅ 0 high/critical vulnerabilities (94 dependencies tested)
**Mobile**: ✅ 0 high/critical vulnerabilities (SBOM scan)
**Status**: Clean scan - all security gates passed

**Tools Configuration**:
- Snyk CLI 1.1307.0 with API token authentication
- OSV-Scanner v2.5.0
- npm audit (built-in)

**Scanned Files**:
- Backend: `package-lock.json` (181 packages)
- Mobile: `pubspec.lock` (144 packages), SBOM analysis

**Reports**:
- `docs/sbom/cve-snyk-backend.json`
- `docs/sbom/cve-snyk-mobile.json`
- `docs/sbom/cve-osv.json`
- `docs/sbom/cve-npm-audit.json`

**CI/CD**: GitHub Actions workflow configured for weekly automated scans

---

## [2026-09-23] - No Critical Findings

**Scan Date**: 2026-09-23
**Scanned by**: Snyk + OSV-Scanner + npm audit
**Backend**: ✅ 0 high/critical vulnerabilities
**Mobile**: ✅ 0 high/critical vulnerabilities
**Status**: Clean scan

**Reports**:
- `docs/sbom/cve-snyk-backend.json`
- `docs/sbom/cve-snyk-mobile.json`
- `docs/sbom/cve-osv.md`

---

## [Future Fixes Will Be Logged Here]

<!-- 
Example entry:

## [2026-09-25] - CVE-2026-12345

**Severity**: High
**Component**: backend
**Package**: express@4.17.1
**Vulnerability**: Prototype pollution in query parser
**Fixed in**: express@4.18.2
**Action**: Upgraded dependency
**Verification**: 
- Re-ran `./scripts/scan-cve.sh` - finding resolved
- Integration tests passed
- Manual verification: tested affected endpoint

**Commit**: abc123def456
**References**: 
- https://nvd.nist.gov/vuln/detail/CVE-2026-12345
- https://github.com/expressjs/express/security/advisories/GHSA-xxxx
-->
