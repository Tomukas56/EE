# System Architecture & Technology Stack

## 1. Technology Stack

### 1.1 Mobile Application (Frontend)
-   **Framework**: **Flutter** (Dart)
    -   *Reasoning*: Cross-platform (iOS & Android) with a single codebase, high performance, and excellent UI capabilities for maps and animations.

### 1.2 Backend API
-   **Runtime**: **Node.js** (TypeScript recommended)
    -   *Reasoning*: Excellent for I/O-heavy operations (handling multiple CPO API requests simultaneously), large ecosystem, and JSON-native handling.
-   **Framework**: Express.js or NestJS.

### 1.3 Database
-   **Primary Database**: **PostgreSQL** (Cloud-hosted)
    -   *Reasoning*: Robust relational database for structured data (users, transactions, station metadata).
-   **Local Storage (On-Device)**: **Hive** or **SQLite**
    -   *Reasoning*: Caching frequently accessed data (e.g., map pins, user settings) for offline support and performance.

## 2. High-Level Architecture

```mermaid
graph TD
    User[User / Mobile App]
    
    subgraph "Client Side (Flutter)"
        AppUI[UI Layer]
        LocalDB[Local Cache (Hive/SQLite)]
        AppLogic[Business Logic]
    end
    
    subgraph "Server Side (Cloud)"
        API[Node.js Backend API]
        Auth[Auth Service]
        Pay[Payment Service]
        MainDB[(PostgreSQL Database)]
    end
    
    subgraph "External Services"
        CPO1[CPO: Ignitis]
        CPO2[CPO: Elinta]
        CPO3[CPO: UniPark]
        Maps[Google/Mapbox API]
        Bank[Payment Gateway]
    end

    User --> AppUI
    AppUI --> AppLogic
    AppLogic <--> LocalDB
    AppLogic <-->|HTTPS / REST / WebSocket| API
    
    API <--> MainDB
    API --> Auth
    API --> Pay
    
    API <-->|API Calls| CPO1
    API <-->|API Calls| CPO2
    API <-->|API Calls| CPO3
    
    Pay <--> Bank
    AppUI --> Maps
```

## 3. Database Strategy: Cloud vs. Local

### 3.1 Why Cloud Database (PostgreSQL)?
For "Energy Eniwhere", the **PostgreSQL database must run in the Cloud (Server)**, not on the phone.
-   **Centralization**: User data (accounts, balance, history) must be accessible from any device.
-   **Real-time Aggregation**: The backend fetches status from CPOs and updates the central DB. If every phone queried CPOs directly, it would be slow and inefficient.
-   **Security**: Sensitive logic (payments, pricing rules) must stay on the server.

### 3.2 Role of Local Database
The phone will have a small **Local Database** (cache) to store:
-   User preferences (theme, language).
-   Recently viewed stations.
-   Auth tokens.
This ensures the app feels fast and works even with poor internet connection, but it syncs with the Cloud DB.

## 4. Security & Compliance Architecture

### 4.1 Regulatory Compliance
-   **GDPR**:
    -   **Data Minimization**: Only collect essential data.
    -   **Encryption**: All PII (Personally Identifiable Information) encrypted at rest in PostgreSQL.
    -   **Audit Logs**: Immutable logs for all data access and modifications.
-   **PSD2**:
    -   **SCA**: Integration with payment providers that support 3D Secure 2.0.

### 4.2 Security Measures
-   **API Security**:
    -   Rate limiting (to prevent DDoS).
    -   Input validation (Zod/Joi) to prevent Injection attacks (SQLi, NoSQLi).
    -   JWT (JSON Web Tokens) with short expiration and refresh token rotation.
-   **Mobile Security**:
    -   **Obfuscation**: Code obfuscation for release builds.
    -   **Root/Jailbreak Detection**: Prevent running on compromised devices.
    -   **Secure Storage**: Use `flutter_secure_storage` (wraps Keychain/Keystore) for tokens.
