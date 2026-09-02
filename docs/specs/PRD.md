# Product Requirements Document (PRD)

## 1. Introduction
### 1.1 Purpose
The purpose of this document is to define the requirements for the "Energy Eniwhere" mobile application. The application aims to simplify the experience for Electric Vehicle (EV) owners by aggregating multiple charging station providers into a single, unified user interface.

### 1.2 Scope
The "Energy Eniwhere" application will allow users to view, filter, and navigate to charging stations from various providers.
**In Scope:**
-   Unified map and list view of charging stations.
-   Integration with multiple charging point operators (CPOs).
-   Real-time availability status (where API allows).
-   User authentication and profile management.
-   Filtering by connector type, power, and provider.
-   **Charging Session Management**: Start/Stop charging directly from the app.
-   **Payments**: In-app payment processing for charging sessions.

**Out of Scope (for MVP):**
-   Hardware integration with vehicles (e.g., reading SOC directly from car).

### 1.3 Definitions, Acronyms, and Abbreviations
-   **EV**: Electric Vehicle
-   **CPO**: Charging Point Operator
-   **UI**: User Interface
-   **MVP**: Minimum Viable Product

### 1.4 Implementation Status (As of 2026-09-02)

**Lab (USB Android, not a store build)**
- PostgreSQL via Colima Compose on host port **5433**; Open Charge Map sync LT/LV/EE/PL (~2590 mappable stations)
- REST: stations, lab sessions start/stop, account erase, crowd submit / owner confirm
- Flutter: welcome, map (Google Maps + right-side filter/zoom rail + search match list), list, trip map + Navigate, Payments menu, owner review
- Occupancy UNKNOWN; payments = lab-estimate; Google Sign-In needs Firebase SHA-1

**✅ Completed — Phase-1 stations API**
- Prisma schema, Express API, SyncWorker

**🚧 In progress**
- Store-ready auth, Stripe Payment Sheet, OCPI occupancy

**📋 Still planned**
- Real CPO integrations (OCPI), User JWT, iOS, production HTTPS, CRA/CE

**Honest completeness:** ~35–40% of the full product PRD. See [docs/PRD.md](../PRD.md) §6 and `memory-bank/progress.md`.

**🔄 Implementation Changes**
See [memory-bank.md](../memory-bank.md) and `memory-bank/` for the change log (Prisma, port 5433, lab map IA).


## 2. Product Overview
### 2.1 Product Perspective
"Energy Eniwhere" acts as an aggregator layer on top of existing CPO networks. It eliminates the need for EV owners to switch between multiple apps to find suitable charging stations.

### 2.2 Product Functions
-   **Station Discovery**: Locate charging stations on an interactive map.
-   **Aggregated Data**: View details (price, power, connectors) from multiple providers.
-   **Navigation**: seamless integration with Google Maps/Waze/Apple Maps.
-   **Filtering**: Advanced search capabilities for specific charging needs.
-   **Charging Control**: Remote start and stop of charging sessions.
-   **Unified Payment**: Pay for charging across different providers using a single wallet/payment method.

### 2.3 User Classes and Characteristics
-   **EV Owners**: Primary users looking for convenient charging options.
-   **Fleet Managers**: Secondary users monitoring charging options for corporate vehicles.

## 3. Functional Requirements
### 3.1 User Authentication
#### 3.1.1 Description
Users can create an account and log in to save preferences.
#### 3.1.2 Inputs
Email, Password, or Social Login (Google/Apple).
#### 3.1.3 Processing
Validate credentials, create session.
#### 3.1.4 Outputs
Access to personalized features (favorites, history).

### 3.2 Map & Station Discovery
#### 3.2.1 Description
The core feature presenting a map with clustered charging station markers.
#### 3.2.2 Inputs
User location (GPS), Search query, Filters.
#### 3.2.3 Processing
Query local database for station locations (Hybrid Strategy). Fetch real-time availability from CPOs only for visible stations.
#### 3.2.4 Outputs
Map pins indicating station location. Lab occupancy is UNKNOWN until OCPI.
Search on the map shall list matching stations (name and address), not jump to a single hit.
Map controls: compact country / plug / min-kW icons on the **same side** as zoom and my-location (right). Google Maps SDK is the lab basemap.

