# Energy Eniwhere — implementation review

Historical lab notes from the first backend slice. Current lab status is in `README.md` and `docs/specs/SECURITY_COMPLIANCE.md`.

## Completed at the time

### 1. Project setup
- Project structure
- PRD
- DFD (Data Flow Diagram)
- Git repository (https://github.com/Tomukas56/EE)
- Development environment

### 2. Backend

#### 2.1 Database
- PostgreSQL 16 with Docker Compose
- Prisma ORM 5.22 (instead of TypeORM)
- Station and Connector models
- Migrations created and applied

#### 2.2 Core services
- **CPOService**: mock data source with 7 Lithuanian stations
- **SyncWorker**: daily cron at 02:00 (200h sync window)
- **Prisma Client**: type-safe queries

#### 2.3 API endpoints
- `GET /` — health check
- `GET /api/stations` — station list
- `GET /api/stations/:id` — station detail

#### 2.4 Security
- Helmet.js HTTP security headers
- CORS enabled
- Environment variables (`.env`)
- Non-default database passwords

### 3. Mock data
**7 stations loaded:**
1. Ignitis Charging Hub - Vilnius Center (CCS 150kW, Type2 22kW)
2. Elinta Fast Charge - Kaunas (CCS 50kW, CHAdeMO 50kW)
3. Maxima Shopping Center - Vilnius Ozas (Type2 22kW x2)
4. Tesla Supercharger - Vilnius (CCS 250kW x3)
5. Ignitis Green Energy Hub - Vilnius Žirmūnai (CCS 150kW, Type2 22kW)
6. Elinta Downtown - Kaunas Laisvės (Type2 11kW)
7. LIDL Parking - Vilnius Ukmergė (Type2 22kW - OUTOFORDER)

**Total:** 13 charging connectors

### 4. Documentation
- `README.md` — setup guide
- `docs/memory-bank.md` — change history
- `docs/specs/PRD.md` — updated with implementation status
- `.gemini/walkthrough.md` — detailed walkthrough

---

## Deviations from the original plan

### 1. TypeORM → Prisma ORM
**Why:** TypeORM had persistent initialization errors  
**Effect:** Better TypeScript integration, simpler configuration  
**Time:** ~2 hours troubleshooting + 30 min migration

### 2. PostGIS → simple lat/lng
**Why:** PostGIS geometry types caused TypeORM errors  
**Effect:** Simpler schema; spatial indexing can be added later  
**Trade-off:** Distance filters need manual calculations

### 3. Database port: 5432 → 5433
**Why:** Conflict with a local PostgreSQL  
**Effect:** Team uses `DATABASE_URL` with port 5433

---

## Project stats (at the time)

- **Lines of code:** ~1,500 (TypeScript)
- **Files:** 15+ backend files
- **Database tables:** 2 (`station`, `connector`)
- **API endpoints:** 3
- **Development time:** ~4 hours
- **Git commits:** 3

---

## How to run

```bash
# 1. Clone repository
git clone https://github.com/Tomukas56/EE.git
cd EE

# 2. Start PostgreSQL
docker-compose up -d

# 3. Install dependencies
cd backend
npm install

# 4. Run migrations
npx prisma migrate dev

# 5. Build and start
npm run build
npm start
```

Server: `http://localhost:3000`

---

## Test results (at the time)

### API
```bash
✓ GET / → "Energy Eniwhere API is running"
✓ GET /api/stations → Returns 7 stations (JSON)
✓ GET /api/stations/:id → Returns station details with connectors
```

### Database
```sql
✓ SELECT COUNT(*) FROM station;   -- 7
✓ SELECT COUNT(*) FROM connector; -- 13
```

### Server logs
```
✓ Database connected
✓ [SyncWorker] Successfully synced 7 stations
✓ Server is running on port 3000
```

---

## Next steps (original list)

### Backend (optional)
- [ ] Geospatial filtering (ST_DWithin with PostGIS)
- [ ] Redis caching
- [ ] Rate limiting
- [ ] API documentation (Swagger/OpenAPI)

### Mobile (priority at the time)
- [ ] Initialize Flutter project
- [ ] Google Maps / Mapbox
- [ ] Station list screen
- [ ] Station detail screen
- [ ] Backend API integration
- [ ] Filters (connector type, power, distance)

### Later features
- [ ] Real CPO integrations (OCPI)
- [ ] User authentication (JWT)
- [ ] Charging session control
- [ ] Payment processing (Stripe)
- [ ] Push notifications

---

## Review questions (original)

### Technology choices
1. **Prisma ORM:** Approve the move off TypeORM?
2. **Simple lat/lng:** Bring PostGIS back now or later?
3. **Mock data:** Enough stations for testing?

### Architecture
1. **API structure:** Do the endpoints match expectations?
2. **Database schema:** Extra columns needed?
3. **Sync frequency:** Is 24h a reasonable interval?

### Priorities
1. Continue with the Flutter app now?
2. More backend work before mobile?
3. Authentication before the mobile app?

---

## Open questions (original)

1. **CPO integration:** Which live CPOs first?
2. **Payments:** Stripe or another gateway?
3. **Maps:** Google Maps or Mapbox on mobile?
4. **Authentication:** Email/password or social (Google/Apple)?
5. **Deployment:** Where to host the backend (AWS, Azure, GCP)?
