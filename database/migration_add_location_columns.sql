-- Migration: Add location columns (province / district / sub_district / village_name) to communities
-- Run this once against your PostgreSQL database.
-- Safe to run again — all statements use IF NOT EXISTS.

ALTER TABLE communities
  ADD COLUMN IF NOT EXISTS village_name  VARCHAR(200),
  ADD COLUMN IF NOT EXISTS sub_district  VARCHAR(150),
  ADD COLUMN IF NOT EXISTS district      VARCHAR(150),
  ADD COLUMN IF NOT EXISTS province      VARCHAR(150);

CREATE INDEX IF NOT EXISTS idx_communities_province ON communities(province);
CREATE INDEX IF NOT EXISTS idx_communities_district ON communities(district);

COMMENT ON COLUMN communities.village_name IS 'ชื่อหมู่บ้าน';
COMMENT ON COLUMN communities.sub_district  IS 'ตำบล';
COMMENT ON COLUMN communities.district      IS 'อำเภอ';
COMMENT ON COLUMN communities.province      IS 'จังหวัด';
