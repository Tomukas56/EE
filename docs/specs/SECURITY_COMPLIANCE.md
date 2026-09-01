# Energy Eniwhere — Security & Compliance Document

**Product:** Energy Eniwhere (EE)  
**Package:** `com.eniwhere.energy`  
**Manufacturer (intended):** Energy Eniwhere, Lithuania  
**Document status:** Working control — not a CE declaration, GDPR certification, or PCI ROC  
**Version:** 1.0  
**Date:** 2026-09-01  
**Related:** [PRD.md](../PRD.md) §5–7, [SECURITY_AND_THREATS.md](SECURITY_AND_THREATS.md), in-app Agreement (`mobile/lib/legal/service_agreement.dart`)

This document is the security-requirements register for EE. It states **which laws apply**, **when they apply**, **what we must do**, and **what is still a gap**. It does **not** claim that EE is certified or production-ready.

---

## 1. Product and two operating regimes

EE is an **EU consumer mobile app** (Flutter) plus a **Node.js API** and PostgreSQL. It is an **eMSP-style aggregator**: station search, later session and payment. It is **not** a charge-point operator (CPO) and does not run charging hardware.

The API that the app needs in order to list stations, accept crowd reports, and (later) start sessions is a **remote data processing solution** in the sense of the Cyber Resilience Act: without it, the product cannot perform those functions.

| Regime | What it is | What we may claim |
|--------|------------|-------------------|
| **Lab** | USB/Wi-Fi debug build, LAN HTTP API, owner PIN | Functional MVP for internal QA |
| **Union market** | Google Play / App Store (or any commercial supply in the EU, paid or free) | Only after the controls in §4–§6 that are marked mandatory for that regime |

USB lab builds are **not** “placing on the market”. Listing the app on an EU store **is**.

---

## 2. Requirement inventory (what applies)

### 2.1 Product cybersecurity — Cyber Resilience Act

