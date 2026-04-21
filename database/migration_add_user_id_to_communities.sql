-- Migration: Add user_id to communities table
-- Date: 2026-04-21
-- Purpose: Link communities to users table instead of using email

-- Step 1: Add user_id column (nullable first)
ALTER TABLE communities 
ADD COLUMN user_id INTEGER;

-- Step 2: Populate user_id for existing communities
-- Match communities.email with users.email
UPDATE communities c
SET user_id = u.id
FROM users u
WHERE c.email = u.email;

-- Step 3: For communities that don't have matching user email
-- Find by matching first/last name or create a mapping manually
-- (This step may need manual intervention)

-- Step 4: Set user_id as NOT NULL (after ensuring all have values)
-- ALTER TABLE communities 
-- ALTER COLUMN user_id SET NOT NULL;

-- Step 5: Add foreign key constraint
-- ALTER TABLE communities
-- ADD CONSTRAINT fk_communities_user
-- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 6: Create index for better query performance
CREATE INDEX idx_communities_user_id ON communities(user_id);

-- Verification query - check which communities don't have user_id
SELECT 
    id, 
    community_name, 
    email, 
    user_id,
    CASE 
        WHEN user_id IS NULL THEN '❌ No user_id'
        ELSE '✅ Has user_id'
    END as status
FROM communities
ORDER BY user_id NULLS FIRST;
