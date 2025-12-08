import "reflect-metadata";
import { DataSource } from "typeorm";
import { Station } from "./entity/Station.js";
import { Connector } from "./entity/Connector.js";
// ... (other imports)
export const AppDataSource = new DataSource({
    // ...
    entities: [Station, Connector],
    // ...
    migrations: [],
    subscribers: [],
});
//# sourceMappingURL=data-source.js.map