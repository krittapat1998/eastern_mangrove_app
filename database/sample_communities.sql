-- Insert sample community data
INSERT INTO communities (
    community_name, 
    location, 
    contact_person, 
    phone_number, 
    email, 
    description, 
    established_year, 
    member_count,
    photo_type,
    registration_status,
    area_size,
    conservation_status
) VALUES 
(
    'ชุมชนป่าชายเลนบางปู', 
    'บางปู สมุทรปราการ', 
    'สมชาย ใจดี', 
    '081-234-5678', 
    'leader1@bangpu.th', 
    'ชุมชนที่อนุรักษ์ป่าชายเลนบางปู', 
    1995, 
    120, 
    'ecosystem', 
    'approved', 
    15.5, 
    'good'
) ON CONFLICT (email) DO NOTHING;