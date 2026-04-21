-- Migration: Add username column to users table
-- Date: 2026-04-21
-- Description: เพิ่ม column username สำหรับใช้ login แทน email

-- Step 1: เพิ่ม column username (ยอมรับ NULL ก่อน)
ALTER TABLE eastern_mangrove_communities.users 
ADD COLUMN IF NOT EXISTS username VARCHAR(50);

-- Step 2: Update existing users - สร้าง username จาก email
-- ตัวอย่าง: user@example.com -> user
-- ถ้าซ้ำกัน จะเพิ่ม id ต่อท้าย เช่น user_123
UPDATE eastern_mangrove_communities.users
SET username = LOWER(
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM eastern_mangrove_communities.users u2 
      WHERE LOWER(SPLIT_PART(u2.email, '@', 1)) = LOWER(SPLIT_PART(eastern_mangrove_communities.users.email, '@', 1))
      AND u2.id < eastern_mangrove_communities.users.id
    )
    THEN SPLIT_PART(email, '@', 1) || '_' || id
    ELSE SPLIT_PART(email, '@', 1)
  END
)
WHERE username IS NULL;

-- Step 3: ทำให้ username เป็น NOT NULL หลังจาก update
ALTER TABLE eastern_mangrove_communities.users
ALTER COLUMN username SET NOT NULL;

-- Step 4: สร้าง unique constraint
ALTER TABLE eastern_mangrove_communities.users
ADD CONSTRAINT users_username_unique UNIQUE (username);

-- Step 5: สร้าง index สำหรับ performance
CREATE INDEX IF NOT EXISTS idx_users_username 
ON eastern_mangrove_communities.users(username);
