# Memory Bank - Implementation Changes & Decisions

## 🔄 Major Deviations from Original Plan

### 1. ORM Migration: TypeORM → Prisma

**Original Plan**: Use TypeORM for database management

**What Changed**: Migrated to Prisma ORM v5.22

**Reason**: 
- TypeORM had persistent `EntityMetadataValidator` initialization errors
- Multiple troubleshooting attempts failed:
  - Removed `Relation<>` type wrappers
  - Simplified entity relationships
  - Removed PostGIS geometry type
  - Disabled circular dependency resolution
- Prisma offers better TypeScript integration and simpler configuration

**Impact**:
- ✅ Faster development with auto-generated type-safe client
- ✅ Cleaner schema definition in `schema.prisma`
- ✅ Better migration management
- ⚠️ Learning curve for team members familiar with TypeORM

**Files Affected**:
- Deleted: `src/entity/Station.ts`, `src/entity/Connector.ts`, `src/data-source.ts`
- Created: `prisma/schema.prisma`, `src/lib/prisma.ts`
- Modified: All database queries in routes and workers

---

### 2. Geospatial Data: PostGIS → Simple Lat/Lng

**Original Plan**: Use PostGIS `geometry` type for location data with spatial queries

**What Changed**: Store latitude and longitude as `Decimal` columns

**Reason**:
- PostGIS integration caused TypeORM metadata validation errors
- Simple lat/lng sufficient for MVP
- PostGIS can be re-added later with Prisma's raw SQL support

**Impact**:
- ✅ Simplified database schema
- ⚠️ No spatial indexing yet (can add later)
- ⚠️ Manual distance calculations needed for geo-filtering

**Future Enhancement**:
- Add PostGIS extension
- Create spatial index on lat/lng
- Implement `ST_DWithin` for radius searches

---

### 3. Entity Relationships: Simplified Foreign Keys

**Original Plan**: Use TypeORM decorators (`@OneToMany`, `@ManyToOne`) with automatic relationship loading

**What Changed**: Manual foreign key (`station_id`) with explicit queries

**Reason**:
- TypeORM relationship metadata errors
- Prisma uses explicit `include` for relations (more predictable)

**Impact**:
- ✅ More explicit control over query performance
- ✅ No N+1 query issues
- ⚠️ Slight verbosity in queries (must specify `include: { connectors: true }`)

---

### 4. Development Port: PostgreSQL 5432 → 5433

**Original Plan**: PostgreSQL on default port 5432

**What Changed**: Mapped Docker PostgreSQL to host port 5433

**Reason**:
- Port conflict with local PostgreSQL installation on developer machine
- Avoided shutdown of local PostgreSQL instance

**Impact**:
- ✅ No conflicts with existing services
- ⚠️ Team must use `DATABASE_URL` with `:5433`

---

## ✅ Implementations Matching Original Plan

### Backend Architecture
- ✅ Node.js + TypeScript + Express
- ✅ PostgreSQL database
- ✅ Docker Compose for database
- ✅ Environment variable configuration

### Data Model
- ✅ Station entity with operator details
- ✅ Connector entity with types and status
- ✅ Enums for connector types (CCS, CHAdeMO, Type2, Type1)
- ✅ Enum for connector status (AVAILABLE, OCCUPIED, etc.)

### Services
- ✅ CPO Integration Service (mock implementation)
- ✅ Sync Worker with cron scheduling
- ✅ Daily sync at 2 AM

### API Endpoints
- ✅ `GET /` - Health check
- ✅ `GET /api/stations` - List all stations
- ✅ `GET /api/stations/:id` - Station details
- ✅ Proper error handling and JSON responses

### Security
- ✅ Helmet.js for HTTP headers
- ✅ CORS enabled
- ✅ Environment variables for secrets
- ✅ Non-default database passwords

---

## 📊 Technical Decisions

### Database Connection
**Decision**: Use Prisma Client singleton pattern  
**Rationale**: Prevents connection pool exhaustion, recommended by Prisma

