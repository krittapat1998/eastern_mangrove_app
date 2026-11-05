-- Migration for app v1.0.12: area values rai -> hectares
--
-- BACKGROUND
--   Columns `mangrove_areas.size_hectares` and `communities.area_size` are
--   documented as HECTARES, but app versions <= 1.0.11 labelled the fields
--   "ไร่" and stored whatever the user typed (i.e. rai) without conversion.
--   From v1.0.12 the app converts: DB = hectares, UI = rai (1 ha = 6.25 rai).
--
-- RUN THIS ONLY IF the existing rows really contain rai
--   (check a few rows against the real area first!).
--   Run it ONCE, right when v1.0.12 goes live. Running it twice divides twice.
--   Users still on v1.0.11 will see values 6.25x too small until they update.
--
-- BACKUP FIRST, e.g.:
--   pg_dump -n eastern_mangrove_communities "$DATABASE_URL" > backup_before_area_migration.sql
--
-- NOTE: mangrove_areas has CHECK (size_hectares > 0). Rows are rounded to 2
--   decimals; a tiny value could round to 0 and fail the check, so such rows
--   are kept at 0.01.

BEGIN;

SET search_path TO eastern_mangrove_communities, public;

-- Preview what will change
SELECT 'mangrove_areas' AS tbl, id, size_hectares AS before_value, ROUND(size_hectares / 6.25, 2) AS after_value
FROM mangrove_areas WHERE size_hectares IS NOT NULL
UNION ALL
SELECT 'communities', id, area_size, ROUND(area_size / 6.25, 2)
FROM communities WHERE area_size IS NOT NULL
ORDER BY 1, 2;

UPDATE mangrove_areas
SET size_hectares = GREATEST(ROUND(size_hectares / 6.25, 2), 0.01),
    updated_at = NOW()
WHERE size_hectares IS NOT NULL;

UPDATE communities
SET area_size = ROUND(area_size / 6.25, 2),
    updated_at = NOW()
WHERE area_size IS NOT NULL;

-- Review the preview above, then COMMIT (or ROLLBACK to abort).
COMMIT;
