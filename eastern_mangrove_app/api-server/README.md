# Eastern Mangrove Communities API Server

API Server สำหรับแอปพลิเคชัน Eastern Mangrove Communities - ระบบจัดการข้อมูลชุมชนป่าชายเลนภาคตะวันออก

## 🛠️ การติดตั้งและเซ็ตอัพ

### ข้อกำหนดระบบ
- Node.js 16+ 
- PostgreSQL 12+
- pgAdmin 4 (สำหรับจัดการ database)

### 1. Clone และติดตั้ง Dependencies

```bash
# เข้าสู่โฟลเดอร์ API server
cd api-server

# ติดตั้ง dependencies
npm install
```

### 2. ตั้งค่า PostgreSQL Database

#### เปิด pgAdmin และสร้างฐานข้อมูล:

1. เปิด pgAdmin
2. เชื่อมต่อเซิร์ฟเวอร์ PostgreSQL
3. สร้างฐานข้อมูลใหม่ชื่อ `eastern_mangrove_communities`
4. เปิด Query Tool และรันไฟล์ SQL:

```sql
-- รันไฟล์ database/schema.sql เพื่อสร้างโครงสร้างตาราง
-- รันไฟล์ database/sample_data.sql เพื่อใส่ข้อมูลตัวอย่าง (optional)
```

### 3. ตั้งค่า Environment Variables

```bash
# สำเนาไฟล์ .env.example เป็น .env
cp .env.example .env

# แก้ไขไฟล์ .env ด้วยข้อมูลการเชื่อมต่อ database
```

**ตัวอย่างการตั้งค่าไฟล์ .env:**
```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=eastern_mangrove_communities
DB_USER=postgres
DB_PASSWORD=your_password_here
JWT_SECRET=your-super-secret-jwt-key-change-in-production
```

### 4. รัน API Server

```bash
# Development mode (auto-restart)
npm run dev

# Production mode
npm start
```

เซิร์ฟเวอร์จะรันที่ `http://localhost:3000`

## 📚 API Documentation

### Authentication Endpoints

#### POST `/api/auth/register`
ลงทะเบียนผู้ใช้ใหม่

**Request Body:**
```json
{
  "username": "testuser",
  "email": "test@example.com", 
  "password": "Test123456",
  "user_type": "community"
}
```

#### POST `/api/auth/register/community`
ลงทะเบียนชุมชนใหม่ (พร้อมผู้ใช้)

**Request Body:**
```json
{
  "username": "community_test",
  "email": "community@example.com",
  "password": "Test123456",
  "community_name": "ชุมชนทดสอบ",
  "province": "ระยอง", 
  "contact_person": "นายทดสอบ",
  "phone": "081-234-5678"
}
```

#### POST `/api/auth/login`
เข้าสู่ระบบ

**Request Body:**
```json
{
  "username": "testuser",
  "password": "Test123456"
}
```

### Protected Endpoints

ต้องใส่ Authorization Header: `Bearer <token>`

#### GET `/api/community/dashboard`
ข้อมูล dashboard ของชุมชน

#### GET `/api/admin/dashboard`
ข้อมูล dashboard ของ admin

## 🧪 การทดสอบ API

### ใช้ curl หรือ Postman

```bash
# ทดสอบ Health Check
curl http://localhost:3000/health

# ทดสอบ Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# ทดสอบ Protected Route
curl -X GET http://localhost:3000/api/community/dashboard \
  -H "Authorization: Bearer YOUR_JWT_TOKEN_HERE"
```

### ข้อมูล User ตัวอย่างในระบบ

| Username | Password | User Type | Status |
|----------|----------|-----------|---------|
| admin | admin123 | admin | Approved |
| community_rayong | community123 | community | Approved |
| community_trat | community123 | community | Approved |

## 📁 โครงสร้างโปรเจค

```
api-server/
├── config/
│   └── database.js          # การเชื่อมต่อ PostgreSQL
├── middleware/
│   ├── auth.js               # JWT authentication
│   ├── errorHandler.js       # Error handling
│   └── validation.js         # Input validation
├── routes/
│   ├── auth.js               # Authentication routes
│   ├── admin.js              # Admin routes
│   ├── community.js          # Community routes
│   ├── public.js             # Public routes
│   └── upload.js             # File upload routes
├── uploads/                  # สำหรับเก็บไฟล์ที่อัปโหลด
├── .env.example              # ตัวอย่างการตั้งค่า environment
├── package.json              # Dependencies
└── server.js                 # Main server file
```

## 🔒 Security Features

- JWT Authentication
- Password hashing with bcrypt
- Rate limiting
- Input validation
- CORS protection
- Helmet security headers
- SQL injection protection

## 🔄 ขั้นตอนต่อไป

1. **เชื่อมต่อ Flutter App** - สร้าง HTTP client ใน Flutter
2. **เพิ่ม Routes** - สร้าง admin, community, public routes
3. **File Upload** - เพื่อรองรับการอัปโหลดเอกสารและรูปภาพ
4. **Real-time Features** - WebSocket สำหรับ notifications
5. **Testing** - Unit tests และ Integration tests

## 🐛 Troubleshooting

### ปัญหาที่พบบ่อย:

1. **Connection refused**
   - ตรวจสอบว่า PostgreSQL รันอยู่
   - ตรวจสอบ DB credentials ในไฟล์ .env

2. **JWT errors** 
   - ตรวจสอบ JWT_SECRET ในไฟล์ .env
   - ตรวจสอบ token expiration

3. **Port already in use**
   ```bash
   lsof -ti:3000 | xargs kill -9
   ```

## 🤝 การพัฒนาต่อ

สำหรับการพัฒนาต่อ ให้ดูที่:
- `/routes` - เพิ่ม API endpoints
- `/middleware` - เพิ่ม security/validation
- Database schema - ปรับปรุงโครงสร้างตาราง

---

**หมายเหตุ:** นี่เป็นเวอร์ชัน development กรุณาเปลี่ยน JWT_SECRET และ database credentials ก่อน deploy production!