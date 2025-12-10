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
    *   Estimated total duration.
    *   Estimated charging cost.
    *   Energy consumption estimate.

### 2.4 Charging Station Discovery
*   Real-time map and list of stations.
*   Filter by connector, speed (kW), and availability.
*   "Nearest Station" quick action.

### 2.5 Charging Session Control
*   Start/Stop charging via app.
*   Real-time monitoring (kWh delivered, current cost).
*   History of sessions.

### 2.6 Payments
*   Wallet system (Stripe/Payment Gateway).
*   Automatic payments after session.
*   Payment history and invoices.

## 3. Technical Constraints
*   **Platform**: Flutter (iOS/Android/Web).
*   **Backend**: Node.js + Prisma + PostgreSQL.
*   **Maps**: Google Maps Platform (Directions API, Places API).

## 4. Success Metrics
*   Successful route calculation with <5% error in energy estimation.
*   100% of active users have a registered vehicle profile.
*   Seamless charging experience for supported CPOs.
