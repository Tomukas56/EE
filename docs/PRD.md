# Product Requirements Document (PRD) - Energy Eniwhere

## 1. Introduction
Energy Eniwhere is a comprehensive mobile application for Electric Vehicle (EV) owners, enabling seamless charging station discovery, session management, route planning, and payments.

## 2. Core Requirements

### 2.1 User Authentication & Onboarding
*   **Sign Up/Login**: Support for Google, Apple, and Email auth.
*   **Production auth (email + 2FA, tokens, biometrics):** **§11**. **Do not implement §11 in the current lab app** — it would block station / trip / vehicle QA. Lab remains: Google / device session, Skip = map only, saved session on this tablet.
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
*   Map chrome (lab, approved 2026-09-02): search at the top with a **list of name/address matches**; search is **diacritic-insensitive** for LT/LV/EE/PL (`Raciu` matches `Račių`). Compact **country / plug / kW** icons on the **right**, same column as zoom `+` `−`, nearest, and my location. Google Maps is the basemap.
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
*   **Platform**: Flutter (iOS/Android).
*   **Lab backend (today)**: Node.js + Express + Prisma + PostgreSQL on the developer machine (Compose port **5433**).
*   **Online / production backend (required)**: aggregation server in §10. The Flutter app **must not** call operator APIs. Canonical DFD: [specs/DFD.md](specs/DFD.md).
*   **Maps (lab)**: Google Maps Platform. Production may keep it or use MapLibre; catalogue data still comes only from our API.
*   **Station catalogue (lab today)**: Open Charge Map (LT, LV, EE, PL) + owner-confirmed user submissions. Occupancy is **UNKNOWN**. Production catalogue: connectors in §10 (OCPI / national / CPO).
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
8. **§11** (email + Argon2id + TOTP 2FA + short-lived tokens + device biometrics). Binding for production payments and charging control. **Not in the USB lab build.**

---

## 6. Gap assessment vs §5 (as of 2026-09-01)

| Control | Required by | Status | Notes |
|---------|-------------|--------|--------|
| GDPR lawful basis, privacy notice, DSR, DPIA | GDPR/BDAR | **Gap** | Agreement exists; no full privacy policy, no DPO/DSR process, no DPIA, local session in SharedPreferences. |
| Location consent and purpose limit | ePrivacy / GDPR | **Partial** | OS permission used; purpose described in Agreement. No granular in-app consent log. |
| TLS 1.3 in production | ASVS / stores | **Gap (prod)** | Dev API is `http://` on the LAN (`usesCleartextTraffic=true`). Fine for lab; not for production. |
| Google Sign-In / OIDC | Auth | **Partial** | Wired; Android OAuth client empty until SHA-1 is in Firebase. Debug local session exists. |
| Email + password + TOTP 2FA (§11) | This PRD / ASVS | **Not started (deferred)** | Required before live payments / START-STOP. **Do not build during current lab QA.** |
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
| Account | Signed in, Legal & privacy, Owner review, Sign out | Owner review = PIN inbox. Menu **title** size matches other tiles. **Sign out** closes the app. Skip **Sign in** → welcome. |

Tablet QA (SM-T585): map layout and this IA **locked in** 2026-09-02. Completeness vs this PRD remains ~35–40% — see `memory-bank/progress.md`.

---

## 10. Online aggregation architecture (required for production)

A proper **online** product needs a dedicated backend that collects, normalizes, deduplicates, and serves station data. This section is **binding** for production. Diagrams: [specs/DFD.md](specs/DFD.md). The USB lab on this Mac is **not** this architecture yet (§10.11).

### 10.1 Principle

**The mobile app never talks to operator APIs, OCPI hubs, or national registers.**

```
CPO / OCPI / national APIs → Connectors → Sync → Normalizer → Duplicate Resolver
  → PostgreSQL/PostGIS → (Redis) → our REST API → Flutter
```

A new operator or country is a new **connector** on the server. The app is unchanged.

### 10.2 What the driver must see (from our API)

Location, operator, coordinates, EVSE points, connector types, power, AC/DC, **real-time occupancy (last known)**, **last update time**. Later: tariffs, server-side route planning, session start/stop.

Example station card:

* IGNITIS ON · Ukmergės g. 100, Vilnius  
* 2 available · 2 occupied  
* CCS2 150 kW AVAILABLE · CCS2 150 kW OCCUPIED · CCS2 50 kW AVAILABLE · Type 2 22 kW OCCUPIED  
* Updated: 12 sec ago  

Stale last-known must be shown as unreliable or `UNKNOWN`, not as a live free plug.

### 10.3 External sources (connectors)

