-- Crowd-sourced station submissions and on-site check-ins

CREATE TYPE "SubmissionStatus" AS ENUM ('PENDING', 'OWNER_CONFIRMED', 'REJECTED');
CREATE TYPE "CheckAnswer" AS ENUM ('YES', 'NO', 'DISMISSED');

CREATE TABLE "station_submission" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "operator_name" TEXT,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "connector_note" TEXT,
    "submitted_by" TEXT NOT NULL,
    "status" "SubmissionStatus" NOT NULL DEFAULT 'PENDING',
    "owner_note" TEXT,
    "published_station_id" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "station_submission_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "site_check_in" (
    "id" TEXT NOT NULL,
    "station_id" TEXT NOT NULL,
    "reporter_id" TEXT NOT NULL,
    "working" "CheckAnswer" NOT NULL,
    "free_connectors" "CheckAnswer" NOT NULL,
    "latitude" DECIMAL(10,7),
    "longitude" DECIMAL(10,7),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "site_check_in_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "site_check_in" ADD CONSTRAINT "site_check_in_station_id_fkey"
  FOREIGN KEY ("station_id") REFERENCES "station"("id") ON DELETE CASCADE ON UPDATE CASCADE;
