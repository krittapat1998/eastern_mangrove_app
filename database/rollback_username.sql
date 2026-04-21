-- Rollback: Remove username column
-- Date: 2026-04-21

-- ลบ index
DROP INDEX IF EXISTS eastern_mangrove_communities.idx_users_username;

-- ลบ constraint
ALTER TABLE eastern_mangrove_communities.users
DROP CONSTRAINT IF EXISTS users_username_unique;

-- ลบ column
ALTER TABLE eastern_mangrove_communities.users
DROP COLUMN IF EXISTS username;
