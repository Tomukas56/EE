export declare class SyncWorker {
    private cpoService;
    private task;
    constructor();
    /**
     * Start the sync worker (runs daily at 2 AM)
     */
    start(): void;
    /**
     * Stop the sync worker
     */
    stop(): void;
    /**
     * Manually trigger sync (for testing)
     */
    syncNow(): Promise<void>;
    /**
     * Fetch stations from CPO and upsert into database
     */
    private syncStations;
}
//# sourceMappingURL=SyncWorker.d.ts.map