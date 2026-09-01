ALTER TABLE "station" ADD COLUMN IF NOT EXISTS "country_code" TEXT;
UPDATE "station" SET "country_code" = 'LT' WHERE "country_code" IS NULL AND "external_id" LIKE 'ocm:%';
