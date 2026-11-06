-- Release v1.0.12: convert communities.area_size from rai to hectares (1 ha = 6.25 rai)
--
-- Safe to re-run: each row is updated ONLY while it still has its original (rai) value,
-- so a second run changes nothing. Rows created by the new app (already hectares,
-- e.g. a community registered after 1.0.12) are never touched.
--
-- Run when Apple approves and you release. Back up first:
--   pg_dump -n eastern_mangrove_communities "$DATABASE_URL" > backup_before_area_migration.sql
--
-- Skipped on purpose: id 11 เนินฆ้อ (8.00) and id 20 ประมงพื้นบ้านปากคลองใหญ่ (2937.50)
-- - they look like hectares already. ids below were read from pgAdmin on 2026-11-06.
-- mangrove_areas.size_hectares is NULL in the only production row, so nothing to convert there.

BEGIN;

SET search_path TO eastern_mangrove_communities, public;

-- 1) BEFORE: current values
SELECT id, community_name, area_size AS before_value
FROM communities
WHERE area_size IS NOT NULL
ORDER BY id;

-- 2) Convert (only rows that still hold the original rai value)
UPDATE communities
SET area_size = ROUND(area_size / 6.25, 2),
    updated_at = NOW()
WHERE (id, area_size) IN (
  (6,  250.00),     -- บ้านปลา
  (7,  18358.00),   -- สองคลอง
  (8,  451.00),     -- คลองตำหรุ
  (12, 500.00),     -- ประมงเรือเล็ก
  (14, 12000.00)    -- ป่าชายเลนบ้านเปร็ดใน
)
RETURNING id, community_name, area_size AS after_value;
-- Expected: 5 rows -> 40.00, 2937.28, 72.16, 80.00, 1920.00
-- If it returns 0 rows the ids/values do not match this database: ROLLBACK and re-check.

-- 3) AFTER: check everything, then run ONE of the two lines below
SELECT id, community_name, area_size FROM communities WHERE area_size IS NOT NULL ORDER BY id;

-- COMMIT;     -- values look right
-- ROLLBACK;   -- anything unexpected
