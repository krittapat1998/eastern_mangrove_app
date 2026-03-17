-- Migration: Add admin management fields
-- Description: Add rejection fields and admin_actions table for admin section

-- Add rejection fields to communities table
ALTER TABLE communities
ADD COLUMN IF NOT EXISTS rejected_by INTEGER REFERENCES users(id),
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Create admin_actions table for logging admin activities
CREATE TABLE IF NOT EXISTS admin_actions (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL, -- 'approve_community', 'reject_community', 'activate_user', 'deactivate_user', etc.
    target_type VARCHAR(50) NOT NULL, -- 'community', 'user', 'report', etc.
    target_id INTEGER NOT NULL, -- ID of the target entity
    notes TEXT, -- Additional notes about the action
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for admin_actions table
CREATE INDEX IF NOT EXISTS idx_admin_actions_admin_id ON admin_actions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_target ON admin_actions(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_created_at ON admin_actions(created_at DESC);

-- Add comments for documentation
COMMENT ON TABLE admin_actions IS 'Logs all administrative actions for audit trail';
COMMENT ON COLUMN admin_actions.action_type IS 'Type of action performed (approve_community, reject_community, etc.)';
COMMENT ON COLUMN admin_actions.target_type IS 'Type of entity being acted upon (community, user, etc.)';
COMMENT ON COLUMN admin_actions.target_id IS 'ID of the entity being acted upon';

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_communities_registration_status ON communities(registration_status);
CREATE INDEX IF NOT EXISTS idx_communities_approved_at ON communities(approved_at DESC);
CREATE INDEX IF NOT EXISTS idx_communities_rejected_at ON communities(rejected_at DESC);

-- Update existing communities table comment
COMMENT ON COLUMN communities.approved_by IS 'Admin user ID who approved this community';
COMMENT ON COLUMN communities.approved_at IS 'Timestamp when the community was approved';
COMMENT ON COLUMN communities.rejected_by IS 'Admin user ID who rejected this community';
COMMENT ON COLUMN communities.rejected_at IS 'Timestamp when the community was rejected';
COMMENT ON COLUMN communities.rejection_reason IS 'Reason provided by admin for rejection';

-- Grant permissions to appadmin
GRANT ALL ON admin_actions TO appadmin;
GRANT USAGE, SELECT ON SEQUENCE admin_actions_id_seq TO appadmin;
