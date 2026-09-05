export declare class SyncWorker {
    private cpoService;
    private viaLietuva;
    private dailyTask;
    private viaTask;
    constructor();
    start(): void;
    stop(): void;
    syncNow(): Promise<void>;
    private syncAll;
    private syncViaLietuva;
    private syncOcm;
    private upsertCatalogue;
    private upsertStation;
}
//# sourceMappingURL=SyncWorker.d.ts.map