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
A **local developer MVP**: PostgreSQL + Express API with mock CPO data, and a Flutter client that can browse real station records from that API.

## Source of truth
- Product: `docs/PRD.md` (includes security standards, gap table, Wallet, crowd stations), `docs/specs/PRD.md`, `docs/scenarios.md`
- Architecture: `docs/architecture/*`, `docs/specs/DFD.md`, `docs/specs/ADR-001-Data-Strategy.md`
- Repo: https://github.com/Tomukas56/EE
