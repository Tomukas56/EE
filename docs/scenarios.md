# Usage Scenarios - Energy Eniwhere

This document outlines the core user flows and operating scenarios for the Energy Eniwhere mobile application, based on the Product Requirements Document (PRD).

## 1. User Onboarding & Vehicle Registration (First Time Use)
**Goal**: Create an account and set up the mandatory vehicle profile to enable route planning.
**Pre-conditions**: User has installed the app.

1.  **Launch**: User opens the app for the first time.
2.  **Sign Up**: User selects "Sign up with Google/Apple" or enters email/password.
3.  **Profile Basics**: User confirms name and phone number.
4.  **Vehicle Prompt**: App prompts: "Add your vehicle to start." (This is mandatory).
5.  **Vehicle Entry**:
    *   **Brand**: User selects (e.g., "Tesla").
    *   **Model**: User selects (e.g., "Model 3 Long Range").
    *   **Specs**: App auto-fills default Capacity (75 kWh) and Max Range (500 km). User can adjust.
    *   **Connector**: User confirms Connector Type (e.g., CCS2).
6.  **Completion**: Dashboard loads, showing user's location and "Ready to Plan" status.

## 2. Smart Route Planning (Long Distance Trip)
**Goal**: Plan a trip from A to B with necessary charging stops based on current battery.
**Pre-conditions**: User is logged in and has a vehicle registered.

1.  **Initiate**: User taps "Plan Route" on the dashboard.
2.  **Input**:
    *   **Destination**: User types "Paris" (auto-complete via Google Places).
    *   **Current SoC**: User inputs "40%" (or app reads from vehicle if connected).
3.  **Calculation**: App executes algorithm:
    *   Checks distance vs. current range.
    *   Finds stations along the route compatible with CCS2.
    *   Prioritizes fast chargers (>150kW) to minimize dwell time.
4.  **Result**:
    *   Map shows the route line.
    *   **Stop 1**: "Ionity Station, 20 min charge (20% -> 80%)".
    *   **Summary**: "Total time: 4h 30m (Driving: 4h, Charging: 30m)".
5.  **Navigation**: User taps "Start Navigation" to push coordinates to Google Maps/Waze.

## 3. Ad-hoc Charging (Nearest Station)
**Goal**: Quickly find a place to charge nearby without a full route plan.
**Pre-conditions**: User is looking for immediate charging.

1.  **Discovery**: User taps "Find Chargers Near Me" on the map.
2.  **Filter**: User toggles "Only Fast Chargers (>50kW)" and "Available Only".
3.  **Selection**: User taps a station pin on the map.
    *   Details pane slides up: "Circle K Station - 2 x CCS2 Available".
    *   Price: "0.50 €/kWh".
4.  **Navigate**: User taps "Go" to navigate to the pin.

## 4. Charging Session
**Goal**: Start and complete a charging session at a station.
**Pre-conditions**: User is at the station and plugged in.

1.  **Start**:
    *   User scans QR code on the charger OR selects the specific station ID in the app.
    *   User taps "Start Charging".
2.  **Active Session**:
    *   App displays "Charging...".
    *   Live metrics: "15.4 kWh delivered", "Current Power: 45 kW", "Cost so far: 7.70 €".
3.  **Stop**:
    *   User reaches desired SoC (e.g., 80%).
    *   User taps "Stop Charging".
4.  **Payment**:
    *   App calculates final total.
    *   Charges the linked credit card automatically.
    *   Displays "Success! Receipt sent to email."

## 5. Account & History
**Goal**: Review past charges.

1.  **Access**: User taps "Profile" -> "History".
2.  **List**: Shows list of past sessions with Date, Location, kWh, and Cost.
3.  **Detail**: Tapping a session shows the PDF invoice.
