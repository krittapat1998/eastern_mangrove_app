-- Migration: Add improved ecosystem services fields
-- Date: 2026-03-12
-- Purpose: Support resource tracking (weight × price) and activity tracking (participants × cost per person)

-- Add new columns for improved ecosystem services tracking
ALTER TABLE ecosystem_services 
ADD COLUMN IF NOT EXISTS category VARCHAR(20) DEFAULT 'resource' CHECK (category IN ('resource', 'activity')),
ADD COLUMN IF NOT EXISTS service_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS quantity DECIMAL(15, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS unit VARCHAR(50) DEFAULT 'กก.',
ADD COLUMN IF NOT EXISTS unit_price DECIMAL(15, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS participants INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS price_per_person DECIMAL(15, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS economic_value DECIMAL(15, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS year INTEGER,
ADD COLUMN IF NOT EXISTS month INTEGER CHECK (month >= 1 AND month <= 12),
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS beneficiaries_count INTEGER DEFAULT 0;

-- Update existing data to have default category
UPDATE ecosystem_services
SET category = 'resource'
WHERE category IS NULL;

-- Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_ecosystem_services_category ON ecosystem_services(category);
CREATE INDEX IF NOT EXISTS idx_ecosystem_services_year_month ON ecosystem_services(year, month);
CREATE INDEX IF NOT EXISTS idx_ecosystem_services_service_type ON ecosystem_services(service_type);

-- Comments for documentation
COMMENT ON COLUMN ecosystem_services.category IS 'Type of service: resource (weight-based) or activity (participant-based)';
COMMENT ON COLUMN ecosystem_services.service_name IS 'Name of the service or resource';
COMMENT ON COLUMN ecosystem_services.quantity IS 'Quantity for resources (e.g., weight in kg)';
COMMENT ON COLUMN ecosystem_services.unit IS 'Unit of measurement (default: กก.)';
COMMENT ON COLUMN ecosystem_services.unit_price IS 'Price per unit for resources (baht/kg)';
COMMENT ON COLUMN ecosystem_services.participants IS 'Number of participants for activities';
COMMENT ON COLUMN ecosystem_services.price_per_person IS 'Cost per person for activities (baht/person)';
COMMENT ON COLUMN ecosystem_services.economic_value IS 'Calculated economic value = quantity × unit_price OR participants × price_per_person';
COMMENT ON COLUMN ecosystem_services.year IS 'Year in Buddhist Era (พ.ศ.)';
COMMENT ON COLUMN ecosystem_services.month IS 'Month (1-12)';
