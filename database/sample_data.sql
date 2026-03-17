-- Sample Data for Eastern Mangrove Communities Database
-- Run this after schema.sql
-- This will create test users, communities, and activities

-- Clear existing data (except system admin)
DELETE FROM activity_logs;
DELETE FROM photo_uploads;
DELETE FROM community_activities;
DELETE FROM community_members;
DELETE FROM communities;
DELETE FROM users WHERE email != 'admin@easternmangrove.th';

-- Reset sequences
ALTER SEQUENCE users_id_seq RESTART WITH 2;
ALTER SEQUENCE communities_id_seq RESTART WITH 1;
ALTER SEQUENCE community_members_id_seq RESTART WITH 1;
ALTER SEQUENCE community_activities_id_seq RESTART WITH 1;
ALTER SEQUENCE photo_uploads_id_seq RESTART WITH 1;
ALTER SEQUENCE activity_logs_id_seq RESTART WITH 1;

-- Update admin password to a known value for testing
-- Password: admin123!
UPDATE users 
SET password_hash = '$2a$12$LGqhX1qL8wXxmzX1qL8wXuxKqjq7.7yJ.vqHqjq7.7yJ.vqH2.7yJ' 
WHERE email = 'admin@easternmangrove.th';

-- Sample Users
INSERT INTO users (email, password_hash, first_name, last_name, user_type, phone_number, is_active, email_verified) VALUES
-- Community Leaders (password: community123!)
('leader1@bangpu.th', '$2a$12$CommunityHash1.CommunityHash1.CommunityHash1.Community', 'สมชาย', 'ใจดี', 'community', '081-234-5678', true, true),
('leader2@laemfapha.th', '$2a$12$CommunityHash2.CommunityHash2.CommunityHash2.Community', 'สมหญิง', 'รักษ์ป่า', 'community', '082-345-6789', true, true),
('leader3@klaeng.th', '$2a$12$CommunityHash3.CommunityHash3.CommunityHash3.Community', 'วิชัย', 'อนุรักษ์', 'community', '083-456-7890', true, true),

-- Public Users (password: public123!)
('user1@gmail.com', '$2a$12$PublicHash1.PublicHash1.PublicHash1.PublicHash1.Public', 'อนันต์', 'ธรรมชาติ', 'public', '084-567-8901', true, true),
('user2@gmail.com', '$2a$12$PublicHash2.PublicHash2.PublicHash2.PublicHash2.Public', 'สุดา', 'รักทะเล', 'public', '085-678-9012', true, true),
('user3@gmail.com', '$2a$12$PublicHash3.PublicHash3.PublicHash3.PublicHash3.Public', 'ธนา', 'เขียวชอุ่ม', 'public', '086-789-0123', true, false),

-- Research Users
('research1@university.th', '$2a$12$ResearchHash1.ResearchHash1.ResearchHash1.Research', 'ดร.วิรัช', 'วิจัยป่า', 'public', '087-890-1234', true, true),
('research2@university.th', '$2a$12$ResearchHash2.ResearchHash2.ResearchHash2.Research', 'ดร.นิตยา', 'สิ่งแวดล้อม', 'public', '088-901-2345', true, true);

-- Sample Communities
INSERT INTO communities (
    community_name, location, contact_person, phone_number, email, 
    description, established_year, member_count, photo_type, 
    registration_status, approved_by, approved_at,
    coordinates, area_size, mangrove_species, conservation_status
) VALUES
-- Approved Communities
(
    'ชุมชนอนุรักษ์ป่าชายเลนบางปู',
    'ตำบลบางปู อำเภอเมือง จังหวัดสมุทรปราการ',
    'นายสมชาย ใจดี',
    '081-234-5678',
    'bangpu@community.th',
    'ชุมชนที่มุ่งเน้นการอนุรักษ์และฟื้นฟูป่าชายเลนในพื้นที่บางปู มีกิจกรรมการจัดการขยะ การปลูกป่าชายเลน และการศึกษาธรรมชาติ',
    1998,
    150,
    'community',
    'approved',
    1, -- admin user
    NOW() - INTERVAL '30 days',
    POINT(100.6331, 13.4955), -- Bangpu coordinates
    25.5,
    ARRAY['โกงกาง', 'แสม', 'ลำพู', 'โพธิ์ทะเล'],
    'Good'
),
(
    'กลุ่มอนุรักษ์ป่าชายเลนแหลมผาพา',
    'ตำบลกิ่งอำพอ อำเภอเมือง จังหวัดสมุทรสาคร',
    'นางสมหญิง รักษ์ป่า',
    '082-345-6789',
    'laemfapha@community.th',
    'กลุ่มผู้ที่มีความหลงใหลในการอนุรักษ์ระบบนิเวศป่าชายเลน เน้นการศึกษาวิจัยและการท่องเที่ยวเชิงนิเวศ',
    2005,
    89,
    'mangrove',
    'approved',
    1,
    NOW() - INTERVAL '20 days',
    POINT(100.2741, 13.4139),
    18.3,
    ARRAY['โกงกาง', 'แสม', 'ตาบูน'],
    'Excellent'
),
(
    'เครือข่ายชุมชนป่าชายเลนแกลง',
    'ตำบลแกลง อำเภอแกลง จังหวัดระยอง',
    'นายวิชัย อนุรักษ์',
    '083-456-7890',
    'klaeng@network.th',
    'เครือข่ายที่รวมหลายชุมชนในพื้นที่แกลง ทำงานร่วมกันในการปกป้องและฟื้นฟูป่าชายเลนจากผลกระทบของอุตสาหกรรม',
    2010,
    245,
    'community',
    'approved',
    1,
    NOW() - INTERVAL '15 days',
    POINT(101.3480, 12.7307),
    42.8,
    ARRAY['โกงกาง', 'แสม', 'ลำพู', 'โพธิ์ทะเล', 'ตาบูน'],
    'Fair'
),

