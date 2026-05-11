# คู่มือการอัปโหลดแอป - เวอร์ชัน 1.0.9 (Build 9)
**วันที่:** 12 พฤษภาคม 2026

## 📦 ไฟล์ที่พร้อมอัปโหลด

### iOS (App Store)
- **ไฟล์:** `eastern_mangrove_app/build/ios/ipa/eastern_mangrove_app.ipa`
- **ขนาด:** 26.3 MB
- **เวอร์ชัน:** 1.0.9
- **Build Number:** 9
- **Bundle ID:** com.kritdev.easternmangrove
- **รองรับ iOS:** 13.0 ขึ้นไป
- **Team ID:** 2TA4S4VU44

### Android (Google Play)
- **ไฟล์:** `eastern_mangrove_app/build/app/outputs/bundle/release/app-release.aab`
- **ขนาด:** 44.8 MB
- **Version Name:** 1.0.9
- **Version Code:** 9
- **Package Name:** com.kritdev.easternmangrove
- **รองรับ Android:** 5.0 (API 21) ขึ้นไป
- **Target SDK:** 34 (Android 14)

---

## 🍎 วิธีอัปโหลดขึ้น App Store (iOS)

### วิธีที่ 1: ใช้แอป Apple Transporter (แนะนำ)
1. เปิดแอป **Transporter** บน Mac
   - ดาวน์โหลดได้ที่: https://apps.apple.com/us/app/transporter/id1450874784
2. ลากไฟล์ `eastern_mangrove_app/build/ios/ipa/eastern_mangrove_app.ipa` มาวางในแอป
3. กดปุ่ม **Deliver** (ส่ง)
4. รอให้อัปโหลดเสร็จสมบูรณ์
5. ไปที่ App Store Connect เพื่อทำขั้นตอนต่อไป

### วิธีที่ 2: ใช้ Command Line
```bash
xcrun altool --upload-app --type ios \
  -f eastern_mangrove_app/build/ios/ipa/eastern_mangrove_app.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

### การตั้งค่าใน App Store Connect
1. เข้าไปที่ https://appstoreconnect.apple.com
2. เลือกแอป **Eastern Mangrove**
3. กดปุ่ม **+** เพื่อสร้างเวอร์ชันใหม่ → เลือก **1.0.9**
4. เลือก build ที่อัปโหลด (อาจใช้เวลา 5-15 นาทีกว่าจะแสดง)
5. กรอกข้อมูล:
   - **มีอะไรใหม่ในเวอร์ชันนี้:** ดูรายละเอียดด้านล่าง
   - **ข้อมูลสำหรับการตรวจสอบ:**
     - Username: `admin`
     - Password: `admin1234`
   - **หมายเหตุบัญชีทดลอง:** ดูรายละเอียดใน TEST_CREDENTIALS.md
6. กดบันทึกแล้ว **ส่งเพื่อตรวจสอบ**

---

## 🤖 วิธีอัปโหลดขึ้น Google Play (Android)

### อัปโหลดไปยัง Google Play Console
1. เข้าไปที่ https://play.google.com/console
2. เลือกแอป **Eastern Mangrove**
3. ไปที่ **Production** → **สร้างรุ่นใหม่** (Create new release)
4. อัปโหลดไฟล์ AAB:
   ```
   eastern_mangrove_app/build/app/outputs/bundle/release/app-release.aab
   ```
5. กรอกรายละเอียดการอัปเดต:
   - **ชื่อรุ่น:** 1.0.9 (9)
   - **บันทึกการอัปเดต:** ดูด้านล่าง

### บันทึกการอัปเดต (Release Notes)

#### ภาษาไทย
```
เวอร์ชัน 1.0.9

🔧 แก้ไขและปรับปรุง
• เพิ่มความสามารถในการแก้ไขชื่อผู้ใช้งาน (username) ในหน้าโปรไฟล์
• ปรับปรุงระบบการลงทะเบียนชุมชนให้รองรับชื่อผู้ใช้
• แก้ไขข้อผิดพลาดในการตรวจสอบข้อมูลการลงทะเบียน
• ปรับปรุงความเสถียรของระบบ backend
• แก้ไขปัญหา user_id ในระบบข้อมูลนิเวศและข้อมูลมลพิษ
• เปลี่ยนระบบเข้าสู่ระบบจากอีเมลเป็นชื่อผู้ใช้

