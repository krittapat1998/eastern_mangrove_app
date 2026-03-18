const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const { validate, schemas } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Generate JWT token
const generateToken = (user) => {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      userType: user.user_type
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
};

// User Registration
router.post('/register', validate(schemas.userRegistration), async (req, res, next) => {
  try {
    const { email, password, firstName, lastName, userType, phoneNumber } = req.body;

    // Check if user already exists
    const existingUser = await db.query(
      'SELECT email FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Registration failed',
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Insert new user
    const result = await db.query(`
      INSERT INTO users (email, password_hash, first_name, last_name, user_type, phone_number, created_at, is_active)
      VALUES ($1, $2, $3, $4, $5, $6, NOW(), true)
      RETURNING id, email, first_name, last_name, user_type, phone_number, created_at
    `, [email, hashedPassword, firstName, lastName, userType, phoneNumber]);

    const newUser = result.rows[0];

    // Generate token
    const token = generateToken(newUser);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        token,
        user: {
          id: newUser.id,
          email: newUser.email,
          firstName: newUser.first_name,
          lastName: newUser.last_name,
          userType: newUser.user_type,
          phoneNumber: newUser.phone_number,
          createdAt: newUser.created_at
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// User Login
router.post('/login', validate(schemas.userLogin), async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const result = await db.query(
      'SELECT * FROM users WHERE email = $1 AND is_active = true',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Authentication failed',
        message: 'Invalid email or password'
      });
    }

    const user = result.rows[0];

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: 'Authentication failed',
        message: 'Invalid email or password'
      });
    }

    // Update last login
    await db.query(
      'UPDATE users SET last_login = NOW() WHERE id = $1',
      [user.id]
    );

    // Generate token
    const token = generateToken(user);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          firstName: user.first_name,
          lastName: user.last_name,
          userType: user.user_type,
          phoneNumber: user.phone_number,
          createdAt: user.created_at,
          lastLogin: user.last_login
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Community Registration
router.post('/register-community', validate(schemas.communityRegistration), async (req, res, next) => {
  try {
    const {
      communityName,
      location,
      contactPerson,
      phoneNumber,
      email,
      password,
      description,
      establishedYear,
      memberCount,
      photoType
    } = req.body;

    // Check if community already exists
    const existingCommunity = await db.query(
      'SELECT community_name FROM communities WHERE community_name = $1 OR email = $2',
      [communityName, email]
    );

    if (existingCommunity.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'ลงทะเบียนไม่สำเร็จ',
        message: 'มีชุมชนที่ใช้ชื่อหรืออีเมลนี้อยู่แล้ว กรุณาใช้ชื่อหรืออีเมลอื่น'
      });
    }

    // Check if user with this email already exists
    const existingUser = await db.query(
      'SELECT email FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'ลงทะเบียนไม่สำเร็จ',
        message: 'มีผู้ใช้งานที่ใช้อีเมลนี้อยู่แล้ว กรุณาใช้อีเมลอื่น'
      });
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Start transaction
    await db.query('BEGIN');

    try {
      // Insert new user (set is_active = false until admin approves)
      const userResult = await db.query(`
        INSERT INTO users (
          email, password_hash, first_name, last_name, user_type, 
          phone_number, is_active, email_verified, created_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, false, false, NOW())
        RETURNING id, email, first_name, last_name, user_type, phone_number, created_at
      `, [email, hashedPassword, contactPerson, communityName, 'community', phoneNumber]);

      const newUser = userResult.rows[0];

      // Insert new community
      const communityResult = await db.query(`
        INSERT INTO communities (
          community_name, location, contact_person, phone_number, email,
          description, established_year, member_count, photo_type,
          registration_status, created_at, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending', NOW(), NOW())
        RETURNING id, community_name, location, contact_person, phone_number, 
                 email, description, established_year, member_count, photo_type,
                 registration_status, created_at
      `, [
        communityName, location, contactPerson, phoneNumber, email,
        description, establishedYear, memberCount, photoType
      ]);

      const newCommunity = communityResult.rows[0];

      // Commit transaction
      await db.query('COMMIT');

      res.status(201).json({
        success: true,
        message: 'ส่งคำขอลงทะเบียนเรียบร้อย! คำขอของคุณจะได้รับการพิจารณาจากเจ้าหน้าที่',
        data: {
          community: {
            id: newCommunity.id,
            communityName: newCommunity.community_name,
            location: newCommunity.location,
            contactPerson: newCommunity.contact_person,
            phoneNumber: newCommunity.phone_number,
            email: newCommunity.email,
            description: newCommunity.description,
            establishedYear: newCommunity.established_year,
            memberCount: newCommunity.member_count,
            photoType: newCommunity.photo_type,
            registrationStatus: newCommunity.registration_status,
            createdAt: newCommunity.created_at
          }
        }
      });

    } catch (error) {
      // Rollback transaction on error
      await db.query('ROLLBACK');
      throw error;
    }

  } catch (error) {
    next(error);
  }
});