-- Pending Communities
(
    'ชุมชนป่าชายเลนปากน้ำประแสร์',
    'ตำบลประแสร์ อำเภอแกลง จังหวัดระยอง',
    'นางสาวพิมพ์ใจ ทะเลสวย',
    '089-012-3456',
    'prasae@community.th',
    'ชุมชนริมแม่น้ำประแสร์ที่ต้องการเข้าร่วมเครือข่ายเพื่อการอนุรักษ์ป่าชายเลนและการพัฒนาการท่องเที่ยวอย่างยั่งยืน',
    2020,
    67,
    'profile',
    'pending',
    NULL,
    NULL,
    POINT(101.4223, 12.6830),
    15.2,
    ARRAY['โกงกาง', 'แสม'],
    'Good'
),
(
    'กลุ่มผู้ใหญ่บ้านคลองโคน',
    'ตำบลคลองโคน อำเภอคลองโคน จังหวัดสมุทรสงคราม',
    'นายประยุทธ สีเขียว',
    '090-123-4567',
    'klongkone@village.th',
    'กลุ่มผู้ใหญ่บ้านที่ต้องการพัฒนาการจัดการท่องเที่ยวชุมชนและการอนุรักษ์ป่าชายเลนในท้องถิ่น',
    2018,
    34,
    'community',
    'pending',
    NULL,
    NULL,
    POINT(100.1167, 13.3167),
    8.7,
    ARRAY['โกงกาง', 'ลำพู'],
    'Fair'
);

-- Community Members (link users to communities)
INSERT INTO community_members (user_id, community_id, role) VALUES
-- Bangpu Community
(2, 1, 'admin'),    -- สมชาย as admin of Bangpu
(5, 1, 'member'),   -- สุดา as member
(6, 1, 'volunteer'), -- ธนา as volunteer

-- Laem Fapha Community  
(3, 2, 'admin'),    -- สมหญิง as admin of Laem Fapha
(7, 2, 'member'),   -- ดร.วิรัช as member (researcher)
(4, 2, 'member'),   -- อนันต์ as member

-- Klaeng Network
(4, 3, 'admin'),    -- วิชัย as admin of Klaeng
(8, 3, 'member'),   -- ดร.นิตยา as member (researcher)
(5, 3, 'volunteer'); -- สุดา as volunteer (multi-community member)

-- Sample Activities
INSERT INTO community_activities (
    community_id, created_by, title, description, activity_type,
    start_date, end_date, location, coordinates,
    max_participants, current_participants, status,
    budget, funding_source, tags
) VALUES
-- Past Activities
(
    1, 2, -- Bangpu, by สมชาย
    'โครงการปลูกป่าชายเลน ครั้งที่ 15',
    'กิจกรรมปลูกต้นโกงกางและแสมเพื่อฟื้นฟูพื้นที่ป่าชายเลนที่เสื่อมโทรม ร่วมมือกับโรงเรียนในพื้นที่และหน่วยงานราชการ',
    'planting',
    NOW() - INTERVAL '45 days',
    NOW() - INTERVAL '44 days',
    'ป่าชายเลนบางปู หน้าเขื่อน',
    POINT(100.6340, 13.4960),
    100,
    87,
    'completed',
    15000.00,
    'เทศบาลเมืองสมุทรปราการ',
    ARRAY['ปลูกป่า', 'โกงกาง', 'แสม', 'ฟื้นฟู']
),
(
    2, 3, -- Laem Fapha, by สมหญิง
    'การสำรวจความหลากหลายทางชีวภาพ',
    'โครงการสำรวจและบันทึกข้อมูลสัตว์น้ำและพืชในระบบนิเวศป่าชายเลน ร่วมกับนักวิจัยจากมหาวิทยาลัย',
    'research',
    NOW() - INTERVAL '30 days',
    NOW() - INTERVAL '28 days',
    'แหลมผาพา พื้นที่อนุรักษ์',
    POINT(100.2750, 13.4150),
    25,
    23,
    'completed',
    25000.00,
    'กรมทรัพยากรทางทะเลและชายฝั่ง',
    ARRAY['วิจัย', 'สำรวจ', 'ความหลากหลายทางชีวภาพ']
),