### Mock Data
**Decision**: 7 Lithuanian stations with realistic addresses  
**Locations**: Vilnius (5), Kaunas (2)  
**Rationale**: Representative sample for development and testing

### TypeScript Configuration
**Decision**: Strict mode with `exactOptionalPropertyTypes`  
**Rationale**: Maximum type safety, catches `undefined` vs `null` mismatches

### Error Handling in SyncWorker
**Decision**: Catch and log errors but don't crash server  
**Rationale**: Failed sync shouldn't bring down API

---

## 🚧 Known Limitations & Future Improvements

### Current Limitations
1. **No Authentication**: API is publicly accessible
2. **No Rate Limiting**: Vulnerable to abuse
3. **No Geospatial Queries**: Filtering by distance not implemented
4. **Mock Data Only**: No real CPO integration
5. **No Caching**: Every request hits database

### Planned Improvements
1. **Add JWT Authentication**
   - User registration and login
   - Protected endpoints

2. **Implement Geospatial Queries**
   - Add PostGIS extension
   - Create spatial index
   - Filter stations by radius

3. **Real CPO Integration**
   - OCPI 2.2 protocol
   - Hubject integration
   - Tesla Supercharger API (if available)

4. **Add Redis Caching**
   - Cache station list (15-minute TTL)
   - Invalidate on sync

5. **WebSocket Support**
   - Real-time connector status updates
   - Push notifications for availability

---

## 📝 Documentation Updates

### Files Updated
- ✅ `README.md` - Complete setup and API documentation
- ✅ `docs/memory-bank.md` - This change log
- ✅ `docs/specs/PRD.md` - Updated with Prisma implementation
- ✅ `.gemini/walkthrough.md` - Implementation walkthrough

### Files to Update (Mobile Phase)
- `docs/specs/DFD.md` - Add mobile app data flows
- `docs/API.md` - Detailed API specification with examples
- `docs/DEPLOYMENT.md` - Production deployment guide

---

## 🎯 Current Status

**Backend**: ✅ **Production-ready MVP**
- All planned endpoints working
- Database schema stable
- Mock data loaded
- Sync worker operational

**Next Phase**: Flutter mobile application development

---

## 📅 Timeline

- **2025-12-05**: Project initialization, PRD creation
- **2025-12-08 AM**: TypeORM setup attempt (failed)
- **2025-12-08 11:00-12:00**: Multiple TypeORM debugging sessions
- **2025-12-08 12:06**: Decision to migrate to Prisma
- **2025-12-08 12:15**: Backend complete and verified
- **2025-12-08 12:20**: Documentation and Git push

**Total Development Time**: ~4 hours (including troubleshooting)

---

## 2026-08-31 — Local bring-up on macOS 13 (Ventura)

- Cloned/synced repo; nested `OneDrive - teltonika.lt/` tree is a duplicate and should be removed later.
- Docker is not installed. Database runs on **Postgres.app 18.3, port 5434**, database `energy_db`.
- `backend/.env` uses `DATABASE_URL` (Prisma does not read `DB_HOST`/`DB_PORT` alone).
- Stripe v20 throws if constructed with an empty key. `PaymentService` now lazily creates the client so station API can boot without `STRIPE_SECRET_KEY`.
- `import 'dotenv/config'` is the first backend import so env is available under ESM.
- Flutter **3.47.2 cannot run on macOS 13** (needs 14). SDK restored to **3.32.8 / Dart 3.8.1**.
- `mobile/pubspec.yaml`: SDK `>=3.8.0 <4.0.0`, `google_fonts` pinned to `6.2.1`, `assets/google_logo.png` added (welcome screen referenced a missing asset).
- Verified: `GET /` and `GET /api/stations` return 7 synced stations.
- Memory Bank files created under `memory-bank/` (projectbrief, productContext, systemPatterns, techContext, activeContext, progress).
