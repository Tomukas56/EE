import cron from 'node-cron';
import prisma from '../lib/prisma.js';
import { CPOService } from '../services/CPOService.js';
import { ViaLietuvaService } from '../services/ViaLietuvaService.js';
const VL_PREFIX = 'vl:';
const USER_PREFIX = 'user:';
export class SyncWorker {
    cpoService;
    viaLietuva;
    dailyTask = null;
    viaTask = null;
    constructor() {
        this.cpoService = new CPOService();
        this.viaLietuva = new ViaLietuvaService();
    }
    start() {
        console.log('[SyncWorker] Starting… Via Lietuva OCPI every 5 min; Open Charge Map daily 02:00');
        this.syncAll().catch((err) => console.error('[SyncWorker] Initial sync failed:', err));
        this.viaTask = cron.schedule('*/5 * * * *', async () => {
            console.log('[SyncWorker] Scheduled Via Lietuva refresh…');
            await this.syncViaLietuva();
        });
        this.dailyTask = cron.schedule('0 2 * * *', async () => {
            console.log('[SyncWorker] Scheduled Open Charge Map sync…');
            await this.syncOcm();
        });
    }
    stop() {
        this.viaTask?.stop();
        this.dailyTask?.stop();
        this.viaTask = null;
        this.dailyTask = null;
        console.log('[SyncWorker] Stopped');
    }
    async syncNow() {
        console.log('[SyncWorker] Manual sync triggered');
        await this.syncAll();
    }
    async syncAll() {
        const viaOk = await this.syncViaLietuva();
        await this.syncOcm({ skipLithuania: viaOk });
    }
    async syncViaLietuva() {
        try {
            console.log('[SyncWorker] Fetching Via Lietuva open OCPI…');
            const stations = await this.viaLietuva.fetchStations();
            if (stations.length === 0) {
                throw new Error('Via Lietuva returned no mappable locations');
            }
            await this.upsertCatalogue(stations);
            const stale = await prisma.station.deleteMany({
                where: {
                    external_id: { startsWith: VL_PREFIX },
                    NOT: { external_id: { in: stations.map((s) => s.external_id) } },
                },
            });
            if (stale.count) {
                console.log(`[SyncWorker] Removed ${stale.count} stale Via Lietuva rows`);
            }
            return true;
        }
        catch (error) {
            console.error('[SyncWorker] Via Lietuva sync failed — keeping existing vl: rows:', error);
            return false;
        }
    }
    async syncOcm(options) {
        try {
            const exclude = options?.skipLithuania ? ['LT'] : [];
            console.log(`[SyncWorker] Fetching Open Charge Map…` +
                (exclude.length ? ` (skip ${exclude.join(',')})` : ''));
            const { stations, fetchedCountries } = await this.cpoService.fetchStations({
                excludeCountries: exclude,
            });
            if (stations.length === 0 || fetchedCountries.length === 0) {
                throw new Error('Open Charge Map returned no mappable stations');
            }
            await this.upsertCatalogue(stations);
            if (options?.skipLithuania) {
                const removedLt = await prisma.station.deleteMany({
                    where: {
                        country_code: 'LT',
                        external_id: { startsWith: 'ocm:' },
                    },
                });
                if (removedLt.count) {
                    console.log(`[SyncWorker] Removed ${removedLt.count} OCM Lithuania rows (Via Lietuva is source)`);
                }
            }
            const syncedIds = stations.map((s) => s.external_id);
            const removed = await prisma.station.deleteMany({
                where: {
                    AND: [
                        { NOT: { external_id: { startsWith: USER_PREFIX } } },
                        { NOT: { external_id: { startsWith: VL_PREFIX } } },
                        {
                            OR: [
                                { external_id: null },
                                {
                                    AND: [
                                        { country_code: { in: fetchedCountries } },
                                        { external_id: { notIn: syncedIds } },
                                    ],
                                },
                            ],
                        },
                    ],
                },
            });
            console.log(`[SyncWorker] Synced ${stations.length} OCM stations` +
                (removed.count ? `, removed ${removed.count} stale/mock rows` : ''));
        }
        catch (error) {
            console.error('[SyncWorker] OCM sync failed:', error);
        }
    }
    async upsertCatalogue(stations) {
        const now = new Date();
        let i = 0;
        for (const incoming of stations) {
            i += 1;
            const station = await this.upsertStation(incoming, now);
            await prisma.connector.deleteMany({ where: { station_id: station.id } });
            if (incoming.connectors.length === 0)
                continue;
            await prisma.connector.createMany({
                data: incoming.connectors.map((connector) => ({
                    evse_id: connector.evse_id,
                    type: connector.type,
                    max_power_kw: connector.max_power_kw,
                    status: connector.status,
                    tariff: connector.tariff || null,
                    station_id: station.id,
                })),
            });
            if (i % 250 === 0) {
                console.log(`[SyncWorker] Upsert progress ${i}/${stations.length}`);
            }
        }
        console.log(`[SyncWorker] Upserted ${stations.length} stations`);
    }
    async upsertStation(incoming, now) {
        const data = {
            external_id: incoming.external_id,
            name: incoming.name,
            operator_name: incoming.operator_name,
            address: incoming.address,
            country_code: incoming.country_code,
            latitude: incoming.latitude,
            longitude: incoming.longitude,
            is_public: incoming.is_public,
            website: incoming.website || null,
            phone: incoming.phone || null,
            opening_hours: incoming.opening_hours || null,
            last_synced_at: now,
        };
        return prisma.station.upsert({
            where: { external_id: incoming.external_id },
            create: data,
            update: data,
        });
    }
}
//# sourceMappingURL=SyncWorker.js.map