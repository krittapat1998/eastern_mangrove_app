/**
 * Demo / screenshot seed for LOCAL development only.
 *
 * Fills an (already created) database with fictional data so every screen of
 * the app has something nice to show. Nothing here is real: names, phone
 * numbers and e-mails are made up (example.com).
 *
 * Usage (from api-server/, so that node_modules is found):
 *   NODE_PATH="$PWD/node_modules" DB_NAME=eastern_mangrove_demo node ../database/demo/seed_demo.js
 *
 * It refuses to run unless DB_HOST is localhost and DB_NAME contains "demo".
 * It TRUNCATES the main tables first.
 */
require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

if (!['localhost', '127.0.0.1'].includes(process.env.DB_HOST) || !/demo/.test(process.env.DB_NAME || '')) {
  console.error('Refusing to run: DB_HOST must be localhost and DB_NAME must contain "demo".');
  process.exit(1);
}

// ---- demo logins (local only) ---------------------------------------------
const DEMO_ADMIN = { username: 'demo_admin', password: 'DemoAdmin#2026', email: 'admin.demo@example.com' };
const DEMO_COMMUNITY = { username: 'demo_community', password: 'DemoCommunity#2026', email: 'community.demo@example.com' };

const pool = new Pool({
  host: process.env.DB_HOST, port: process.env.DB_PORT, database: process.env.DB_NAME,
  user: process.env.DB_USER, password: process.env.DB_PASSWORD,
  options: '-c search_path=eastern_mangrove_communities,public',
});

// small deterministic PRNG so the data is the same on every run
let seed = 20261106;
const rnd = () => ((seed = (seed * 1664525 + 1013904223) % 4294967296) / 4294967296);
const between = (a, b) => a + (b - a) * rnd();
const int = (a, b) => Math.round(between(a, b));

const COMMUNITIES = [
  // name, village, sub_district, district, province, lat, lng, members, species, status, user?
  ['กลุ่มอนุรักษ์ป่าชายเลนบ้านปากคลองแสม', 'บ้านปากคลองแสม', 'เกาะเปริด', 'แหลมสิงห์', 'จันทบุรี', 12.52, 102.08, 86, ['โกงกางใบเล็ก', 'แสมขาว', 'ถั่วขาว'], 'approved', 'demo'],
  ['ชุมชนรักษ์ป่าชายเลนบ้านท่าระแนะ', 'บ้านท่าระแนะ', 'แหลมงอบ', 'แหลมงอบ', 'ตราด', 12.1855, 102.4172, 64, ['โกงกางใบใหญ่', 'ตะบูนดำ', 'ลำพู'], 'approved', 'u2'],
  ['วิสาหกิจชุมชนปากน้ำประแสร์', 'บ้านปากน้ำประแสร์', 'ปากน้ำประแสร์', 'แกลง', 'ระยอง', 12.6821, 101.7173, 112, ['โกงกางใบเล็ก', 'แสมทะเล', 'พังกาหัวสุมดอกแดง'], 'approved', 'u3'],
  ['กลุ่มประมงพื้นบ้านคลองโตนด', 'บ้านคลองโตนด', 'คลองโตนด', 'ขลุง', 'จันทบุรี', 12.4723, 102.2441, 73, ['ถั่วดำ', 'โพทะเล', 'ตะบูนขาว'], 'approved', null],
  ['ชุมชนบางปะกงรักษ์ป่า', 'บ้านบางปะกง', 'ท่าข้าม', 'บางปะกง', 'ฉะเชิงเทรา', 13.4458, 100.9612, 58, ['แสมขาว', 'ลำแพน', 'ปรงทะเล'], 'approved', null],
  ['กลุ่มท่องเที่ยวเชิงนิเวศบ้านแหลมงอบ', 'บ้านแหลมงอบ', 'แหลมงอบ', 'แหลมงอบ', 'ตราด', 12.1738, 102.4056, 91, ['โกงกางใบใหญ่', 'ฝาดดอกแดง'], 'approved', null],
  // pending approval
  ['ชุมชนใหม่บ้านปากแม่น้ำเวฬุ', 'บ้านปากแม่น้ำเวฬุ', 'ท่าช้าง', 'เมืองจันทบุรี', 'จันทบุรี', 12.5102, 102.1189, 22, ['แสมขาว', 'โกงกางใบเล็ก'], 'pending', null],
  ['กลุ่มอนุรักษ์ป่าชายเลนบ้านบางพระ', 'บ้านบางพระ', 'ทุ่งสุขลา', 'ศรีราชา', 'ชลบุรี', 13.1442, 100.9187, 31, ['โกงกางใบเล็ก', 'ตะบูนขาว'], 'pending', null],
];

