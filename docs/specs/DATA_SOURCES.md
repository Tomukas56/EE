# Data sources — what we get, from where, and whether a contract is required

**Date:** 2026-09-05  
**Rule:** the Flutter app talks **only** to the EE API. Connectors run on the server.

Licence / contract column:

| Mark | Meaning |
|------|---------|
| **No CPO deal** | Official public feed or our own DB. Still obey that source’s licence / ToS. |
| **Key only** | Developer key or account, not a charging-roaming contract. |
| **CPO or hub** | Bilateral CPO agreement **or** one roaming-hub (eMSP) contract. |

---

## Catalogue and live station data

| Data | Lab today | Source | Contract? |
|------|-----------|--------|-----------|
| LT location, address, plugs, kW | Yes | [Via Lietuva](https://ev.vialietuva.lt/atviri-duomenys-1) OCPI 2.3.0 `locations` | **No CPO deal.** CC BY 4.0 / ODC-BY — attribution required. |
| LT occupancy (AVAILABLE / CHARGING / …) | Yes | Same OCPI `locations` (EVSE status), POLL every 5 min | **No CPO deal.** Same licence. |
| LT published €/kWh | Yes (~1450 sites) | Via Lietuva OCPI `tariffs` + `tariff_ids` | **No CPO deal.** Show operator price; do not invent (AFIR). |
| LV, EE, PL location, plugs, kW | Yes | Open Charge Map `/v3/poi` | **Key only** (`CPOAPI`). OCM ToS. Occupancy not live. |
| LV, EE, PL live occupancy / price | No | National NAP or CPO/hub later | Usually **no** if a public NAP exists (like LT); otherwise **CPO or hub**. |
| Duplicate merge (same site twice) | No | EE Duplicate Resolver | Ours. Needs ≥2 feeds. |
| User-marked pin | Yes, after owner PIN | EE DB | Ours. |

Via Lietuva’s `x-total-count` may say ~3248; the public pager yields ~1500 unique locations. We store what the API returns.

---

## Session, money, identity (not the map)

| Data | Lab today | Source | Contract? |
|------|-----------|--------|-----------|
| Start / Stop at a physical pole | No (lab row in EE DB only) | CPO or roaming hub OCPI Commands | **CPO or hub** — required. NAP does not allow this. |
| Live kWh, running cost, CDR | No (time × kW × €0.32) | CPO / hub session + CDR | **CPO or hub.** |
| Card / Apple Pay / Google Pay | Banner only | Stripe | **PSP** (Stripe), then store wallets. Not a CPO deal. |
| Google Sign-In | Lab fallback if SHA-1 missing | Firebase / Google | **Key only** (Firebase + SHA-1). |
| Vehicle profile | Yes, on device | SharedPreferences | Ours. |

One **hub** contract (GIREVE, Hubject, …) can cover many CPOs for start/stop. Direct CPO deals are per operator.

---

## Maps and trip (not the station catalogue)

| Data | Lab today | Source | Contract? |
|------|-----------|--------|-----------|
| Map tiles, pins | Yes | Google Maps SDK | **Key only.** Restrict before store. |
| OSM tiles fallback | Yes | openstreetmap.org | OSM tile policy. |
| Route line / Navigate | Yes | Google Directions or OSRM + Google Maps app | Maps key / public OSRM. |
| Geocode fallback | Yes | Photon / Nominatim | Usage policy; no CPO deal. |

The app must **not** scrape Ignitis (or other CPO) HTML for catalogue or start.

---

## Practical sequence

1. **Now:** Via Lietuva (free, attributed) + OCM key + Maps key.  
2. **More users:** EE cloud API (VPS) — hosting, not a CPO deal.  
3. **Start in this app:** one hub **or** one large LT CPO.  
4. **More countries live:** their NAP if public; else hub/CPO.
