-- Insert Sample Economic Data
INSERT INTO economic_data (community_id, year, quarter, income_fishery, income_tourism, income_agriculture, income_others, employment_count, notes)
VALUES
  -- Community 1 data (2025)
  (1, 2025, 1, 45000.00, 12000.00, 8000.00, 5000.00, 25, 'รายได้จากการทำประมงเพิ่มขึ้น'),
  (1, 2025, 2, 52000.00, 18000.00, 10000.00, 6000.00, 28, 'ช่วงนักท่องเที่ยวเริ่มมาเยือน'),
  (1, 2025, 3, 48000.00, 25000.00, 9000.00, 7000.00, 30, 'ฤดูท่องเที่ยวเต็มรูปแบบ'),
  (1, 2025, 4, 50000.00, 15000.00, 11000.00, 6500.00, 27, 'รายได้คงที่'),
  -- Community 1 data (2026)
  (1, 2026, 1, 55000.00, 20000.00, 12000.00, 8000.00, 32, 'เริ่มต้นปีใหม่ด้วยยอดที่ดี')
ON CONFLICT DO NOTHING;

-- Insert Sample Ecosystem Services Data
INSERT INTO ecosystem_services (community_id, service_type, service_name, quantity, unit, economic_value, year, month, description, beneficiaries_count)
VALUES
  -- Ecotourism services
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 150, 'คน', 45000.00, 2025, 7, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 150),
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 180, 'คน', 54000.00, 2025, 8, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 180),
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 210, 'คน', 63000.00, 2025, 9, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 210),
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 195, 'คน', 58500.00, 2025, 10, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 195),
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 220, 'คน', 66000.00, 2025, 11, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 220),
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 240, 'คน', 72000.00, 2025, 12, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 240),
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 260, 'คน', 78000.00, 2026, 1, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 260),
  (1, 'ecotourism', 'ทัวร์ชมป่าชายเลน', 230, 'คน', 69000.00, 2026, 2, 'นำเที่ยวชมความหลากหลายทางชีวภาพ', 230),
  
  -- Education services
  (1, 'education', 'ค่ายเยาวชนอนุรักษ์', 80, 'คน', 16000.00, 2025, 7, 'ค่ายเรียนรู้ระบบนิเวศ', 80),
  (1, 'education', 'ค่ายเยาวชนอนุรักษ์', 95, 'คน', 19000.00, 2025, 10, 'ค่ายเรียนรู้ระบบนิเวศ', 95),
  (1, 'education', 'ค่ายเยาวชนอนุรักษ์', 110, 'คน', 22000.00, 2026, 1, 'ค่ายเรียนรู้ระบบนิเวศ', 110),
  
  -- Resource extraction
  (1, 'provisioning', 'จับปู', 250.5, 'กิโลกรัม', 30060.00, 2025, 8, 'ปูทะเล', 15),
  (1, 'provisioning', 'จับกุ้ง', 180.0, 'กิโลกรัม', 50400.00, 2025, 9, 'กุ้งก้ามกราม', 12),
  (1, 'provisioning', 'เก็บหอย', 320.0, 'กิโลกรัม', 38400.00, 2025, 10, 'หอยแครง', 18),
  
  -- Carbon sequestration
  (1, 'regulating', 'ดูดซับคาร์บอน', 45.5, 'ตันคาร์บอน', 227500.00, 2025, 12, 'บริการดูดซับคาร์บอน', 0),
  
  -- Water filtration
  (1, 'regulating', 'กรองน้ำ', 1000, 'ลูกบาศก์เมตร', 50000.00, 2025, 11, 'กรองน้ำจากชุมชน', 0)
ON CONFLICT DO NOTHING;

-- Insert Sample Pollution Reports
INSERT INTO pollution_reports (community_id, report_type, pollution_source, severity_level, description, latitude, longitude, report_date, status, photos)
VALUES
  (1, 'Water Pollution', 'โรงงานแปรรูปอาหารทะเล', 'high', 'พบน้ำเสียสีเข้มปล่อยจากโรงงานลงสู่คลองที่ไหลผ่านป่าชายเลน มีกลิ่นเหม็นรุนแรง', 12.6789, 101.5432, '2026-02-15', 'investigating', ARRAY['pollution_001.jpg']),
  (1, 'Solid Waste', 'ขยะจากชาวบ้านและนักท่องเที่ยว', 'medium', 'ขยะพลาสติกสะสมริมหาดและในป่าชายเลน', 12.6543, 101.5678, '2026-02-20', 'pending', ARRAY['waste_001.jpg', 'waste_002.jpg']),
  (1, 'Chemical Pollution', 'ฟาร์มกุ้ง', 'medium', 'สารเคมีจากฟาร์มกุ้งปนเปื้อนในดิน', 12.6234, 101.5891, '2026-03-01', 'pending', ARRAY[]::TEXT[]),
  (1, 'Air Pollution', 'โรงงานอุตสาหกรรม', 'low', 'ควันจากโรงงานในพื้นที่ใกล้เคียง', 12.6890, 101.5123, '2026-03-05', 'monitoring', ARRAY['air_001.jpg'])
ON CONFLICT DO NOTHING;

-- Insert Sample Mangrove Areas (for public view)
INSERT INTO mangrove_areas (community_id, area_name, location, province, size_hectares, mangrove_species, conservation_status, latitude, longitude, description, established_year, managing_organization)
VALUES
  (1, 'ป่าชายเลนวังก์แก้ว', 'ตำบลวังก์แก้ว อำเภอระเอง', 'ระเอง', 250.00, ARRAY['ถั่วดำ', 'โปรง', 'แสม'], 'good', 12.6789, 101.5432, 'ป่าชายเลนที่มีความหลากหลายทางชีวภาพสูง', 1995, 'ชุมชนบ้านปลา'),
  (1, 'ป่าชายเลนปากคลองใหญ่', 'ตำบลเทพา อำเภอระเอง', 'ระเอง', 180.50, ARRAY['โปรง', 'แสม', 'ตะบูน'], 'moderate', 12.6543, 101.5678, 'ป่าชายเลนที่กำลังฟื้นฟูระบบนิเวศ', 2000, 'ชุมชนบ้านปลา'),
  (1, 'ป่าชายเลนเทพา', 'ตำบลเทพา อำเภอระเอง', 'ระเอง', 320.00, ARRAY['ถั่วดำ', 'โปรง', 'แสม', 'ตะบูน'], 'excellent', 12.6234, 101.5891, 'ป่าชายเลนที่อุดมสมบูรณ์ เหมาะกับการศึกษาธรรมชาติ', 1985, 'ชุมชนบ้านปลา')
ON CONFLICT DO NOTHING;

-- Log completed
SELECT 'Sample data inserted successfully!' as message;
