export declare enum ConnectorType {
    CCS = "CCS",
    CHAdeMO = "CHAdeMO",
    TYPE2 = "TYPE2",
    TYPE1 = "TYPE1"
}
export declare enum ConnectorStatus {
    AVAILABLE = "AVAILABLE",
    OCCUPIED = "OCCUPIED",
    CHARGING = "CHARGING",
    OUTOFORDER = "OUTOFORDER",
    UNKNOWN = "UNKNOWN"
}
export interface MockStationData {
    name: string;
    operator_name: string;
    address: string;
    latitude: number;
    longitude: number;
    is_public: boolean;
    website?: string;
    phone?: string;
    opening_hours?: string;
    connectors: {
        evse_id: string;
        type: ConnectorType;
        max_power_kw: number;
        status: ConnectorStatus;
        tariff?: string;
    }[];
}
export declare class CPOService {
    /**
     * Mock CPO API - simulates fetching station data from external provider
     */
    fetchStations(): Promise<MockStationData[]>;
}
//# sourceMappingURL=CPOService.d.ts.map