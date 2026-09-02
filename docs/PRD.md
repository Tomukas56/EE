# Product Requirements Document (PRD) - Energy Eniwhere

## 1. Introduction
Energy Eniwhere is a comprehensive mobile application for Electric Vehicle (EV) owners, enabling seamless charging station discovery, session management, route planning, and payments.

## 2. Core Requirements

### 2.1 User Authentication & Onboarding
*   **Sign Up/Login**: Support for Google, Apple, and Email auth.
*   **Mandatory Profile Setup**:
    *   **User Details**: Name, Email, Phone.
    *   **Vehicle Profile**: Users **MUST** register their vehicle to use the app.

### 2.2 Vehicle Management
*   **Mandatory Vehicle Data**:
    *   **Make & Model**: e.g., Tesla Model 3, Nissan Leaf.
    *   **Battery Capacity**: Total usable battery in kWh.
    *   **Max Range**: WLTP range in km/miles.
    *   **Connector Type**: CCS2, Type 2, CHAdeMO.
    *   **Average Consumption**: kWh/100km (optional, can be derived).
*   **Use Cases**:
    *   Route planning calculations.
    *   Filtering compatible stations.

### 2.3 Smart Route Planning
*   **Input**:
    *   Start Location (Current or Custom).
    *   Destination.
    *   **Initial State of Charge (SoC)**: Percentage of battery at start (e.g., 80%).
*   **Logic**:
    *   Calculate max driving distance based on Vehicle Profile and Initial SoC.
    *   If `Distance > Current Range`:
        *   Identify necessary charging stops along the route.
        *   Select stations based on connector compatibility and charging speed.
        *   Optimize for minimum travel time (Driving + Charging).
*   **Output**:
    *   Visual route map with charging stops.
    *   **Navigate** opens Google Maps driving directions (waypoint when a charging stop is suggested).
    *   Estimated total duration.
    *   Estimated charging cost.
    *   Energy consumption estimate.

### 2.4 Charging Station Discovery
*   Real-time map and list of stations.
*   Filter by country, connector, speed (kW), and (when available) occupancy.
*   Map chrome (lab, approved 2026-09-02): search at the top with a **list of name/address matches**; compact **country / plug / kW** icons on the **right**, same column as zoom `+` `−`, nearest, and my location. Google Maps is the basemap.
*   "Nearest Station" quick action (same map, centered on the device).
*   **Mark a new station**: a driver can pin a missing column. The pin is **not** shown on the public map until the **app owner confirms the physical location**.
*   **Arrival check**: when the driver arrives, the app asks (Yes / No / Dismiss): is the station working? are there free connectors?

### 2.5 Charging Session Control
*   Start/Stop charging via app.
*   Real-time monitoring (kWh delivered, current cost).
*   History of sessions under the **Payments** root tile (subtitle: Sessions · History), not a tile named History.

### 2.6 Payments
*   Wallet system (Stripe/Payment Gateway) — **target**.
*   Automatic payments after session — **target**.
*   Payment history and invoices.
*   Lab: show whether this **device wallet** is linked (Google Wallet / Google Pay on Android, Apple Wallet / Apple Pay on iOS). Lab builds are **not linked**; receipts stay in-app.

## 3. Technical Constraints
*   **Platform**: Flutter (iOS/Android/Web).
*   **Backend**: Node.js + Prisma + PostgreSQL.
*   **Maps**: Google Maps Platform (Maps SDK, later Directions / Places).
*   **Station catalogue (today)**: Open Charge Map (Lithuania, Latvia, Estonia, Poland) + owner-confirmed user submissions.
*   **Payments (target)**: Stripe Payment Sheet + Apple Pay / Google Pay (device wallet). EE must not store raw card numbers.

## 4. Success Metrics
*   Successful route calculation with <5% error in energy estimation.
*   100% of active users have a registered vehicle profile.
*   Seamless charging experience for supported CPOs.

---

## 5. Security and compliance standards (this product class)

Energy Eniwhere is an **EU consumer mobile app**, an **EV charging aggregator (eMSP-style)**, and (when payments go live) a **payment-initiating client**. It is **not** a CPO and does not operate charging hardware. The following standards apply. Formal certification is a later milestone; the gap table in §6 and [SECURITY_COMPLIANCE.md](specs/SECURITY_COMPLIANCE.md) are the current honest status.

