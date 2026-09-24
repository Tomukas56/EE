# Žingsnis Po Žingsnio Veiksmų Planas — Energy Eniwhere

**Dabartinė būklė**: ~48% PRD užbaigta  
**Tikslas**: Pilnai veikiantis produktas, paruoštas produkcijai  
**Paskutinis atnaujinimas**: 2026-09-24

---

## Prioritetų Legenda

🔴 **CRITICAL** — Būtina produkcijai  
🟡 **HIGH** — Svarbu funkcionalumui  
🟢 **MEDIUM** — Pagerina UX  
🔵 **LOW** — Papildomos funkcijos

---

## FAZĖ 1: Backend Migracija į Cloud (2–3 savaitės)

### Prioritetas: 🔴 CRITICAL

#### 1.1 VPS Serverio Setup
- [ ] Užsakyti VPS (OVH ar Hetzner: 2 vCPU, 4 GB RAM, 80 GB NVMe)
- [ ] Ubuntu 24.04 LTS instalacija
- [ ] Docker + Docker Compose setup
- [ ] Nginx setup (HTTPS, Let's Encrypt)
- [ ] Firewall konfigūracija (UFW: 22, 80, 443, 5432 tik localhost)
- [ ] SSH key authentication (disable password login)

#### 1.2 PostgreSQL/PostGIS Production Setup
- [ ] PostgreSQL 16 + PostGIS 3.4 Docker konteineris
- [ ] Production database credentials (strong passwords)
- [ ] Persistent volumes (`/var/lib/postgresql/data`)
- [ ] Daily automated backups (`pg_dump` + rsync į backup server)
- [ ] Point-in-time recovery setup (WAL archiving)
- [ ] Database performance tuning (shared_buffers, effective_cache_size)

#### 1.3 Backend Application Deployment
- [ ] Node.js production build setup (`npm run build`)
- [ ] Environment variables (`DATABASE_URL`, `JWT_SECRET`, `STRIPE_SECRET_KEY`)
- [ ] PM2 ar systemd service backend procesui
- [ ] Nginx reverse proxy (`/api/*` → `http://localhost:3000`)
- [ ] CORS konfigūracija (tik production domain)
- [ ] Rate limiting (express-rate-limit)
- [ ] Health check endpoint (`GET /health`)

#### 1.4 Data Migration
- [ ] Export local PostgreSQL data (`pg_dump`)
- [ ] Import į production DB (`psql`)
- [ ] Verify data integrity (stations count, coordinates)
- [ ] Test API endpoints remotely

#### 1.5 CI/CD Setup
- [ ] GitHub Actions deployment workflow
  - Trigger: push to `main` branch
  - Steps: build → test → deploy to VPS via SSH
- [ ] Automated security scanning (existing workflow)
- [ ] Database migration automation (Prisma/Knex migrations)

---

## FAZĖ 2: Authentication & Security (2 savaitės)

### Prioritetas: 🔴 CRITICAL

#### 2.1 JWT Authentication Backend
- [ ] Users table schema (`id`, `email`, `password_hash`, `name`, `phone`, `created_at`)
- [ ] `POST /api/auth/register` (email + password, bcrypt hash)
- [ ] `POST /api/auth/login` (JWT token generation, 24h expiry)
- [ ] `POST /api/auth/refresh` (refresh token, 30 days expiry)
- [ ] JWT middleware (protect charging session endpoints)
- [ ] Password reset flow (`POST /api/auth/reset-password`)

#### 2.2 Two-Factor Authentication (2FA)
- [ ] TOTP implementation (speakeasy library)
- [ ] `POST /api/auth/2fa/setup` (generate QR code)
- [ ] `POST /api/auth/2fa/verify` (verify 6-digit code)
- [ ] `users.two_factor_enabled` column
- [ ] Mandatory 2FA for charging sessions

#### 2.3 OAuth Integration (Google/Apple)
- [ ] Firebase Authentication setup
- [ ] Google Sign-In (release SHA-1/SHA-256 certificates)
- [ ] Apple Sign-In (Apple Developer account, service ID)
- [ ] Backend OAuth verification endpoint
- [ ] Link OAuth account to local user

#### 2.4 Mobile App Authentication
- [ ] Login/Register screens (email + password)
- [ ] Google Sign-In button (Firebase)
- [ ] Apple Sign-In button (iOS only)
- [ ] JWT token storage (`flutter_secure_storage`)
- [ ] Token refresh on API 401
- [ ] 2FA setup screen (QR code scanner)
- [ ] 2FA verify screen (6-digit input)
- [ ] Biometric authentication (local_auth package)

---

## FAZĖ 3: Real-Time OCPI Integration (3–4 savaitės)

### Prioritetas: 🔴 CRITICAL

#### 3.1 OCPI Connectors (Backend Services)
- [ ] Via Lietuva OCPI connector
  - Endpoint: `ev.vialietuva.lt/ocpi/2.3.0`
  - License: CC BY 4.0
  - Sync: locations, tariffs, sessions
  - Frequency: every 5 minutes (POLL)
- [ ] Latvia national feed connector (identify source)
- [ ] Estonia national feed connector (identify source)
- [ ] Poland EIPA connector (identify source)
- [ ] Generic OCPI 2.3.0 connector (reusable)

#### 3.2 Sync Worker Service
- [ ] Separate Node.js service (`backend/src/services/sync-worker.ts`)
- [ ] PM2 process management
- [ ] Scheduler (node-cron: daily 02:00 full sync)
- [ ] Real-time PUSH handler (webhook endpoint)
- [ ] Deduplication logic (same station from multiple sources)
- [ ] Normalization (status codes, connector types, power units)

#### 3.3 Occupancy & Status
- [ ] Database schema: `evse_status` table
  - `station_id`, `evse_id`, `connector_id`, `status`, `last_update`
- [ ] API endpoint: `GET /api/stations/:id/status`
- [ ] Mobile app: real-time status display
- [ ] Stale data warning (>15 min old = "Last known")

#### 3.4 Tariffs (Pricing)
- [ ] Database schema: `tariffs` table
  - `station_id`, `operator_id`, `price_per_kwh`, `currency`, `valid_from`
- [ ] API endpoint: `GET /api/stations/:id/tariffs`
- [ ] Mobile app: price display on map pins and detail
- [ ] Price filter: `GET /api/stations?maxPrice=0.40`

---

## FAZĖ 4: Charging Session Management (2 savaitės)

### Prioritetas: 🔴 CRITICAL

#### 4.1 OCPI Session Start/Stop
- [ ] Backend: OCPI session start (`POST /ocpi/2.3.0/commands/START_SESSION`)
- [ ] Backend: OCPI session stop (`POST /ocpi/2.3.0/commands/STOP_SESSION`)
- [ ] Database: `charging_sessions` table update (real CPO session ID)
- [ ] API: `POST /api/sessions/start` (requires JWT)
- [ ] API: `POST /api/sessions/stop` (requires JWT)
- [ ] Error handling (CPO timeout, connector unavailable)

#### 4.2 Real-Time Session Monitoring
- [ ] Backend: Poll CPO for session progress (kWh, duration, cost)
- [ ] WebSocket or Server-Sent Events (SSE) for live updates
- [ ] Mobile app: live charging screen
  - kWh delivered
  - Current cost (€)
  - Elapsed time
  - Estimated time to full (based on vehicle battery)
- [ ] Push notifications (charging complete, error)

#### 4.3 Session History
- [ ] Backend: `GET /api/sessions?userId=X` (authenticated)
- [ ] Mobile app: Payments → Charging history
- [ ] Session detail screen (kWh, cost, duration, location)
- [ ] Export session receipt (PDF)

---

## FAZĖ 5: Stripe Payment Integration (2 savaitės)

### Prioritetas: 🔴 CRITICAL

#### 5.1 Stripe Backend Setup
- [ ] Stripe account (test + live keys)
- [ ] `STRIPE_SECRET_KEY` į production `.env`
- [ ] Webhook endpoint: `POST /api/webhooks/stripe`
  - `payment_intent.succeeded`
  - `payment_intent.payment_failed`
- [ ] Stripe signature verification
- [ ] Link payment to charging session

#### 5.2 Payment Flow
- [ ] Backend: `POST /api/payments/create-intent` (amount, session_id)
- [ ] Return `client_secret` to mobile app
- [ ] Mobile app: Stripe SDK setup
  - `flutter_stripe` package
  - Publishable key configuration
- [ ] Payment sheet: Apple Pay / Google Pay
- [ ] Payment confirmation screen
- [ ] Automatic payment after session ends

#### 5.3 Wallet Integration
- [ ] Google Pay setup (Android)
  - Google Cloud Console configuration
  - Release SHA-1/SHA-256 certificates
  - Test environment → Production
- [ ] Apple Pay setup (iOS)
  - Apple Developer Merchant ID
  - Payment Processing Certificate
  - App Store Connect configuration
- [ ] Wallet status check (linked/not linked)
- [ ] Wallet-not-linked banner (current lab feature)

#### 5.4 Payment History & Invoices
- [ ] Backend: `GET /api/payments?userId=X`
- [ ] Mobile app: Payments → Payment history
- [ ] Invoice generation (PDF with VAT)
- [ ] Email invoice to user

---

## FAZĖ 6: iOS Support (1–2 savaitės)

### Prioritetas: 🟡 HIGH

#### 6.1 Apple Developer Setup
- [ ] Apple Developer account (99 USD/year)
- [ ] Bundle ID: `com.eniwhere.energy`
- [ ] App ID configuration
- [ ] Push notification certificates
- [ ] Apple Sign-In capability

#### 6.2 iOS Build & Testing
- [ ] Xcode setup (macOS required)
- [ ] iOS provisioning profiles
- [ ] Build & test on iOS device/simulator
- [ ] Fix iOS-specific issues (permissions, UI)
- [ ] Apple Maps integration (optional, or keep Google Maps)

#### 6.3 App Store Submission
- [ ] App Store Connect setup
- [ ] App metadata (description, screenshots, keywords)
- [ ] Privacy Policy URL
- [ ] Terms of Service URL
- [ ] App icon (all sizes)
- [ ] Submit for review
- [ ] Handle review feedback

---

## FAZĖ 7: Testing & Quality Assurance (2 savaitės)

### Prioritetas: 🔴 CRITICAL

#### 7.1 Backend Testing
- [ ] Unit tests (Jest)
  - Authentication functions
  - JWT token generation/validation
  - OCPI connectors
  - Payment processing
- [ ] Integration tests
  - API endpoints
  - Database operations
  - External API calls (mock)
- [ ] Load testing (Artillery/k6)
  - 100 concurrent users
  - API response time <200ms
- [ ] Security testing
  - SQL injection prevention
  - XSS prevention
  - CSRF protection
  - Rate limiting

#### 7.2 Mobile Testing
- [ ] Unit tests (Flutter test)
  - Providers (Riverpod)
  - Utils functions
  - Models
- [ ] Widget tests
  - Screens
  - Components
- [ ] Integration tests
  - User flows (login → find station → start session)
- [ ] Device testing
  - Android 8.0+ (multiple devices)
  - iOS 13.0+ (multiple devices)
  - Tablet (SM-T585 and iPad)

#### 7.3 User Acceptance Testing (UAT)
- [ ] Beta testers (10–20 users)
- [ ] TestFlight (iOS) + Google Play Internal Testing (Android)
- [ ] Feedback collection (Google Forms)
- [ ] Bug tracking (GitHub Issues)
- [ ] Fix critical bugs
- [ ] Iterate based on feedback

---

## FAZĖ 8: Performance & Optimization (1 savaitė)

### Prioritetas: 🟢 MEDIUM

#### 8.1 Backend Optimization
- [ ] Database indexing (lat/lng, station_id, user_id)
- [ ] Query optimization (EXPLAIN ANALYZE)
- [ ] Redis caching
  - Station list (5 min TTL)
  - Tariffs (15 min TTL)
  - Status (1 min TTL)
- [ ] API response compression (gzip)
- [ ] CDN for static assets (optional)

#### 8.2 Mobile Optimization
- [ ] Image optimization (compressed PNG/WebP)
- [ ] Lazy loading (station list)
- [ ] Map marker clustering (>100 stations)
- [ ] Offline caching improvements
- [ ] Reduce APK/IPA size
  - Remove unused dependencies
  - ProGuard/R8 (Android)
  - BitCode (iOS, if applicable)

#### 8.3 Monitoring & Logging
- [ ] Backend logging (Winston)
  - Error logs → file + Sentry
  - Access logs → Nginx
- [ ] Application monitoring (Sentry/LogRocket)
- [ ] Server monitoring (Prometheus + Grafana, optional)
- [ ] Uptime monitoring (UptimeRobot)
- [ ] Database monitoring (pg_stat_statements)

---

## FAZĖ 9: Documentation & Compliance (1 savaitė)

### Prioritetas: 🔴 CRITICAL

#### 9.1 User Documentation
- [ ] In-app help screens
- [ ] FAQ page (web)
- [ ] Video tutorials (YouTube)
  - How to find a station
  - How to start charging
  - How to add payment method

#### 9.2 Developer Documentation
- [ ] API documentation (OpenAPI/Swagger)
- [ ] README.md (setup instructions)
- [ ] Architecture diagram (update DFD.md)
- [ ] Database schema diagram (update ERD)
- [ ] Deployment guide
- [ ] Troubleshooting guide

#### 9.3 Legal & Privacy
- [ ] Privacy Policy (GDPR compliant)
  - Data collected
  - Data retention
  - User rights (access, deletion)
- [ ] Terms of Service
- [ ] Cookie Policy (if web dashboard)
- [ ] GDPR consent flow (mobile app)

#### 9.4 CRA Compliance (Cyber Resilience Act)
- [ ] Final SBOM generation (`scripts/generate-sbom.sh`)
- [ ] CVE management process documentation (complete ✓)
- [ ] Security fixes audit trail (complete ✓)
- [ ] Vulnerability disclosure policy
- [ ] CE marking documentation (if hardware involved)
- [ ] CRA Declaration of Conformity
- [ ] Technical documentation file
- [ ] Risk assessment report

#### 9.5 PCI DSS Compliance (Payments)
- [ ] Stripe handles card data (PCI SAQ A eligible)
- [ ] No card data storage in app/backend
- [ ] HTTPS only
- [ ] Secure API communication
- [ ] PCI compliance attestation

---

## FAZĖ 10: Launch Preparation (1 savaitė)

### Prioritetas: 🔴 CRITICAL

#### 10.1 Google Play Store
- [ ] Google Play Console account (25 USD one-time)
- [ ] App listing
  - Title, description (LT, EN)
  - Screenshots (phone + tablet)
  - Feature graphic
  - Privacy Policy link
  - Content rating questionnaire
- [ ] Release APK/AAB (signed, ProGuard enabled)
- [ ] Submit for review
- [ ] Respond to review feedback

#### 10.2 App Store (iOS)
- [ ] App Store Connect listing
  - Title, subtitle, description
  - Screenshots (all device sizes)
  - Preview videos (optional)
  - Privacy Policy link
  - Age rating
- [ ] Release IPA (signed, release configuration)
- [ ] Submit for review
- [ ] Respond to review feedback

#### 10.3 Production Checklist
- [ ] All environment variables set (production)
- [ ] API keys restricted (Google Maps, Stripe)
- [ ] Database backups automated
- [ ] Monitoring alerts configured
- [ ] Error tracking (Sentry)
- [ ] Analytics (Firebase/Google Analytics)
- [ ] Push notifications configured
- [ ] Rate limiting active
- [ ] HTTPS certificates valid
- [ ] DNS configured (custom domain)

#### 10.4 Marketing & Launch
- [ ] Landing page (web)
- [ ] Social media accounts (Facebook, Instagram, Twitter/X)
- [ ] Press release (optional)
- [ ] Launch email to beta testers
- [ ] Monitor app store reviews
- [ ] Respond to user feedback

---

## FAZĖ 11: Post-Launch (Ongoing)

### Prioritetas: 🟢 MEDIUM

#### 11.1 User Support
- [ ] Support email (support@eniwhere.com)
- [ ] In-app feedback form
- [ ] FAQ updates based on user questions
- [ ] Response time SLA (24h for critical)

#### 11.2 Feature Enhancements (PRD Backlog)
- [ ] **Price prediction** (ML model based on time, station, operator)
- [ ] **Occupancy prediction** (ML model)
- [ ] **Favorite stations** (bookmarks)
- [ ] **Trip history** (routes saved)
- [ ] **Carbon footprint calculator**
- [ ] **Social features** (share charging spots)
- [ ] **Gamification** (badges, leaderboard)
- [ ] **Admin dashboard** (web, for owner review)

#### 11.3 Maintenance
- [ ] Weekly security scans (automated ✓)
- [ ] Monthly dependency updates
- [ ] Quarterly security audits
- [ ] Database maintenance (VACUUM, ANALYZE)
- [ ] Log rotation
- [ ] Backup testing (restore drill)

---

## Laiko Įvertinimas

| Fazė | Prioritetas | Trukmė | Priklausomybės |
|------|-------------|--------|----------------|
| 1. Backend Cloud | 🔴 CRITICAL | 2–3 savaitės | - |
| 2. Authentication | 🔴 CRITICAL | 2 savaitės | Fazė 1 |
| 3. OCPI Integration | 🔴 CRITICAL | 3–4 savaitės | Fazė 1 |
| 4. Charging Sessions | 🔴 CRITICAL | 2 savaitės | Fazė 2, 3 |
| 5. Stripe Payments | 🔴 CRITICAL | 2 savaitės | Fazė 2, 4 |
| 6. iOS Support | 🟡 HIGH | 1–2 savaitės | Fazė 1-5 |
| 7. Testing & QA | 🔴 CRITICAL | 2 savaitės | Fazė 1-6 |
| 8. Optimization | 🟢 MEDIUM | 1 savaitė | Fazė 7 |
| 9. Documentation | 🔴 CRITICAL | 1 savaitė | Fazė 7 |
| 10. Launch Prep | 🔴 CRITICAL | 1 savaitė | Fazė 9 |
| **TOTAL** | | **17–21 savaitė** | **~4–5 mėnesiai** |

---

## Resursai

### Reikalinga Komanda
- **1 Backend Developer** (Node.js, PostgreSQL, OCPI)
- **1 Mobile Developer** (Flutter, Dart)
- **0.5 DevOps** (VPS setup, CI/CD, arba konsultantas)
- **0.5 QA Tester** (testai, UAT)

### Kaina (Preliminari)
- **VPS**: ~20 EUR/mėn (OVH)
- **Domain**: ~15 EUR/metams
- **SSL**: 0 EUR (Let's Encrypt)
- **Apple Developer**: 99 USD/metams
- **Google Play**: 25 USD (vienkartinis)
- **Stripe fees**: 1.4% + 0.25 EUR per transaction (EU)
- **Firebase**: 0 EUR (Spark plan, vėliau Blaze ~10 EUR/mėn)
- **Sentry**: 0 EUR (Developer plan, vėliau ~26 USD/mėn)
- **Backup storage**: ~5 EUR/mėn

**Total pirmus metus**: ~500–800 EUR (infrastruktūra) + darbo valandos

---

## Rizikos

| Rizika | Tikimybė | Poveikis | Mitigation |
|--------|----------|----------|------------|
| OCPI integracija užtrunka | HIGH | HIGH | Pradėti nuo Via Lietuva (veikia), kitas šalis vėliau |
| Stripe mokėjimų problemos | MEDIUM | HIGH | Išsamus testavimas test mode, skaityk Stripe docs |
| iOS review rejection | MEDIUM | MEDIUM | Follow Apple guidelines, responsive support |
| Backend performance issues | LOW | HIGH | Load testing, Redis caching, scaling plan |
| Security breach | LOW | CRITICAL | Regular scans, penetration testing, insurance |

---

## Sekantys Žingsniai (Iškart Po Šio Plano Patvirtinimo)

1. **✅ VPS užsakymas** (OVH ar Hetzner)
2. **✅ PostgreSQL production setup** (Docker Compose)
3. **✅ Nginx + HTTPS konfigūracija** (Let's Encrypt)
4. **✅ Backend deployment** (PM2, environment variables)
5. **✅ Data migration** (local → production)

---

## Tracking

Šis planas bus sekamas:
- **GitHub Projects** board su fazėmis
- **Weekly progress meeting** (jei komanda)
- **Progress.md** atnaujinimai po kiekvienos fazės

---

**Patvirtino**: [Vardas]  
**Data**: 2026-09-24  
**Versija**: 1.0
