-- CreateEnum
CREATE TYPE "ConnectorType" AS ENUM ('CCS', 'CHAdeMO', 'TYPE2', 'TYPE1');

-- CreateEnum
CREATE TYPE "ConnectorStatus" AS ENUM ('AVAILABLE', 'OCCUPIED', 'CHARGING', 'OUTOFORDER', 'UNKNOWN');

-- CreateTable
CREATE TABLE "station" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "operator_name" TEXT,
    "address" TEXT NOT NULL,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "website" TEXT,
    "phone" TEXT,
    "opening_hours" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "station_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "connector" (
    "id" TEXT NOT NULL,
    "evse_id" TEXT NOT NULL,
    "type" "ConnectorType" NOT NULL,
    "max_power_kw" DECIMAL(10,2) NOT NULL,
    "status" "ConnectorStatus" NOT NULL DEFAULT 'UNKNOWN',
    "tariff" TEXT,
    "station_id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "connector_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "connector" ADD CONSTRAINT "connector_station_id_fkey" FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE CASCADE ON UPDATE CASCADE;
