# Database Schema Design

## 1. ER Diagram

```mermaid
erDiagram
    USERS ||--o{ SESSIONS : "initiates"
    USERS ||--o{ FAVORITES : "has"
    USERS ||--o{ PAYMENT_METHODS : "owns"
    
    PROVIDERS ||--|{ STATIONS : "operates"
    
    STATIONS ||--|{ CONNECTORS : "contains"
    STATIONS ||--o{ FAVORITES : "is_in"
    
    CONNECTORS ||--o{ SESSIONS : "used_in"
    
    SESSIONS ||--|| PAYMENTS : "generates"
    
    USERS {
        uuid id PK
        string email UK
        string password_hash
        string full_name
        string phone_number
        timestamp created_at
        timestamp updated_at
    }

    PROVIDERS {
        uuid id PK
        string name
        string api_base_url
        jsonb config "API keys, auth details"
        string support_phone
    }

    STATIONS {
        uuid id PK
        uuid provider_id FK
        string external_id "ID in CPO system"
        string name
        string address
        float latitude
        float longitude
        boolean is_active
        timestamp last_synced_at
    }

    CONNECTORS {
        uuid id PK
        uuid station_id FK
        string external_id
        string type "CCS, Type2, CHAdeMO"
        float max_power_kw
        decimal price_per_kwh
        string status "AVAILABLE, CHARGING, FAULTED"
    }

    SESSIONS {
        uuid id PK
        uuid user_id FK
        uuid connector_id FK
        timestamp start_time
        timestamp end_time
        float kwh_delivered
        decimal total_cost
        string status "ACTIVE, COMPLETED, FAILED"
    }

    PAYMENTS {
        uuid id PK
        uuid session_id FK
        decimal amount
        string currency
        string status "PENDING, SUCCESS, FAILED"
        string transaction_id
        timestamp created_at
    }

    FAVORITES {
        uuid user_id PK, FK
        uuid station_id PK, FK
        timestamp created_at
    }
```

## 2. Table Definitions

### 2.1 Users
Stores user account information.
- **id**: Primary Key (UUID).
- **email**: Unique email address.
- **password_hash**: Bcrypt/Argon2 hash.
- **full_name**: User's display name.
- **phone_number**: Contact number (optional).

### 2.2 Providers (CPOs)
Stores configuration for different Charging Point Operators (Ignitis, Elinta, etc.).
- **config**: JSONB column to store provider-specific API credentials flexibly.

### 2.3 Stations
Represents a physical charging location.
- **external_id**: The ID used by the CPO to identify this station.
- **last_synced_at**: Timestamp of the last successful data fetch from CPO.

### 2.4 Connectors
Represents a specific plug at a station.
- **status**: Real-time status (synced frequently or fetched on demand).

### 2.5 Sessions
Records charging history.
- **kwh_delivered**: Updated periodically during charging and finalized at the end.

### 2.6 Payments
Records financial transactions linked to sessions.
