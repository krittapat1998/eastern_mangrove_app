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
📍 ขอใช้ตำแหน่งเฉพาะตอนเปิดแผนที่ ไม่ขอทันทีที่เปิดแอป
```

#### รูปแบบยาว (สำหรับ Google Play)
```
เวอร์ชัน 1.0.12

✨ ปรับปรุง
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
📍 Location is requested only when you open the map, not at launch
```

#### Long Format (Google Play)
```
Version 1.0.12

✨ Improvements
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
1. **หน่วยพื้นที่ถูกต้อง (ไร่ ↔ เฮกตาร์)** — ฐานข้อมูลเก็บเป็นเฮกตาร์ แอปแสดง/รับเป็นไร่ (1 เฮกตาร์ = 6.25 ไร่) แปลงที่ชั้น `ApiClient` (`AreaUnit`) ที่เดียว
2. **ปี พ.ศ. ทุกหน้า** — เพิ่ม [`thai_date.dart`](eastern_mangrove_app/lib/utils/thai_date.dart) ฐานข้อมูลยังเก็บ ค.ศ. ช่องกรอกปีเป็น พ.ศ. (ถ้าพิมพ์ 2026 ก็ยังบันทึกถูก)
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

### Backend (ต้อง deploy ขึ้น Render ด้วย — แอปทำงานได้โดยไม่ต้องรอ แต่ผู้ใช้จะไม่ได้ข้อความ error ใหม่/ที่อยู่ที่เก็บแยก)
- [`database.js`](api-server/config/database.js) — แปลง error ข้อมูลผิดของ Postgres เป็น 400/409 พร้อมข้อความไทย (เดิมตอบ 500 + ข้อความ SQL ดิบ)
- [`auth.js`](api-server/routes/auth.js), [`validation.js`](api-server/middleware/validation.js) — `register-community` เก็บ village/sub_district/district/province; ไม่ log รหัสผ่านอีกต่อไป
- routes ใน `admin/` และ `community/` — catch block ใช้ `error.status` แทน 500 ตายตัว

### Database
- **โครงสร้างตาราง/คอลัมน์ไม่เปลี่ยน** ไม่มี schema migration
- ⚠️ **ต้องพิจารณา data migration ของหน่วยพื้นที่:** [`migration_convert_area_rai_to_hectares.sql`](database/migration_convert_area_rai_to_hectares.sql)
  เวอร์ชัน ≤ 1.0.11 เก็บค่า "ไร่" ลงคอลัมน์ที่เป็นเฮกตาร์ ถ้าไม่ migrate ข้อมูลเดิมจะแสดงมากกว่าจริง 6.25 เท่าในแอป v1.0.12
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
