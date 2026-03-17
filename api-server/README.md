# Eastern Mangrove Communities API Server

🌿 **API Backend สำหรับระบบจัดการชุมชนป่าชายเลนภาคตะวันออก**

## 📋 **Features**

- ✅ JWT Authentication & Authorization
- ✅ User Registration & Login
- ✅ Community Registration System
- ✅ PostgreSQL Database Integration
- ✅ Input Validation & Error Handling
- ✅ Rate Limiting & Security
- ✅ Role-based Access Control

## 🛠️ **Tech Stack**

- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** PostgreSQL
- **Authentication:** JWT (JSON Web Tokens)
- **Validation:** Joi
- **Security:** Helmet, CORS, Rate Limiting
- **Password Hashing:** bcrypt

## 🔧 **Installation & Setup**

### 1. Install Dependencies
```bash
cd api-server
npm install
```

### 2. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your database credentials
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=eastern_mangrove_communities
# DB_USER=AppAdmin
# DB_PASSWORD=AppAdmin#1!
```

### 3. Database Setup
```sql
-- 1. Create database in pgAdmin
-- 2. Run schema.sql to create tables
-- 3. Run sample_data.sql to insert test data
```

### 4. Start Server
```bash
# Development mode with auto-restart
npm run dev

# Production mode
npm start
```

## 🌐 **API Endpoints**

### **Authentication**

#### POST `/api/auth/register`
**สำหรับลงทะเบียนผู้ใช้ใหม่**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "firstName": "John",
  "lastName": "Doe",
  "userType": "community",
  "phoneNumber": "0812345678"
}
```

#### POST `/api/auth/login`
**สำหรับเข้าสู่ระบบ**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

#### POST `/api/auth/register-community`
**สำหรับลงทะเบียนชุมชน**
```json
{
  "communityName": "ชุมชนป่าชายเลนบางปู",
  "location": "สมุทรปราการ",
  "contactPerson": "นายสมชาย ใจดี",
  "phoneNumber": "0891234567",
  "email": "bangpu@community.th",
  "description": "ชุมชนอนุรักษ์ป่าชายเลน",
  "establishedYear": 1995,
  "memberCount": 150,
  "photoType": "community"
}
```

#### GET `/api/auth/profile`
**ดูข้อมูลโปรไฟล์ (ต้อง login)**
```bash
Authorization: Bearer <jwt_token>
```

#### GET `/api/auth/verify-token`
**ตรวจสอบ token**

#### POST `/api/auth/logout`
**ออกจากระบบ**

### **Utility**

#### GET `/api/health`
**ตรวจสอบสถานะ server และการเชื่อมต่อฐานข้อมูล**

#### GET `/`
**Welcome message และข้อมูล API**

## 🔐 **Authentication**

### **JWT Token**
เมื่อ login สำเร็จ API จะส่ง JWT token กลับมา:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "userType": "community"
    }
  }
}
```

### **ใช้งาน Token**
ส่ง token ใน Authorization header:
```bash
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 👥 **User Roles**

- **admin**: ผู้ดูแลระบบ (เข้าถึงได้ทุกอย่าง)
- **community**: สมาชิกชุมชน (จัดการข้อมูลชุมชน)
- **public**: ผู้ใช้ทั่วไป (ดูข้อมูลสาธารณะ)

## 🛡️ **Security Features**

- **Rate Limiting**: จำกัด 100 requests ต่อ 15 นาที
- **CORS**: กำหนด allowed origins
- **Helmet**: Security headers
- **Password Hashing**: bcrypt with salt rounds 12
- **JWT Expiration**: Token หมดอายุใน 24 ชั่วโมง
- **Input Validation**: Joi validation schemas

## 📋 **Response Format**

### **Success Response**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data here
  }
}
```

### **Error Response**
```json
{
  "success": false,
  "error": "Error type",
  "message": "Error description",
  "details": [
    {
      "field": "email",
      "message": "Please provide a valid email address"
    }
  ]
}
```

## 🚀 **Development**

### **Testing API**
```bash
# ตรวจสอบสถานะ server
curl http://localhost:3000/api/health

# ทดสอบ registration
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User",
    "userType": "community"
  }'
```

### **Environment Variables**
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=eastern_mangrove_communities
DB_USER=AppAdmin
DB_PASSWORD=AppAdmin#1!

# JWT
JWT_SECRET=your_secret_key_here
JWT_EXPIRES_IN=24h

# Server
PORT=3000
NODE_ENV=development

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

## 📝 **Database Schema**

Schema อยู่ในไฟล์ `../database/schema.sql` และ sample data อยู่ในไฟล์ `../database/sample_data.sql`

## ⚡ **Quick Start**

1. สร้าง PostgreSQL database
2. รันไฟล์ schema.sql และ sample_data.sql
3. คัดลอกและแก้ไข .env file
4. `npm install && npm run dev`
5. ทดสอบที่ http://localhost:3000/api/health

## 🐛 **Troubleshooting**

### **Database Connection Error**
```bash
# ตรวจสอบการเชื่อมต่อ PostgreSQL
psql -h localhost -p 5432 -U AppAdmin -d eastern_mangrove_communities

# ตรวจสอบว่า PostgreSQL service ทำงาน
pg_isready -h localhost -p 5432
```

### **Port Already in Use**
```bash
# หา process ที่ใช้ port 3000
lsof -ti:3000

# หยุด process
kill -9 $(lsof -ti:3000)
```

---

**🌿 Eastern Mangrove Communities API v1.0.0**

*Built with ❤️ for mangrove conservation*