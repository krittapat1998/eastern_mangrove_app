# Release Notes - Version 1.0.9
**วันที่เผยแพร่:** 12 พฤษภาคม 2026

---

## 📱 สำหรับ App Store Connect และ Google Play Console

### 🇹🇭 ภาษาไทย (Thai)

#### รูปแบบสั้น (สำหรับ App Store - 170 ตัวอักษร)
```
เวอร์ชัน 1.0.9
✨ เพิ่มการแก้ไขชื่อผู้ใช้ในโปรไฟล์
🔐 เปลี่ยนการเข้าสู่ระบบเป็นชื่อผู้ใช้แทนอีเมล
🐛 แก้ไขข้อผิดพลาดการลงทะเบียนชุมชน
⚡ ปรับปรุงความเสถียรของระบบ
```

#### รูปแบบยาว (สำหรับ Google Play - 500 ตัวอักษร)
```
เวอร์ชัน 1.0.9 - อัปเดตครั้งใหญ่

✨ ฟีเจอร์ใหม่
• สามารถแก้ไขชื่อผู้ใช้ (username) ในหน้าโปรไฟล์ได้แล้ว
• ระบบตรวจสอบชื่อผู้ใช้ซ้ำอัตโนมัติ
• เปลี่ยนการเข้าสู่ระบบเป็นชื่อผู้ใช้แทนอีเมล

🔧 แก้ไขและปรับปรุง
• แก้ไขปัญหาการลงทะเบียนชุมชนไม่สำเร็จ
• ปรับปรุงการตรวจสอบข้อมูลให้แม่นยำยิ่งขึ้น
• แก้ไขปัญหาการเข้าถึงข้อมูลนิเวศและมลพิษ
• เพิ่มความเสถียรของระบบโดยรวม

⚡ การปรับปรุงเพิ่มเติม
• ปรับปรุง backend API ให้ทำงานได้เร็วขึ้น
• เพิ่มการแสดงข้อความแจ้งเตือนที่ชัดเจนขึ้น
• ปรับปรุงประสบการณ์การใช้งาน

หมายเหตุสำคัญ: ผู้ใช้งานเดิมสามารถเข้าสู่ระบบด้วยชื่อผู้ใช้แทนอีเมลได้ทันที
```

---

### 🇬🇧 English

#### Short Format (App Store - 170 characters)
```
Version 1.0.9
✨ Added username editing in profile
🔐 Changed login to username-based authentication
🐛 Fixed community registration errors
⚡ Improved system stability
```

#### Long Format (Google Play - 500 characters)
```
Version 1.0.9 - Major Update

✨ New Features
• Edit username in profile settings
• Automatic duplicate username detection
• Login system changed from email to username

🔧 Bug Fixes & Improvements
• Fixed community registration failures
• Improved data validation accuracy
• Fixed ecosystem and pollution data access issues
• Enhanced overall system stability

⚡ Additional Improvements
• Optimized backend API performance
• Better error messages and notifications
• Enhanced user experience

Important Note: Existing users can now login with username instead of email
```

---

## 📋 รายละเอียดการเปลี่ยนแปลงทั้งหมด

### ✨ ฟีเจอร์ใหม่ (New Features)

1. **การแก้ไขชื่อผู้ใช้ (Username Editing)**
   - ผู้ใช้ชุมชนสามารถแก้ไขชื่อผู้ใช้ในหน้าโปรไฟล์
   - ผู้ดูแลระบบสามารถแก้ไขชื่อผู้ใช้ได้
   - ระบบตรวจสอบชื่อผู้ใช้ซ้ำอัตโนมัติ
   - ชื่อผู้ใช้: 3-50 ตัวอักษร, รองรับตัวอักษร ตัวเลข และ underscore (_)

2. **ระบบเข้าสู่ระบบใหม่ (New Login System)**
   - เปลี่ยนจากการใช้อีเมลเป็นชื่อผู้ใช้
   - รองรับทั้งตัวพิมพ์เล็กและใหญ่ (case-insensitive)
   - ปลอดภัยและใช้งานง่ายขึ้น

### 🔧 การแก้ไขบั๊ก (Bug Fixes)

1. **การลงทะเบียนชุมชน**
   - แก้ไขปัญหา "ไม่ได้" เมื่อพยายามลงทะเบียน
   - แก้ไขข้อผิดพลาดการตรวจสอบข้อมูล
   - ลบฟิลด์ที่ไม่จำเป็นออก (firstName/lastName)

2. **Backend API Routes**
   - แก้ไข route ข้อมูลนิเวศให้ใช้ user_id ถูกต้อง
   - แก้ไข route รายงานมลพิษ
   - แก้ไข route ข้อมูลเศรษฐกิจ
   - แก้ไขการอัปเดตโปรไฟล์ผู้ดูแลระบบ

3. **การตรวจสอบข้อมูล**
   - ปรับปรุง Joi validation schemas
   - แก้ไขข้อความแจ้งเตือนให้ชัดเจนขึ้น
   - ตรวจสอบความถูกต้องของข้อมูลก่อนส่ง

### ⚡ การปรับปรุง (Improvements)

1. **ประสิทธิภาพ (Performance)**
   - ปรับปรุง backend API ให้ทำงานเร็วขึ้น
   - ลด redundant code
   - ปรับปรุงการจัดการ errors