### 3.2.a Data Synchronization Strategy (Hybrid Model)
**Requirement**: To ensure performance and reliability, the system shall operate on a Hybrid Data Model.
1.  **Static Data (Location, Metadata)**: Must be stored and indexed in the local application database.
    *   *Update Mechanism*: Periodic background synchronization (e.g., nightly) with CPO APIs.
2.  **Dynamic Data (Availability, Status)**: Must be fetched in real-time or near real-time.
    *   *Update Mechanism*: On-demand fetching when the user views the station or map region.

### 3.3 Station Details
#### 3.3.1 Description
Detailed view of a specific charging station.
#### 3.3.2 Inputs
Selection of a map pin or list item.
#### 3.3.3 Processing
Retrieve real-time details from CPO API.
#### 3.3.4 Outputs
-   Provider Name
-   Address
-   Connector Types (CCS, Type 2, CHAdeMO)
-   Power Output (kW)
-   Pricing Information
-   Current Availability

### 3.4 Filtering
#### 3.4.1 Description
Allow users to narrow down search results.
#### 3.4.2 Inputs
Filter criteria: Country (LT/LV/EE/PL), connector type, minimum power (kW), search text. Availability when a CPO feed exists.
#### 3.4.3 Processing
Filter displayed stations on map and list.
#### 3.4.4 Outputs
Refined view of stations matching criteria.

### 3.5 Charging Session Management
#### 3.5.1 Description
Users can start and stop charging sessions directly from the app.
#### 3.5.2 Inputs
Station ID, Connector ID, User command (Start/Stop).
#### 3.5.3 Processing
Send command to CPO API, monitor session status.
#### 3.5.4 Outputs
Real-time session data (kWh delivered, time elapsed, current cost).

### 3.6 Payments
#### 3.6.1 Description
Secure in-app payment processing for charging sessions via the device wallet (Apple Pay / Google Pay) and Stripe. See docs/PRD.md §7.
#### 3.6.2 Inputs
Payment method (Credit Card, Apple Pay, Google Pay), Billing details.
#### 3.6.3 Processing
Authorize payment, process transaction upon session completion, generate invoice.
#### 3.6.4 Outputs
Payment confirmation, transaction history, invoices.
Lab: Payments root menu (Sessions · History). Screen must show device wallet binding status (Google Wallet/Pay vs Apple Wallet/Pay); lab devices are not linked.

### 3.7 Mark a new station
A signed-in driver may submit a pin + metadata. The station is unpublished until the app owner confirms the physical location, then it appears on the map.

### 3.8 Arrival check
On arrival the app asks whether the station is working and whether connectors are free. Answers: Yes, No, Dismiss.

## 4. Non-Functional Requirements
### 4.1 Performance Requirements
-   Map loading time should be under 2 seconds.
-   Real-time status updates should be reflected within 30 seconds of change.

### 4.2 Security Requirements
The binding list of standards, the gap assessment, Wallet requirements, and crowd-station rules live in **[docs/PRD.md](../PRD.md) §§5–8**.

Summary: GDPR/BDAR, ePrivacy, consumer law, PSD2 SCA, PCI DSS SAQ A via Stripe, OWASP MASVS/ASVS, TLS 1.3 in production, OAuth/OIDC, store policies, Google Maps / Firebase / OCM / Stripe terms, OCPI when CPO links exist. ISO 27001 and NIS2 are later. Current lab build is **not** production-compliant — see the gap table in docs/PRD.md §6.

### 4.3 Reliability and Availability
-   99.9% uptime for the application backend.
-   Graceful handling of CPO API failures (show cached data with warning).

## 5. Interface Requirements
### 5.1 User Interfaces
-   **Mobile App**: Native or Cross-platform (React Native/Flutter) for iOS and Android.
-   **Design Language**: Clean, modern, eco-friendly aesthetic. Dark mode support.

### 5.2 Software Interfaces
-   **CPO APIs**: Integration with major local and international charging providers (e.g., Ignitis, Elinta, UniPark, etc. - *TBD*).
-   **Maps API**: Google Maps or Mapbox for rendering.
