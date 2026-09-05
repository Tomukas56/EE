export var ConnectorType;
(function (ConnectorType) {
    ConnectorType["CCS"] = "CCS";
    ConnectorType["CHAdeMO"] = "CHAdeMO";
    ConnectorType["TYPE2"] = "TYPE2";
    ConnectorType["TYPE1"] = "TYPE1";
})(ConnectorType || (ConnectorType = {}));
export var ConnectorStatus;
(function (ConnectorStatus) {
    ConnectorStatus["AVAILABLE"] = "AVAILABLE";
    ConnectorStatus["OCCUPIED"] = "OCCUPIED";
    ConnectorStatus["CHARGING"] = "CHARGING";
    ConnectorStatus["OUTOFORDER"] = "OUTOFORDER";
    ConnectorStatus["UNKNOWN"] = "UNKNOWN";
})(ConnectorStatus || (ConnectorStatus = {}));
const SKIP_STATION_STATUS_IDS = new Set([150, 200, 210]);
const PUBLIC_USAGE_IDS = new Set([1, 4, 5, 7]);
/** OCM ConnectionType IDs that map onto our Prisma enums. Others are skipped. */
const CONNECTION_TYPE_MAP = {
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
    apiKey;
    countries;
    maxResults;
    constructor() {
        this.apiKey = (process.env.CPOAPI || "").trim();
        const fromList = (process.env.OCM_COUNTRIES || "").trim();
        const fromSingle = (process.env.OCM_COUNTRY || "").trim();
        this.countries = (fromList || fromSingle || "LT,LV,EE,PL")
            .split(",")
            .map((code) => code.trim().toUpperCase())
            .filter(Boolean);
        this.maxResults = Number(process.env.OCM_MAX_RESULTS || 10000);
    }
    get configuredCountries() {
        return [...this.countries];
    }
    async fetchStations(options) {
        if (!this.apiKey) {
            throw new Error("CPOAPI is not set — cannot fetch Open Charge Map data");
        }
        const reference = await this.getJson("referencedata");
        const operators = indexById(reference.Operators || []);
        const usageTypes = indexById(reference.UsageTypes || []);
        const seen = new Set();
        const merged = [];
        const fetchedCountries = [];
        const skip = new Set((options?.excludeCountries || []).map((code) => code.toUpperCase()));
        for (const country of this.countries) {
            if (skip.has(country))
                continue;
            try {
                const pois = await this.getJson(`poi/?output=json&countrycode=${encodeURIComponent(country)}` +
                    `&maxresults=${this.maxResults}&compact=true&verbose=false`);
                let mappedCount = 0;
                for (const poi of pois) {
                    const mapped = this.mapPoi(poi, operators, usageTypes, country);
                    if (!mapped || seen.has(mapped.external_id))
                        continue;
                    seen.add(mapped.external_id);
                    merged.push(mapped);
                    mappedCount += 1;
                }
                fetchedCountries.push(country);
                console.log(`[CPOService] ${country}: ${mappedCount} mappable stations (${pois.length} POIs)`);
            }
            catch (error) {
                console.error(`[CPOService] ${country} fetch failed — keeping existing rows for that country:`, error);
            }
        }
        return { stations: merged, fetchedCountries };
    }
    async getJson(path) {
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
        return response.json();
    }
    mapPoi(poi, operators, usageTypes, countryCode) {
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
        ].filter((part) => Boolean(part && part.trim()));
        const mapped = {
            external_id: `ocm:${poi.ID}`,
            name: (address?.Title || `OCM ${poi.ID}`).trim(),
            operator_name: operator?.Title || "Unknown",
            address: addressParts.join(", ") || (address?.Title || "Unknown address"),
            country_code: countryCode,
            latitude,
            longitude,
            is_public: isPublic,
            connectors,
        };
        const website = address?.RelatedURL || operator?.WebsiteURL;
        if (website)
            mapped.website = website;
        const phone = address?.ContactTelephone1 || operator?.PhonePrimaryContact;
        if (phone)
            mapped.phone = phone;
        if (address?.AccessComments)
            mapped.opening_hours = address.AccessComments;
        return mapped;
    }
    mapConnectors(poi) {
        const connectors = [];
        const stationOperational = poi.StatusTypeID !== 100 && poi.StatusTypeID !== 30;
        for (const connection of poi.Connections || []) {
            const type = CONNECTION_TYPE_MAP[connection.ConnectionTypeID ?? -1];
            if (!type)
                continue;
            const quantity = Math.min(Math.max(connection.Quantity || 1, 1), 16);
            const status = mapConnectorStatus(connection.StatusTypeID, stationOperational);
            const evseBase = connection.Reference ||
                (connection.ID != null ? `OCM-${connection.ID}` : `OCM-${poi.ID}`);
            for (let i = 0; i < quantity; i++) {
                const row = {
                    evse_id: quantity > 1 ? `${evseBase}:${i + 1}` : evseBase,
                    type,
                    max_power_kw: connection.PowerKW ?? 0,
                    status,
                };
                if (poi.UsageCost)
                    row.tariff = poi.UsageCost;
                connectors.push(row);
            }
        }
        return connectors;
    }
}
function mapConnectorStatus(statusTypeId, stationOperational) {
    if (statusTypeId === 100 || statusTypeId === 30 || statusTypeId === 200) {
        return ConnectorStatus.OUTOFORDER;
    }
    if (!stationOperational) {
        return ConnectorStatus.OUTOFORDER;
    }
    // OCM occupancy (10/20) is community-based and often stale — do not treat as live.
    return ConnectorStatus.UNKNOWN;
}
function indexById(items) {
    const map = new Map();
    for (const item of items) {
        const id = item.ID;
        if (typeof id === "number") {
            map.set(id, item);
        }
    }
    return map;
}
//# sourceMappingURL=CPOService.js.map