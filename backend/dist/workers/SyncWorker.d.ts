export declare class SyncWorker {
    private cpoService;
    private task;
    constructor();
    start(): void;
    stop(): void;
    syncNow(): Promise<void>;
    private syncStations;
    private upsertStation;
}
//# sourceMappingURL=SyncWorker.d.ts.map