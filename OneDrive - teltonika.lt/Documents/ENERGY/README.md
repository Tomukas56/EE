# Energy Eniwhere - EV Charging Station Aggregator

Mobile application to find and use EV charging stations across Lithuania.

## 📋 Project Overview

**Energy Eniwhere** aggregates electric vehicle charging stations from multiple operators (CPOs) into a single platform, allowing users to:
- Find nearby charging stations
- View real-time connector availability
- See pricing and power ratings
- Navigate to stations
- (Future) Start/stop charging sessions
- (Future) Pay for charging

## 🏗️ Architecture

### Backend
- **Runtime**: Node.js 22+ with TypeScript
- **Framework**: Express.js 5
- **Database**: PostgreSQL 16 with Prisma ORM 5.22
- **Data**: Mock CPO service (7 Lithuanian stations)
- **Sync**: Cron worker (daily at 2 AM)

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

### Frontend (Planned)
- **Framework**: Flutter
- **Maps**: Google Maps / Mapbox
- **State**: Provider / Riverpod

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

2. **Start PostgreSQL**
```bash
docker-compose up -d
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
npx prisma migrate dev
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
│   │   │   └── CPOService.ts   # Mock CPO data provider
│   │   ├── workers/
│   │   │   └── SyncWorker.ts   # Data sync cron job
│   │   ├── routes/
│   │   │   └── stationRoutes.ts # API endpoints
│   │   └── index.ts            # Express server
│   ├── .env                    # Environment variables
│   └── package.json
├── docs/
│   ├── specs/
│   │   ├── PRD.md              # Product Requirements
│   │   └── DFD.md              # Data Flow Diagram
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

## 📊 Mock Data

Currently loads 7 charging stations:
1. **Ignitis Charging Hub** - Vilnius Center
2. **Elinta Fast Charge** - Kaunas
3. **Maxima Shopping Center** - Vilnius Ozas
4. **Tesla Supercharger** - Vilnius
5. **Ignitis Green Energy Hub** - Vilnius Žirmūnai
6. **Elinta Downtown** - Kaunas Laisvės
7. **LIDL Parking** - Vilnius Ukmergė

Total: **13 connectors** with various types and power levels.

## 🔐 Security & Compliance

- **GDPR**: No personal data stored yet
- **Database**: Strong passwords, non-default ports
- **API**: Helmet.js security headers, CORS enabled
- **Future**: JWT authentication, rate limiting

## 🛣️ Roadmap

### Phase 1: Backend (✅ Complete)
- [x] Database schema
- [x] Mock CPO service
- [x] Sync worker
- [x] REST API endpoints

### Phase 2: Mobile App (In Progress)
- [ ] Flutter project setup
- [ ] Google Maps integration
- [ ] Station list & detail screens
- [ ] Backend API integration

### Phase 3: Advanced Features
- [ ] Real CPO integrations (OCPI protocol)
- [ ] User authentication
- [] Charging session control
- [ ] In-app payments (Stripe)
- [ ] Push notifications

## 📝 License

Private project - All rights reserved.

## 👤 Author

**Tomas Lapinskas**  
GitHub: [@Tomukas56](https://github.com/Tomukas56)

## 📞 Support

For issues or questions, create an issue in the GitHub repository.
