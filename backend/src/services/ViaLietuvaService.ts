import {
    ConnectorStatus,
    ConnectorType,
    type StationData,
} from './CPOService.js';

/**
 * Official Via Lietuva open data (NAP), CC BY 4.0 / ODC-BY.
 * https://ev.vialietuva.lt/atviri-duomenys-1
 * App never calls this — only the server connector does.
 */
const VL_BASE = 'https://ev.vialietuva.lt/ocpi/2.3.0';
const VL_UA =
    'EnergyEniwhere/1.0 (lab aggregator; attribution: Via Lietuva CC BY 4.0)';

type OcpiEnvelope<T> = {
    status_code?: number;
    data?: T;
};

type OcpiPrice = { excl_vat?: number | string; incl_vat?: number | string };

type OcpiTariff = {
    id: string;
    currency?: string;
    elements?: Array<{
        price_components?: Array<{
            type?: string;
            price?: number | string;
            vat?: number | string | null;
        }>;
    }>;
    min_price?: OcpiPrice | null;
    max_price?: OcpiPrice | null;
};

type OcpiConnector = {
    id?: string;
    standard?: string;
    max_electric_power?: number | string;
    amperage?: number | string;
    voltage?: number | string;
    tariff_ids?: string[];
};

type OcpiEvse = {
    uid?: string;
    evse_id?: string;
    status?: string;
    last_updated?: string;
    connectors?: OcpiConnector[];
};

type OcpiLocation = {
    id?: string | number;
    country_code?: string;
    party_id?: string;
    publish?: boolean;
    name?: string;
    address?: string;
    city?: string;
    coordinates?: { latitude?: string; longitude?: string };
    operator?: { name?: string; website?: string };
    owner?: { name?: string };
    help_phone?: string;
    evses?: OcpiEvse[];
    last_updated?: string;
};

export class ViaLietuvaService {
    async fetchStations(): Promise<StationData[]> {
        const tariffs = await this.fetchTariffs();
        const locations = await this.fetchAllLocations();
        const mapped: StationData[] = [];
        const seen = new Set<string>();

        for (const loc of locations) {
            const station = this.mapLocation(loc, tariffs);
            if (!station || seen.has(station.external_id)) continue;
            seen.add(station.external_id);
            mapped.push(station);
        }

        console.log(
            `[ViaLietuva] ${mapped.length} mappable locations ` +
                `(${locations.length} OCPI rows, ${tariffs.size} tariffs)`,
        );
        return mapped;
    }

    private async fetchAllLocations(): Promise<OcpiLocation[]> {
        const all: OcpiLocation[] = [];
        let offset = 0;
        const limit = 100;

        for (let page = 0; page < 80; page += 1) {
            const url = `${VL_BASE}/locations?offset=${offset}&limit=${limit}`;
            const { data, total } = await this.getJsonPage<OcpiLocation>(url);
            if (data.length === 0) break;
            all.push(...data);
            offset += limit;
            if (total != null && offset >= total) break;
        }

        return all;
    }

    private async fetchTariffs(): Promise<Map<string, string>> {
        const map = new Map<string, string>();
        const { data } = await this.getJsonPage<OcpiTariff>(`${VL_BASE}/tariffs`);
        for (const tariff of data) {
            const label = formatTariff(tariff);
            if (label) map.set(String(tariff.id), label);
        }
        return map;
    }

    private async getJsonPage<T>(
        url: string,
    ): Promise<{ data: T[]; total: number | null }> {
        const response = await fetch(url, {
            headers: { Accept: 'application/json', 'User-Agent': VL_UA },
        });
        if (!response.ok) {
            const body = await response.text();
            throw new Error(
                `Via Lietuva ${url} failed (${response.status}): ${body.slice(0, 200)}`,
            );
        }
        const envelope = (await response.json()) as OcpiEnvelope<T[]>;
        if (envelope.status_code != null && envelope.status_code !== 1000) {
            throw new Error(
                `Via Lietuva ${url} OCPI status ${envelope.status_code}`,
            );
        }
        const totalHeader = response.headers.get('x-total-count');
        const total = totalHeader != null ? Number(totalHeader) : null;
        return {
            data: Array.isArray(envelope.data) ? envelope.data : [],
            total: Number.isFinite(total) ? total : null,
        };
    }

    private mapLocation(
        loc: OcpiLocation,
        tariffs: Map<string, string>,
    ): StationData | null {
        if (loc.publish === false) return null;

        const latitude = Number(loc.coordinates?.latitude);
        const longitude = Number(loc.coordinates?.longitude);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            return null;
        }

        const connectors = this.mapConnectors(loc, tariffs);
        if (connectors.length === 0) return null;

