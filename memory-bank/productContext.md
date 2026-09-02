# Product Context

## Why this exists
EV drivers in Lithuania currently switch between Ignitis, Elinta, Tesla, and retail-site apps to find a plug, compare price, and pay. Energy Eniwhere is meant to be the single layer on top of those networks.

## How it should work (product target)
1. User signs in and registers a vehicle (connector type, battery, range).
2. App shows nearby stations from a local database (fast map) and refreshes availability on demand.
3. For a trip, the app calculates whether range is enough and inserts compatible fast-charge stops.
4. At a station the user starts a session in-app, watches kWh/cost, then pays via device wallet (Apple Pay / Google Pay) through Stripe.

## UX goals
- Map and list load quickly even with many stations (hybrid cache, not live fan-out to every CPO).
- Availability and price visible before the user drives there (AFIR price transparency) — **not true yet** (occupancy UNKNOWN).
- Clear map chrome: search + compact filters next to zoom, Google Maps underneath.

## What users can do today (lab build, SM-T585)
- Welcome → tick Agreement → Continue with Google (lab fallback if Play OAuth 10) or Skip (map-only this session).
- Root menu: **Stations**, **Trip**, **Payments**, **Account**.
- Map: Google Maps pins, search match list, right-side country/plug/kW icons and zoom/location. Go opens Google Maps navigation.
- List, Mark a new station (hidden until Owner review PIN), vehicle profile on device.
- Trip planner: route map + Navigate.
- Start/Stop lab sessions; charging and payment lists from the API (estimates, wallet not linked).
- Sign out closes the app.

They cannot yet really authenticate with store-ready Google Sign-In, pay with Stripe/wallets, see live occupancy, or use iOS.
