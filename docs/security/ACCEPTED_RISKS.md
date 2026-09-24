# Accepted Security Risks

This document tracks security findings that have been accepted as risks (not immediately fixed).

**Purpose**: CRA compliance - document risk acceptance decisions with justification.

## Active Accepted Risks

### Template
```markdown
## [ID] - Brief Description

**Severity**: High/Medium/Low
**Component**: backend/mobile
**Package**: package-name@version
**Finding**: Description
**Risk**: Why this is a concern
**Justification**: Why we accept this risk
**Mitigation**: What we're doing to reduce risk
**Review Date**: When to revisit this decision
**Decision By**: Name/Role
**Ticket**: Link to tracking issue
```

---

## [Current] - No Accepted Risks

All current findings are either:
- ✅ Fixed
- ✅ Ignored with technical justification (see `.snyk` and `osv-scanner.toml`)
- ✅ False positives (documented in ignore configs)

---

## [Historical Example for Reference]

<!--
## SNYK-JS-EXAMPLE-123456 - Prototype Pollution in minimist

**Severity**: Medium
**Component**: backend (dev dependency)
**Package**: minimist@1.2.5 (via test framework)
**Finding**: Prototype pollution vulnerability
**Risk**: Could allow code injection if attacker controls CLI arguments
**Justification**: 
- Only used in development/testing environment
- Not included in production bundle
- No user input reaches this code path
**Mitigation**: 
- Isolated to dev environment
- Monitoring for patches
- Will upgrade when compatible version available
**Review Date**: 2026-12-31
**Decision By**: Security Lead
**Ticket**: #123
-->

---

## Risk Acceptance Process

Before adding to this document:

1. ✅ Verify no patch/fix available
2. ✅ Confirm it affects our usage (not false positive)
3. ✅ Document risk and mitigation
4. ✅ Get approval from security lead
5. ✅ Set review date (max 6 months for High, 1 year for Medium/Low)
6. ✅ Create tracking ticket
7. ✅ Add to ignore config with reference to this doc

## Quarterly Review

Review all accepted risks quarterly:
- Check for new patches
- Re-assess risk level
- Update mitigation measures
- Extend or close risk acceptance