const AREAS = [
  // name, location, province, hectares, status, lat, lng, species, est, org, community index
  ['ป่าชายเลนปากคลองแสม', 'ต.เกาะเปริด อ.แหลมสิงห์', 'จันทบุรี', 412.5, 'excellent', 12.52, 102.08, ['โกงกางใบเล็ก', 'แสมขาว', 'ถั่วขาว'], 1998, 'ชุมชนบ้านปากคลองแสม', 0],
  ['ป่าชายเลนบ้านท่าระแนะ', 'ต.แหลมงอบ อ.แหลมงอบ', 'ตราด', 286.0, 'protected', 12.1855, 102.4172, ['โกงกางใบใหญ่', 'ตะบูนดำ', 'ลำพู'], 2003, 'ชุมชนบ้านท่าระแนะ', 1],
  ['ป่าชายเลนปากน้ำประแสร์', 'ต.ปากน้ำประแสร์ อ.แกลง', 'ระยอง', 538.4, 'excellent', 12.6821, 101.7173, ['โกงกางใบเล็ก', 'แสมทะเล', 'พังกาหัวสุมดอกแดง'], 1995, 'วิสาหกิจชุมชนปากน้ำประแสร์', 2],
  ['ป่าชายเลนคลองโตนด', 'ต.คลองโตนด อ.ขลุง', 'จันทบุรี', 197.8, 'good', 12.4723, 102.2441, ['ถั่วดำ', 'โพทะเล', 'ตะบูนขาว'], 2005, 'กลุ่มประมงพื้นบ้านคลองโตนด', 3],
  ['ป่าชายเลนบางปะกง', 'ต.ท่าข้าม อ.บางปะกง', 'ฉะเชิงเทรา', 154.2, 'moderate', 13.4458, 100.9612, ['แสมขาว', 'ลำแพน', 'ปรงทะเล'], 2010, 'ชุมชนบางปะกงรักษ์ป่า', 4],
  ['ป่าชายเลนอ่าวแหลมงอบ', 'ต.แหลมงอบ อ.แหลมงอบ', 'ตราด', 223.6, 'restored', 12.1738, 102.4056, ['โกงกางใบใหญ่', 'ฝาดดอกแดง'], 2012, 'กลุ่มท่องเที่ยวเชิงนิเวศบ้านแหลมงอบ', 5],
  ['ป่าชายเลนทุ่งสุขลา', 'ต.ทุ่งสุขลา อ.ศรีราชา', 'ชลบุรี', 68.9, 'threatened', 13.1442, 100.9187, ['โกงกางใบเล็ก', 'ตะบูนขาว'], 2015, 'กรมทรัพยากรทางทะเลและชายฝั่ง', null],
];

const RESOURCES = [
  ['crab', 'ปูทะเล', 'กก.', 260, [40, 130]],
  ['shrimp', 'กุ้งแชบ๊วย', 'กก.', 220, [25, 90]],
  ['shellfish', 'หอยแครง', 'กก.', 75, [60, 220]],
  ['fish', 'ปลากะพงขาว', 'กก.', 180, [30, 110]],
  ['firewood', 'ถ่านไม้โกงกาง', 'กก.', 18, [100, 400]],
];
const ACTIVITIES = [
  ['tour_guide', 'นำเที่ยวเดินป่าชายเลน', 350, [8, 40]],
  ['seminar', 'สัมมนาอนุรักษ์ป่าชายเลน', 500, [15, 60]],
  ['learning_camp', 'ค่ายเรียนรู้เยาวชน', 900, [12, 45]],
];

