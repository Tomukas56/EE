import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

import { AppDataSource } from "./data-source.js"

app.get('/', (req, res) => {
  res.send('Energy Eniwhere API is running');
});

AppDataSource.initialize().then(async () => {
  console.log("Database connected")
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}).catch(error => console.log(error))