// Get current user profile
router.get('/profile', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;

    const result = await db.query(`
      SELECT id, email, first_name, last_name, user_type, phone_number, 
             created_at, last_login, updated_at
      FROM users 
      WHERE id = $1 AND is_active = true
    `, [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
        message: 'User profile not found'
      });
    }

    const user = result.rows[0];

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.first_name,
          lastName: user.last_name,
          userType: user.user_type,
          phoneNumber: user.phone_number,
          createdAt: user.created_at,
          lastLogin: user.last_login,
          updatedAt: user.updated_at
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Update user profile
router.put('/profile', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { firstName, lastName, phoneNumber, email } = req.body;

    if (!firstName && !lastName && !phoneNumber && !email) {
      return res.status(400).json({ success: false, message: 'ไม่มีข้อมูลที่ต้องการอัปเดต' });
    }

    // Build dynamic update
    const fields = [];
    const values = [];
    let idx = 1;

    if (firstName !== undefined) { fields.push(`first_name = $${idx++}`); values.push(firstName); }
    if (lastName !== undefined)  { fields.push(`last_name = $${idx++}`);  values.push(lastName); }
    if (phoneNumber !== undefined){ fields.push(`phone_number = $${idx++}`);values.push(phoneNumber); }
    if (email !== undefined) {
      // Check email not taken by someone else
      const emailCheck = await db.query('SELECT id FROM users WHERE email = $1 AND id != $2', [email, userId]);
      if (emailCheck.rows.length > 0) {
        return res.status(400).json({ success: false, message: 'อีเมลนี้ถูกใช้งานแล้ว' });
      }
      fields.push(`email = $${idx++}`);
      values.push(email);
    }

    fields.push(`updated_at = NOW()`);
    values.push(userId);

    const result = await db.query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${idx} RETURNING id, email, first_name, last_name, phone_number, user_type`,
      values
    );

    const u = result.rows[0];
    res.json({
      success: true,
      message: 'อัปเดตโปรไฟล์สำเร็จ',
      data: {
        user: {
          id: u.id,
          email: u.email,
          firstName: u.first_name,
          lastName: u.last_name,
          phoneNumber: u.phone_number,
          userType: u.user_type
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

// Change password
router.post('/change-password', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'กรุณากรอกรหัสผ่านปัจจุบันและรหัสผ่านใหม่' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร' });
    }

    const result = await db.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'ไม่พบผู้ใช้งาน' });
    }

    const isMatch = await bcrypt.compare(currentPassword, result.rows[0].password_hash);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'รหัสผ่านปัจจุบันไม่ถูกต้อง' });
    }

    const newHash = await bcrypt.hash(newPassword, 12);
    await db.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [newHash, userId]);

    res.json({ success: true, message: 'เปลี่ยนรหัสผ่านสำเร็จ' });
  } catch (error) {
    next(error);
  }
});

// Verify token endpoint
router.get('/verify-token', authenticateToken, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Token is valid',
    data: {
      user: {
        id: req.user.id,
        email: req.user.email,
        userType: req.user.userType
      }
    }
  });
});

// Logout (client-side token removal)
router.post('/logout', authenticateToken, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Logged out successfully. Please remove token from client storage.'
  });
});

module.exports = router;