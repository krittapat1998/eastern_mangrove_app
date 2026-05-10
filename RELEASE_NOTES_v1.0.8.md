# Release Notes - Eastern Mangrove Communities App v1.0.8

**Build:** 8  
**Release Date:** May 10, 2026  
**Platform:** iOS & Android

---

## 📋 What's New in Version 1.0.8

### ✨ New Features

1. **เข้าสู่ระบบด้วย Username**
   - เปลี่ยนจากการใช้อีเมลเป็นใช้ username ในการเข้าสู่ระบบ
   - ง่ายและสะดวกยิ่งขึ้นสำหรับผู้ใช้งาน

2. **ฟีเจอร์เปลี่ยนรหัสผ่าน**
   - เพิ่มความสามารถในการเปลี่ยนรหัสผ่านในหน้าโปรไฟล์
   - รักษาความปลอดภัยของบัญชีผู้ใช้

3. **การแสดงข้อมูลผู้ใช้ที่ดีขึ้น**
   - แสดง username ในหน้าโปรไฟล์
   - แก้ไขอีเมลติดต่อได้ในส่วน "ข้อมูลติดต่อ"

### 🔧 Improvements

1. **ปรับปรุง UI/UX**
   - รวมปุ่มบันทึกเหลือปุ่มเดียว "บันทึกการเปลี่ยนแปลง"
   - แสดงผลแบบเดียวกันระหว่างโหมดดูและโหมดแก้ไข
   - ปรับปรุงการแสดงผลฟิลด์ต่างๆ ให้สม่ำเสมอ

2. **การจัดระเบียบข้อมูล**
   - แยกส่วนข้อมูลบัญชีและข้อมูลติดต่อให้ชัดเจน
   - ลบข้อมูลซ้ำซ้อนออก

### 🐛 Bug Fixes

1. **แก้ไขปัญหาการโหลดโปรไฟล์**
   - แก้ไขปัญหาโปรไฟล์โหลดไม่ได้หลังจากแก้ไขอีเมลติดต่อ
   - ใช้ระบบ user_id แทนการจับคู่อีเมลเพื่อความเสถียร
   - ปรับปรุงความเร็วในการโหลดข้อมูล

2. **แก้ไข Build Errors**
   - แก้ไขปัญหา compilation errors
   - ปรับปรุงการจัดการ controllers ในหน้าโปรไฟล์

### 🔐 Security & Performance

1. **ความปลอดภัย**
   - ปรับปรุงการเข้ารหัสรหัสผ่าน (bcrypt)
   - เพิ่มการตรวจสอบความถูกต้องของรหัสผ่าน (ขั้นต่ำ 6 ตัวอักษร)

2. **ประสิทธิภาพ**
   - เพิ่ม database index สำหรับ user_id
   - ปรับปรุงการค้นหาข้อมูลชุมชนให้เร็วขึ้น

---

## 🎯 Release Notes for App Store (Thai)

**มีอะไรใหม่ในเวอร์ชัน 1.0.8**

• เปลี่ยนมาใช้ username ในการเข้าสู่ระบบแทนอีเมล ใช้งานง่ายขึ้น
• เพิ่มฟีเจอร์เปลี่ยนรหัสผ่านในหน้าโปรไฟล์
• ปรับปรุงหน้าโปรไฟล์ให้แสดงผลสวยงามและใช้งานง่ายยิ่งขึ้น
• แก้ไขปัญหาการโหลดโปรไฟล์หลังจากแก้ไขข้อมูลติดต่อ
• เพิ่มความปลอดภัยและประสิทธิภาพของแอพ
• แก้ไขจุดบกพร่องและปรับปรุงเสถียรภาพ

---

## 🎯 Release Notes for App Store (English)

**What's New in Version 1.0.8**

• Login with username instead of email for easier access
• Added password change feature in profile settings
• Improved profile interface with better layout and usability
• Fixed profile loading issue after updating contact information
• Enhanced security with improved password encryption
• Performance improvements and bug fixes

---

## 📝 Technical Changes

### Backend
- Updated authentication to support username login
- Modified profile endpoints to use user_id instead of email matching
- Added password change API endpoint
- Database migration to add and populate user_id column
- Improved error handling and validation

### Frontend
- Updated login screen to use username field
- Added password change fields in profile
- Improved form validation
- Better error messages and user feedback
- UI consistency improvements

### Database
- Added user_id foreign key to communities table
- Created index for better query performance
- Migrated data to use stable user_id relationships

---

## 🔄 Migration Notes

This version includes important database changes:
- Existing users can continue using the app normally
- Login credentials remain the same (use username instead of email)
- All existing data is preserved and migrated automatically

---

## 📞 Support

หากพบปัญหาการใช้งาน กรุณาติดต่อ:
- Email: support@easternmangrove.com
- หรือแจ้งปัญหาผ่านหน้า "ตั้งค่า" ในแอพ

---

## 🙏 Acknowledgments

ขอบคุณผู้ใช้งานทุกท่านที่ให้ข้อเสนอแนะและรายงานปัญหา
เราจะพัฒนาแอพให้ดียิ่งขึ้นต่อไป
