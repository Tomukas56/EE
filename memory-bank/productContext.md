# Product Context

## Why this exists
EV drivers in Lithuania currently switch between Ignitis, Elinta, Tesla, and retail-site apps to find a plug, compare price, and pay. Energy Eniwhere is meant to be the single layer on top of those networks.

## How it should work
1. User signs in and registers a vehicle (connector type, battery, range).
2. App shows nearby stations from a local database (fast map) and refreshes availability on demand.
3. For a trip, the app calculates whether the current SoC is enough and inserts compatible fast-charge stops.
4. At a station the user starts a session in-app, watches kWh/cost, then pays automatically.

## UX goals
- Map and list load quickly even with many stations (hybrid cache, not live fan-out to every CPO).
- Availability and price visible before the user drives there (AFIR price transparency).
- Modern Material 3 UI (electric blue → teal), dark mode, Poppins.

## What users can do today (local build)
- Open the Flutter shell (welcome → vehicle form → home dashboard).
- Browse 7 mock Lithuanian stations and their connectors from the live API.
- Search the list, open details, jump out to Maps / phone / website.
- See **mock** charging and payment history screens.

They cannot yet really authenticate, persist a vehicle, plan a route, start a charge, or pay.
