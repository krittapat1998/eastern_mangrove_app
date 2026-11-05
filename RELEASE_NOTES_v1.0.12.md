# Release Notes - Version 1.0.12
**วันที่เผยแพร่:** 6 พฤศจิกายน 2026

---

## 📱 สำหรับ App Store Connect และ Google Play Console

### 🇹🇭 ภาษาไทย (Thai)

#### รูปแบบสั้น (ช่อง "มีอะไรใหม่ในเวอร์ชันนี้" บน App Store)
```
เวอร์ชัน 1.0.12
✨ แสดงปีเป็น พ.ศ. และพื้นที่เป็นไร่ทุกหน้า ตรงกันทั้งแอป
🔧 แก้ไขหน้าข้อมูลชุมชนที่ค้างเมื่อมีข้อมูลอาชีพที่ไม่ตรงตัวเลือก
🔧 ปรับปรุงหน้าลงทะเบียนชุมชน เก็บที่อยู่ครบ และข้อความแจ้งเตือนชัดเจนขึ้น
📝 รายงานมลพิษเพิ่มช่อง "น่าจะส่งผลอย่างไร" และระบุพิกัดผ่าน Google Maps ได้
📍 ขอใช้ตำแหน่งเฉพาะตอนเปิดแผนที่ ไม่ขอทันทีที่เปิดแอป
```

#### รูปแบบยาว (สำหรับ Google Play)
```
เวอร์ชัน 1.0.12

✨ ปรับปรุง
• รายงานมลพิษ: เพิ่มช่อง "น่าจะส่งผลอย่างไรต่อป่าชายเลน"
• ระบุพิกัดมลพิษจาก Google Maps (เปิด Google Maps แล้ววางพิกัดที่คัดลอก)
• ผู้ดูแลระบบบันทึกผู้ติดต่อและช่องทางติดต่อของแต่ละพื้นที่ป่า (เห็นเฉพาะผู้ดูแลระบบ)
• แสดงปีเป็น พ.ศ. ทุกหน้า (รายงานไตรมาส บริการนิเวศ รายงานมลพิษ หน้าอนุมัติ)
• แสดงและกรอกขนาดพื้นที่เป็น "ไร่" ทุกหน้า และแปลงหน่วยให้ถูกต้อง
• หน้าสถิติของผู้ใช้ทั่วไปแสดงจำนวนพื้นที่ ชุมชน และมูลค่าได้ถูกต้อง
• กิจกรรมล่าสุดในหน้าชุมชนแสดงชื่อรายการจริง
• ขอสิทธิ์เข้าถึงตำแหน่งเมื่อเปิดแท็บแผนที่เท่านั้น

🔧 แก้ไข
• แก้ไขหน้าข้อมูลชุมชนที่ใช้งานไม่ได้เมื่ออาชีพที่บันทึกไว้ไม่ตรงตัวเลือก
• การลงทะเบียนชุมชนเก็บจังหวัด อำเภอ ตำบล ครบถ้วน
• ข้อความแจ้งเตือนสีแดงในฟอร์มหายทันทีเมื่อแก้ไขข้อมูลถูกต้อง
• ตัวเลขชุมชนรออนุมัติของผู้ดูแลระบบอัปเดตหลังกลับจากหน้าอนุมัติ
• ข้อความแจ้งเมื่อกรอกข้อมูลไม่ถูกต้องอ่านเข้าใจง่ายขึ้น
• ปรับหน้าเลือกประเภทผู้ใช้ไม่ให้ข้อความถูกตัด
```

---

### 🇬🇧 English

#### Short Format (App Store "What's New")
```
Version 1.0.12
✨ Years shown in Buddhist Era and areas in rai consistently across the app
🔧 Fixed a crash on the community info page for unusual saved occupation values
🔧 Better community registration: full address saved, clearer error messages
📝 Pollution reports have an "expected impact" field; pick coordinates via Google Maps
📍 Location is requested only when you open the map, not at launch
```

