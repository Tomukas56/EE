import { Station } from "./Station.js";
export declare enum ConnectorType {
    CCS = "CCS",
    CHAdeMO = "CHAdeMO",
    TYPE2 = "Type 2",
    TYPE1 = "Type 1"
}
export declare enum ConnectorStatus {
    AVAILABLE = "AVAILABLE",
    OCCUPIED = "OCCUPIED",
    CHARGING = "CHARGING",
    OUTOFORDER = "OUTOFORDER",
    UNKNOWN = "UNKNOWN"
}
export declare class Connector {
    id: string;
    evse_id: string;
    type: ConnectorType;
    max_power_kw: number;
    status: ConnectorStatus;
    tariff: string;
    station: Station;
}
//# sourceMappingURL=Connector.d.ts.map