Each provider is its own module, for example: Via Lietuva OCPI; Poland EIPA; Latvia and Estonia national feeds; Shell EV; Ignitis ON; Eleport; Enefit; Eldrive; GreenWay; other CPOs; later GIREVE / Hubject.

### 10.4 Server (online MVP)

One VPS is enough at first (OVH: **2 vCPU, 4 GB RAM, 40–80 GB NVMe**, Ubuntu, Docker, HTTPS, automated DB backups). No Kubernetes.

| Component | Role |
|-----------|------|
| **Nginx** | HTTPS to the app; TLS termination |
| **Backend API** | Only API the app calls |
| **Sync service** | Ingest from connectors (PUSH and POLL) |
| **Scheduler** | Cron for sources without PUSH |
| **PostgreSQL + PostGIS** | Catalogue + geo queries |
| **Redis** | Optional hot cache (not required on day one) |
| **Backup** | Periodic database dumps |

### 10.5 Normalize to one model

Statuses in the wild (`AVAILABLE`, `Available`, `FREE`) become **`AVAILABLE`**. Internal set: `AVAILABLE`, `OCCUPIED`, `CHARGING`, `RESERVED`, `OUT_OF_ORDER`, `OFFLINE`, `UNKNOWN`.

Connectors: CCS / Combo 2 / `IEC_62196_T2_COMBO` → **`CCS2`**.

Design the schema **close to OCPI** even when the feed is not OCPI.

Keep three objects distinct: **Location → EVSE → Connector**. One site can have many EVSE; one EVSE can have many plugs.

Tables (production): Countries, Operators, Locations, EVSE, Connectors, Status History, Tariffs, Data Sources, Users, Vehicles, Trips.

Every object stores **our id** plus **source** plus **source_*_id** (e.g. Via Lietuva location id) so the same physical site from two feeds can merge.

### 10.6 Duplicates and source priority

The same column may arrive from Via Lietuva, Shell, Ignitis, and Hubject. The app must show **one** pin. Duplicate Resolver compares coordinates, operator, EVSE id, address, name, connectors, then links aliases to one Location.

When feeds disagree, prefer in order: (1) direct CPO API, (2) national register, (3) roaming hub, (4) aggregator (Shell/GIREVE), (5) static open data. Always also compare **`last_updated`**. Example: Ignitis OCCUPIED vs Shell AVAILABLE → use Ignitis if it is the primary and newer.

### 10.7 PUSH vs POLL

* **PUSH (preferred):** OCPI Locations / Status / Tariffs webhooks update the DB immediately (`AVAILABLE` → `CHARGING`).
* **POLL:** scheduler hits the provider API. Dynamic status only as often as the contract allows (e.g. 30–60 s). Static fields (coordinates, plug type, max kW) far less often.

Map and list always serve **last known** from our DB so a down CPO does not blank the map.

PostGIS examples: free CCS2 ≥150 kW within 20 km; chargers within 5 km of a Vilnius–Warsaw path.

### 10.8 Our API and the Flutter app

App endpoints (production): `GET /stations`, `/stations/{id}`, `/stations/nearby`, `/stations/bbox`, `/operators`, `/connectors`, `/station/{id}/status`, later `GET /route/chargers`.

Server-side filters: AVAILABLE, operator, CCS2, CHAdeMO, Type 2, AC/DC, min kW, distance, later price. Example: **CCS2 + ≥150 kW + AVAILABLE**.

App modules: Map (home), Station Search, Filters, Station Details, Vehicle, Route Planner, Favorites, Account, Settings.

**Vehicle (later):** battery kWh, CCS/CHAdeMO/Type 2, max AC/DC kW, consumption, range — hide or demote incompatible plugs.

**Route planner (later, on the server):** origin, destination, vehicle, SoC → stops from compatibility, power, last-known occupancy, later price and charge time. Lab trip sketch on the device is not this.

Auth (production): JWT / OAuth. Lab device session is not production IAM.

### 10.9 Production MVP stack (chosen 2026-09-03)

| Piece | Choice |
|-------|--------|
| Host | OVH VPS 2 vCPU / 4 GB / 40–80 GB NVMe |
| OS | Ubuntu Server |
| Containers | Docker |
| Reverse proxy | Nginx |
| API | **Python FastAPI** |
| DB | PostgreSQL + **PostGIS** |
| Cache | Redis (optional at start) |
| Ingest | OCPI + REST + national APIs |
| App API | REST/JSON |
| App | Flutter |
| Maps | MapLibre **or** keep Google Maps SDK; **catalogue still only from our API** |
| First markets | LT, LV, EE, PL |
| Data model | OCPI-shaped Location / EVSE / Connector |

