import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import prisma from './lib/prisma.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(
  helmet({
    // Browser JSON viewers inject scripts; CSP would render /api/stations as a blank page.
    contentSecurityPolicy: process.env.NODE_ENV === 'production',
  }),
);
app.use(cors());
app.use(express.json());

import stationRoutes from './routes/stationRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import crowdRoutes from './routes/crowdRoutes.js';
import sessionRoutes from './routes/sessionRoutes.js';
import { SyncWorker } from './workers/SyncWorker.js';

app.get('/', (req, res) => {
  if (req.get('sec-fetch-dest') === 'document') {
    res.redirect('/api/stations');
    return;
  }
  res.send('Energy Eniwhere API is running');
});

// API Routes
app.use('/api/stations', stationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/crowd', crowdRoutes);
app.use('/api/sessions', sessionRoutes);

// Test database connection and start server
prisma.$connect()
  .then(async () => {
    console.log("Database connected");

    // Initialize and start sync worker
    const syncWorker = new SyncWorker();
    syncWorker.start();

    app.listen(Number(PORT), "0.0.0.0", () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error("Database connection failed:", error);
    process.exit(1);
  });
