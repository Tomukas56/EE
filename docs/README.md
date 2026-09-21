# Energy Eniwhere Documentation

This directory contains **mandatory documentation** required for **CRA (Cyber Resilience Act)** compliance and **Secure Software Development Lifecycle (SDLC)** practices.

---

## 📋 Core Documentation

### Product Requirements
- **[PRD.md](PRD.md)** - Product Requirements Document
  - Complete product specification
  - Security requirements (§5-7)
  - Gap assessment (§6)
  - Authentication architecture (§11)
  - Offline mode (§2.7)
  - Online aggregation architecture (§10)

### Security & Compliance
- **[specs/SECURITY_COMPLIANCE.md](specs/SECURITY_COMPLIANCE.md)** - CRA Compliance Register
  - Article-by-article compliance status
  - Manufacturer obligations
  - Timeline for CE/DoC
  
- **[specs/SECURITY_AND_THREATS.md](specs/SECURITY_AND_THREATS.md)** - Threat Model
  - Identified security threats
  - Attack vectors
  - Mitigation strategies

- **[specs/SRD.md](specs/SRD.md)** - Security Requirements Document
  - Functional security requirements
  - Non-functional security requirements
  - Security controls

### Architecture & Design
- **[specs/DFD.md](specs/DFD.md)** - Data Flow Diagrams
  - Production architecture
  - Data flows between components
  - Trust boundaries

- **[architecture/system_architecture.md](architecture/system_architecture.md)** - System Architecture
  - High-level system design
  - Component relationships
  - Technology stack

- **[specs/ADR-001-Data-Strategy.md](specs/ADR-001-Data-Strategy.md)** - Architecture Decision Record
  - Key architectural decisions
  - Rationale and trade-offs
  - Consequences

### Data & Integration
- **[specs/DATA_SOURCES.md](specs/DATA_SOURCES.md)** - Data Sources & Contracts
  - Third-party data sources
  - Licensing requirements (CC BY 4.0, ODC-BY)
  - CPO/hub contracts
  - Security boundary enforcement ("app never talks to CPO APIs")

---

## 🔒 SBOM & CVE Tracking (CRA Art. 14)

**Directory:** `sbom/`

Software Bill of Materials and vulnerability tracking as required by CRA Article 14:

### SBOM Files
- **ee-backend.cdx.json** - Backend SBOM (CycloneDX format)
- **ee-mobile.cdx.json** - Mobile app SBOM (CycloneDX format)
- **README.md** - SBOM generation and usage instructions

### CVE Reports
- **cve-snyk.md** - Snyk vulnerability scan results
- **cve-snyk-backend.json** - Backend vulnerabilities (JSON)
- **cve-snyk-mobile.json** - Mobile vulnerabilities (JSON)
- **cve-osv.md** - OSV vulnerability scan results
- **cve-osv.json** - OSV scan data (JSON)
- **cve-npm-audit.json** - npm audit results

**Update frequency:** Before each release via `./scripts/scan-cve.sh`

---

## 🐛 Issue Tracking

- **[specs/PROBLEMS.txt](specs/PROBLEMS.txt)** - Active issues and problems
  - Current blockers
  - Known bugs
  - Technical debt
  - **Note:** This file is gitignored

---

## 📂 What Was Removed

The following files were removed as **duplicates or non-essential** for CRA/SDLC:

- ❌ `memory-bank.md` - Duplicate (exists as `memory-bank/` directory)
- ❌ `project_rules.md` - Duplicate (exists in `.cursor/rules/`)
- ❌ `scenarios.md` - Redundant (scenarios covered in PRD.md)
- ❌ `specs/WORK_PLAN.md` - Project planning (not a compliance requirement)
- ❌ `ANDROID_STUDIO_SETUP.md` - Development setup (not security documentation)

---

## 🎯 Purpose

This documentation structure ensures:

1. **CRA Compliance** - Article 14 reporting, SBOM, CVE tracking, manufacturer obligations
2. **Secure SDLC** - Threat modeling, security requirements, architecture decisions
3. **Traceability** - Clear requirements → design → implementation path
4. **Audit Readiness** - All compliance evidence in one place
5. **Third-Party Transparency** - Data sources, licenses, and contracts documented

---

## 🔄 Maintenance

- **PRD updates:** When product requirements change
- **Security docs:** After security reviews or threat model updates
- **SBOM/CVE:** Before every release (`npm run sbom` + `./scripts/scan-cve.sh`)
- **Architecture:** When significant technical decisions are made (create new ADR-XXX)
- **PROBLEMS.txt:** Updated continuously during development

---

**Last Updated:** 2026-09-21
