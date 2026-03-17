-- Additional tables for Economic Data, Ecosystem Services, Pollution Reports, and Mangrove Areas
-- Add these to the main schema

-- Mangrove Areas table - พื้นที่ป่าชายเลน
CREATE TABLE IF NOT EXISTS mangrove_areas (
    id SERIAL PRIMARY KEY,
    community_id INTEGER REFERENCES communities(id) ON DELETE SET NULL,
    area_name VARCHAR(200) NOT NULL,
    location VARCHAR(300) NOT NULL,
    province VARCHAR(100) NOT NULL,
    size_hectares DECIMAL(10, 2) CHECK (size_hectares > 0),
    mangrove_species TEXT[],
    conservation_status VARCHAR(50) CHECK (conservation_status IN ('excellent', 'good', 'moderate', 'poor', 'critical')),
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    description TEXT,
    established_year INTEGER CHECK (established_year >= 1900 AND established_year <= EXTRACT(YEAR FROM NOW())),
    managing_organization VARCHAR(200),
    threats TEXT[],
    conservation_activities TEXT[],
    photos TEXT[],
    monitoring_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Economic Data table - ข้อมูลเศรษฐกิจชุมชน
CREATE TABLE IF NOT EXISTS economic_data (
    id SERIAL PRIMARY KEY,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2100),
    quarter INTEGER CHECK (quarter >= 1 AND quarter <= 4),
    income_fishery DECIMAL(15, 2) DEFAULT 0 CHECK (income_fishery >= 0),
    income_tourism DECIMAL(15, 2) DEFAULT 0 CHECK (income_tourism >= 0),
    income_agriculture DECIMAL(15, 2) DEFAULT 0 CHECK (income_agriculture >= 0),
    income_others DECIMAL(15, 2) DEFAULT 0 CHECK (income_others >= 0),
    total_income DECIMAL(15, 2) GENERATED ALWAYS AS (
        COALESCE(income_fishery, 0) + 
        COALESCE(income_tourism, 0) + 
        COALESCE(income_agriculture, 0) + 
        COALESCE(income_others, 0)
    ) STORED,
    employment_count INTEGER DEFAULT 0 CHECK (employment_count >= 0),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate entries
    CONSTRAINT economic_data_unique UNIQUE (community_id, year, quarter)
);

-- Ecosystem Services table - บริการทางนิเวศ
CREATE TABLE IF NOT EXISTS ecosystem_services (
    id SERIAL PRIMARY KEY,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    service_type VARCHAR(50) NOT NULL CHECK (service_type IN (
        'provisioning',     -- การจัดหาทรัพยากร (ปลา กุ้ง ปู)
        'regulating',       -- การควบคุม (กรองน้ำ ดูดซับคาร์บอน)
        'supporting',       -- การสนับสนุน (ที่อยู่อาศัยสัตว์)
        'cultural',         -- วัฒนธรรม (จิตวิญญาณ ความเชื่อ)
        'ecotourism',       -- ท่องเที่ยวเชิงนิเวศ
        'education',        -- การศึกษา
        'recreation'        -- นันทนาการ
    )),
    service_name VARCHAR(200) NOT NULL,
    quantity DECIMAL(12, 2) DEFAULT 0,
    unit VARCHAR(50),
    economic_value DECIMAL(15, 2) DEFAULT 0 CHECK (economic_value >= 0),
    year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2100),
    month INTEGER CHECK (month >= 1 AND month <= 12),
    description TEXT,
    beneficiaries_count INTEGER DEFAULT 0 CHECK (beneficiaries_count >= 0),
    measurement_method VARCHAR(100),
    data_source VARCHAR(100),
    confidence_level VARCHAR(20) CHECK (confidence_level IN ('low', 'medium', 'high', 'verified')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pollution Reports table - รายงานมลพิษ
CREATE TABLE IF NOT EXISTS pollution_reports (
    id SERIAL PRIMARY KEY,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN (
        'Water Pollution',
        'Air Pollution',
        'Solid Waste',
        'Chemical Pollution',
        'Noise Pollution',
        'Oil Spill',
        'Other'
    )),
    pollution_source VARCHAR(255) NOT NULL,
    severity_level VARCHAR(20) NOT NULL CHECK (severity_level IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    report_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending',
        'investigating',
        'monitoring',
        'resolved',
        'closed'
    )),
    reported_by INTEGER REFERENCES users(id),
    assigned_to INTEGER REFERENCES users(id),
    resolution_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    photos TEXT[], -- Array of photo URLs
    affected_area_hectares DECIMAL(10, 2),
    estimated_cost DECIMAL(15, 2),
    action_taken TEXT,
    follow_up_required BOOLEAN DEFAULT true,
    next_inspection_date DATE,
    tags TEXT[],
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_mangrove_areas_province ON mangrove_areas(province);
CREATE INDEX IF NOT EXISTS idx_mangrove_areas_community_id ON mangrove_areas(community_id);
CREATE INDEX IF NOT EXISTS idx_mangrove_areas_location ON mangrove_areas USING GIST(ll_to_earth(latitude, longitude));

