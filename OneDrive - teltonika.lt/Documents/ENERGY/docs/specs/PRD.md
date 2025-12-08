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
Map pins indicating station location and status (Available, Occupied, Out of Order).

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
Filter criteria: Connector type, Minimum power (kW), Specific providers, Availability.
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
Secure in-app payment processing for charging sessions.
#### 3.6.2 Inputs
Payment method (Credit Card, Apple Pay, Google Pay), Billing details.
#### 3.6.3 Processing
Authorize payment, process transaction upon session completion, generate invoice.
#### 3.6.4 Outputs
Payment confirmation, Transaction history, Invoices.

## 4. Non-Functional Requirements
### 4.1 Performance Requirements
-   Map loading time should be under 2 seconds.
-   Real-time status updates should be reflected within 30 seconds of change.

### 4.2 Security Requirements
### 4.2 Security Requirements
-   **Data Protection (GDPR/BDAR)**:
    -   Strict compliance with General Data Protection Regulation (EU) 2016/679.
    -   Implementation of "Right to be Forgotten" and data portability.
    -   User consent management for data processing.
-   **Payment Security (PSD2 & PCI DSS)**:
    -   Compliance with Payment Services Directive 2 (EU) 2015/2366, specifically Strong Customer Authentication (SCA).
    -   Adherence to PCI DSS (Payment Card Industry Data Security Standard) guidelines (using compliant payment gateways).
-   **Application Security**:
    -   Adherence to **OWASP Mobile Top 10** security risks.
    -   Secure storage of sensitive data (Keychain/Keystore).
    -   Certificate pinning for API communication to prevent Man-in-the-Middle (MitM) attacks.
-   **Authentication**:
    -   Implementation of OAuth 2.0 / OpenID Connect standards.
-   **Encrypted Communication**:
    -   TLS 1.3 for all data in transit.
    -   AES-256 encryption for sensitive data at rest.

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