### 5.1 Personal data and privacy (mandatory for launch in LT/EU)

| Standard | Why it applies |
|----------|----------------|
| **GDPR** (EU 2016/679) and Lithuanian **BDAR** | Account (Google id, name, email, photo), location, vehicle profile, crowd reports, payment metadata. Need lawful basis, purpose limitation, DPA with processors, records of processing, DPIA for location + payments, DSR (access / erasure / portability), breach notification (72h). |
| **ePrivacy Directive** 2002/58/EC (as implemented) | Device location, identifiers, any tracking. Location is optional; refuse = nearest-column off. |
| **Consumer law** (EU 2011/83, unfair terms 93/13, Lithuanian CK) | Agreement must be readable; cannot waive mandatory consumer rights. |

### 5.2 Payments (mandatory before live charging payments)

| Standard | Why it applies |
|----------|----------------|
| **PSD2** (EU 2015/2366) and Lithuanian **Mokėjimo įstatymas** | Strong Customer Authentication (SCA) for electronic payments. Use a licensed PSP (Stripe) rather than becoming a payment institution. |
| **PCI DSS v4.0** | Card data. Target model: **SAQ A** — card numbers never touch EE servers or the Flutter app; Stripe + Apple Pay / Google Pay collect them. Do not log PANs, CVV, or full track data. |
| **EBA guidelines** on ICT and security risk (for the PSP; EE follows their integration rules). |

### 5.3 Application and API security

| Standard | Why it applies |
|----------|----------------|
| **OWASP MASVS 2.0** and **OWASP Mobile Top 10 (2024)** | Auth, storage, network, reverse engineering, privacy. |
| **OWASP ASVS 4.0** (API) | Backend: authn/z, injection, session, error handling. |
| **TLS 1.2+** (prefer **1.3**) for all production traffic | Data in transit. Local HTTP to a LAN API is **dev only**. |
| **Regulation (EU) 2024/2847 Cyber Resilience Act (CRA)** / Lithuanian **Kibernetinio atsparumo aktas** | The Flutter app is a **product with digital elements**; the EE API is **remote data processing** without which the app cannot list stations or take reports. Manufacturer duties (Annex I, vulnerability handling, SBOM, support period, from 11 Sep 2026 Art. 14 reporting for products on the Union market, from 11 Dec 2027 CE / EU declaration) apply when EE is made available on Play/App Store. Lab USB builds are not placing on the market. Full register: [SECURITY_COMPLIANCE.md](specs/SECURITY_COMPLIANCE.md). |
| **OAuth 2.0 / OIDC** | Google Sign-In. |
| **Secure storage** | Tokens in Android Keystore / iOS Keychain — not SharedPreferences in production. |

### 5.4 Platform and third-party policies (store / SDK)

| Policy | Why it applies |
|--------|----------------|
| **Google Play** User Data, Data safety, and API policies | Android distribution. |
| **Apple App Store Review Guidelines** + **App Tracking Transparency** | iPhone distribution. |
| **Google Maps Platform Terms** + attribution | Map SDK / key restrictions (package + SHA-1 / bundle id). |
| **Firebase / Google Identity** terms | Sign-In. |
| **Open Charge Map** data licence and attribution | Static POIs. |
| **Stripe** + **Apple Pay** + **Google Pay** terms | Wallet payments. |

### 5.5 EV / roaming domain (when CPO links go live)

| Standard | Why it applies |
|----------|----------------|
| **OCPI 2.2.1** (security tokens, TLS, role credentials) | Talking to CPOs / hubs. |
| **AFIR** (EU 2023/1804) price-transparency spirit | Display operator price honestly; we are not the CPO but must not invent a price. |
| **OCPP** | Does **not** apply to EE (CPO hardware protocol). |

### 5.6 Organisational / optional certifications (growth)

