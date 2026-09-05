import { ConnectorStatus, ConnectorType, } from './CPOService.js';
/**
 * Official Via Lietuva open data (NAP), CC BY 4.0 / ODC-BY.
 * https://ev.vialietuva.lt/atviri-duomenys-1
 * App never calls this — only the server connector does.
 */
const VL_BASE = 'https://ev.vialietuva.lt/ocpi/2.3.0';
const VL_UA = 'EnergyEniwhere/1.0 (lab aggregator; attribution: Via Lietuva CC BY 4.0)';
export class ViaLietuvaService {
    async fetchStations() {
        const tariffs = await this.fetchTariffs();
        const locations = await this.fetchAllLocations();
        const mapped = [];
        const seen = new Set();
        for (const loc of locations) {
            const station = this.mapLocation(loc, tariffs);
            if (!station || seen.has(station.external_id))
                continue;
            seen.add(station.external_id);
            mapped.push(station);
        }
        console.log(`[ViaLietuva] ${mapped.length} mappable locations ` +
            `(${locations.length} OCPI rows, ${tariffs.size} tariffs)`);
        return mapped;
    }
    async fetchAllLocations() {
        const all = [];
        let offset = 0;
        const limit = 100;
        for (let page = 0; page < 80; page += 1) {
            const url = `${VL_BASE}/locations?offset=${offset}&limit=${limit}`;
            const { data, total } = await this.getJsonPage(url);
            if (data.length === 0)
                break;
            all.push(...data);
            offset += data.length;
            if (total != null && offset >= total)
                break;
        }
        return all;
    }
    async fetchTariffs() {
        const map = new Map();
        const { data } = await this.getJsonPage(`${VL_BASE}/tariffs`);
        for (const tariff of data) {
            const label = formatTariff(tariff);
            if (label)
                map.set(String(tariff.id), label);
        }
        return map;
    }
    async getJsonPage(url) {
        const response = await fetch(url, {
            headers: { Accept: 'application/json', 'User-Agent': VL_UA },
        });
        if (!response.ok) {
            const body = await response.text();
            throw new Error(`Via Lietuva ${url} failed (${response.status}): ${body.slice(0, 200)}`);
        }
        const envelope = (await response.json());
        if (envelope.status_code != null && envelope.status_code !== 1000) {
            throw new Error(`Via Lietuva ${url} OCPI status ${envelope.status_code}`);
        }
        const totalHeader = response.headers.get('x-total-count');
        const total = totalHeader != null ? Number(totalHeader) : null;
        return {
            data: Array.isArray(envelope.data) ? envelope.data : [],
            total: Number.isFinite(total) ? total : null,
        };
    }
    mapLocation(loc, tariffs) {
        if (loc.publish === false)
            return null;
        const latitude = Number(loc.coordinates?.latitude);
        const longitude = Number(loc.coordinates?.longitude);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            return null;
        }
        const connectors = this.mapConnectors(loc, tariffs);
        if (connectors.length === 0)
            return null;
        const country = (loc.country_code || 'LT').toUpperCase();
        const party = loc.party_id || 'UNK';
        const id = loc.id != null ? String(loc.id) : '';
        if (!id)
            return null;
        const addressParts = [loc.address, loc.city].filter((part) => Boolean(part && String(part).trim()));
        const mapped = {
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
        if (loc.operator?.website)
            mapped.website = loc.operator.website;
        if (loc.help_phone)
            mapped.phone = loc.help_phone;
        return mapped;
    }
    mapConnectors(loc, tariffs) {
        const connectors = [];
        for (const evse of loc.evses || []) {
            const status = mapOcpiStatus(evse.status);
            if (status === null)
                continue;
            const evseId = evse.evse_id || evse.uid;
            if (!evseId)
                continue;
            for (const raw of evse.connectors || []) {
                const type = mapOcpiStandard(raw.standard);
                if (!type)
                    continue;
                const row = {
                    evse_id: raw.id ? `${evseId}:${raw.id}` : evseId,
                    type,
                    max_power_kw: powerKw(raw),
                    status,
                };
                const tariff = firstTariffLabel(raw.tariff_ids, tariffs);
                if (tariff)
                    row.tariff = tariff;
                connectors.push(row);
            }
        }
        return connectors;
    }
}
/** REMOVED / PLANNED EVSE are skipped (null). */
function mapOcpiStatus(status) {
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
function mapOcpiStandard(standard) {
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
function powerKw(connector) {
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
function firstTariffLabel(ids, tariffs) {
    for (const id of ids || []) {
        const label = tariffs.get(id);
        if (label)
            return label;
    }
    return undefined;
}
function formatTariff(tariff) {
    const currency = (tariff.currency || 'EUR').toUpperCase() === 'EUR' ? '€' : `${tariff.currency} `;
    for (const element of tariff.elements || []) {
        for (const component of element.price_components || []) {
            if ((component.type || '').toUpperCase() !== 'ENERGY')
                continue;
            const price = Number(component.price);
            if (!Number.isFinite(price))
                continue;
            return `${currency}${price.toFixed(2)}/kWh`;
        }
    }
    const fallback = Number(tariff.min_price?.incl_vat ?? tariff.min_price?.excl_vat);
    if (Number.isFinite(fallback)) {
        return `${currency}${fallback.toFixed(2)}/kWh`;
    }
    return undefined;
}
//# sourceMappingURL=ViaLietuvaService.js.map