| Item | Detail |
|------|--------|
| **Law** | Regulation **(EU) 2024/2847** — Cyber Resilience Act (CRA). Lithuanian: **Kibernetinio atsparumo aktas**. |
| **Official summary** | [European Commission CRA summary](https://digital-strategy.ec.europa.eu/en/policies/cra-summary) |
| **Why it applies** | The mobile app is a **product with digital elements** (software whose reasonably foreseeable use includes a network connection). The EE backend is in scope as **remote data processing** designed for that product. Manufacturer obligations apply when EE is **made available on the Union market** (Play/App Store), including if free of charge. |
| **Role** | EE is the **manufacturer** (develops and will market the app under its name). |
| **Class (working assumption)** | **Default product** (self-assessment, Module A), unless a later Commission act or Annex III/IV listing reclassifies the core functionality as an *important* or *critical* product. Reassess before store launch with legal counsel. |
| **Not CRA** | Pure internal lab use; open-source *steward* rules (we are not an OSS steward for EE). OCPP hardware is out of scope (we are not a CPO). |

#### Timeline (Article 71)

| Date | Obligation |
|------|------------|
| **10 Dec 2024** | CRA in force |
| **11 Jun 2026** | Notified-body / Chapter IV machinery (Member States) |
| **11 Sep 2026** | **Article 14 reporting** — actively exploited vulnerabilities and severe security incidents: early warning **24 h**, main notification **72 h**, via the ENISA CRA single reporting platform and the CSIRT of the Member State of main establishment (Lithuania: **NKSC / CERT-LT**). Applies to products **already on the Union market**, including those placed before Dec 2027. |
| **11 Dec 2027** | Full application: Annex I essential requirements, technical documentation, **EU declaration of conformity**, **CE marking**, support period. Products placed on the market from this date must comply. Products already on the market before this date are pulled in if they undergo a **substantial modification**. |

**Lab implication (today, 1 Sep 2026):** Article 14 starts in days, but only for products **made available on the market**. Do not publish EE on Play/App Store until a reporting mailbox, CSIRT contact, and 24h/72h procedure exist. Building those processes now is mandatory work, not optional polish.

#### Annex I — essential requirements mapped to EE

**Part I — properties of the product (app + API that it depends on)**

| CRA essential requirement (Annex I Part I, summarised) | EE interpretation | Status 2026-09-01 |
|--------------------------------------------------------|-------------------|-------------------|
| Appropriate cybersecurity for intended use | Risk assessment documented; secure-by-design for map, account, later payments | **Gap** — no CRA risk assessment file |
| No known exploitable vulnerabilities at delivery | Track CVEs in Flutter/Node/OS deps; patch before store | **Partial** — local Snyk + OSV + npm audit gate (`scripts/scan-cve.sh`); no CI / store attestation |
| Secure by default | No debug bypass, no owner PIN, HTTPS, least privilege | **Gap (prod)** — lab PIN, cleartext HTTP, local session bypass |
| Security updates during support period | Play/App Store updates; API patches; stated end-of-support date | **Gap** — no support-period statement |
| Confidentiality (encryption in transit / at rest as needed) | TLS 1.2+ prod; DB encryption; no PAN | **Partial** — Prisma/ORM; TLS only in prod plan; session in SharedPreferences |
| Integrity of software and data | Signed store builds; server-side validation; no unsigned sideload as the production channel | **Partial** |
| Data minimisation | Location only for nearby/arrival; no raw cards | **Partial** — Agreement states purpose; no DPIA |
| Availability / DoS resilience proportionate to risk | Rate limit, hosting | **Gap** |
| Minimise attack surface | No unused ports/APIs; restrict Maps key | **Partial** |
| Reduce impact of incidents | Logging (no secrets), backups, rollback | **Gap** |
| Security event recording | Authn failures, payments (no PAN), admin actions | **Gap** |
| User can reset / withdraw data securely | Account deletion / DSR | **Gap** |

**Part II — vulnerability handling (manufacturer processes)**

| CRA essential requirement (Annex I Part II, summarised) | EE interpretation | Status |
|---------------------------------------------------------|-------------------|--------|
| Identify and document components and vulnerabilities | Machine-readable **SBOM** (app + backend); dependency scanning | **Partial** — CycloneDX 1.6 in `docs/sbom/`; Snyk + OSV + npm audit locally; no CI |
| Address and remediate without undue delay | Patch SLA (e.g. critical ≤ 7 days) | **Gap** |
| Coordinated vulnerability disclosure (CVD) | Public security@ contact; policy on a website | **Gap** |
| Share information on fixed issues | Release notes / advisory | **Gap** |
| Regular security tests | SAST/DAST, dependency audit, periodic pen-test before store | **Gap** — lab QA is not this |
| Public disclosure of fixed vulnerabilities | After patch is available | **Gap** |

#### Manufacturer duties (Article 13) we treat as EE backlog

1. Documented **cybersecurity risk assessment** (update during the support period).  
2. **Due diligence on third-party components** (Flutter, Node, Google Maps, Firebase, Stripe, OCM, Postgres).  
3. **Technical documentation** (kept ≥ 10 years after placing on the market or for the support period, whichever is longer).  
4. Conformity assessment → **EU declaration of conformity** → **CE marking** (from 11 Dec 2027 for market placement).  
5. Identification of the product (version/build), manufacturer name, postal and email contact, **support-period end date** (month and year) at purchase. Support period **at least five years**, unless expected use is shorter.  
6. User instructions (Annex II): intended use, security recommendations, how to report vulnerabilities.

CE marking of a **mobile app** follows Commission guidance for software (electronic marking / accompanying documentation). Exact placement will follow the implementing practice available at store launch; the **substance** (Annex I + technical file) is not optional.

---

### 2.2 Personal data and privacy (mandatory once personal data is processed)

| Standard | Why it applies to EE | Status |
|----------|----------------------|--------|
| **GDPR** (EU 2016/679) + Lithuanian **BDAR** | Google account, location, crowd reports, later payment metadata | **Gap** — Agreement exists; no privacy policy, DSR, DPIA, RoPA |
| **ePrivacy** 2002/58/EC (as implemented) | Device location and identifiers | **Partial** — OS permission; no consent log |
| **Consumer law** (2011/83, 93/13, Lithuanian CK) | Readable contract; cannot waive mandatory rights | **Partial** — in-app Agreement |

GDPR already applies to **lab** processing of Google identity, location, and crowd reports. CRA does not replace GDPR.

### 2.3 Payments (mandatory before the first real charge)

| Standard | Why it applies | Status |
|----------|----------------|--------|
| **PSD2** (EU 2015/2366) + **Mokėjimo įstatymas** | SCA for electronic payments | **Not started** — no Payment Sheet; Stripe key empty |
| **PCI DSS v4.0** — target **SAQ A** | Cards never on EE servers or in Flutter forms | **Not started** as a programme; **no PAN collection** (good) |
| Stripe + Apple Pay / Google Pay terms | Wallet sheet | **Not started** |

EE will **not** become a payment institution. SCA is Stripe + wallet. See PRD §7.

### 2.4 Application and API security (mandatory for store / pen-test)

| Standard | Why it applies | Status |
|----------|----------------|--------|
| **OWASP MASVS 2.0** / Mobile Top 10 (2024) | Mobile app | **Gap** |
| **OWASP ASVS 4.0** | API | **Gap** — open station list; crowd without user JWT; lab PIN |
| **TLS 1.2+** (prefer 1.3) | Data in transit | **Gap (prod)** — lab HTTP allowed |
| **OAuth 2.0 / OIDC** | Google Sign-In | **Partial** |
| Secure storage (Keystore / Keychain) | Tokens | **Gap** — SharedPreferences |

MASVS/ASVS are how we **implement** many CRA Annex I controls in software. They are not a substitute for the CRA legal file.

### 2.5 Store and third-party policies

Google Play, Apple App Store, Google Maps, Firebase, Open Charge Map licence, Stripe. Maps API key must be restricted (package + SHA-1 / iOS bundle).

### 2.6 EV / roaming (when CPO links go live)

| Standard | Status |
|----------|--------|
| **OCPI 2.2.1** security | **N/A** — no CPO link; occupancy UNKNOWN |
| **AFIR** (EU 2023/1804) price honesty | Display operator price; do not invent a tariff. Ad-hoc payment at the column is the **CPO’s** duty, not EE’s. |
| **OCPP** | **Does not apply** (hardware protocol) |

### 2.7 Organisational — not claimed, reassess later

| Standard | Position |
|----------|----------|
| **ISO/IEC 27001** / **27701** | Useful later for B2B; **not** claimed |
| **NIS2** / Lithuanian Kibernetinio saugumo įstatymas | Unlikely for a small consumer app; reassess if EE becomes an essential/important entity |
| **DORA** | Financial entities — **not EE** unless it becomes a regulated PSP |
| **EN 301 549 / WCAG 2.2** | Store expectation; not audited |

---

## 3. Security requirements EE commits to (product rules)

These are the engineering rules. CRA, GDPR, and store review all expect them.

1. Production builds: Google (or later Apple) sign-in only — **no** “continue on this device” bypass.  
2. **No** raw card data in EE code, logs, or database.  
3. Location only for nearby stations, arrival reports, and later routing; user may refuse.  
4. User-marked stations stay unpublished until the owner confirms the physical site.  
5. Production API **HTTPS only**; Maps/Firebase keys restricted by app identity.  
6. Processors listed in the Agreement.  
7. Crowd reports are personal data (reporter id).  
8. **CRA:** no store release without: risk assessment, SBOM for that build, CVD contact, Article 14 reporting playbook, and a stated security-support period. From **11 Dec 2027**, also CE / EU declaration of conformity for Union-market versions.

Lab-only: owner PIN (`X-Owner-Pin`), cleartext LAN API, debug Google Maps key. These **must be removed** before market placement.

---

## 4. Gap register (honest status, 2026-09-01)

| ID | Control | Required by | When | Status |
|----|---------|-------------|------|--------|
| C-01 | CRA cybersecurity risk assessment | CRA Art. 13, Annex I | Before market; living document | **Gap** |
| C-02 | SBOM + third-party due diligence | CRA Annex I Part II | Before market | **Partial** — CycloneDX + `./scripts/scan-cve.sh` (Snyk high/critical + OSV + npm). No CI. |
| C-03 | CVD policy + security contact | CRA Annex I Part II | Before market; needed for Art. 14 | **Gap** |
| C-04 | Art. 14 24h/72h reporting to CSIRT + ENISA | CRA Art. 14 | **From 11 Sep 2026** for products **on the market** | **Gap** — do not list on stores until ready |
| C-05 | Support period (≥ 5 years unless shorter use) published | CRA Art. 13 | At purchase / store listing | **Gap** |
| C-06 | Technical file, EU DoC, CE | CRA | **From 11 Dec 2027** for market placement | **Gap** — plan now |
| C-07 | Secure defaults (no PIN, no HTTP, no debug bypass) | CRA + MASVS | Store | **Gap (prod)** |
| G-01 | GDPR lawful basis, privacy notice, DSR, DPIA, RoPA | GDPR/BDAR | Already (personal data) | **Gap** |
| G-02 | Location consent log | ePrivacy / GDPR | Already | **Partial** |
| S-01 | TLS production | ASVS / CRA confidentiality | Store | **Gap (prod)** |
| S-02 | OIDC complete (Firebase SHA-1) | Auth | Store | **Partial** |
| S-03 | Token in Keystore/Keychain | MASVS / CRA | Store | **Gap** |
| S-04 | API authentication / authorisation | ASVS / CRA | Store | **Gap** |
| P-01 | PCI SAQ A + Stripe Payment Sheet | PCI / PSD2 | First live payment | **Not started** |
| P-02 | SCA via wallet | PSD2 | First live payment | **Not started** |
| M-01 | Maps key restriction | Maps ToS | Store | **Partial** |
| O-01 | OCPI | OCPI | When CPO connected | **N/A** |

---

## 5. How this relates to testing and vulnerabilities

| Activity | Allowed now? |
|----------|----------------|
| Laboratory functional QA (map, stations, crowd, agreement) | **Yes** |
| Payment / session / wallet tests as if live | **No** — nothing real |
| Vulnerability / MASVS-ASVS review | **Next** after lab QA; findings feed the CRA risk assessment (C-01) |
| Claiming “CRA compliant” or CE | **No** until §4 C-01…C-07 and Dec 2027 duties are met |
| EU store listing | **No** until C-03, C-04, G-01, S-01, S-04 at minimum, and PIN/HTTP/debug bypass removed |

---

## 6. Roadmap (compliance, not feature work)

1. **Immediately (before any store listing):** security contact, CVD page, Art. 14 playbook (CSIRT-LT + ENISA platform), disable lab PIN and cleartext in release flavour.  
2. **With first production backend:** HTTPS, JWT/OIDC on mutating APIs, Keystore session, privacy policy + DSR.  
3. **Before first payment:** Stripe test → live, Payment Sheet, SAQ A evidence, no PAN in logs.  
4. **Continuous:** SBOM per release, dependency CVE gate, CRA risk assessment updates.  
5. **By 11 Dec 2027 (if EE is on the Union market):** Module A (or notified body if reclassified), technical documentation, EU declaration of conformity, CE marking, support-period date on the listing.

---

## 7. Document control

| | |
|--|--|
| Owner | Energy Eniwhere |
| Review | Before every store submission and at least annually |
| Legal note | This is an engineering register. Classification (default vs important product), CE placement for software, and Art. 14 operational details must be confirmed with qualified EU product-security counsel. |

**This document is not a certificate.**