| Standard | Notes |
|----------|--------|
| **ISO/IEC 27001** (and 27017/27018 for cloud) | Information security MS. Not required to ship an MVP; expected by larger B2B partners. |
| **ISO/IEC 27701** | Privacy extension to 27001. |
| **NIS2** / Lithuanian **Kibernetinio saugumo įstatymas** | Unlikely for a small consumer app today; reassess if EE becomes a critical digital service. |
| **DORA** | Applies to financial entities — not EE unless it becomes a regulated PSP. |
| **EN 301 549 / WCAG 2.2** | Accessibility; increasingly expected on store review. |

### 5.7 Security requirements we commit to in the product

1. Google (or later Apple) sign-in before charging UI; no shared “demo” bypass in production builds.
2. No raw card data in EE code, logs, or database.
3. Location used only for nearby stations, arrival reports, and (later) routing; can be refused.
4. User-submitted stations stay **unpublished** until the app owner confirms the physical location.
5. Production API on HTTPS only; API keys restricted by app identity.
6. Processor list disclosed in the Agreement (§11).
7. Crowd reports stored with a reporter id — treat as personal data under GDPR.

---

## 6. Gap assessment vs §5 (as of 2026-09-01)

| Control | Required by | Status | Notes |
|---------|-------------|--------|--------|
| GDPR lawful basis, privacy notice, DSR, DPIA | GDPR/BDAR | **Gap** | Agreement exists; no full privacy policy, no DPO/DSR process, no DPIA, local session in SharedPreferences. |
| Location consent and purpose limit | ePrivacy / GDPR | **Partial** | OS permission used; purpose described in Agreement. No granular in-app consent log. |
| TLS 1.3 in production | ASVS / stores | **Gap (prod)** | Dev API is `http://` on the LAN (`usesCleartextTraffic=true`). Fine for lab; not for production. |
| Google Sign-In / OIDC | Auth | **Partial** | Wired; Android OAuth client empty until SHA-1 is in Firebase. Debug local session exists. |
| Secure token storage | MASVS | **Gap** | Session JSON in SharedPreferences. |
| OWASP MASVS / cert pinning | MASVS | **Gap** | No pinning, no jailbreak/root policy, no release obfuscation policy documented. |
| Backend authn/z on APIs | ASVS | **Gap** | Station list is open. Crowd submit/check-in have no user JWT. Owner PIN header is a **lab control**, not production IAM. |
| PCI DSS SAQ A via Stripe | PCI / PSD2 | **Not started** | Stripe routes exist; `STRIPE_SECRET_KEY` empty. No Payment Sheet. |
| SCA / Apple Pay / Google Pay | PSD2 | **Not started** | See §7. |
| Maps key restriction | Google Maps ToS | **Partial** | Key is in the client; must be restricted to package + SHA-1 / iOS bundle / HTTP referrers. |
| OCM attribution | OCM licence | **Partial** | Data used; licence text not shown on every map. |
| OCPI security | OCPI | **N/A yet** | No CPO link. Occupancy is UNKNOWN. |
| ISO 27001 / NIS2 / DORA | Org | **N/A** | Not claimed. |
| Cyber Resilience Act (EU) 2024/2847 | CRA | **Gap** | No risk assessment, SBOM, CVD, Art. 14 playbook, CE/DoC. Do not list on EU stores until reporting contact exists (Art. 14 from 11 Sep 2026 for products on the market). See docs/specs/SECURITY_COMPLIANCE.md. |
| Accessibility WCAG | Stores | **Gap** | Not audited. |
| Crowd publish-after-owner-confirm | This PRD | **Implemented (lab)** | Pending submissions hidden; owner PIN confirms physical location; then public map. |
| Arrival Yes/No/Dismiss | This PRD | **Implemented (lab)** | Working + free connectors; stored as check-ins. |

**Verdict:** the product is a **local developer MVP**. It must **not** be described as GDPR-certified, PCI-compliant, or production-ready until the Gap column is closed for the rows marked mandatory in §5.1–5.3.

---

## 7. Phone Wallet for payment — possibility and what is required

### 7.1 What “Wallet” means

Drivers expect the **system payment sheet** (Apple Pay on iPhone, Google Pay on Android), not a boarding-pass in Apple Wallet / Google Wallet. For charging, EE should open that sheet when a session must be paid.

The existing `pay` and `flutter_stripe` packages in the Flutter app are the right direction. EE should **not** collect PAN/CVV in its own form.