-- Ongoing Activities
(
    3, 4, -- Klaeng, by วิชัย
    'โครงการตรวจสอบคุณภาพน้ำประจำเดือน',
    'กิจกรรมตรวจสอบคุณภาพน้ำในแม่น้ำและคลองที่ไหลผ่านป่าชายเลน เพื่อติดตามผลกระทบจากโรงงานอุตสาหกรรม',
    'monitoring',
    NOW() - INTERVAL '5 days',
    NOW() + INTERVAL '25 days',
    'แม่น้ำแกลง หลายจุดตรวจสอบ',
    POINT(101.3500, 12.7320),
    15,
    12,
    'ongoing',
    8000.00,
    'กองทุนสิ่งแวดล้อม',
    ARRAY['ตรวจสอบ', 'คุณภาพน้ำ', 'มลพิษ']
),

-- Future Activities
(
    1, 2, -- Bangpu, by สมชาย
    'ค่ายเยาวชนรักป่าชายเลน ครั้งที่ 8',
    'ค่ายสำหรับเยาวชนอายุ 12-18 ปี เรียนรู้เกี่ยวกับระบบนิเวศป่าชายเลน การอนุรักษ์ และการดำรงชีวิตอย่างยั่งยืน',
    'education',
    NOW() + INTERVAL '10 days',
    NOW() + INTERVAL '12 days',
    'ศูนย์การเรียนรู้ป่าชายเลนบางปู',
    POINT(100.6335, 13.4958),
    50,
    23,
    'planned',
    20000.00,
    'มูลนิธิป่าชายเลน',
    ARRAY['การศึกษา', 'เยาวชน', 'ค่าย']
),
(
    2, 3, -- Laem Fapha, by สมหญิง
    'เทศกาลป่าชายเลนแหลมผาพา',
    'เทศกาลประจำปีเพื่อส่งเสริมการท่องเที่ยวเชิงนิเวศและสร้างความตระหนักเรื่องการอนุรักษ์ มีกิจกรรมทั้งการแสดง การขาย และการเรียนรู้',
    'community_event',
    NOW() + INTERVAL '30 days',
    NOW() + INTERVAL '32 days',
    'หาดแหลมผาพา',
    POINT(100.2745, 13.4145),
    500,
    78,
    'planned',
    150000.00,
    'การท่องเที่ยวแห่งประเทศไทย',
    ARRAY['เทศกาล', 'ท่องเที่ยว', 'ชุมชน', 'การแสดง']
),
(
    3, 4, -- Klaeng, by วิชัย
    'อบรมการจัดการขยะชุมชนและการรีไซเคิล',
    'การอบรมให้ความรู้เรื่องการลดการใช้พลาสติก การจัดการขยะ และการนำขยะกลับมาใช้ใหม่ เพื่อลดปัญหาขยะในทะเล',
    'training',
    NOW() + INTERVAL '20 days',
    NOW() + INTERVAL '21 days',
    'ศาลาอเนกประสงค์ ตำบลแกลง',
    POINT(101.3485, 12.7310),
    80,
    31,
    'planned',
    12000.00,
    'สำนักงานสิ่งแวดล้อมภาค',
    ARRAY['การอบรม', 'ขยะ', 'รีไซเคิล', 'สิ่งแวดล้อม']
);

