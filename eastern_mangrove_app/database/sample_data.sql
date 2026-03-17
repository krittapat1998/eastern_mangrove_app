-- Sample Data for Eastern Mangrove Communities App
-- ข้อมูลตัวอย่างสำหรับการทดสอบระบบ

-- Sample Users
INSERT INTO users (username, email, password_hash, user_type, is_active, is_approved) VALUES 
-- Admin users
('admin', 'admin@easternmangrove.org', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'admin', true, true),
('admin2', 'admin2@easternmangrove.org', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'admin', true, true),

-- Community users (approved)
('community_rayong', 'rayong@community.org', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'community', true, true),
('community_trat', 'trat@community.org', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'community', true, true),
('community_chanthaburi', 'chanthaburi@community.org', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'community', true, true),

-- Community users (pending approval)
('community_sattahip', 'sattahip@community.org', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'community', true, false),

-- Public users
('public_user1', 'user1@example.com', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'public', true, true),
('public_user2', 'user2@example.com', '$2b$12$LQv3c1yqBwlVZHpTmgNMHOGaxdTqNfA4dqLV.k/EjFQYILlxCpJZu', 'public', true, true);

-- Sample Communities
INSERT INTO communities (user_id, community_name, village_name, sub_district, district, province, contact_person, phone, description, latitude, longitude, registration_status) VALUES 
-- Approved communities
(3, 'ชุมชนอนุรักษ์ป่าชายเลนระยอง', 'บ้านเพ', 'เพ', 'เมืองระยอง', 'ระยอง', 'นายสมชาย ใจดี', '038-123456', 'ชุมชนที่มุ่งเน้นการอนุรักษ์ป่าชายเลนและการท่องเที่ยวเชิงนิเวศ', 12.6802, 101.2816, 'approved'),
(4, 'ชุมชนประมงป่าชายเลนตราด', 'บ้านบางปู', 'บางปู', 'เมืองตราด', 'ตราด', 'นางสมศรี ปลาดิบ', '039-234567', 'ชุมชนประมงที่อาศัยทรัพยากรป่าชายเลน', 12.2436, 102.5156, 'approved'),
(5, 'ชุมชนท่องเที่ยวจันทบุรี', 'บ้านลำสิง', 'ลำสิง', 'ลำสิง', 'จันทบุรี', 'นายประเสริฐ ท่องเที่ยว', '039-345678', 'ชุมชนที่พัฒนาการท่องเที่ยวร่วมกับการอนุรักษ์', 12.6112, 102.1038, 'approved'),

-- Pending communities
(6, 'ชุมชนอนุรักษ์สัตหีบ', 'บ้านสัตหีบ', 'สัตหีบ', 'สัตหีบ', 'ชลบุรี', 'นายวิชัย ทะเลใส', '038-456789', 'ชุมชนใหม่ที่ต้องการเข้าร่วมการอนุรักษ์', 12.6731, 100.9298, 'pending');

-- Sample Community Documents
INSERT INTO community_documents (community_id, document_name, document_type, file_path, file_size) VALUES 
(1, 'หนังสือจัดตั้งชุมชนอนุรักษ์ป่าชายเลนระยอง', 'หนังสือจัดตั้งชุมชน', '/documents/rayong/setup_document.pdf', 2048000),
(1, 'แผนที่พื้นที่ชุมชน', 'แผนที่พื้นที่', '/documents/rayong/area_map.pdf', 1024000),
(1, 'รายชื่อสมาชิกชุมชน', 'รายชื่อสมาชิก', '/documents/rayong/members_list.pdf', 512000),

(2, 'ใบประกอบการประมง', 'ใบประกอบการ', '/documents/trat/fishing_license.pdf', 1536000),
(2, 'โครงการอนุรักษ์ป่าชายเลน', 'โครงการอนุรักษ์', '/documents/trat/conservation_project.pdf', 3072000),

(3, 'แผนพัฒนาการท่องเที่ยว', 'โครงการอนุรักษ์', '/documents/chanthaburi/tourism_plan.pdf', 2560000);

-- Sample Mangrove Areas
INSERT INTO mangrove_areas (community_id, area_name, total_area, latitude, longitude, description, conservation_status) VALUES 
(1, 'ป่าชายเลนบ้านเพ', 150.5, 12.6802, 101.2816, 'พื้นที่ป่าชายเลนหลักของชุมชน มีต้นโกงกางและแสมขาว', 'protected'),
(1, 'ป่าชายเลนคลองตาเนิน', 89.3, 12.6850, 101.2900, 'พื้นที่ป่าชายเลนริมคลอง เหมาะสำหรับการศึกษาธรรมชาติ', 'protected'),

(2, 'ป่าชายเลนบางปู', 203.7, 12.2436, 102.5156, 'ป่าชายเลนขนาดใหญ่ที่มีความหลากหลายทางชีวภาพสูง', 'conservation'),
(2, 'ป่าชายเลนคลองยาย', 76.2, 12.2500, 102.5200, 'พื้นที่ป่าชายเลนที่มีการฟื้นฟูธรรมชาติ', 'restoration'),

(3, 'ป่าชายเลนลำสิง', 120.8, 12.6112, 102.1038, 'พื้นที่ป่าชายเลนที่ใช้สำหรับการท่องเที่ยวเชิงนิเวศ', 'eco-tourism');

