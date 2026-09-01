-- CreateTable
CREATE TABLE "charging_session" (
    "id" TEXT NOT NULL,
    "station_id" TEXT NOT NULL,
    "reporter_id" TEXT NOT NULL,
    "connector_type" TEXT,
    "max_power_kw" DECIMAL(10,2),
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ended_at" TIMESTAMP(3),
    "energy_kwh" DECIMAL(10,2),
    "cost_eur" DECIMAL(10,2),
    "status" TEXT NOT NULL DEFAULT 'charging',
    "payment_method" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "charging_session_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "charging_session_reporter_id_status_idx" ON "charging_session"("reporter_id", "status");

ALTER TABLE "charging_session" ADD CONSTRAINT "charging_session_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE CASCADE ON UPDATE CASCADE;