### 7.2 Feasibility

**Yes — recommended path:** Stripe Payment Sheet (or Checkout) with **Apple Pay** and **Google Pay** enabled. The app calls the backend for a PaymentIntent; Stripe SDK presents the wallet UI; the card never enters EE servers. This is how most EU eMSP apps stay on **PCI SAQ A** and satisfy **PSD2 SCA** (wallet + bank biometric is SCA).

Apple Wallet passes (a “charging card” in Wallet) are a **separate**, later product (Apple Wallet Issuer / Google Wallet generic pass). Not needed for the first payment.

### 7.3 What is required — Apple Pay (iPhone)

1. Apple Developer Program (paid).
2. Merchant ID (`merchant.…`) and Apple Pay capability on the iOS app id.
3. Payment processing certificate (often created in the Stripe Dashboard → Apple Pay).
4. Stripe account with Apple Pay enabled; country **Lithuania** / EUR.
5. iOS app: `flutter_stripe` + Apple Pay entitlement; merchant id in `Info.plist` / Runner.
6. Physical iPhone with Wallet set up (the current lab tablet is Android-only; Xcode on this Mac is incomplete).
7. Domain verification if a web pay page is used.

### 7.4 What is required — Google Pay (Android)

1. Google Pay API / Business Console profile; accept Google Pay ToS.
2. Stripe account with Google Pay enabled.
3. Android: `flutter_stripe` / `pay` with Google Pay environment `TEST` then `PRODUCTION`.
4. App `applicationId` `com.eniwhere.energy` + **release SHA-1/256** in Firebase **and** in Google Cloud / Pay.
5. Play Store listing (production Google Pay often needs a signed Play app, not only a debug USB build).
6. Device with Google Wallet / Play Services (SM-T585 has Play Services; Wallet UX is better on phones).

### 7.5 What is required — EE backend and product

1. `STRIPE_SECRET_KEY` (test, then live) and webhook `payment_intent.succeeded` to close a charging session.
2. Never log client_secret in client analytics.
3. Show **price and EE fee** before the wallet sheet (consumer law + AFIR honesty).
4. Refunds / disputes: operator energy vs EE service fee — define in Agreement (already points disputes to the operator first).
5. Production HTTPS API (wallet SDKs will not talk to `http://192.168.1.x` in store builds).

### 7.6 Decision

Use **Stripe + Apple Pay + Google Pay** as the Wallet integration. Do not store cards in-app. Defer Apple/Google Wallet **passes**. Lab PIN / cleartext API must be removed before any real charge.

---

## 8. Crowd-sourced stations and arrival reports (functional)

### 8.1 Mark a new station
* Entry: Stations submenu → **Mark a new station**.
* Driver drops a pin, enters name/address/connectors.
* Stored as `PENDING`. **Not** in `GET /api/stations`.
* App owner (Account → **Owner review**, PIN) confirms physical location → row is published (`external_id` `user:{id}`) and appears on the map.
* Owner may reject. Nightly OCM sync must **not** delete `user:` stations.

### 8.2 Arrival check
* Entry: destination card **I've arrived**, station detail, or automatic prompt within ~120 m of the chosen station.
* Questions: station working? free connectors? Each: **Yes / No / Dismiss**.
* Stored as `site_check_in`. These are observations, not live CPO occupancy.

---

## 9. Lab information architecture (2026-09-02)

Root menu (English UI): **Stations** · **Trip** · **Payments** · **Account**.

| Tile | Submenu | Lab notes |
|------|---------|-----------|
| Stations | Map of stations, Nearest column, Station list, Mark a new station | Map chrome in §2.4. Skip mode: map only. |
| Trip | Trip with charging, My vehicle | Planner shows a map polyline and **Navigate**. |
| Payments | Charging history, Payments | Former “History” tile. Payments lists lab estimates + wallet-not-linked banner. |
| Account | Signed in, Legal & privacy, Owner review, Sign out | Owner review = PIN inbox for crowd marks. **Sign out** ends the session and closes the app. Skip **Sign in** returns to welcome only. |

Tablet QA (SM-T585): map layout approved. Completeness vs this PRD remains ~35–40% — see `memory-bank/progress.md`.

