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
-- PRODUCTION CHECK (Nov 2026): mangrove_areas.size_hectares is NULL in the only
--   row, so it is unaffected. communities.area_size (ids 1,2,3,6,7 look like rai)
--   needs converting. ids 5 (8.00) and 10 (2937.50) may already be hectares
--   (18358 rai / 6.25 ~= 2937), so they are SKIPPED by default below.
--   Edit the skip list after you confirm their real size.
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
FROM communities WHERE area_size IS NOT NULL AND id NOT IN (5, 10)
ORDER BY 1, 2;

UPDATE mangrove_areas
SET size_hectares = GREATEST(ROUND(size_hectares / 6.25, 2), 0.01),
    updated_at = NOW()
WHERE size_hectares IS NOT NULL;

UPDATE communities
SET area_size = ROUND(area_size / 6.25, 2),
    updated_at = NOW()
WHERE area_size IS NOT NULL
  AND id NOT IN (5, 10);   -- ids believed to be hectares already; edit after checking

-- The transaction is intentionally left OPEN. Check the result, then run ONE of:
--   SELECT id, area_size FROM communities ORDER BY id;   -- inspect new values
--   COMMIT;      -- keep the change
--   ROLLBACK;    -- undo everything
-- (In pgAdmin run the script, look at the output, then run COMMIT or ROLLBACK
--  in the same query session.)
