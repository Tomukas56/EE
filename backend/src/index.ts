import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import prisma from './lib/prisma.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

import stationRoutes from './routes/stationRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import { SyncWorker } from './workers/SyncWorker.js';

app.get('/', (req, res) => {
  res.send('Energy Eniwhere API is running');
});

// API Routes
app.use('/api/stations', stationRoutes);
app.use('/api/payments', paymentRoutes);

// Test database connection and start server
prisma.$connect()
  .then(async () => {
    console.log("Database connected");

    // Initialize and start sync worker
    const syncWorker = new SyncWorker();
    syncWorker.start();

    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error("Database connection failed:", error);
    process.exit(1);
  });