        const country = (loc.country_code || 'LT').toUpperCase();
        const party = loc.party_id || 'UNK';
        const id = loc.id != null ? String(loc.id) : '';
        if (!id) return null;

        const addressParts = [loc.address, loc.city].filter(
            (part): part is string => Boolean(part && String(part).trim()),
        );

        const mapped: StationData = {
            external_id: `vl:${country}:${party}:${id}`,
            name: (loc.name || `Via Lietuva ${id}`).trim(),
            operator_name: loc.operator?.name || loc.owner?.name || 'Via Lietuva',
            address: addressParts.join(', ') || (loc.name || 'Lithuania'),
            country_code: country,
            latitude,
            longitude,
            is_public: true,
            connectors,
        };

        if (loc.operator?.website) mapped.website = loc.operator.website;
        if (loc.help_phone) mapped.phone = loc.help_phone;

        return mapped;
    }

    private mapConnectors(
        loc: OcpiLocation,
        tariffs: Map<string, string>,
    ): StationData['connectors'] {
        const connectors: StationData['connectors'] = [];

        for (const evse of loc.evses || []) {
            const status = mapOcpiStatus(evse.status);
            if (status === null) continue;
            const evseId = evse.evse_id || evse.uid;
            if (!evseId) continue;

            for (const raw of evse.connectors || []) {
                const type = mapOcpiStandard(raw.standard);
                if (!type) continue;
                const row: StationData['connectors'][number] = {
                    evse_id: raw.id ? `${evseId}:${raw.id}` : evseId,
                    type,
                    max_power_kw: powerKw(raw),
                    status,
                };
                const tariff = firstTariffLabel(raw.tariff_ids, tariffs);
                if (tariff) row.tariff = tariff;
                connectors.push(row);
            }
        }

        return connectors;
    }
}

/** REMOVED / PLANNED EVSE are skipped (null). */
function mapOcpiStatus(status: string | undefined): ConnectorStatus | null {
    switch ((status || 'UNKNOWN').toUpperCase()) {
        case 'AVAILABLE':
            return ConnectorStatus.AVAILABLE;
        case 'CHARGING':
            return ConnectorStatus.CHARGING;
        case 'OCCUPIED':
        case 'RESERVED':
            return ConnectorStatus.OCCUPIED;
        case 'OUTOFORDER':
        case 'INOPERATIVE':
        case 'BLOCKED':
            return ConnectorStatus.OUTOFORDER;
        case 'REMOVED':
        case 'PLANNED':
            return null;
        default:
            return ConnectorStatus.UNKNOWN;
    }
}

function mapOcpiStandard(standard: string | undefined): ConnectorType | null {
    switch ((standard || '').toUpperCase()) {
        case 'IEC_62196_T2':
        case 'IEC_62196_T2_CABLE':
            return ConnectorType.TYPE2;
        case 'IEC_62196_T1':
            return ConnectorType.TYPE1;
        case 'IEC_62196_T2_COMBO':
        case 'IEC_62196_T1_COMBO':
        case 'TESLA_S':
        case 'TESLA_R':
            return ConnectorType.CCS;
        case 'CHADEMO':
            return ConnectorType.CHAdeMO;
        default:
            return null;
    }
}

function powerKw(connector: OcpiConnector): number {
    const raw = Number(connector.max_electric_power);
    if (Number.isFinite(raw) && raw > 0) {
        return raw >= 1000 ? Math.round((raw / 1000) * 10) / 10 : raw;
    }
    const amps = Number(connector.amperage);
    const volts = Number(connector.voltage);
    if (Number.isFinite(amps) && Number.isFinite(volts) && amps > 0 && volts > 0) {
        return Math.round(((amps * volts) / 1000) * 10) / 10;
    }
    return 0;
}

function firstTariffLabel(
    ids: string[] | undefined,
    tariffs: Map<string, string>,
): string | undefined {
    for (const id of ids || []) {
        const label = tariffs.get(id);
        if (label) return label;
    }
    return undefined;
}

function formatTariff(tariff: OcpiTariff): string | undefined {
    const currency = (tariff.currency || 'EUR').toUpperCase() === 'EUR' ? '€' : `${tariff.currency} `;
    for (const element of tariff.elements || []) {
        for (const component of element.price_components || []) {
            if ((component.type || '').toUpperCase() !== 'ENERGY') continue;
            const price = Number(component.price);
            if (!Number.isFinite(price)) continue;
            return `${currency}${price.toFixed(2)}/kWh`;
        }
    }
    const fallback = Number(tariff.min_price?.incl_vat ?? tariff.min_price?.excl_vat);
    if (Number.isFinite(fallback)) {
        return `${currency}${fallback.toFixed(2)}/kWh`;
    }
    return undefined;
}
