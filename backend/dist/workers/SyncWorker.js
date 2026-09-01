import cron from 'node-cron';
import prisma from '../lib/prisma.js';
import { CPOService } from '../services/CPOService.js';
export class SyncWorker {
    cpoService;
    task = null;
    constructor() {
        this.cpoService = new CPOService();
    }
    start() {
        console.log('[SyncWorker] Starting... Schedule: Daily at 02:00 (Open Charge Map)');
        this.syncStations().catch(err => console.error('[SyncWorker] Initial sync failed:', err));
        this.task = cron.schedule('0 2 * * *', async () => {
            console.log('[SyncWorker] Running scheduled sync...');
            await this.syncStations();
        });
    }
    stop() {
        if (this.task) {
            this.task.stop();
            console.log('[SyncWorker] Stopped');
        }
    }
    async syncNow() {
        console.log('[SyncWorker] Manual sync triggered');
        await this.syncStations();
    }
    async syncStations() {
        try {
            console.log('[SyncWorker] Fetching stations from Open Charge Map...');
            const stations = await this.cpoService.fetchStations();
            if (stations.length === 0) {
                throw new Error('Open Charge Map returned no mappable stations — leaving existing data unchanged');
            }
            const syncedIds = [];
            const now = new Date();
            for (const incoming of stations) {
                const station = await this.upsertStation(incoming, now);
                syncedIds.push(station.external_id);
                await prisma.connector.deleteMany({
                    where: { station_id: station.id }
                });
                if (incoming.connectors.length > 0) {
                    await prisma.connector.createMany({
                        data: incoming.connectors.map(connector => ({
                            evse_id: connector.evse_id,
                            type: connector.type,
                            max_power_kw: connector.max_power_kw,
                            status: connector.status,
                            tariff: connector.tariff || null,
                            station_id: station.id
                        }))
                    });
                }
            }
            const removed = await prisma.station.deleteMany({
                where: {
                    AND: [
                        { NOT: { external_id: { startsWith: 'user:' } } },
                        {
                            OR: [
                                { external_id: null },
                                { external_id: { notIn: syncedIds } },
                            ],
                        },
                    ],
                },
            });
            console.log(`[SyncWorker] Synced ${stations.length} OCM stations` +
                (removed.count ? `, removed ${removed.count} stale/mock rows` : ''));
        }
        catch (error) {
            console.error('[SyncWorker] Sync failed:', error);
            throw error;
        }
    }
    async upsertStation(incoming, now) {
        const data = {
            external_id: incoming.external_id,
            name: incoming.name,
            operator_name: incoming.operator_name,
            address: incoming.address,
            latitude: incoming.latitude,
            longitude: incoming.longitude,
            is_public: incoming.is_public,
            website: incoming.website || null,
            phone: incoming.phone || null,
            opening_hours: incoming.opening_hours || null,
            last_synced_at: now
        };
        return prisma.station.upsert({
            where: { external_id: incoming.external_id },
            create: data,
            update: data
        });
    }
}
//# sourceMappingURL=SyncWorker.js.map