CREATE INDEX IF NOT EXISTS idx_economic_data_community_id ON economic_data(community_id);
CREATE INDEX IF NOT EXISTS idx_economic_data_year_quarter ON economic_data(year, quarter);
CREATE INDEX IF NOT EXISTS idx_economic_data_created_at ON economic_data(created_at);

CREATE INDEX IF NOT EXISTS idx_ecosystem_services_community_id ON ecosystem_services(community_id);
CREATE INDEX IF NOT EXISTS idx_ecosystem_services_type ON ecosystem_services(service_type);
CREATE INDEX IF NOT EXISTS idx_ecosystem_services_year_month ON ecosystem_services(year, month);
CREATE INDEX IF NOT EXISTS idx_ecosystem_services_created_at ON ecosystem_services(created_at);

CREATE INDEX IF NOT EXISTS idx_pollution_reports_community_id ON pollution_reports(community_id);
CREATE INDEX IF NOT EXISTS idx_pollution_reports_status ON pollution_reports(status);
CREATE INDEX IF NOT EXISTS idx_pollution_reports_severity ON pollution_reports(severity_level);
CREATE INDEX IF NOT EXISTS idx_pollution_reports_type ON pollution_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_pollution_reports_date ON pollution_reports(report_date);
CREATE INDEX IF NOT EXISTS idx_pollution_reports_location ON pollution_reports USING GIST(ll_to_earth(latitude, longitude));

-- Triggers for automatic timestamp updates
CREATE TRIGGER update_mangrove_areas_updated_at
    BEFORE UPDATE ON mangrove_areas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_economic_data_updated_at
    BEFORE UPDATE ON economic_data
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ecosystem_services_updated_at
    BEFORE UPDATE ON ecosystem_services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pollution_reports_updated_at
    BEFORE UPDATE ON pollution_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL PRIVILEGES ON TABLE mangrove_areas TO appadmin;
GRANT ALL PRIVILEGES ON TABLE economic_data TO appadmin;
GRANT ALL PRIVILEGES ON TABLE ecosystem_services TO appadmin;
GRANT ALL PRIVILEGES ON TABLE pollution_reports TO appadmin;

GRANT USAGE, SELECT ON SEQUENCE mangrove_areas_id_seq TO appadmin;
GRANT USAGE, SELECT ON SEQUENCE economic_data_id_seq TO appadmin;
GRANT USAGE, SELECT ON SEQUENCE ecosystem_services_id_seq TO appadmin;
GRANT USAGE, SELECT ON SEQUENCE pollution_reports_id_seq TO appadmin;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Additional tables created successfully!';
    RAISE NOTICE '📊 Tables: mangrove_areas, economic_data, ecosystem_services, pollution_reports';
END $$;
