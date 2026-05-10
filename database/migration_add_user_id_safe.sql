-- Safe Migration: Add user_id to communities table
-- Date: 2026-05-10
-- Purpose: Link communities to users table to allow changing community email

-- Step 1: Check if user_id column already exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'eastern_mangrove_communities'
        AND table_name = 'communities' 
        AND column_name = 'user_id'
    ) THEN
        -- Add user_id column (nullable)
        ALTER TABLE eastern_mangrove_communities.communities 
        ADD COLUMN user_id INTEGER;
        
        RAISE NOTICE 'Added user_id column to communities table';
    ELSE
        RAISE NOTICE 'user_id column already exists, skipping...';
    END IF;
END $$;

-- Step 2: Populate user_id for existing communities
-- Match communities.email with users.email
UPDATE eastern_mangrove_communities.communities c
SET user_id = u.id
FROM users u
WHERE c.email = u.email
AND c.user_id IS NULL;

-- Step 3: Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_communities_user_id 
ON eastern_mangrove_communities.communities(user_id);

-- Step 4: Verification - check results
SELECT 
    COUNT(*) as total_communities,
    COUNT(user_id) as communities_with_user_id,
    COUNT(*) - COUNT(user_id) as communities_without_user_id
FROM eastern_mangrove_communities.communities;

-- Step 5: Show communities without user_id (if any)
SELECT 
    id,
    community_name,
    email,
    registration_status,
    CASE 
        WHEN user_id IS NULL THEN '❌ No user_id - needs manual fix'
        ELSE '✅ Has user_id'
    END as status
FROM eastern_mangrove_communities.communities
ORDER BY user_id NULLS FIRST
LIMIT 20;
