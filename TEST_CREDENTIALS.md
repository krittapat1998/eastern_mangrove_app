# Test Credentials - Eastern Mangrove Communities App

**Last Updated:** March 10, 2026

---

## 📋 System Overview

ระบบมีผู้ใช้งาน **2 ประเภทที่ต้องเข้าสู่ระบบ:**
- **Admin** - ผู้ดูแลระบบ
- **Community** - ผู้นำชุมชน/สมาชิกชุมชน

> **หมายเหตุ:** ไม่มี Public users ในระบบการเข้าสู่ระบบ  
> ผู้ใช้ทั่วไปสามารถดูข้อมูลสาธารณะได้โดยไม่ต้อง login

---

## 👤 Active User Accounts

### 1️⃣ Administrator
```
Email:    admin@easternmangrove.th
Password: Admin1234!
Type:     admin
Name:     System Administrator
```
**สิทธิ์:** เข้าถึงและจัดการทุกฟังก์ชันในระบบ

---

### 2️⃣ Community Account (แนะนำสำหรับทดสอบ) ⭐
```
Email:    user1@gmail.com
Password: User1234!
Type:     community
Name:     อนันต์ ธรรมชาติ
Community: ชุมชนทดสอบ
Status:   ✅ Approved
```
**สิทธิ์:** สร้าง/แก้ไข/ลบรายงานมลพิษ, ดูข้อมูลชุมชน  
**พร้อมใช้งานทันที:** มี Community ที่ approved แล้ว

---

### 3️⃣ Community Leaders

#### ชุมชนบางปู
```
Email:    leader1@bangpu.th
Password: User1234!
Type:     community
Name:     สมชาย ใจดี
Community: ชุมชนอนุรักษ์ป่าชายเลนบางปู
Status:   ✅ Approved
```

#### ชุมชนแหลมผักเผา
```
Email:    leader2@laemfapha.th
Password: User1234!
Type:     community
Name:     สมหญิง รักษ์ป่า
Community: (ยังไม่มี community record)
Status:   ⚠️ Need setup
```

#### ชุมชนแกลง
```
Email:    leader3@klaeng.th
Password: User1234!
Type:     community
Name:     วิชัย อนุรักษ์
Community: (ยังไม่มี community record)
Status:   ⚠️ Need setup
```

---

## 🎯 Recommended Testing Account

**ใช้บัญชีนี้สำหรับการทดสอบ:**

```
Email:    user1@gmail.com
Password: User1234!
```

**เหตุผล:**
- ✅ มี Community ที่ approved แล้ว
- ✅ สร้างรายงานมลพิษได้ทันที
- ✅ ไม่ต้อง setup อะไรเพิ่ม
- ✅ เหมาะสำหรับทดสอบฟีเจอร์ทั้งหมด

---

## 🔧 API Testing

### 1. Login (รับ JWT Token)
```bash
curl -X POST http://localhost:3002/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user1@gmail.com",
    "password": "User1234!"
  }'
```

**Response ที่คาดหวัง:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGci...",
    "user": {
      "id": 5,
      "email": "user1@gmail.com",
      "firstName": "อนันต์",
      "lastName": "ธรรมชาติ",
      "userType": "community"
    }
  }
}
```

---

### 2. สร้างรายงานมลพิษ (ต้องมี Token)
```bash
# แทนที่ YOUR_TOKEN ด้วย token ที่ได้จากการ login
curl -X POST http://localhost:3002/api/pollution/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "reportType": "water",
    "severityLevel": "high",
    "status": "pending",
    "description": "ทดสอบระบบรายงานมลพิษ",
    "pollutionSource": "แหล่งทดสอบ",
    "latitude": 13.5,
    "longitude": 100.5,
    "photos": []
  }'
```

**Response ที่คาดหวัง:**
```json
{
  "success": true,
  "message": "บันทึกรายงานมลพิษสำเร็จ",
  "data": {
    "id": 1,
    "report_type": "Water Pollution",
    "severity_level": "high",
    "status": "pending",
    ...
  }
}
```

---

### 3. ดูรายงานทั้งหมด (ต้องมี Token)
```bash
curl http://localhost:3002/api/pollution/reports \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🗄️ Database Information

### Connection Details
```
Host:     localhost
Port:     5432
Database: eastern_mangrove_communities
User:     appadmin
Password: AppAdmin1234
```

### ตรวจสอบ Active Users
```bash
PGPASSWORD="Jobiza3499.Krit" psql -U postgres \
  -d eastern_mangrove_communities \
  -c "SELECT email, user_type, is_active FROM users WHERE is_active = true;"
```

### ตรวจสอบ Communities
```bash
PGPASSWORD="Jobiza3499.Krit" psql -U postgres \
  -d eastern_mangrove_communities \
  -c "SELECT email, community_name, registration_status FROM communities;"
```

---

## 📱 Mobile App Usage

