-- Eastern Mangrove Communities Database Schema
-- Created: March 2026
-- PostgreSQL Database Structure

-- Drop existing tables if they exist (for fresh install)
DROP TABLE IF EXISTS community_activities CASCADE;
DROP TABLE IF EXISTS photo_uploads CASCADE;
DROP TABLE IF EXISTS community_members CASCADE;
DROP TABLE IF EXISTS activity_logs CASCADE;
DROP TABLE IF EXISTS communities CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table - สำหรับผู้ใช้ระบบ
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('admin', 'community', 'public')),
    phone_number VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    profile_image_url TEXT,
    bio TEXT,
    
    -- Indexes
    CONSTRAINT users_email_valid CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Communities table - สำหรับข้อมูลชุมชน
CREATE TABLE communities (
    id SERIAL PRIMARY KEY,
    community_name VARCHAR(200) NOT NULL,
    location VARCHAR(300) NOT NULL,
    contact_person VARCHAR(150) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    description TEXT,
    established_year INTEGER CHECK (established_year >= 1900 AND established_year <= EXTRACT(YEAR FROM NOW())),
    member_count INTEGER CHECK (member_count >= 0),
    photo_type VARCHAR(20) CHECK (photo_type IN ('profile', 'community', 'activity', 'mangrove')),
    registration_status VARCHAR(20) DEFAULT 'pending' CHECK (registration_status IN ('pending', 'approved', 'rejected', 'suspended')),
    approved_by INTEGER REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    coordinates POINT, -- For geographic coordinates (lat, lng)
    area_size DECIMAL(10, 2), -- In hectares
    mangrove_species TEXT[], -- Array of mangrove species found
    conservation_status VARCHAR(50),
    website_url TEXT,
    social_media JSONB, -- For storing social media links
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraints
    CONSTRAINT communities_unique_name UNIQUE (community_name),
    CONSTRAINT communities_unique_email UNIQUE (email),
    CONSTRAINT communities_email_valid CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Community Members table - เชื่อมต่อระหว่าง users และ communities
CREATE TABLE community_members (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member', 'volunteer')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    permissions JSONB DEFAULT '{}', -- For granular permissions
    
    -- Prevent duplicate memberships
    CONSTRAINT community_members_unique UNIQUE (user_id, community_id)
);

-- Community Activities table - กิจกรรมของชุมชน
CREATE TABLE community_activities (
    id SERIAL PRIMARY KEY,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    created_by INTEGER REFERENCES users(id),
    title VARCHAR(300) NOT NULL,
    description TEXT,
    activity_type VARCHAR(50) NOT NULL CHECK (activity_type IN (
        'conservation', 
        'education', 
        'research', 
        'restoration', 
        'monitoring', 
        'community_event',
        'training',
        'cleanup',
        'planting',
        'survey'
    )),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    location VARCHAR(300),
    coordinates POINT,
    max_participants INTEGER CHECK (max_participants > 0),
    current_participants INTEGER DEFAULT 0 CHECK (current_participants >= 0),
    status VARCHAR(30) DEFAULT 'planned' CHECK (status IN ('planned', 'ongoing', 'completed', 'cancelled')),
    budget DECIMAL(12, 2) CHECK (budget >= 0),
    funding_source VARCHAR(200),
    impact_metrics JSONB, -- For storing measurable impacts
    photos TEXT[], -- Array of photo URLs
    documents TEXT[], -- Array of document URLs
    tags TEXT[], -- For categorization and search
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Photo Uploads table - จัดการรูปภาพ
CREATE TABLE photo_uploads (
    id SERIAL PRIMARY KEY,
    uploaded_by INTEGER REFERENCES users(id),
    community_id INTEGER REFERENCES communities(id) ON DELETE CASCADE,
    activity_id INTEGER REFERENCES community_activities(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    file_path TEXT NOT NULL,
    file_size INTEGER CHECK (file_size > 0),
    mime_type VARCHAR(100),
    photo_type VARCHAR(30) NOT NULL CHECK (photo_type IN (
        'profile', 
        'community', 
        'activity', 
        'mangrove', 
        'before_after', 
        'monitoring',
        'species',
        'damage',
        'restoration'
    )),
    description TEXT,
    coordinates POINT,
    taken_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB, -- For storing EXIF data, etc.
    is_public BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure either community_id or activity_id is provided
    CONSTRAINT photo_uploads_reference_check CHECK (
        (community_id IS NOT NULL) OR (activity_id IS NOT NULL)
    )
);

-- Activity Logs table - บันทึกการดำเนินการในระบบ
CREATE TABLE activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL, -- 'user', 'community', 'activity', 'photo'
    entity_id INTEGER,
    description TEXT,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_is_active ON users(is_active);

CREATE INDEX idx_communities_status ON communities(registration_status);
CREATE INDEX idx_communities_location ON communities(location);
CREATE INDEX idx_communities_created_at ON communities(created_at);
CREATE INDEX idx_communities_coordinates ON communities USING GIST(coordinates);

CREATE INDEX idx_community_members_user_id ON community_members(user_id);
CREATE INDEX idx_community_members_community_id ON community_members(community_id);
CREATE INDEX idx_community_members_role ON community_members(role);

CREATE INDEX idx_activities_community_id ON community_activities(community_id);
CREATE INDEX idx_activities_type ON community_activities(activity_type);
CREATE INDEX idx_activities_status ON community_activities(status);
CREATE INDEX idx_activities_start_date ON community_activities(start_date);
CREATE INDEX idx_activities_coordinates ON community_activities USING GIST(coordinates);

CREATE INDEX idx_photos_community_id ON photo_uploads(community_id);
CREATE INDEX idx_photos_activity_id ON photo_uploads(activity_id);
CREATE INDEX idx_photos_type ON photo_uploads(photo_type);
CREATE INDEX idx_photos_uploaded_by ON photo_uploads(uploaded_by);
CREATE INDEX idx_photos_taken_at ON photo_uploads(taken_at);
CREATE INDEX idx_photos_coordinates ON photo_uploads USING GIST(coordinates);

CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_communities_updated_at 
    BEFORE UPDATE ON communities 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at 
    BEFORE UPDATE ON community_activities 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically update current_participants when someone joins/leaves activity
CREATE OR REPLACE FUNCTION update_activity_participants()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be implemented when we have activity participants table
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Views for common queries

-- Active communities view
CREATE VIEW active_communities AS
SELECT 
    c.*,
    u.first_name || ' ' || u.last_name AS approved_by_name,
    COUNT(cm.id) AS member_count_actual
FROM communities c
LEFT JOIN users u ON c.approved_by = u.id
LEFT JOIN community_members cm ON c.id = cm.community_id AND cm.is_active = true
WHERE c.registration_status = 'approved'
GROUP BY c.id, u.first_name, u.last_name;

-- Upcoming activities view
CREATE VIEW upcoming_activities AS
SELECT 
    ca.*,
    c.community_name,
    c.location AS community_location,
    u.first_name || ' ' || u.last_name AS created_by_name
FROM community_activities ca
JOIN communities c ON ca.community_id = c.id
LEFT JOIN users u ON ca.created_by = u.id
WHERE ca.start_date > NOW() 
  AND ca.status IN ('planned', 'ongoing')
ORDER BY ca.start_date ASC;

-- User statistics view
CREATE VIEW user_statistics AS
SELECT 
    user_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_count,
    COUNT(CASE WHEN email_verified = true THEN 1 END) as verified_count
FROM users
GROUP BY user_type;

-- Create AppAdmin role if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'appadmin') THEN
        CREATE ROLE appadmin WITH
        LOGIN
        SUPERUSER
        INHERIT
        CREATEDB
        CREATEROLE
        REPLICATION
        PASSWORD 'AppAdmin#1!';
    END IF;
END $$;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appadmin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO appadmin;
GRANT USAGE ON SCHEMA public TO appadmin;

-- Also grant to current user (for development)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO CURRENT_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO CURRENT_USER;

-- Insert system admin user (password: admin123! - should be changed in production)
INSERT INTO users (email, password_hash, first_name, last_name, user_type, is_active, email_verified, created_at) 
VALUES (
    'admin@easternmangrove.th', 
    '$2a$12$rGqhX1qL8wXxmzX1qL8wXCqhX1qL8wXxmzX1qL8wXCqhX1qL8w', -- This will be updated with proper hash
    'System',
    'Administrator',
    'admin',
    true,
    true,
    NOW()
);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🌿 Eastern Mangrove Communities database schema created successfully!';
    RAISE NOTICE '📊 Tables created: users, communities, community_members, community_activities, photo_uploads, activity_logs';
    RAISE NOTICE '👁️  Views created: active_communities, upcoming_activities, user_statistics';
    RAISE NOTICE '🔧 Next step: Run sample_data.sql to insert test data';
END $$;