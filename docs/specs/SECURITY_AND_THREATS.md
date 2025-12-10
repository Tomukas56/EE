# Security & Compliance Analysis

## 1. Applicable EU Legal Acts & Regulations

### 1.1 GDPR (General Data Protection Regulation) - EU 2016/679
*   **Relevance**: We collect user emails, names, and charging history.
*   **Key Requirements**:
    *   **Consent**: Explicit opt-in for marketing or non-essential data processing.
    *   **Right to be Forgotten**: Users must be able to delete their account and all associated personal data.
    *   **Data Minimization**: Collect only what is needed (e.g., do not store GPS history if not strictly necessary for the service).
    *   **Data Locality**: Data should ideally stay within the EU/EEA.

### 1.2 PSD2 (Payment Services Directive 2) - EU 2015/2366
*   **Relevance**: In-app payments for charging sessions.
*   **Key Requirements**:
    *   **SCA (Strong Customer Authentication)**: Mandatory 2-factor authentication for payments (e.g., 3D Secure 2.0).
    *   **Open Banking**: If we integrate directly with banks, we must follow Open Banking standards.
    *   **Role**: Since we likely use a Payment Service Provider (PSP) like Stripe/Adyen, we must ensure they are PSD2 compliant and we handle tokens correctly.

### 1.3 AFIR (Alternative Fuels Infrastructure Regulation) - EU 2023/1804
*   **Relevance**: Specific to EV charging infrastructure.
*   **Key Requirements**:
    *   **Ad-Hoc Payments**: Users must be able to pay without a subscription (e.g., via card reader or dynamic QR code).
    *   **Price Transparency**: Prices must be clearly displayed *before* the session starts (per kWh, per minute, etc.).
    *   **Data Accessibility**: Static and dynamic data (availability) must be made available through National Access Points (NAPs).

### 1.4 NIS2 (Network and Information Security Directive) - EU 2022/2555
*   **Relevance**: Energy sector is considered "Critical Infrastructure".
*   **Key Requirements**:
    *   **Incident Reporting**: Significant cyber incidents must be reported to authorities (e.g., CERT) within 24 hours.
    *   **Supply Chain Security**: We must assess the security of our suppliers (CPOs, Cloud Providers).
    *   **Cyber Hygiene**: Mandatory basic security practices (MFA, backups, vulnerability management).

---

## 2. Threat Landscape & Risk Assessment

### 2.1 Threat Model (STRIDE Analysis)

| Threat Category | Description in Context | Risk Level | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **Spoofing** | Attacker impersonates a CPO to send fake "Available" status or fake pricing. | High | TLS 1.3, Certificate Pinning, API Key rotation. |
| **Tampering** | Modifying charging session data (e.g., reporting 10kWh instead of 50kWh). | Critical | Digital signatures on session logs, Server-side validation. |
| **Repudiation** | User claims they didn't authorize a charging session. | Medium | SCA (3D Secure), Audit logs of user actions. |
| **Information Disclosure** | Leaking user location history or payment details. | Critical (GDPR) | Encrypt DB at rest, Tokenize payments, Do not store GPS history. |
| **Denial of Service** | Flooding the API to prevent legitimate users from finding stations. | High | Rate limiting (Cloudflare), Caching (Hybrid Strategy). |
| **Elevation of Privilege** | Regular user accessing Admin dashboard or other users' data. | High | RBAC (Role-Based Access Control), Strict API authorization checks. |

### 2.2 Specific Compliance Threats

1.  **Non-Compliance with AFIR**:
    *   *Threat*: App shows different price than the CPO charges.
    *   *Consequence*: Legal fines, loss of trust.
    *   *Mitigation*: Real-time price check before session start (part of Hybrid Strategy).

2.  **GDPR Breach**:
    *   *Threat*: Database dump exposed publicly.
    *   *Consequence*: Fines up to 4% of turnover.
    *   *Mitigation*: Minimal data collection, Encryption, Penetration testing.

3.  **PSD2 Violation**:
    *   *Threat*: Processing payments without 2FA.
    *   *Consequence*: Declined transactions, fines.
    *   *Mitigation*: Use Stripe/Adyen SDKs with built-in SCA handling.

## 3. Security Requirements Checklist

- [ ] **Authentication**: Implement OAuth 2.0 / OIDC.
- [ ] **Transport Security**: Enforce HTTPS (TLS 1.2+) everywhere.
- [ ] **Data at Rest**: Enable AES-256 encryption on PostgreSQL volumes.
- [ ] **Secrets Management**: Never commit `.env` files; use Vault or Cloud Secret Manager.
- [ ] **Input Validation**: Sanitize all inputs to prevent SQL Injection (use ORM).
- [ ] **Logging**: Centralized logging for security audits (excluding sensitive data).
