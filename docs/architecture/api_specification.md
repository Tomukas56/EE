# API Specification

## 1. Overview
-   **Base URL**: `https://api.energyeniwhere.com/v1`
-   **Content-Type**: `application/json`
-   **Authentication**: Bearer Token (JWT) in `Authorization` header.

## 2. Authentication

### 2.1 Register
-   **POST** `/auth/register`
-   **Body**: `{ "email": "user@example.com", "password": "...", "full_name": "..." }`
-   **Response**: `201 Created`
    ```json
    {
      "user": { "id": "uuid", "email": "..." },
      "token": "jwt_token",
      "refresh_token": "..."
    }
    ```

### 2.2 Login
-   **POST** `/auth/login`
-   **Body**: `{ "email": "...", "password": "..." }`
-   **Response**: `200 OK` (Same as Register)

## 3. Stations

### 3.1 List Stations
-   **GET** `/stations`
-   **Query Params**:
    -   `lat`, `lng`: User location.
    -   `radius`: Search radius in km.
    -   `connectors`: Filter by type (e.g., `CCS`).
    -   `min_power`: Minimum kW.
-   **Response**: `200 OK`
    ```json
    [
      {
        "id": "uuid",
        "name": "Station A",
        "location": { "lat": 54.68, "lng": 25.27 },
        "status": "AVAILABLE",
        "connectors": [...]
      }
    ]
    ```

### 3.2 Station Details
-   **GET** `/stations/{id}`
-   **Response**: `200 OK` - Full details including current pricing and real-time connector status.

## 4. Charging Sessions

### 4.1 Start Session
-   **POST** `/sessions/start`
-   **Body**: `{ "station_id": "...", "connector_id": "..." }`
-   **Response**: `201 Created`
    ```json
    {
      "session_id": "uuid",
      "status": "INITIATING"
    }
    ```

### 4.2 Stop Session
-   **POST** `/sessions/{id}/stop`
-   **Response**: `200 OK`
    ```json
    {
      "status": "COMPLETED",
      "total_kwh": 15.5,
      "total_cost": 4.50
    }
    ```

### 4.3 Session Status
-   **GET** `/sessions/{id}`
-   **Response**: `200 OK` - Real-time updates (kWh, time, cost).

## 5. Payments

### 5.1 Get Payment Methods
-   **GET** `/payments/methods`
-   **Response**: `200 OK` - List of saved cards/methods.

### 5.2 Add Payment Method
-   **POST** `/payments/methods`
-   **Body**: `{ "token": "stripe_token_or_similar" }`
-   **Response**: `201 Created`