### เข้าสู่ระบบ
1. เปิดแอพ Eastern Mangrove
2. กรอก Email: **user1@gmail.com**
3. กรอก Password: **User1234!**
4. กดปุ่ม "เข้าสู่ระบบ"

### สร้างรายงานมลพิษ
1. ไปที่หน้า **"รายงานมลพิษ"**
2. กดปุ่ม **"+ รายงานมลพิษใหม่"**
3. กรอกข้อมูล:
   - เลือกประเภทมลพิษ
   - เลือกความรุนแรง
   - กรอกคำอธิบาย
   - กรอกแหล่งที่มาของมลพิษ
   - เลือกตำแหน่ง:
     - **กดการ์ด "ตำแหน่งมลพิษ"** เพื่อเลือกจากแผนที่
     - **หรือกดปุ่ม "ใช้ตำแหน่งปัจจุบัน"** เพื่อใช้ GPS
4. กดปุ่ม **"บันทึก"**

### แก้ไขรายงานมลพิษ
1. กดที่รายงานที่ต้องการแก้ไข
2. กดปุ่ม **"แก้ไข"**
3. แก้ไขข้อมูล
4. กดปุ่ม **"บันทึก"**

### ฟีเจอร์ที่มี
- ✅ ดูรายการรายงานพร้อมฟิลเตอร์
- ✅ ดูแผนที่มลพิษแบบสี (ตามความรุนแรง)
- ✅ ดูสถิติและกราฟวิเคราะห์
- ✅ สร้างรายงานมลพิษใหม่
- ✅ แก้ไขรายงานที่มีอยู่
- ✅ ลบรายงาน
- ✅ ใช้ GPS ดึงตำแหน่งปัจจุบัน
- ✅ เลือกตำแหน่งจากแผนที่

---

## ❗ Troubleshooting

### ปัญหา: "Invalid email or password"
**แก้ไข:**
1. ตรวจสอบว่าใช้ email และ password ถูกต้อง
2. ตรวจสอบ backend server: `curl http://localhost:3002/api/health`
3. ลองใช้บัญชีแนะนำ: `user1@gmail.com` / `User1234!`

---

### ปัญหา: "User has no associated community"
**แก้ไข:**
- เฉพาะ `user1@gmail.com` และ `leader1@bangpu.th` ที่มี approved communities
- บัญชีอื่นต้องสร้าง community record ในฐานข้อมูล
- ใช้บัญชีที่แนะนำสำหรับทดสอบ

---

### ปัญหา: Backend ไม่ตอบสนอง
**แก้ไข:**
```bash
# ตรวจสอบว่า server ทำงานหรือไม่
curl http://localhost:3002/api/health

# ถ้าไม่ทำงาน ให้เริ่มใหม่:
cd api-server && node server.js
```

---

### ปัญหา: ใช้ GPS ไม่ได้
**แก้ไข:**
1. **บนมือถือจริง:**
   - เปิด GPS/Location Services
   - อนุญาตสิทธิ์ให้แอพ
   - ตรวจสอบว่าอยู่ในพื้นที่ที่รับสัญญาณได้

2. **บน Simulator/Emulator:**
   - iOS: Debug → Location → Custom Location
   - Android Studio: Extended Controls → Location

3. **บน Chrome:**
   - Browser จะขอ permission อัตโนมัติ
   - อนุญาตเมื่อขึ้นป๊อปอัพ

---

## 🔐 Password Policy

รูปแบบรหัสผ่าน:
- **Admin:** `Admin1234!`
- **Community users:** `User1234!`

ข้อกำหนดรหัสผ่าน:
- ความยาวขั้นต่ำ 8 ตัวอักษร
- ตัวพิมพ์ใหญ่อย่างน้อย 1 ตัว
- ตัวพิมพ์เล็กอย่างน้อย 1 ตัว
- ตัวเลขอย่างน้อย 1 ตัว
- อักขระพิเศษอย่างน้อย 1 ตัว

---

## 📝 Notes

- รหัสผ่านทั้งหมดถูก reset เมื่อ March 10, 2026
- Public users (user2, user3, research1, research2) ถูก disable แล้ว
- ระบบไม่ใช้ user type "public" สำหรับการ login
- มีเฉพาะ Admin และ Community users ที่สามารถ login ได้
- การเข้าถึงแบบ public ไม่ต้อง login (view-only)
- ใช้ `user1@gmail.com` สำหรับการทดสอบส่วนใหญ่

---

## 🎓 Quick Start Guide

**เริ่มต้นใช้งานใน 3 ขั้นตอน:**

1. **เริ่ม Backend Server**
   ```bash
   cd api-server && node server.js
   ```

2. **เริ่ม Flutter App**
   ```bash
   cd eastern_mangrove_app && flutter run
   ```

3. **Login และทดสอบ**
   - Email: `user1@gmail.com`
   - Password: `User1234!`
   - ไปที่หน้า "รายงานมลพิษ"
   - ลองสร้างรายงานใหม่

**เสร็จแล้ว!** 🎉
