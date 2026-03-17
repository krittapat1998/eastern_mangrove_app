-- Migration: Add economic and social fields to communities table
-- Date: 2026-03-09

-- Add new columns for economic and social data
ALTER TABLE communities 
ADD COLUMN IF NOT EXISTS village_name VARCHAR(200),
ADD COLUMN IF NOT EXISTS sub_district VARCHAR(150),
ADD COLUMN IF NOT EXISTS district VARCHAR(150),
ADD COLUMN IF NOT EXISTS province VARCHAR(150),
ADD COLUMN IF NOT EXISTS total_population INTEGER DEFAULT 0 CHECK (total_population >= 0),
ADD COLUMN IF NOT EXISTS resource_dependent_population INTEGER DEFAULT 0 CHECK (resource_dependent_population >= 0),
ADD COLUMN IF NOT EXISTS households INTEGER DEFAULT 0 CHECK (households >= 0),
ADD COLUMN IF NOT EXISTS main_occupation VARCHAR(100),
ADD COLUMN IF NOT EXISTS main_religion VARCHAR(50),
ADD COLUMN IF NOT EXISTS occupations TEXT[], -- Array of occupations in the community
ADD COLUMN IF NOT EXISTS average_income DECIMAL(15, 2) DEFAULT 0 CHECK (average_income >= 0);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_communities_province ON communities(province);
CREATE INDEX IF NOT EXISTS idx_communities_district ON communities(district);

-- Add comment for documentation
COMMENT ON COLUMN communities.village_name IS 'ชื่อหมู่บ้าน';
COMMENT ON COLUMN communities.sub_district IS 'ตำบล';
COMMENT ON COLUMN communities.district IS 'อำเภอ';
COMMENT ON COLUMN communities.province IS 'จังหวัด';
COMMENT ON COLUMN communities.total_population IS 'จำนวนประชากรทั้งหมด (คน)';
COMMENT ON COLUMN communities.resource_dependent_population IS 'จำนวนคนที่พึ่งพิงทรัพยากรป่าชายเลน (คน)';
COMMENT ON COLUMN communities.households IS 'จำนวนครัวเรือน';
COMMENT ON COLUMN communities.main_occupation IS 'อาชีพหลัก';
COMMENT ON COLUMN communities.main_religion IS 'ศาสนาหลัก';
COMMENT ON COLUMN communities.occupations IS 'อาชีพที่มีในชุมชน (array)';
COMMENT ON COLUMN communities.average_income IS 'รายได้เฉลี่ยต่อครัวเรือน (บาท/เดือน)';
