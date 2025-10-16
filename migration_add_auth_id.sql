-- Migration: Add auth_id column to users table
-- This allows linking Supabase Auth UUIDs with our integer user IDs

-- Add auth_id column to store Supabase Auth UUID
ALTER TABLE users ADD COLUMN auth_id UUID UNIQUE;

-- Create index for faster lookups
CREATE INDEX idx_users_auth_id ON users(auth_id);

-- Update existing users to have auth_id = ma_nguoi_dung (if they were created before this change)
-- This is a temporary fix for existing data
UPDATE users 
SET auth_id = gen_random_uuid() 
WHERE auth_id IS NULL;

-- Add comment explaining the structure
COMMENT ON COLUMN users.auth_id IS 'Supabase Auth UUID - links to auth.users.id';
COMMENT ON COLUMN users.ma_nguoi_dung IS 'Internal integer ID used throughout the app';