Lab Node/Express may keep running on the Mac until this VPS exists. Shipping store/online means implementing §10, not pointing the app at Ignitis.

### 10.10 Build order

1. VPS + Docker + PostgreSQL/PostGIS  
2. API + Location → EVSE → Connector  
3. **First technical goal:** one real Lithuanian source → Location + EVSE + Connector + power + real-time status in our DB → our API → Flutter map  
4. Filters  
5. Poland, then Latvia, then Estonia  
6. Only then: user accounts, vehicle on server, trips, tariffs, occupancy forecast, reserve if the CPO allows, START/STOP, payments/roaming  

### 10.11 Lab vs this requirement (honest)

| Topic | Lab now | §10 production |
|-------|---------|----------------|
| App → operators | Already forbidden | Same |
| Ingest | OCM nightly pull | Per-source connectors, PUSH + POLL |
| Occupancy | Always UNKNOWN | Last-known + timestamp |
| Dedup | Name upsert | Duplicate Resolver + source ids |
| Geo | Distances in the app | PostGIS nearby / bbox |
| Host | Colima Postgres :5433, `npm start` :3000 | OVH + Nginx HTTPS |
| API runtime | Node Express + Prisma | FastAPI |

Until step 3 in §10.10 works, EE is a **lab aggregator with a static OCM snapshot**, not an online occupancy product.

---

## 11. Security and 2FA authentication (production — do not implement in the lab app)

**Status:** specified for production. **Out of scope for the current USB / tablet QA cycle.** Do not add email-password screens, TOTP, or Keystore token flows until map, trip, vehicle, and lab sessions have been verified. Implementing §11 now would block that testing.

**Goal:** a stolen password or a stolen phone must not by itself grant full access to the account, payments, or charging control.

### 11.1 Primary login (server)

* Email + password.
* Store passwords **only** as a one-way hash. Recommended algorithm: **Argon2id**.
* Never store plaintext or reversibly encrypted passwords.

Google / Apple OIDC (already in §2.1) remain allowed; they do not replace password hashing rules for email accounts.

### 11.2 Second factor (TOTP)

* 6-digit **TOTP**, compatible with Google Authenticator, Microsoft Authenticator, Authy, and other RFC 6238 apps.
* TOTP secret stored **encrypted** at rest on the server.
* When the user enables 2FA, generate **recovery codes**: one-time use, never stored in plaintext.

### 11.3 Login sequence

1. User enters email and password.  
2. Backend verifies the account.  
3. If 2FA is enabled, the app asks for the TOTP code.  
4. Backend verifies TOTP.  
5. **Only then** issue session tokens.

### 11.4 Tokens

* Short-lived **Access Token** (recommended **10–15 minutes**).
* Separate **Refresh Token**, stored in the mobile OS secure store (Keystore / Keychain) — not SharedPreferences.
* Refresh tokens must be **revocable** on the server.
* Password change or suspected compromise: **revoke all sessions**.

### 11.5 Device biometrics

* Support Face ID, Touch ID, and Android biometrics.
* Biometrics **only unlock credentials already on the device**.
* Biometrics **must not** replace server auth or TOTP.
* Biometric templates **must not** be sent to or stored on the backend.

### 11.6 Step-up by operation

| Level | When | Proof |
|-------|------|--------|
| Normal | Catalogue, map, trip sketch | Valid access token |
| Sensitive | Extra biometric unlock on device | Token + biometric |
| Highly sensitive | Re-authenticate + 2FA | Password/OIDC + TOTP |

Treat as **highly sensitive** (or at least sensitive): add/change payment method; change account email; change password; disable 2FA; delete account; add a trusted device.

When charging control and payments exist, also step-up: **START CHARGING**, **STOP CHARGING**, reservation, payment confirmation, invoice / payment-settings changes.

### 11.7 Abuse controls

* Cap failed logins; **rate-limit** login, 2FA, and password-reset endpoints.
* After many failures: temporary lockout or extra challenge.
* Log security events.
* User can see **active sessions / devices** and **sign out all other devices**.

### 11.8 Transport and secrets

* App ↔ backend **HTTPS / TLS only** in production.
* API credentials, TOTP secrets, operator API keys **must not** live in the app binary.
* Operator keys stay on the **backend** only (same rule as §10).

### 11.9 2FA policy by product stage

* **Map + trip only (no money, no CPO start/stop):** 2FA **optional** for the user.
* **Payments, charging session control, reservations, or other financially sensitive features:** 2FA **mandatory** to use those features.

Lab today: Google / lab-device session, no email password, no TOTP, session in SharedPreferences. That is **not** §11.