const POLLUTION = [
  // community idx, type, source, severity, status, description, lat, lng, daysAgo, hectares, cost
  [0, 'Water Pollution', 'น้ำเสียจากบ่อเลี้ยงกุ้ง', 'high', 'investigating', 'พบน้ำสีขุ่นและมีกลิ่นเหม็นบริเวณปากคลอง ปลาลอยตายหลายตัว', 12.522, 102.082, 6, 4.5, 85000],
  [0, 'Community Waste', 'ขยะพลาสติกจากชุมชน', 'medium', 'monitoring', 'ขยะพลาสติกและโฟมติดอยู่ตามรากโกงกางตลอดแนวชายฝั่ง', 12.512, 102.092, 19, 1.2, 12000],
  [0, 'Industrial Waste', 'น้ำมันรั่วไหลจากเรือประมง', 'critical', 'investigating', 'คราบน้ำมันลอยเป็นแนวยาวเข้าสู่แนวป่าชายเลนช่วงน้ำขึ้น', 12.528, 102.070, 3, 6.8, 240000],
  [0, 'Community Waste', 'ขยะลอยตามน้ำขึ้นน้ำลง', 'low', 'resolved', 'อาสาสมัครร่วมเก็บขยะ 40 คน ขนขยะออกได้ประมาณ 1.5 ตัน', 12.517, 102.101, 45, 0.8, 6000],
  [0, 'Water Pollution', 'น้ำทิ้งจากโรงงานแปรรูปอาหารทะเล', 'high', 'monitoring', 'ค่าออกซิเจนในน้ำต่ำผิดปกติ ตรวจวัดซ้ำทุกสัปดาห์', 12.534, 102.088, 12, 3.1, 120000],
  [0, 'Air Pollution', 'ควันจากการเผาขยะ', 'medium', 'pending', 'ควันจากการเผาขยะกลางแจ้งใกล้ชุมชนในช่วงเย็น', 12.508, 102.078, 2, 0.5, 0],
  [3, 'Water Pollution', 'ตะกอนจากการขุดลอกคลอง', 'medium', 'resolved', 'น้ำขุ่นจากการขุดลอก ปรับวิธีทำงานแล้ว น้ำกลับมาใสภายใน 2 สัปดาห์', 12.4701, 102.2420, 60, 2.0, 30000],
  [4, 'Community Waste', 'ขยะจากตลาดริมน้ำ', 'medium', 'investigating', 'ขยะอินทรีย์สะสมบริเวณท่าเรือ ประสานเทศบาลเพื่อจัดจุดทิ้งใหม่', 13.4440, 100.9590, 9, 0.6, 15000],
  [5, 'Industrial Waste', 'น้ำเสียจากอู่ซ่อมเรือ', 'high', 'pending', 'พบคราบสีและน้ำมันที่ปากร่องน้ำใกล้อู่ซ่อมเรือ', 12.1720, 102.4040, 1, 1.9, 0],
  [5, 'Water Pollution', 'ปุ๋ยและสารเคมีจากพื้นที่เกษตร', 'low', 'closed', 'ตรวจสอบแล้วอยู่ในเกณฑ์มาตรฐาน ปิดเรื่อง', 12.1760, 102.4090, 90, 0.3, 0],
];

