import "reflect-metadata"
import { DataSource } from "typeorm"
import { Station } from "./entity/Station.js"
import { Connector } from "./entity/Connector.js"
import * as dotenv from "dotenv"

dotenv.config()

const { DB_USER, DB_PASSWORD, DB_NAME } = process.env;

if (!DB_USER || !DB_PASSWORD || !DB_NAME) {
    throw new Error("Missing database credentials in environment variables.");
}

export const AppDataSource = new DataSource({
    type: "postgres",
    host: "localhost",
    port: 5432,
    username: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
    synchronize: true, // TODO: Disable in production
    logging: false,
    entities: [Station, Connector],
    migrations: [],
    subscribers: [],
})
