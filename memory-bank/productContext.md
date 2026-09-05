# Product Context

## Why this exists
EV drivers in Lithuania currently switch between Ignitis, Elinta, Tesla, and retail-site apps to find a plug, compare price, and pay. Energy Eniwhere is meant to be the single layer on top of those networks.

## How it should work (product target)
1. User signs in and registers a vehicle (connector type, battery, range).
2. App shows stations **only from our API**. The server aggregates CPO/OCPI/national feeds, deduplicates, and stores last-known occupancy (PRD §10, DFD).
3. For a trip, the **server** (later) calculates range and compatible stops; lab trip is a device sketch.
4. At a station the user starts a session in-app, then pays via device wallet through Stripe.

## UX goals
First driver feedback (2026-09-05), in order:
1. See **prices on the map** without opening every station.
2. Filter by **power** and **maximum price** (€/kWh).
3. On a chosen station, see **occupancy** (free / busy / charging).
4. **Start charging in this app** and **watch progress** (kWh, time, running cost).

These outrank trip polish, iOS, and store listing. Lab today: pins and min-kW filter exist; **no pin price**, **no max-price filter**, occupancy **UNKNOWN**, Start/Stop is a lab estimate.

- Map and list load quickly even with many stations (hybrid cache, not live fan-out to every CPO).
- Availability and price visible before the user drives there (AFIR) — **not true yet**.
- Clear map chrome: search + compact filters next to zoom, Google Maps underneath.

## What users can do today (lab build, SM-T585)
- Welcome → tick Agreement → Continue with Google (lab fallback if Play OAuth 10) or Skip (map-only this session).
- Root menu: **Stations**, **Trip**, **Payments**, **Account**.
- Map: Google Maps pins, search match list (Lithuanian letters folded: `c`/`č`), right-side country/plug/kW icons and zoom/location. Go opens Google Maps navigation.
- List, Mark a new station (hidden until Owner review PIN), vehicle profile on device.
- Trip planner: route map + Navigate.
- Start/Stop lab sessions; charging and payment lists from the API (estimates, wallet not linked).
- Sign out closes the app.

They cannot yet really authenticate with store-ready Google Sign-In, pay with Stripe/wallets, see live occupancy, or use iOS.
