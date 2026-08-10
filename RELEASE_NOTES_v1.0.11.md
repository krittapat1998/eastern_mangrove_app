# Release Notes - Version 1.0.11
**วันที่เผยแพร่:** 10 สิงหาคม 2026

---

## 📱 สำหรับ App Store Connect และ Google Play Console

### 🇹🇭 ภาษาไทย (Thai)

#### รูปแบบสั้น (สำหรับ App Store - 170 ตัวอักษร)
```
เวอร์ชัน 1.0.11
🐛 แก้ไขปัญหาบัญชีชุมชนบางส่วนเข้าดูรายงานไตรมาส/มลพิษ/บริการนิเวศไม่ได้
✅ ข้อความแจ้งเตือนตอน error แสดงสาเหตุจริงแทนกล่องว่าง
```

#### รูปแบบยาว (สำหรับ Google Play - 500 ตัวอักษร)
```
เวอร์ชัน 1.0.11 - อัปเดตแก้ไขบั๊กสำคัญ

🔧 แก้ไขและปรับปรุง
• แก้ไขปัญหาบัญชีชุมชนบางบัญชีเข้าหน้า "รายงานรายไตรมาส", "รายงานแหล่งมลพิษ"
  และ "จัดการข้อมูลบริการทางนิเวศ" ไม่ได้ (ขึ้น "ไม่พบข้อมูลชุมชน")
• แก้ไขข้อความแจ้งเตือนที่เคยว่างเปล่าเมื่อเกิดข้อผิดพลาด ให้แสดงสาเหตุจริงแทน

หมายเหตุ: เวอร์ชันนี้เป็นการแก้ไขบั๊กสำคัญ แนะนำให้อัปเดตทันที
```

---

### 🇬🇧 English

#### Short Format (App Store - 170 characters)
```
Version 1.0.11
🐛 Fixed some community accounts unable to view quarterly/pollution/ecosystem reports
✅ Error messages now show the real cause instead of a blank box
```

#### Long Format (Google Play - 500 characters)
```
Version 1.0.11 - Important Bug Fix Update

🔧 Fixes & Improvements
• Fixed some community accounts being unable to access "Quarterly Report",
  "Pollution Reports", and "Ecosystem Services" pages ("Community not found")
• Fixed error messages that used to appear blank on failure — now show the
  real reason

Note: This is an important bug-fix release. Update is recommended.
```

---

## 📋 รายละเอียดการเปลี่ยนแปลงทั้งหมด

### 🔧 การแก้ไขบั๊ก (Bug Fixes)

1. **บัญชีชุมชนบางบัญชีเข้า 3 หน้าหลักไม่ได้ (Critical)**
   - Backend หาข้อมูลชุมชนของผู้ใช้โดยอ้างอิงจาก `user_id` เพียงอย่างเดียว ใน endpoint
     ของรายงานมลพิษ, บริการนิเวศ, และรายงานเศรษฐกิจ/ไตรมาส
   - บัญชีที่ `user_id` ยังไม่ถูกผูก (เช่น สมัครก่อนมีระบบผูกบัญชี, หรืออีเมลไม่ตรงกันตอน backfill)
     จะได้รับ error "ไม่พบข้อมูลชุมชน" ทุกครั้งที่เปิด 3 หน้านี้ ทั้งที่ login เข้าระบบได้ปกติ
   - แก้ไขโดยเพิ่มการค้นหาแบบ fallback ด้วยอีเมล (เหมือนที่หน้าโปรไฟล์ใช้อยู่แล้ว) ใน
     6 จุดของ backend (`pollution.js`, `ecosystem.js`, `economic.js`)
   - **แก้ไขนี้ deploy ขึ้น production แล้วตั้งแต่ก่อนออกเวอร์ชันนี้** ผู้ใช้ได้รับผลทันที
     โดยไม่ต้องอัปเดตแอป

2. **ข้อความแจ้งเตือนว่างเปล่าเมื่อเกิดข้อผิดพลาด**
   - `ApiResponse.error()` เก็บข้อความ error ไว้ผิดฟิลด์ ทำให้หน้าจอที่ error แสดงแค่ไอคอน
     กับปุ่ม "ลองใหม่" โดยไม่มีข้อความอธิบายสาเหตุเลย ทำให้วินิจฉัยปัญหาได้ยากทั้งฝั่งผู้ใช้และทีมงาน
   - แก้ไขให้ `message` เก็บข้อความ error จริง ครอบคลุมทุกหน้าจอในแอปที่ใช้ pattern เดียวกัน

---

## 💻 Technical Details

### Backend Changes (deployed separately, live in production already)
- [`pollution.js`](api-server/routes/community/pollution.js), [`ecosystem.js`](api-server/routes/community/ecosystem.js), [`economic.js`](api-server/routes/community/economic.js) — เพิ่ม fallback ค้นหาชุมชนด้วยอีเมลใน GET/PUT/DELETE รวม 6 endpoint

### Frontend Changes
- [`models.dart`](eastern_mangrove_app/lib/models/models.dart) — แก้ `ApiResponse.error()` ให้ `message` มีข้อความ error จริง

---

## 🐛 Known Issues

1. **ข้อมูลชุมชนบางรายการยัง user_id เป็น NULL ใน database**
   - แก้ไขปัญหาการใช้งานแล้วด้วย fallback ทางอีเมล แต่ค่า `user_id` ในฐานข้อมูลของบางชุมชนยังไม่ถูกอัปเดตให้ถูกต้อง
   - ไม่กระทบการใช้งาน แต่ควรทำความสะอาดข้อมูลในโอกาสถัดไป

2. **iOS Launch Image**
   - ยังใช้ placeholder เริ่มต้น (ค้างมาจาก v1.0.9)

---

**Build Information:**
- iOS IPA: 26.4 MB
- Android AAB: 44.8 MB
- Version: 1.0.11
- Build Number: 11
- Bundle ID: com.kritdev.easternmangrove
- Min iOS: 13.0