#### Long Format (Google Play)
```
Version 1.0.12

✨ Improvements
• Pollution reports: new "expected impact on the mangrove" field
• Pick pollution coordinates from Google Maps (open Google Maps, then paste the copied coordinates)
• Admins can record a contact person and contact channel per mangrove area (admin-only)
• Years are shown in Buddhist Era (B.E.) on every screen
• Area sizes are shown and entered in rai everywhere, with correct unit conversion
• Public statistics card now shows the correct number of areas, communities and value
• "Recent activity" on the community home shows real item names
• Location permission is requested only when opening the map tab

🔧 Fixes
• Fixed the community info screen failing when a saved occupation is not a standard option
• Community registration now stores province, district and sub-district
• Red form errors clear as soon as the value is corrected
• Admin pending-approval count refreshes after returning from the approval screen
• Clearer messages when submitted data is invalid
• Role picker text is no longer cut off
```

---

## 🔑 ข้อมูลสำหรับผู้ตรวจสอบ (App Review Notes)

> ใส่บัญชีทดสอบของ production ที่ **คุณสร้างเอง** (ผมไม่ได้ใส่รหัสผ่านให้ในไฟล์นี้)
> ผู้ใช้ทั่วไปดูข้อมูลได้โดยไม่ต้องล็อกอิน (กด "ผู้ใช้ทั่วไป")

```
How to use:
1. Tap "ผู้ใช้ทั่วไป" (General user) to browse public data without signing in.
2. Tap "ชุมชน" (Community) or "ผู้ดูแลระบบ (Admin)" to sign in.
Demo accounts: <ใส่ username/password ของบัญชีทดสอบบน production>
Location is requested only when opening the map tab (to show the user's position).
```

---

## 📋 รายละเอียดการเปลี่ยนแปลงทั้งหมด

### ✨ การปรับปรุง
0. **ตามเอกสารขอบเขตงาน:** ช่อง "น่าจะส่งผลอย่างไร" ในรายงานมลพิษ, ระบุพิกัดผ่าน Google Maps (ปุ่ม "เปิด Google Maps" + "วางพิกัดที่คัดลอก" ใน [`coordinates.dart`](eastern_mangrove_app/lib/utils/coordinates.dart) ตรวจว่าเป็นพิกัดในประเทศไทย และสลับ lat/lng ให้ถ้ากลับด้าน), ผู้ติดต่อ/ช่องทางติดต่อของพื้นที่ป่า (เฉพาะ Admin)
1. **หน่วยพื้นที่ถูกต้อง (ไร่ ↔ เฮกตาร์)** — ฐานข้อมูลเก็บเป็นเฮกตาร์ แอปแสดง/รับเป็นไร่ (1 เฮกตาร์ = 6.25 ไร่) แปลงที่ชั้น `ApiClient` (`AreaUnit`) ที่เดียว
2. **ปี พ.ศ. ทุกหน้า** (รวมหน้าสร้าง/แก้ไขชุมชนของ Admin และปีที่ก่อตั้งพื้นที่ป่า ที่เดิมลงปี ค.ศ. ทั้งที่ป้ายเขียน พ.ศ.) — เพิ่ม [`thai_date.dart`](eastern_mangrove_app/lib/utils/thai_date.dart) ฐานข้อมูลยังเก็บ ค.ศ. ช่องกรอกปีเป็น พ.ศ. (ถ้าพิมพ์ 2026 ก็ยังบันทึกถูก)
3. **การ์ดสถิติหน้า public** เดิมแสดง 0 เสมอ (อ่าน JSON ผิดระดับ)
4. **ขอสิทธิ์ตำแหน่ง** เฉพาะตอนเปิดแท็บแผนที่ และปรับข้อความอธิบายใน `Info.plist`
5. **กิจกรรมล่าสุด** แสดงชื่อรายการจริง และแปลประเภทมลพิษเป็นไทย
6. **หน้าสมัครชุมชน/ล็อกอิน** ฟอร์มตรวจสอบซ้ำขณะพิมพ์ และ status bar เป็นสีเข้มบนพื้นสว่าง

### 🔧 การแก้ไขบั๊ก
1. หน้าข้อมูลชุมชนแครช (จอแดง) เมื่ออาชีพที่บันทึกไว้ไม่ตรงตัวเลือก dropdown
2. ลงทะเบียนชุมชนไม่ได้เก็บจังหวัด/อำเภอ/ตำบลแยกฟิลด์
3. ตัวเลขชุมชนรออนุมัติบนแดชบอร์ด Admin ไม่รีเฟรชหลังกลับจากหน้าอนุมัติ
4. กล่องข้อความท้ายหน้าเลือกประเภทผู้ใช้ถูกตัด

