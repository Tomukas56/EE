-- AlterTable
ALTER TABLE "station" ADD COLUMN "external_id" TEXT;
ALTER TABLE "station" ADD COLUMN "last_synced_at" TIMESTAMP(3);

-- CreateIndex
CREATE UNIQUE INDEX "station_external_id_key" ON "station"("external_id");
