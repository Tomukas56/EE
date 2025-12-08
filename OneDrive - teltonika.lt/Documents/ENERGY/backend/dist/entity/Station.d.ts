import type { Relation } from "typeorm";
import { Connector } from "./Connector.js";
export declare class Station {
    id: string;
    name: string;
    operator_name: string;
    address: string;
    location: any;
    is_public: boolean;
    website: string;
    phone: string;
    opening_hours: string;
    connectors: Relation<Connector[]>;
}
//# sourceMappingURL=Station.d.ts.map