(async () => {
  const c = await pool.connect();
  try {
    await c.query('BEGIN');
    await c.query(`TRUNCATE users, communities, mangrove_areas, activity_logs, admin_actions, community_activities,
      community_members, economic_data, ecosystem_services, photo_uploads, pollution_reports RESTART IDENTITY CASCADE`);

    // ---- users
    const hash = (p) => bcrypt.hash(p, 10);
    const mkUser = async (username, email, pw, first, last, type, phone) => (await c.query(
      `INSERT INTO users (username,email,password_hash,first_name,last_name,user_type,phone_number,is_active,email_verified)
       VALUES ($1,$2,$3,$4,$5,$6,$7,true,true) RETURNING id`, [username, email, await hash(pw), first, last, type, phone])).rows[0].id;
    const adminId = await mkUser(DEMO_ADMIN.username, DEMO_ADMIN.email, DEMO_ADMIN.password, 'ผู้ดูแล', 'ระบบ', 'admin', '0810000000');
    const u1 = await mkUser(DEMO_COMMUNITY.username, DEMO_COMMUNITY.email, DEMO_COMMUNITY.password, 'สมหมาย', 'รักษ์ป่า', 'community', '0810000001');
    const u2 = await mkUser('demo_community2', 'community2.demo@example.com', DEMO_COMMUNITY.password, 'วิไล', 'ทะเลใส', 'community', '0810000002');
    const u3 = await mkUser('demo_community3', 'community3.demo@example.com', DEMO_COMMUNITY.password, 'ประเสริฐ', 'ชายเลน', 'community', '0810000003');
    const userFor = { demo: [u1, DEMO_COMMUNITY.email], u2: [u2, 'community2.demo@example.com'], u3: [u3, 'community3.demo@example.com'] };

    // ---- communities
    const communityIds = [];
    for (let i = 0; i < COMMUNITIES.length; i++) {
      const [name, village, sub, dist, prov, lat, lng, members, species, status, u] = COMMUNITIES[i];
      const [uid, email] = u ? userFor[u] : [null, `contact${i + 1}.demo@example.com`];
      const r = await c.query(`INSERT INTO communities
        (community_name, location, contact_person, phone_number, email, description, established_year, member_count,
         photo_type, registration_status, approved_by, approved_at, coordinates, area_size, mangrove_species, conservation_status,
         village_name, sub_district, district, province, total_population, resource_dependent_population, households,
         main_occupation, main_religion, occupations, average_income, user_id, created_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'community',$9,$10,$11,point($12,$13),$14,$15,'protected',
                $16,$17,$18,$19,$20,$21,$22,'ประมง','พุทธ',$23,$24,$25, NOW() - ($26 || ' days')::interval)
        RETURNING id`,
        [name, `${village} ต.${sub} อ.${dist} จ.${prov}`, ['สมหมาย รักษ์ป่า', 'วิไล ทะเลใส', 'ประเสริฐ ชายเลน', 'มานะ ใจดี', 'สุดา แสนสุข', 'ธนา พึ่งทะเล', 'อารีย์ ชายฝั่ง', 'พิชัย รักทะเล'][i],
         `08${String(10000000 + i * 1111).slice(0, 8)}`, email,
         'ชุมชนที่ร่วมกันดูแลและฟื้นฟูป่าชายเลน พร้อมสร้างรายได้จากการประมงและการท่องเที่ยวเชิงนิเวศอย่างยั่งยืน',
         1995 + i * 3, members, status, status === 'approved' ? adminId : null, status === 'approved' ? new Date(Date.now() - (30 + i) * 86400000) : null,
         lng, lat, int(20, 80), species, village, sub, dist, prov,
         members * 6, int(members * 3, members * 5), members * 2,
         ['ประมง', 'ท่องเที่ยว', 'ค้าขาย'], int(9000, 19000), uid, 40 + i * 9]);
      communityIds.push(r.rows[0].id);
    }
    const approved = communityIds.slice(0, 6);

    // ---- mangrove areas
    for (const a of AREAS) {
      await c.query(`INSERT INTO mangrove_areas
        (community_id, area_name, location, province, size_hectares, mangrove_species, conservation_status, latitude, longitude,
         description, established_year, managing_organization, threats, conservation_activities)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)`,
        [a[10] === null ? null : communityIds[a[10]], a[0], a[1], a[2], a[3], a[7], a[4], a[5], a[6],
         'พื้นที่ป่าชายเลนที่เป็นแหล่งอนุบาลสัตว์น้ำและกันคลื่นลมชายฝั่ง มีการลาดตระเวนและปลูกป่าเสริมทุกปี',
         a[8], a[9], ['น้ำเสีย', 'ขยะทะเล'], ['ปลูกป่าเสริม', 'ลาดตระเวนพื้นที่', 'เก็บขยะชายฝั่ง']]);
    }

    // ---- ecosystem services: last 12 months (to this month) for approved communities
    const now = new Date();
    for (const cid of approved) {
      const scale = 0.6 + rnd() * 0.9;
      for (let m = 11; m >= 0; m--) {
        const d = new Date(now.getFullYear(), now.getMonth() - m, 1);
        const year = d.getFullYear(), month = d.getMonth() + 1;
        const season = 0.8 + 0.4 * Math.sin((month / 12) * Math.PI * 2);
        for (const [type, name, unit, price, [lo, hi]] of RESOURCES) {
          if (rnd() < 0.25) continue;
          const qty = Math.round(between(lo, hi) * scale * season);
          await c.query(`INSERT INTO ecosystem_services
            (community_id, service_type, service_name, quantity, unit, economic_value, year, month, description, beneficiaries_count,
             measurement_method, data_source, confidence_level, category, unit_price)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'ชั่งน้ำหนัก','สมุดบันทึกชุมชน','high','resource',$11)`,
            [cid, type, name, qty, unit, qty * price, year, month, `ผลผลิต${name}ประจำเดือน`, int(8, 40), price]);
        }
        for (const [type, name, pricePP, [lo, hi]] of ACTIVITIES) {
          if (rnd() < 0.45) continue;
          const people = Math.round(between(lo, hi) * scale);
          await c.query(`INSERT INTO ecosystem_services
            (community_id, service_type, service_name, quantity, unit, economic_value, year, month, description, beneficiaries_count,
             measurement_method, data_source, confidence_level, category, participants, price_per_person)
            VALUES ($1,$2,$3,1,'ครั้ง',$4,$5,$6,$7,$8,'ทะเบียนผู้เข้าร่วม','สมุดบันทึกชุมชน','high','activity',$8,$9)`,
            [cid, type, name, people * pricePP, year, month, `กิจกรรม${name}`, people, pricePP]);
        }
      }
    }

    // ---- quarterly economic data: 2025 Q1 .. current quarter - 1
    const curYear = now.getFullYear(), curQ = Math.floor(now.getMonth() / 3) + 1;
    for (const cid of approved) {
      const base = 0.7 + rnd() * 0.9;
      for (let y = 2025; y <= curYear; y++) {
        for (let q = 1; q <= 4; q++) {
          if (y === curYear && q >= curQ) break;
          const growth = 1 + ((y - 2025) * 4 + q) * 0.015;
          const f = Math.round(between(60000, 150000) * base * growth);
          const t = Math.round(between(20000, 120000) * base * growth * (q === 4 || q === 1 ? 1.3 : 0.9));
          const ag = Math.round(between(5000, 40000) * base);
          const ot = Math.round(between(3000, 25000) * base);
          await c.query(`INSERT INTO economic_data (community_id, year, quarter, income_fishery, income_tourism, income_agriculture, income_others, employment_count, notes)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`, [cid, y, q, f, t, ag, ot, int(25, 90), 'ข้อมูลรายได้ชุมชนประจำไตรมาส']);
        }
      }
    }

    // ---- pollution reports
    for (const [ci, type, src, sev, status, desc, lat, lng, daysAgo, ha, cost] of POLLUTION) {
      const when = new Date(Date.now() - daysAgo * 86400000);
      await c.query(`INSERT INTO pollution_reports
        (community_id, report_type, pollution_source, severity_level, description, latitude, longitude, report_date, status,
         reported_by, affected_area_hectares, estimated_cost, follow_up_required, created_at, updated_at, resolved_at, resolution_notes)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$8,$8,$14,$15)`,
        [communityIds[ci], type, src, sev, desc, lat, lng, when, status, ci === 0 ? u1 : ci === 1 ? u2 : ci === 2 ? u3 : null, ha, cost,
         !['resolved', 'closed'].includes(status), ['resolved', 'closed'].includes(status) ? when : null,
         ['resolved', 'closed'].includes(status) ? 'ดำเนินการแก้ไขและตรวจสอบเรียบร้อยแล้ว' : null]);
    }

    // optional new fields (need migration_add_area_contact_and_pollution_impact.sql); skipped if columns are missing
    const hasNew = (await c.query(`SELECT count(*) n FROM information_schema.columns WHERE table_schema='eastern_mangrove_communities' AND
      ((table_name='pollution_reports' AND column_name='expected_impact') OR (table_name='mangrove_areas' AND column_name IN ('contact_person','contact_channel')))`)).rows[0].n == 3;
    if (hasNew) {
      await c.query(`UPDATE pollution_reports SET expected_impact = CASE report_type
        WHEN 'Water Pollution' THEN 'น้ำเสียอาจทำให้สัตว์น้ำตายและรากโกงกางเน่า'
        WHEN 'Air Pollution' THEN 'ควันอาจกระทบสุขภาพชาวบ้านและใบโกงกาง'
        WHEN 'Industrial Waste' THEN 'สารปนเปื้อนสะสมในดินเลน กระทบแหล่งอนุบาลสัตว์น้ำ'
        ELSE 'ขยะพันรากไม้ ทำให้ต้นอ่อนโตช้าและน้ำไหลเวียนไม่สะดวก' END`);
      await c.query(`UPDATE mangrove_areas SET contact_person = 'ผู้ประสานงานตัวอย่าง ' || id, contact_channel = 'LINE: demo_area_' || id`);
    }

    await c.query('COMMIT');
    const counts = await c.query(`SELECT
      (SELECT count(*) FROM users) users, (SELECT count(*) FROM communities) communities, (SELECT count(*) FROM mangrove_areas) areas,
      (SELECT count(*) FROM ecosystem_services) services, (SELECT count(*) FROM economic_data) economic, (SELECT count(*) FROM pollution_reports) reports`);
    console.log('Seeded:', counts.rows[0]);
    console.log(`Demo logins -> admin: ${DEMO_ADMIN.username} / community: ${DEMO_COMMUNITY.username} (passwords are in database/demo/seed_demo.js)`);
  } catch (e) {
    await c.query('ROLLBACK');
    console.error('Seed failed:', e.message);
    process.exitCode = 1;
  } finally {
    c.release();
    await pool.end();
  }
})();