✨ ฟีเจอร์ใหม่
• สมาชิกชุมชนและผู้ดูแลระบบสามารถแก้ไขชื่อผู้ใช้ได้
• ระบบตรวจสอบชื่อผู้ใช้ซ้ำอัตโนมัติ
• ปรับปรุงการตรวจสอบข้อมูลให้แม่นยำยิ่งขึ้น
```

#### English
```
Version 1.0.9

🔧 Bug Fixes and Improvements
• Added ability to edit username in profile screens
• Improved community registration system with username support
• Fixed validation errors in registration data
• Enhanced backend system stability
• Fixed user_id issues in ecosystem and pollution data systems
• Changed login system from email to username

✨ New Features
• Community members and admins can edit their usernames
• Automatic duplicate username detection
• Improved data validation accuracy
```

### ข้อมูลบัญชีทดสอบสำหรับผู้ตรวจสอบ
6. ในส่วน **เนื้อหาของแอป** → **การเข้าถึงแอป**:
   - เลือก: "ฟีเจอร์ทั้งหมดใช้งานได้โดยไม่ต้องเข้าสู่ระบบ" ❌
   - เลือก: "แอปต้องเข้าสู่ระบบ" ✅
   - ให้บัญชีทดสอบ:
     ```
     บัญชีผู้ดูแลระบบ (Admin):
     ชื่อผู้ใช้: admin
     รหัสผ่าน: admin1234
     
     บัญชีชุมชน:
     ชื่อผู้ใช้: user1
     รหัสผ่าน: user1234
     
     ดูรายการทั้งหมดในส่วนหมายเหตุ
     ```

7. เพิ่มหมายเหตุสำหรับผู้ตรวจสอบ:
   ```
   บัญชีทดสอบ:
   - ผู้ดูแลระบบ: ชื่อผู้ใช้ "admin", รหัสผ่าน "admin1234"
   - หัวหน้าชุมชน 1: ชื่อผู้ใช้ "leader1", รหัสผ่าน "leader1234"
   - หัวหน้าชุมชน 2: ชื่อผู้ใช้ "leader2", รหัสผ่าน "leader2234"
   - หัวหน้าชุมชน 3: ชื่อผู้ใช้ "leader3", รหัสผ่าน "leader3234"
   - ผู้ใช้ทั่วไป: ชื่อผู้ใช้ "user1", รหัสผ่าน "user1234"
   
   วิธีเข้าสู่ระบบ:
   1. เปิดแอปพลิเคชัน
   2. กดปุ่ม "เข้าสู่ระบบ" (Login)
   3. กรอกชื่อผู้ใช้และรหัสผ่าน
   4. กดปุ่ม "เข้าสู่ระบบ" เพื่อเข้าใช้งาน
   
   หัวหน้าชุมชนสามารถเข้าถึงข้อมูลนิเวศ รายงานมลพิษ และข้อมูลเศรษฐกิจ
   ผู้ดูแลระบบมีสิทธิ์ครบทุกอย่าง รวมถึงการอนุมัติการลงทะเบียนและจัดการข้อมูลทั้งหมด
   ```

8. **ตรวจสอบและเผยแพร่** → **เริ่มเผยแพร่ไปยัง Production**

---

## 📋 รายการตรวจสอบก่อนอัปโหลด

### iOS
- [x] Build IPA สำเร็จ (26.3 MB)
- [x] หมายเลขเวอร์ชัน: 1.0.9
- [x] หมายเลข Build: 9
- [x] Code signing: อัตโนมัติ (Development Team)
- [x] ไอคอนแอป: ตั้งค่าแล้ว ⚠️ (ใช้ launch image เริ่มต้น - อัปเดตได้ในเวอร์ชันถัดไป)
- [x] บัญชีทดสอบพร้อมใน TEST_CREDENTIALS.md
- [ ] อัปโหลดไปยัง App Store Connect
- [ ] ส่งเพื่อตรวจสอบ

### Android
- [x] Build AAB สำเร็จ (44.8 MB)
- [x] ชื่อเวอร์ชัน: 1.0.9
- [x] รหัสเวอร์ชัน: 9
- [x] เซ็นชื่อด้วย upload keystore
- [x] เปิดใช้งาน ProGuard/R8
- [x] บัญชีทดสอบพร้อมใน TEST_CREDENTIALS.md
- [ ] อัปโหลดไปยัง Google Play Console
- [ ] ส่งเพื่อตรวจสอบ

---

## 🔑 ข้อมูลบัญชีทดสอบ
บัญชีทดสอบทั้งหมดอยู่ในไฟล์: `TEST_CREDENTIALS.md`

**อ้างอิงด่วน:**
- ผู้ดูแลระบบ: `admin` / `admin1234`
- ผู้ใช้ 1: `user1` / `user1234`
- หัวหน้าชุมชน 1: `leader1` / `leader1234`
- หัวหน้าชุมชน 2: `leader2` / `leader2234`
- หัวหน้าชุมชน 3: `leader3` / `leader3234`

---

## 🚀 มีอะไรใหม่ในเวอร์ชัน 1.0.9

### ฟีเจอร์ใหม่
1. **การแก้ไขชื่อผู้ใช้**
   - ผู้ใช้ชุมชนสามารถแก้ไขชื่อผู้ใช้ในหน้าโปรไฟล์ได้
   - ผู้ดูแลระบบสามารถแก้ไขชื่อผู้ใช้ได้
   - มีระบบตรวจสอบชื่อผู้ใช้ซ้ำ

2. **ปรับปรุงการลงทะเบียนชุมชน**
   - อัปเดตให้ใช้ระบบยืนยันตัวตนด้วยชื่อผู้ใช้
   - ปรับปรุงการตรวจสอบข้อมูลชุมชน
   - แก้ไขปัญหาฟิลด์ firstName/lastName

### การแก้ไขบั๊ก
1. **Backend Routes**
   - แก้ไข route ข้อมูลนิเวศให้ใช้ user_id แทน email
   - แก้ไข route รายงานมลพิษการยืนยันตัวตน
   - แก้ไข route ข้อมูลเศรษฐกิจให้จัดการ user_id ถูกต้อง
   - อัปเดตโปรไฟล์ผู้ดูแลให้รองรับการแก้ไขชื่อผู้ใช้

2. **การตรวจสอบข้อมูล**
   - ลบ firstName/lastName ที่ไม่ได้ใช้ออกจากการลงทะเบียนชุมชน
   - อัปเดต Joi validation schemas ให้ตรงกับ frontend models
   - เพิ่มการตรวจสอบชื่อผู้ใช้ที่ถูกต้อง (3-50 ตัวอักษร, ตัวอักษร ตัวเลข และ underscore)

3. **ฐานข้อมูล**
   - เพิ่มคอลัมน์ username ในตาราง users
   - แก้ไข user_id references ในตาราง communities
   - หมายเหตุ: มีผู้ใช้ 2 คนที่ต้องอัปเดต user_id ด้วยตนเอง (kumnansuc, boontam)

### การเปลี่ยนแปลงทางเทคนิค
- เปลี่ยนระบบเข้าสู่ระบบจากอีเมลเป็นชื่อผู้ใช้
- อัปเดต API routes ทั้งหมดให้ใช้การยืนยันตัวตนด้วยชื่อผู้ใช้
- ปรับปรุงการจัดการข้อผิดพลาดและข้อความตรวจสอบ
- เพิ่ม backend logging สำหรับการดีบั๊ก

---

## 📊 Git Commits สำหรับรุ่นนี้

```
c0bc378 - docs: Add deployment guide for v1.0.8 with upload instructions
2049a8d - Fix: Update community registration to use contactPerson/communityName
2c814d0 - Fix: Remove firstName and lastName from auth_provider
287641a - Fix: Remove unused firstName and lastName fields
dd53c55 - Remove duplicate updateUserProfile function
b740766 - Add username editing to admin profile
5289348 - Add username editing to community profile
f08adf3 - Fix community registration endpoint to include username
```

---

## ⚠️ ปัญหาที่ทราบแล้ว (ไม่มีผลต่อการใช้งาน)

1. **iOS Launch Image**
   - ขณะนี้ใช้ placeholder เริ่มต้น
   - สามารถอัปเดตในเวอร์ชันถัดไป
   - ไม่กีดขวางการทำงานของแอป

2. **Database User IDs**
   - มีผู้ใช้ 2 คน (kumnansuc, boontam) มี user_id เป็น NULL
   - ต้องรัน SQL update หลังจาก deploy:
     ```sql
     UPDATE communities 
     SET user_id = (SELECT id FROM users WHERE username = 'kumnansuc') 
     WHERE id = 8;
     
     UPDATE communities 
     SET user_id = (SELECT id FROM users WHERE username = 'boontam') 
     WHERE id = 11;
     ```

3. **การอัปเดต Package**
   - มี Flutter packages 38 ตัวที่มีเวอร์ชันใหม่กว่า
   - ทั้งหมดไม่เข้ากันกับ dependency constraints ปัจจุบัน
   - สามารถอัปเดตในเวอร์ชันถัดไปได้ตามต้องการ
   - เวอร์ชันปัจจุบันเสถียรและใช้งานได้ดี

---

## 📞 ข้อมูลการสนับสนุน

- **ชื่อแอป:** Eastern Mangrove Communities (ระบบจัดการชุมชนป่าชายเลนภาคตะวันออก)
- **ผู้พัฒนา:** Eastern Mangrove Team
- **อีเมลสนับสนุน:** (เพิ่มอีเมลสนับสนุนของคุณ)
- **นโยบายความเป็นส่วนตัว:** https://your-domain.com/docs/privacy-policy.html
- **การลบบัญชี:** https://your-domain.com/docs/delete-account.html

---

## 🎯 งานหลังการอัปโหลด

หลังจากทั้งสองแพลตฟอร์มอนุมัติ:

1. **ติดตามรายงานความผิดพลาด:**
   - Firebase Crashlytics (ถ้ามีการตั้งค่า)
   - App Store Connect
   - Google Play Console

2. **แก้ไข user_id ที่เป็น NULL ในฐานข้อมูล:**
   - เชื่อมต่อกับ PostgreSQL
   - รัน SQL updates สำหรับ kumnansuc และ boontam

3. **ติดตามความคิดเห็นของผู้ใช้:**
   - ตรวจสอบรีวิวใน app store
   - ติดตามอีเมลสนับสนุน
   - ติดตามอัตราความสำเร็จของการลงทะเบียน

4. **วางแผนเวอร์ชันถัดไป:**
   - อัปเดต launch image สำหรับ iOS
   - พิจารณาอัปเดต dependencies
   - เพิ่มฟีเจอร์ที่ผู้ใช้ขอ

---

## 💡 เคล็ดลับการอัปโหลด

### สำหรับ iOS:
- ตรวจสอบให้แน่ใจว่า certificate และ provisioning profile ยังไม่หมดอายุ
- ใช้ Apple Transporter จะง่ายกว่า command line
- อัปโหลดใน network ที่เร็วและเสถียร
- build อาจใช้เวลา 5-15 นาทีกว่าจะปรากฏใน App Store Connect

### สำหรับ Android:
- ใช้ไฟล์ .aab แทน .apk เพื่อขนาดที่เล็กกว่า
- ตรวจสอบ keystore signing ให้ถูกต้อง
- กรอก release notes ทั้งภาษาไทยและอังกฤษ
- ตั้งค่า staged rollout ได้ถ้าต้องการทดสอบกับผู้ใช้บางส่วนก่อน

---

## 🔄 ขั้นตอนการอัปเดตเวอร์ชันถัดไป

เมื่อต้องการอัปเดตเป็น 1.0.10 หรือเวอร์ชันใหม่:

1. **อัปเดต pubspec.yaml:**
   ```yaml
   version: 1.0.10+10
   ```

2. **Build ใหม่:**
   ```bash
   flutter clean
   flutter pub get
   flutter build ipa --release
   flutter build appbundle --release
   ```

3. **ทำตามขั้นตอนในคู่มือนี้ แต่ใช้เวอร์ชันใหม่**

---

**อัปเดตล่าสุด:** 12 พฤษภาคม 2026  
**จัดทำโดย:** ทีมพัฒนา  
**สถานะ:** ✅ พร้อมอัปโหลด

---

## 📱 ข้อมูลเพิ่มเติม

### ขนาดไฟล์และความต้องการ
- **iOS:** 26.3 MB (ขนาดอาจแตกต่างไปตามอุปกรณ์)
- **Android:** 44.8 MB (Download size จะเล็กกว่าเนื่องจาก Google Play optimization)
- **พื้นที่ว่างที่แนะนำ:** อย่างน้อย 100 MB

### เวลาในการตรวจสอบโดยประมาณ
- **App Store:** 1-3 วัน
- **Google Play:** ไม่กี่ชั่วโมงถึง 1 วัน
- **หมายเหตุ:** เวลาอาจแตกต่างกันไปตามช่วงเวลาและความซับซ้อนของแอป

### ติดต่อหากมีปัญหา
- ถ้า build ล้มเหลว: ตรวจสอบ Flutter version และ dependencies
- ถ้าอัปโหลดล้มเหลว: ตรวจสอบ internet connection และ credentials
- ถ้าถูกปฏิเสธ: อ่านเหตุผลและแก้ไขตามที่แจ้ง แล้วส่งใหม่

**ขอให้โชคดีกับการอัปโหลด! 🎉**