2. **ประสบการณ์ผู้ใช้ (User Experience)**
   - ข้อความแจ้งเตือนชัดเจนขึ้น
   - ปรับปรุงการ validate แบบ real-time
   - Loading indicators ที่ดีขึ้น

3. **ความปลอดภัย (Security)**
   - ปรับปรุงการตรวจสอบ duplicate username
   - เพิ่มการ validate ข้อมูลทั้งฝั่ง frontend และ backend
   - Password hashing ที่ดีขึ้น

### 🗃️ Database Changes

1. **Schema Updates**
   - เพิ่มคอลัมน์ `username` ในตาราง users
   - ปรับปรุง user_id references ในตาราง communities
   - เพิ่ม unique constraint สำหรับ username

2. **Data Migration**
   - อัปเดต user records ให้มี username
   - แก้ไข community-user relationships

---

## 🔄 Breaking Changes

### สำหรับผู้ใช้งาน (For Users)
- **การเข้าสู่ระบบ:** ต้องใช้ชื่อผู้ใช้แทนอีเมล
  - ผู้ใช้เดิม: ใช้ชื่อผู้ใช้ที่ได้รับจากระบบ
  - ผู้ใช้ใหม่: ต้องกำหนดชื่อผู้ใช้ตอนลงทะเบียน

### สำหรับนักพัฒนา (For Developers)
- API endpoints ทั้งหมดเปลี่ยนจาก email-based เป็น username-based
- CommunityRegistrationRequest model ไม่รองรับ firstName/lastName แล้ว
- Authentication headers ต้องส่ง username แทน email

---

## 📝 Migration Guide สำหรับผู้ใช้งานเดิม

### ผู้ใช้ที่มีบัญชีอยู่แล้ว
1. ชื่อผู้ใช้ถูกสร้างอัตโนมัติจากอีเมลของคุณ
2. สามารถเข้าสู่ระบบด้วยชื่อผู้ใช้ใหม่ได้ทันที
3. สามารถแก้ไขชื่อผู้ใช้ในหน้าโปรไฟล์

### ผู้ใช้ใหม่
1. กรอกชื่อผู้ใช้ตอนลงทะเบียน
2. ชื่อผู้ใช้ต้องไม่ซ้ำกับผู้อื่น
3. รูปแบบ: 3-50 ตัวอักษร, a-z, A-Z, 0-9, และ _

---

## 🎯 Next Version Preview (v1.0.10)

กำลังพัฒนาในเวอร์ชันถัดไป:
- 🖼️ อัปเดต launch image สำหรับ iOS
- 📦 อัปเดต dependencies ไปยังเวอร์ชันล่าสุด
- 🌍 เพิ่มการรองรับหลายภาษา
- 📊 Dashboard สำหรับชุมชนดูสถิติ
- 🔔 ระบบแจ้งเตือนแบบ real-time

---

## 🐛 Known Issues

1. **iOS Launch Image**
   - ยังใช้ placeholder เริ่มต้น
   - จะอัปเดตในเวอร์ชัน 1.0.10

2. **Database**
   - ผู้ใช้ 2 คน (kumnansuc, boontam) ต้องอัปเดต user_id
   - ไม่กระทบการใช้งานทั่วไป

---

## 📞 Support & Feedback

หากพบปัญหาหรือมีข้อเสนอแนะ:
- 📧 Email: support@easternmangrove.com
- 🐛 Report bugs: https://github.com/krittapat1998/eastern_mangrove_app/issues
- ⭐ Rate us on App Store / Google Play

---

## 🙏 ขอบคุณ

ขอบคุณทุกท่านที่ใช้งานแอป Eastern Mangrove Communities และให้ข้อเสนอแนะที่เป็นประโยชน์ 
เราจะพัฒนาแอปให้ดีขึ้นอย่างต่อเนื่อง

**Eastern Mangrove Team**  
May 12, 2026

---

## 📊 Version Comparison

| Feature | v1.0.8 | v1.0.9 |
|---------|--------|--------|
| Login Method | Email | Username ✨ |
| Edit Username | ❌ | ✅ ✨ |
| Community Registration | Buggy | Fixed ✅ |
| Username Validation | ❌ | ✅ ✨ |
| Backend Stability | Good | Better ⚡ |
| Error Messages | Basic | Improved ⚡ |
| Data Validation | Basic | Enhanced ⚡ |

---

## 🔐 Security Updates

- Improved password validation
- Enhanced user authentication
- Better duplicate detection
- Secure username validation
- Case-insensitive username lookup

---

## 💻 Technical Details

### Frontend Changes
- Updated `api_client.dart` with username support
- Modified profile screens for username editing
- Updated authentication flow
- Removed unused firstName/lastName fields
- Enhanced validation UI

### Backend Changes
- Updated all auth routes
- Added username column to database
- Modified Joi validation schemas
- Improved error handling
- Added debug logging

### Dependencies
- No breaking dependency changes
- All packages compatible
- 38 packages have newer versions (optional updates)

---

**Build Information:**
- iOS IPA: 26.3 MB
- Android AAB: 44.8 MB
- Version: 1.0.9
- Build Number: 9
- Min iOS: 13.0
- Min Android: 5.0 (API 21)
