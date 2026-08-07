# Release Notes - Version 1.0.10
**วันที่เผยแพร่:** 7 สิงหาคม 2026

---

## 📱 สำหรับ App Store Connect และ Google Play Console

### 🇹🇭 ภาษาไทย (Thai)

#### รูปแบบสั้น (สำหรับ App Store - 170 ตัวอักษร)
```
เวอร์ชัน 1.0.10
🐛 แก้ไขปัญหาบันทึก "ปีที่ก่อตั้ง" ในโปรไฟล์ชุมชนไม่สำเร็จ
✅ ปรับปรุงข้อความแจ้งเตือนให้ชัดเจนขึ้น
```

#### รูปแบบยาว (สำหรับ Google Play - 500 ตัวอักษร)
```
เวอร์ชัน 1.0.10 - อัปเดตแก้ไขบั๊ก

🔧 แก้ไขและปรับปรุง
• แก้ไขปัญหาบันทึกข้อมูล "ปีที่ก่อตั้ง (พ.ศ.)" ในหน้าโปรไฟล์ชุมชนไม่สำเร็จ
  (ระบบเทียบปีผิดปฏิทิน ทำให้บันทึกไม่ผ่านทุกครั้ง)
• เพิ่มข้อความแจ้งเตือนภาษาไทยที่ชัดเจนขึ้น เมื่อกรอกปีไม่ถูกต้อง

หมายเหตุ: เวอร์ชันนี้เป็นการแก้ไขบั๊กเฉพาะจุด ไม่มีการเปลี่ยนแปลงฟีเจอร์หลัก
```

---

### 🇬🇧 English

#### Short Format (App Store - 170 characters)
```
Version 1.0.10
🐛 Fixed community profile "founding year" failing to save
✅ Clearer validation messages
```

#### Long Format (Google Play - 500 characters)
```
Version 1.0.10 - Bug Fix Update

🔧 Fixes & Improvements
• Fixed the community profile "founding year" field always failing to save
  (a calendar mismatch caused the value to always be rejected)
• Added clearer Thai-language validation messages for invalid year input

Note: This is a targeted bug-fix release with no changes to core features.
```

---

## 📋 รายละเอียดการเปลี่ยนแปลงทั้งหมด

### 🔧 การแก้ไขบั๊ก (Bug Fixes)

1. **ปีที่ก่อตั้งชุมชน (Established Year) บันทึกไม่ได้**
   - ช่อง "ปีที่ก่อตั้ง" ในหน้าโปรไฟล์ชุมชนให้ผู้ใช้กรอกเป็นปี **พ.ศ.** (พุทธศักราช)
     แต่ระบบหลังบ้านเก็บและตรวจสอบค่าเป็นปี **ค.ศ.** (คริสต์ศักราช) โดยไม่มีการแปลงค่า
   - ผลคือทุกครั้งที่กรอกปี พ.ศ. จริง (เช่น 2560-2569) ค่าจะเกินปีปัจจุบันตาม ค.ศ. เสมอ
     ทำให้ฐานข้อมูลปฏิเสธการบันทึกด้วย error `violates check constraint`
   - แก้ไขโดยเพิ่มการแปลงค่า พ.ศ. ↔ ค.ศ. (ผลต่าง 543 ปี) ทั้งตอนโหลดและตอนบันทึกข้อมูล

2. **ข้อความแจ้งเตือนเมื่อกรอกปีไม่ถูกต้อง**
   - เพิ่มการตรวจสอบฝั่งแอปก่อนส่งข้อมูล พร้อมข้อความแจ้งเตือนภาษาไทยที่เข้าใจง่าย
   - ผู้ใช้จะเห็น error ทันทีในฟอร์ม แทนที่จะเจอ error ดิบจากฐานข้อมูล

---

## 💻 Technical Details

### Frontend Changes
- [`community_profile_screen.dart`](eastern_mangrove_app/lib/screens/community/community_profile_screen.dart) — เพิ่มฟังก์ชันแปลงปี พ.ศ. ↔ ค.ศ. (`_adYearToBeText`, `_beTextToAdYear`) และ validator สำหรับช่องปีที่ก่อตั้ง

### Backend / Database
- ไม่มีการเปลี่ยนแปลง — แก้ไขที่ฝั่งแอปเท่านั้น เพื่อให้ค่าที่ส่งไปตรงกับสิ่งที่ constraint ในฐานข้อมูลคาดหวังอยู่แล้ว

---

## 🐛 Known Issues

1. **iOS Launch Image**
   - ยังใช้ placeholder เริ่มต้น (ค้างมาจาก v1.0.9)

---

**Build Information:**
- iOS IPA: 24.5 MB
- Version: 1.0.10
- Build Number: 10
- Bundle ID: com.kritdev.easternmangrove
- Min iOS: 13.0