---

## 💻 Technical Details

### Backend (ต้อง deploy ขึ้น Render หลังรัน migration และก่อนปล่อยแอป)
- [`database.js`](api-server/config/database.js) — แปลง error ข้อมูลผิดของ Postgres เป็น 400/409 พร้อมข้อความไทย (เดิมตอบ 500 + ข้อความ SQL ดิบ)
- [`auth.js`](api-server/routes/auth.js), [`validation.js`](api-server/middleware/validation.js) — `register-community` เก็บ village/sub_district/district/province; ไม่ log รหัสผ่านอีกต่อไป
- [`pollution.js`](api-server/routes/community/pollution.js) — รับ/ส่ง `expected_impact`; [`mangrove-areas.js`](api-server/routes/admin/mangrove-areas.js) — รับ/ส่ง `contact_person`, `contact_channel` (public API ไม่เปิดเผยสองฟิลด์นี้)
- routes ใน `admin/` และ `community/` — catch block ใช้ `error.status` แทน 500 ตายตัว

### Database
- ⚠️ **มีการเพิ่มคอลัมน์ 3 ตัว** (เพิ่มอย่างเดียว ไม่แก้/ลบข้อมูลเดิม) ตาม scope document:
  `mangrove_areas.contact_person`, `mangrove_areas.contact_channel`, `pollution_reports.expected_impact`
  → รัน [`migration_add_area_contact_and_pollution_impact.sql`](database/migration_add_area_contact_and_pollution_impact.sql) (รันซ้ำได้ ปลอดภัย)
- **ลำดับการปล่อย: (1) รัน migration นี้ → (2) deploy `api-server` ขึ้น Render → (3) ปล่อยแอป**
  ถ้า deploy API ก่อน migration การบันทึกรายงานมลพิษ/พื้นที่ป่าจะ error
- ⚠️ **ต้องพิจารณา data migration ของหน่วยพื้นที่:** [`migration_convert_area_rai_to_hectares.sql`](database/migration_convert_area_rai_to_hectares.sql)
  เวอร์ชัน ≤ 1.0.11 เก็บค่า "ไร่" ลงคอลัมน์ที่เป็นเฮกตาร์ (ตรวจข้อมูล production แล้ว: ต้องแก้เฉพาะ `communities.area_size` ids 1,2,3,6,7; ids 5 และ 10 ต้องตรวจก่อน; `mangrove_areas` ไม่มีค่า) ถ้าไม่ migrate ข้อมูลเดิมจะแสดงมากกว่าจริง 6.25 เท่าในแอป v1.0.12
  → ตรวจข้อมูลจริงก่อน, สำรองข้อมูล, รันครั้งเดียวตอนปล่อยเวอร์ชัน (ผู้ใช้ v1.0.11 จะเห็นค่าเล็กลง 6.25 เท่าจนกว่าจะอัปเดต)

### Frontend
- [`api_client.dart`](eastern_mangrove_app/lib/services/api_client.dart), [`thai_date.dart`](eastern_mangrove_app/lib/utils/thai_date.dart), `home_screen.dart`, `login_screen.dart`, `community_registration_screen.dart`, `community_dashboard.dart`, `economic_data_screen_new.dart`, `public_dashboard.dart`, `pollution_reports_new_screen.dart`, หน้าบริการนิเวศ/รายงานไตรมาส/พื้นที่ป่า, `admin_dashboard.dart`

---

## 🐛 Known Issues
1. ภาพ iPad บน App Store (`docs/imageApp/ipad_13_new/`) ถ่ายก่อนแก้หน่วย/พ.ศ. ควรถ่ายใหม่
2. ไฟล์สำรอง `routes/admin_backup.js` ยังใช้ `res.status(500)` แบบเดิม (ไม่ได้ถูกเรียกใช้)
3. iOS Launch Image ยังเป็น placeholder (ค้างมาจาก v1.0.9)

---

**Build Information:**
- Version: 1.0.12
- Build Number: 12
- Bundle ID: com.kritdev.easternmangrove
- Team ID: 2TA4S4VU44
- Min iOS: 13.0