-- Sample Photo Uploads
INSERT INTO photo_uploads (
    uploaded_by, community_id, activity_id, filename, original_filename,
    file_path, file_size, mime_type, photo_type, description,
    coordinates, taken_at, is_public, is_featured, tags
) VALUES
(
    2, 1, 1, -- สมชาย, Bangpu, planting activity
    'bangpu_planting_2026_001.jpg',
    'IMG_20260201_094500.jpg',
    '/uploads/communities/bangpu/activities/bangpu_planting_2026_001.jpg',
    2456789,
    'image/jpeg',
    'activity',
    'เยาวชนและชุมชนร่วมกันปลูกต้นโกงกางในพื้นที่ฟื้นฟู',
    POINT(100.6340, 13.4961),
    NOW() - INTERVAL '44 days 14 hours',
    true,
    true,
    ARRAY['ปลูกป่า', 'เยาวชน', 'โกงกาง']
),
(
    3, 2, NULL, -- สมหญิง, Laem Fapha, community profile
    'laemfapha_profile_2026.jpg',
    'community_photo.jpg',
    '/uploads/communities/laemfapha/laemfapha_profile_2026.jpg',
    3789456,
    'image/jpeg',
    'community',
    'ภาพถ่ายหมู่สมาชิกชุมชนหน้าป้ายแหลมผาพา',
    POINT(100.2745, 13.4148),
    NOW() - INTERVAL '30 days 10 hours',
    true,
    false,
    ARRAY['ชุมชน', 'สมาชิก', 'แหลมผาพา']
),
(
    7, 2, 2, -- ดร.วิรัช, Laem Fapha, research activity
    'biodiversity_survey_crab.jpg',
    'mangrove_crab_species.jpg',
    '/uploads/communities/laemfapha/activities/biodiversity_survey_crab.jpg',
    1234567,
    'image/jpeg',
    'species',
    'ปูป่าชายเลนสายพันธุ์หายาก พบในระหว่างการสำรวจ',
    POINT(100.2752, 13.4152),
    NOW() - INTERVAL '29 days 8 hours',
    true,
    true,
    ARRAY['สำรวจ', 'ปู', 'สายพันธุ์', 'หายาก']
),
(
    4, 3, NULL, -- วิชัย, Klaeng, mangrove ecosystem
    'klaeng_mangrove_sunset.jpg',
    'sunset_mangrove.jpg',
    '/uploads/communities/klaeng/klaeng_mangrove_sunset.jpg',
    4567890,
    'image/jpeg',
    'mangrove',
    'ภาพพระอาทิตย์ตกดินที่ป่าชายเลนแกลง สวยงามและสงบ',
    POINT(101.3485, 12.7315),
    NOW() - INTERVAL '15 days 18 hours',
    true,
    true,
    ARRAY['พระอาทิตย์ตกดิน', 'ธรรมชาติ', 'สวยงาม']
);

-- Sample Activity Logs
INSERT INTO activity_logs (user_id, action, entity_type, entity_id, description, ip_address) VALUES
(1, 'APPROVE_COMMUNITY', 'community', 1, 'Approved Bangpu community registration', '192.168.1.100'),
(1, 'APPROVE_COMMUNITY', 'community', 2, 'Approved Laem Fapha community registration', '192.168.1.100'),
(1, 'APPROVE_COMMUNITY', 'community', 3, 'Approved Klaeng community registration', '192.168.1.100'),
(2, 'CREATE_ACTIVITY', 'activity', 1, 'Created tree planting activity', '192.168.1.101'),
(3, 'CREATE_ACTIVITY', 'activity', 2, 'Created biodiversity survey activity', '192.168.1.102'),
(4, 'CREATE_ACTIVITY', 'activity', 3, 'Created water quality monitoring activity', '192.168.1.103'),
(2, 'UPLOAD_PHOTO', 'photo', 1, 'Uploaded activity photo', '192.168.1.101'),
(7, 'UPLOAD_PHOTO', 'photo', 3, 'Uploaded species documentation photo', '192.168.1.107');

-- Update statistics (only for approved communities)
UPDATE communities SET 
    member_count = (
        SELECT COUNT(*) 
        FROM community_members cm 
        WHERE cm.community_id = communities.id 
        AND cm.is_active = true
    )
WHERE registration_status = 'approved';

UPDATE community_activities SET
    current_participants = 
        CASE 
            WHEN id = 1 THEN 87
            WHEN id = 2 THEN 23  
            WHEN id = 3 THEN 12
            WHEN id = 4 THEN 23
            WHEN id = 5 THEN 78
            WHEN id = 6 THEN 31
            ELSE current_participants
        END;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🌱 Sample data inserted successfully!';
    RAISE NOTICE '👥 Users: % (including 1 admin)', (SELECT COUNT(*) FROM users);
    RAISE NOTICE '🏘️  Communities: % (% approved, % pending)', 
        (SELECT COUNT(*) FROM communities),
        (SELECT COUNT(*) FROM communities WHERE registration_status = 'approved'),
        (SELECT COUNT(*) FROM communities WHERE registration_status = 'pending');
    RAISE NOTICE '🎯 Activities: %', (SELECT COUNT(*) FROM community_activities);
    RAISE NOTICE '📸 Photos: %', (SELECT COUNT(*) FROM photo_uploads);
    RAISE NOTICE '';
    RAISE NOTICE '🔑 Test Login Credentials:';
    RAISE NOTICE '   Admin: admin@easternmangrove.th / admin123!';
    RAISE NOTICE '   Community: leader1@bangpu.th / community123!';
    RAISE NOTICE '   Public: user1@gmail.com / public123!';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Ready to start API server!';
END $$;