-- Sample Economic Data (2024-2025)
INSERT INTO economic_data (community_id, year, quarter, income_fishery, income_tourism, income_agriculture, income_others, employment_count, notes) VALUES 
-- ชุมชนระยอง 2024
(1, 2024, 1, 450000.00, 320000.00, 150000.00, 80000.00, 45, 'ไตรมาสแรกมีนักท่องเที่ยวเยอะ'),
(1, 2024, 2, 380000.00, 280000.00, 180000.00, 90000.00, 42, 'ฤดูฝนเริ่มต้น'),
(1, 2024, 3, 320000.00, 180000.00, 200000.00, 70000.00, 38, 'ฤดูฝนหนัก นักท่องเที่ยวลดลง'),
(1, 2024, 4, 500000.00, 450000.00, 170000.00, 120000.00, 52, 'ฤดูหนาวมีนักท่องเที่ยวมาก'),

-- ชุมชนระยอง 2025
(1, 2025, 1, 480000.00, 380000.00, 160000.00, 100000.00, 48, 'เริ่มต้นปี 2025 สดใส'),

-- ชุมชนตราด 2024
(2, 2024, 1, 680000.00, 150000.00, 120000.00, 50000.00, 35, 'ประมงเป็นรายได้หลัก'),
(2, 2024, 2, 720000.00, 120000.00, 140000.00, 60000.00, 38, 'ฤดูปลาทูน่า'),
(2, 2024, 3, 580000.00, 80000.00, 160000.00, 45000.00, 32, 'ฤดูฝนส่งผลต่อการประมง'),
(2, 2024, 4, 750000.00, 200000.00, 130000.00, 80000.00, 42, 'ประมงและท่องเที่ยวปลายปี'),

-- ชุมชนจันทบุรี 2024
(3, 2024, 1, 200000.00, 520000.00, 180000.00, 100000.00, 28, 'ท่องเที่ยวเป็นรายได้หลัก'),
(3, 2024, 2, 180000.00, 450000.00, 200000.00, 90000.00, 26, 'เริ่มฤดูฝน'),
(3, 2024, 3, 150000.00, 280000.00, 220000.00, 70000.00, 23, 'ฤดูฝน นักท่องเที่ยวลดลง'),
(3, 2024, 4, 220000.00, 650000.00, 190000.00, 140000.00, 32, 'ท่องเที่ยวปลายปีดีมาก');

-- Sample Ecosystem Services
INSERT INTO ecosystem_services (community_id, mangrove_area_id, service_type, measurement_unit, value_quantity, value_monetary, measurement_date, methodology) VALUES 
-- Carbon Storage
(1, 1, 'Carbon Storage', 'tons CO2', 2450.50, 245050.00, '2024-12-01', 'Biomass measurement and carbon calculation'),
(1, 2, 'Carbon Storage', 'tons CO2', 1456.30, 145630.00, '2024-12-01', 'Biomass measurement and carbon calculation'),
(2, 3, 'Carbon Storage', 'tons CO2', 3125.80, 312580.00, '2024-12-01', 'Biomass measurement and carbon calculation'),

-- Coastal Protection
(1, 1, 'Coastal Protection', 'km coastline', 12.5, 2500000.00, '2024-12-01', 'Wave attenuation modeling'),
(2, 3, 'Coastal Protection', 'km coastline', 18.7, 3740000.00, '2024-12-01', 'Wave attenuation modeling'),

-- Fish Nursery
(1, 1, 'Fish Nursery', 'fish species', 45.0, 450000.00, '2024-11-15', 'Fish species diversity survey'),
(2, 3, 'Fish Nursery', 'fish species', 67.0, 670000.00, '2024-11-15', 'Fish species diversity survey'),
(3, 5, 'Fish Nursery', 'fish species', 38.0, 380000.00, '2024-11-15', 'Fish species diversity survey');

-- Sample Pollution Reports
INSERT INTO pollution_reports (community_id, report_type, pollution_source, severity_level, description, latitude, longitude, report_date, status, photos) VALUES 
(1, 'Water Pollution', 'Industrial Waste', 'high', 'พบน้ำเสียจากโรงงานอุตสาหกรรมไหลลงคลอง ทำให้น้ำเปลี่ยนสี', 12.6820, 101.2830, '2024-12-15', 'investigating', '["pollution_img_001.jpg", "pollution_img_002.jpg"]'),

(1, 'Solid Waste', 'Tourism Activities', 'medium', 'ขยะพลาสติกจากนักท่องเที่ยวบริเวณชายหาด', 12.6800, 101.2800, '2024-12-10', 'resolved', '["waste_img_001.jpg"]'),

(2, 'Oil Spill', 'Fishing Boats', 'high', 'น้ำมันรั่วไหลจากเรือประมง ส่งผลต่อระบบนิเวศ', 12.2450, 102.5170, '2024-12-08', 'reported', '["oil_spill_001.jpg", "oil_spill_002.jpg", "oil_spill_003.jpg"]'),

(3, 'Chemical Pollution', 'Agriculture', 'medium', 'สารเคมีจากไร่ผลไม้ไหลลงสู่พื้นที่ป่าชายเลน', 12.6100, 102.1050, '2024-12-05', 'investigating', '["chemical_001.jpg"]'),

(1, 'Noise Pollution', 'Construction', 'low', 'เสียงดังจากการก่อสร้างใกล้พื้นที่อนุรักษ์', 12.6810, 101.2820, '2024-12-03', 'resolved', '[]');

-- Log sample admin actions
INSERT INTO admin_logs (admin_user_id, action, target_table, target_id, old_values, new_values) VALUES 
(1, 'APPROVE_COMMUNITY', 'communities', 1, '{"registration_status": "pending"}', '{"registration_status": "approved"}'),
(1, 'APPROVE_COMMUNITY', 'communities', 2, '{"registration_status": "pending"}', '{"registration_status": "approved"}'),
(1, 'UPDATE_POLLUTION_STATUS', 'pollution_reports', 2, '{"status": "reported"}', '{"status": "resolved"}'),
(2, 'UPDATE_POLLUTION_STATUS', 'pollution_reports', 5, '{"status": "reported"}', '{"status": "resolved"}');