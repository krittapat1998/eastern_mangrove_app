-- Eastern Mangrove Communities Database Schema
-- Created: March 8, 2026

-- สร้างฐานข้อมูล
-- CREATE DATABASE eastern_mangrove_communities;

-- 1. ตาราง Users (ผู้ใช้ทั้งหมด)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('admin', 'community', 'public')),
    is_active BOOLEAN DEFAULT true,
    is_approved BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. ตาราง Communities (ข้อมูลชุมชน)
CREATE TABLE communities (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    community_name VARCHAR(255) NOT NULL,
    village_name VARCHAR(255),
    sub_district VARCHAR(255),
    district VARCHAR(255),
    province VARCHAR(100),
    contact_person VARCHAR(255),
    phone VARCHAR(20),
    description TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    registration_status VARCHAR(20) DEFAULT 'pending' CHECK (
        registration_status IN ('pending', 'approved', 'rejected')
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. ตาราง Community Documents (เอกสารของชุมชน)
CREATE TABLE community_documents (
    id SERIAL PRIMARY KEY,
    community_id INTEGER REFERENCES communities(id) ON DELETE CASCADE,
    document_name VARCHAR(255) NOT NULL,
    document_type VARCHAR(100),
    file_path VARCHAR(500),
    file_size INTEGER,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. ตาราง Mangrove Areas (พื้นที่ป่าชายเลน)
CREATE TABLE mangrove_areas (
    id SERIAL PRIMARY KEY,
    community_id INTEGER REFERENCES communities(id),
    area_name VARCHAR(255) NOT NULL,
    total_area DECIMAL(10, 2), -- เฮกตาร์
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    description TEXT,
    conservation_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. ตาราง Economic Data (ข้อมูลเศรษฐกิจ)
CREATE TABLE economic_data (
    id SERIAL PRIMARY KEY,
    community_id INTEGER REFERENCES communities(id),
    year INTEGER NOT NULL,
    quarter INTEGER CHECK (quarter IN (1, 2, 3, 4)),
    income_fishery DECIMAL(15, 2),
    income_tourism DECIMAL(15, 2),
    income_agriculture DECIMAL(15, 2),
    income_others DECIMAL(15, 2),
    total_income DECIMAL(15, 2) GENERATED ALWAYS AS (
        COALESCE(income_fishery, 0) + 
        COALESCE(income_tourism, 0) + 
        COALESCE(income_agriculture, 0) + 
        COALESCE(income_others, 0)
    ) STORED,
    employment_count INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. ตาราง Ecosystem Services (บริการระบบนิเวศ)
CREATE TABLE ecosystem_services (
    id SERIAL PRIMARY KEY,
    community_id INTEGER REFERENCES communities(id),
    mangrove_area_id INTEGER REFERENCES mangrove_areas(id),
    service_type VARCHAR(100) NOT NULL,
    measurement_unit VARCHAR(50),
    value_quantity DECIMAL(15, 2),
    value_monetary DECIMAL(15, 2),
    measurement_date DATE,
    methodology TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. ตาราง Pollution Reports (รายงานมลภาวะ)
CREATE TABLE pollution_reports (
    id SERIAL PRIMARY KEY,
    community_id INTEGER REFERENCES communities(id),
    report_type VARCHAR(100) NOT NULL,
    pollution_source VARCHAR(255),
    severity_level VARCHAR(20) CHECK (severity_level IN ('low', 'medium', 'high', 'critical')),
    description TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    report_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'reported' CHECK (
        status IN ('reported', 'investigating', 'resolved', 'closed')
    ),
    photos JSONB, -- เก็บ URLs ของรูปภาพ
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. ตาราง Admin Logs (บันทึกการดำเนินการของ Admin)
CREATE TABLE admin_logs (
    id SERIAL PRIMARY KEY,
    admin_user_id INTEGER REFERENCES users(id),
    action VARCHAR(255) NOT NULL,
    target_table VARCHAR(100),
    target_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- สร้าง Indexes เพื่อปรับปรุงประสิทธิภาพ
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_communities_province ON communities(province);
CREATE INDEX idx_communities_status ON communities(registration_status);
CREATE INDEX idx_economic_data_year ON economic_data(year, quarter);
CREATE INDEX idx_pollution_reports_date ON pollution_reports(report_date);
CREATE INDEX idx_pollution_reports_status ON pollution_reports(status);

-- สร้าง Functions เพื่อ auto-update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- สร้าง Triggers สำหรับ auto-update timestamps
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_communities_updated_at BEFORE UPDATE ON communities 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mangrove_areas_updated_at BEFORE UPDATE ON mangrove_areas 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_economic_data_updated_at BEFORE UPDATE ON economic_data 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ecosystem_services_updated_at BEFORE UPDATE ON ecosystem_services 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pollution_reports_updated_at BEFORE UPDATE ON pollution_reports 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();