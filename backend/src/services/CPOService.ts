export enum ConnectorType {
    CCS = "CCS",
    CHAdeMO = "CHAdeMO",
    TYPE2 = "TYPE2",
    TYPE1 = "TYPE1"
}

export enum ConnectorStatus {
    AVAILABLE = "AVAILABLE",
    OCCUPIED = "OCCUPIED",
    CHARGING = "CHARGING",
    OUTOFORDER = "OUTOFORDER",
    UNKNOWN = "UNKNOWN"
}

export interface StationData {
    external_id: string;
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

type OcmLookup = {
    Title?: string;
    WebsiteURL?: string | null;
    PhonePrimaryContact?: string | null;
    IsOperational?: boolean | null;
};

type OcmConnection = {
    ID?: number;
    ConnectionTypeID?: number;
    Reference?: string | null;
    StatusTypeID?: number;
    PowerKW?: number | null;
    Quantity?: number | null;
};

type OcmPoi = {
    ID: number;
    UUID?: string;
    OperatorID?: number;
    UsageTypeID?: number;
    StatusTypeID?: number;
    UsageCost?: string | null;
    AddressInfo?: {
        Title?: string;
        AddressLine1?: string;
        AddressLine2?: string;
        Town?: string;
        Postcode?: string;
        AccessComments?: string;
        ContactTelephone1?: string;
        RelatedURL?: string;
        Latitude?: number;
        Longitude?: number;
    };
    Connections?: OcmConnection[];
};

const SKIP_STATION_STATUS_IDS = new Set([150, 200, 210]);
const PUBLIC_USAGE_IDS = new Set([1, 4, 5, 7]);

/** OCM ConnectionType IDs that map onto our Prisma enums. Others are skipped. */
const CONNECTION_TYPE_MAP: Record<number, ConnectorType> = {
    1: ConnectorType.TYPE1,
    2: ConnectorType.CHAdeMO,
    25: ConnectorType.TYPE2,
    32: ConnectorType.CCS,
    33: ConnectorType.CCS,
    27: ConnectorType.CCS,
    1036: ConnectorType.TYPE2,
};

const OCM_BASE = "https://api.openchargemap.io/v3";

export class CPOService {
    private readonly apiKey: string;
    private readonly country: string;
    private readonly maxResults: number;

    constructor() {
        this.apiKey = (process.env.CPOAPI || "").trim();
        this.country = (process.env.OCM_COUNTRY || "LT").trim();
        this.maxResults = Number(process.env.OCM_MAX_RESULTS || 5000);
    }

    async fetchStations(): Promise<StationData[]> {
        if (!this.apiKey) {
            throw new Error("CPOAPI is not set — cannot fetch Open Charge Map data");
        }

        const [reference, pois] = await Promise.all([
            this.getJson<Record<string, OcmLookup[]>>("referencedata"),
            this.getJson<OcmPoi[]>(
                `poi/?output=json&countrycode=${encodeURIComponent(this.country)}` +
                `&maxresults=${this.maxResults}&compact=true&verbose=false`
            ),
        ]);

        const operators = indexById(reference.Operators || []);
        const usageTypes = indexById(reference.UsageTypes || []);

        const stations: StationData[] = [];
        for (const poi of pois) {
            const mapped = this.mapPoi(poi, operators, usageTypes);
            if (mapped) stations.push(mapped);
        }

        return stations;
    }

    private async getJson<T>(path: string): Promise<T> {
        const response = await fetch(`${OCM_BASE}/${path}`, {
            headers: {
                "X-API-Key": this.apiKey,
                "User-Agent": "EnergyEniwhere/1.0",
            },
        });

        if (!response.ok) {
            const body = await response.text();
            throw new Error(`Open Charge Map ${path} failed (${response.status}): ${body.slice(0, 200)}`);
        }

        return response.json() as Promise<T>;
    }

    private mapPoi(
        poi: OcmPoi,
        operators: Map<number, OcmLookup>,
        usageTypes: Map<number, OcmLookup>,
    ): StationData | null {
        if (SKIP_STATION_STATUS_IDS.has(poi.StatusTypeID ?? -1)) {
            return null;
        }

        const address = poi.AddressInfo;
        const latitude = address?.Latitude;
        const longitude = address?.Longitude;
        if (latitude == null || longitude == null) {
            return null;
        }

        const connectors = this.mapConnectors(poi);
        if (connectors.length === 0) {
            return null;
        }

        const operator = operators.get(poi.OperatorID ?? -1);
        const usage = usageTypes.get(poi.UsageTypeID ?? -1);
        const isPublic = PUBLIC_USAGE_IDS.has(poi.UsageTypeID ?? 1) ||
            (usage?.Title || "").toLowerCase().includes("public");

        const addressParts = [
            address?.AddressLine1,
            address?.AddressLine2,
            address?.Town,
            address?.Postcode,
        ].filter((part): part is string => Boolean(part && part.trim()));

        const mapped: StationData = {
            external_id: `ocm:${poi.ID}`,
            name: (address?.Title || `OCM ${poi.ID}`).trim(),
            operator_name: operator?.Title || "Unknown",
            address: addressParts.join(", ") || (address?.Title || "Unknown address"),
            latitude,
            longitude,
            is_public: isPublic,
            connectors,
        };

        const website = address?.RelatedURL || operator?.WebsiteURL;
        if (website) mapped.website = website;
        const phone = address?.ContactTelephone1 || operator?.PhonePrimaryContact;
        if (phone) mapped.phone = phone;
        if (address?.AccessComments) mapped.opening_hours = address.AccessComments;

        return mapped;
    }

    private mapConnectors(poi: OcmPoi): StationData["connectors"] {
        const connectors: StationData["connectors"] = [];
        const stationOperational = poi.StatusTypeID !== 100 && poi.StatusTypeID !== 30;

        for (const connection of poi.Connections || []) {
            const type = CONNECTION_TYPE_MAP[connection.ConnectionTypeID ?? -1];
            if (!type) continue;

            const quantity = Math.min(Math.max(connection.Quantity || 1, 1), 16);
            const status = mapConnectorStatus(connection.StatusTypeID, stationOperational);
            const evseBase = connection.Reference ||
                (connection.ID != null ? `OCM-${connection.ID}` : `OCM-${poi.ID}`);

            for (let i = 0; i < quantity; i++) {
                const row: StationData["connectors"][number] = {
                    evse_id: quantity > 1 ? `${evseBase}:${i + 1}` : evseBase,
                    type,
                    max_power_kw: connection.PowerKW ?? 0,
                    status,
                };
                if (poi.UsageCost) row.tariff = poi.UsageCost;
                connectors.push(row);
            }
        }

        return connectors;
    }
}

function mapConnectorStatus(statusTypeId: number | undefined, stationOperational: boolean): ConnectorStatus {
    if (statusTypeId === 100 || statusTypeId === 30 || statusTypeId === 200) {
        return ConnectorStatus.OUTOFORDER;
    }
    if (!stationOperational) {
        return ConnectorStatus.OUTOFORDER;
    }
    // OCM occupancy (10/20) is community-based and often stale — do not treat as live.
    return ConnectorStatus.UNKNOWN;
}

function indexById(items: OcmLookup[]): Map<number, OcmLookup> {
    const map = new Map<number, OcmLookup>();
    for (const item of items) {
        const id = (item as OcmLookup & { ID?: number }).ID;
        if (typeof id === "number") {
            map.set(id, item);
        }
    }
    return map;
}
