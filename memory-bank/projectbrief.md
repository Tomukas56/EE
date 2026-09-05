# Project Brief — Energy Eniwhere

## Purpose
Energy Eniwhere (EE) is a mobile EV charging aggregator for Lithuanian (and later EU) drivers. It should let a user find stations, plan routes with charging stops, start/stop sessions, and pay from one app instead of juggling CPO apps.

## In scope (product)
- Station discovery (map + list), filters, navigation
- User accounts and a mandatory vehicle profile
- Route planning based on range / state of charge
- Charging session start/stop and history
- In-app payments (wallet / card / Apple Pay / Google Pay)
- Aggregation of multiple CPOs (Ignitis, Elinta, Tesla, retail chargers, later OCPI)

## Out of scope for MVP
- Direct vehicle telemetry (reading SoC from the car)
- Operating as a CPO (owning hardware)

## Current delivery target
A **local developer MVP** on USB Android: OCM stations in PostgreSQL, Flutter map/list/trip/sessions. Not a store build.

Driver-facing MVP (feedback 2026-09-05): prices on the map, filter by power and max €/kWh, occupancy on the station, then in-app start + live progress. Tracked in `docs/specs/WORK_PLAN.md` (U1–U4).

## Source of truth
- Product: `docs/PRD.md` (security, gap table, Wallet, crowd, §9 lab IA, **§10 online aggregation**, **§11 2FA — spec only, not in lab**), `docs/scenarios.md`
- Architecture: `docs/specs/DFD.md` (production DFD), `docs/architecture/system_architecture.md`, `docs/specs/ADR-001-Data-Strategy.md`, `docs/specs/SRD.md`
- Honest status: `memory-bank/progress.md`
- Work order: `docs/specs/WORK_PLAN.md`
- Repo: https://github.com/Tomukas56/EE
