import cron from 'node-cron';
import prisma from '../lib/prisma.js';
import { CPOService } from '../services/CPOService.js';

export class SyncWorker {
    private cpoService: CPOService;
    private task: cron.ScheduledTask | null = null;

    constructor() {
        this.cpoService = new CPOService();
    }

    /**
     * Start the sync worker (runs daily at 2 AM)
     */
    start(): void {
        console.log('[SyncWorker] Starting... Schedule: Daily at 02:00');

        // Run immediately on startup
        this.syncStations().catch(err =>
            console.error('[SyncWorker] Initial sync failed:', err)
        );

        // Schedule daily at 2 AM
        this.task = cron.schedule('0 2 * * *', async () => {
            console.log('[SyncWorker] Running scheduled sync...');
            await this.syncStations();
        });
    }

    /**
     * Stop the sync worker
     */
    stop(): void {
        if (this.task) {
            this.task.stop();
            console.log('[SyncWorker] Stopped');
        }
    }

    /**
     * Manually trigger sync (for testing)
     */
    async syncNow(): Promise<void> {
        console.log('[SyncWorker] Manual sync triggered');
        await this.syncStations();
    }

    /**
     * Fetch stations from CPO and upsert into database
     */
    private async syncStations(): Promise<void> {
        try {
            console.log('[Sync Worker] Fetching stations from CPO...');
            const mockStations = await this.cpoService.fetchStations();

            for (const mockStation of mockStations) {
                // Find existing station by name
                let station = await prisma.station.findFirst({
                    where: { name: mockStation.name }
                });

                if (station) {
                    // Update existing station
                    station = await prisma.station.update({
                        where: { id: station.id },
                        data: {
                            operator_name: mockStation.operator_name,
                            address: mockStation.address,
                            latitude: mockStation.latitude,
                            longitude: mockStation.longitude,
                            is_public: mockStation.is_public,
                            website: mockStation.website || null,
                            phone: mockStation.phone || null,
                            opening_hours: mockStation.opening_hours || null
                        }
                    });
                } else {
                    // Create new station
                    station = await prisma.station.create({
                        data: {
                            name: mockStation.name,
                            operator_name: mockStation.operator_name,
                            address: mockStation.address,
                            latitude: mockStation.latitude,
                            longitude: mockStation.longitude,
                            is_public: mockStation.is_public,
                            website: mockStation.website || null,
                            phone: mockStation.phone || null,
                            opening_hours: mockStation.opening_hours || null
                        }
                    });
                }

                // Delete old connectors
                await prisma.connector.deleteMany({
                    where: { station_id: station.id }
                });

                // Create new connectors
                for (const mockConnector of mockStation.connectors) {
                    await prisma.connector.create({
                        data: {
                            evse_id: mockConnector.evse_id,
                            type: mockConnector.type,
                            max_power_kw: mockConnector.max_power_kw,
                            status: mockConnector.status,
                            tariff: mockConnector.tariff || null,
                            station_id: station.id
                        }
                    });
                }
            }

            console.log(`[SyncWorker] Successfully synced ${mockStations.length} stations`);
        } catch (error) {
            console.error('[SyncWorker] Sync failed:', error);
            throw error;
        }
    }
}
