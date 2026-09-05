- **Data**: Open Charge Map POIs for LT/LV/EE/PL (~2590 mappable in lab)
- **Sync**: Cron worker (daily at 2 AM) + on boot

### Database Schema
```prisma
model Station {
  id            String      // UUID
  name          String
  operator_name String?
  address       String
  latitude      Decimal?
  longitude     Decimal?
  is_public     Boolean
  website       String?
  phone         String?
  opening_hours String?
  connectors    Connector[]
}

model Connector {
  id           String          // UUID
  evse_id      String
  type         ConnectorType   // CCS, CHAdeMO, TYPE2, TYPE1
  max_power_kw Decimal
  status       ConnectorStatus // AVAILABLE, OCCUPIED, etc.
  tariff       String?
  station_id   String
}
```

### Frontend (lab)
- **Framework**: Flutter **3.32.8** / Dart 3.8.1 (do not upgrade on macOS 13)
- **Maps**: Google Maps SDK; OSM fallback only if Maps never attaches
- **State**: Riverpod
- **Device**: Samsung SM-T585 — `adb reverse tcp:3000 tcp:3000` then `flutter run -d 330039b62585a5df`

## 🚀 Getting Started

### Prerequisites
- Node.js 22+
- Docker & Docker Compose
- Git

### Installation

1. **Clone repository**
```bash
git clone https://github.com/Tomukas56/EE.git
cd EE
```

2. **Start PostgreSQL** (host port **5433**)

On this lab Mac, Colima provides Docker. From the repo root:

```bash
./scripts/db-up.sh
```

That starts Colima if needed and `docker compose up -d db`. The API uses this container on port 5433. Postgres.app is not required.

Elsewhere with Docker Desktop:

```bash
docker compose up -d
```

3. **Install dependencies**
```bash
cd backend
npm install
```

4. **Configure environment**
Create `.env` in `backend/` directory:
```env
DATABASE_URL=postgresql://energy_admin_secure:EniwhereSecurePass2025@127.0.0.1:5433/energy_db
PORT=3000
NODE_ENV=development
```

5. **Run database migrations**
```bash
npx prisma migrate deploy
```

6. **Build and start server**
```bash
npm run build
npm start
```

Server runs on `http://localhost:3000`

## 📡 API Endpoints

### Health Check
```http
GET /
```
**Response**: `"Energy Eniwhere API is running"`

### List Stations
```http
GET /api/stations
```
**Response**:
```json
[
  {
    "id": "90cc06ec-54ef-4c75-97b9-bf5ea5557c82",
    "name": "Ignitis Charging Hub - Vilnius Center",
    "operator_name": "Ignitis",
    "address": "Konstitucijos pr. 20, Vilnius",
    "latitude": 54.6872,
    "longitude": 25.2797,
    "is_public": true,
    "connector_count": 2,
    "available_connectors": 1
  }
]
```

### Station Details
```http
GET /api/stations/:id
```
**Response**:
```json
{
  "id": "90cc06ec-54ef-4c75-97b9-bf5ea5557c82",
  "name": "Ignitis Charging Hub - Vilnius Center",
  "operator_name": "Ignitis",
  "address": "Konstitucijos pr. 20, Vilnius",
  "latitude": 54.6872,
  "longitude": 25.2797,
  "is_public": true,
  "website": "https://ignitis.lt",
  "phone": "+370 700 55 055",
  "opening_hours": "24/7",
  "connectors": [
    {
      "id": "uuid",
      "evse_id": "LT*IGN*E001*1",
      "type": "CCS",
      "max_power_kw": 150,
      "status": "AVAILABLE",
      "tariff": "0.35 EUR/kWh"
    }
  ]
}
```

## 🗂️ Project Structure

```
ENERGY/
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma       # Database schema
│   │   └── migrations/         # Database migrations
│   ├── src/
│   │   ├── lib/
│   │   │   └── prisma.ts       # Prisma client
│   │   ├── services/
│   │   │   └── CPOService.ts   # Open Charge Map pull
│   │   ├── workers/
│   │   │   └── SyncWorker.ts   # Data sync cron job
│   │   ├── routes/
│   │   │   └── stationRoutes.ts # API endpoints
│   │   └── index.ts            # Express server
│   ├── .env                    # Environment variables
│   └── package.json
├── docs/
│   ├── PRD.md                  # Product requirements (canon)
│   ├── specs/
│   │   ├── DFD.md              # Production data-flow
│   │   └── ADR-001-Data-Strategy.md
│   └── memory-bank.md          # Change log
├── docker-compose.yml          # PostgreSQL setup
└── README.md
```

## 🧪 Development

### Database Management

View database:
```bash
npx prisma studio
```

Create new migration:
```bash
npx prisma migrate dev --name description
```

Reset database:
```bash
npx prisma migrate reset
```

### Running Tests
```bash
npm test
```

## 📊 Station catalogue

Lab database is filled from **Open Charge Map**, not the original 7 mock rows. After sync expect on the order of **~2590** mappable stations (Lithuania, Latvia, Estonia, Poland). Occupancy is UNKNOWN until a CPO/OCPI feed exists.

Root menu: Stations · Trip · **Payments** · Account. Map filters (country / plug / kW) sit on the **right** with zoom.

## 🔐 Security & Compliance

Lab only. See `docs/PRD.md` §6. Not GDPR-certified, not PCI, not a store build.

- **API**: Helmet.js, CORS; cleartext HTTP on the LAN
- **Auth**: Google Sign-In attempted; lab-device fallback until Firebase SHA-1
- **Future**: JWT, TLS 1.3, Stripe Payment Sheet, CRA Art. 14

## 🛣️ Roadmap

### Phase 1: Backend (✅ Complete)
- [x] Database schema
- [x] Mock CPO service
- [x] Sync worker
- [x] REST API endpoints

### Phase 2: Mobile App (lab on Android tablet)
- [x] Flutter project setup
- [x] Google Maps integration (right-side filter/zoom rail)
- [x] Station list & detail screens
- [x] Backend API integration
- [ ] Store-ready Google Sign-In (Firebase SHA-1)
- [ ] iOS

### Phase 3: Advanced Features
- [ ] Real CPO integrations (OCPI protocol)
- [ ] User JWT
- [x] Charging session control (lab estimate, not CPO)
- [ ] In-app payments (Stripe + wallets)
- [ ] Push notifications

## 📝 License

Private project - All rights reserved.

## 👤 Author

**Tomas Lapinskas**  
GitHub: [@Tomukas56](https://github.com/Tomukas56)

## 📞 Support

For issues or questions, create an issue in the GitHub repository.
