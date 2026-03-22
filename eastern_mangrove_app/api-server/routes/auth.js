const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { query, queryOne, transaction } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

const router = express.Router();
const SCHEMA = 'eastern_mangrove_communities';

// Helper: generate JWT token
function generateToken(user) {
  return jwt.sign(
    { userId: user.id, email: user.email, userType: user.user_type },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

// Helper: format user for Flutter
function formatUser(user) {
  return {
    id: user.id,
    email: user.email,
    firstName: user.first_name,
    lastName: user.last_name,
    userType: user.user_type,
    phoneNumber: user.phone_number || null,
    isActive: user.is_active,
    isApproved: user.is_approved,
  };
}

// POST /api/auth/register
router.post('/register', asyncHandler(async (req, res) => {
  const { email, password, firstName, lastName, userType, phoneNumber } = req.body;

  if (!email || !password || !firstName || !lastName || !userType) {
    return res.status(400).json({ success: false, message: 'All required fields must be provided' });
  }

  if (!['admin', 'community', 'public'].includes(userType)) {
    return res.status(400).json({ success: false, message: 'Invalid user type' });
  }

  const existing = await queryOne(
    `SELECT id FROM ${SCHEMA}.users WHERE email = $1`,
    [email.toLowerCase().trim()]
  );
  if (existing) {
    return res.status(409).json({ success: false, message: 'Email is already registered' });
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const newUser = await queryOne(
    `INSERT INTO ${SCHEMA}.users (email, password_hash, first_name, last_name, user_type, phone_number, is_active, is_approved)
     VALUES ($1, $2, $3, $4, $5, $6, true, $7) RETURNING *`,
    [email.toLowerCase().trim(), passwordHash, firstName, lastName, userType, phoneNumber || null, userType === 'admin']
  );

  const token = generateToken(newUser);
  return res.status(201).json({
    success: true,
    message: 'Registration successful',
    data: { token, user: formatUser(newUser) },
  });
}));

// POST /api/auth/register-community
router.post('/register-community', asyncHandler(async (req, res) => {
  const {
    email, password, firstName, lastName, phoneNumber,
    communityName, location, contactPerson, description,
    establishedYear, memberCount,
  } = req.body;

  if (!email || !password || !firstName || !lastName || !communityName || !contactPerson) {
    return res.status(400).json({ success: false, message: 'All required fields must be provided' });
  }

  const existing = await queryOne(
    `SELECT id FROM ${SCHEMA}.users WHERE email = $1`,
    [email.toLowerCase().trim()]
  );
  if (existing) {
    return res.status(409).json({ success: false, message: 'Email is already registered' });
  }

  const passwordHash = await bcrypt.hash(password, 12);

  const result = await transaction(async (client) => {
    const userResult = await client.query(
      `INSERT INTO ${SCHEMA}.users (email, password_hash, first_name, last_name, user_type, phone_number, is_active, is_approved)
       VALUES ($1, $2, $3, $4, 'community', $5, true, false) RETURNING *`,
      [email.toLowerCase().trim(), passwordHash, firstName, lastName, phoneNumber || null]
    );
    const user = userResult.rows[0];

    const commResult = await client.query(
      `INSERT INTO ${SCHEMA}.communities
         (community_name, location, contact_person, phone_number, email, description, established_year, member_count, registration_status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending') RETURNING *`,
      [communityName, location || '', contactPerson, phoneNumber || '', email.toLowerCase().trim(),
       description || null, establishedYear || null, memberCount || null]
    );
    return { user, community: commResult.rows[0] };
  });

  return res.status(201).json({
    success: true,
    message: 'Community registration submitted. Awaiting admin approval.',
    data: {
      user: formatUser(result.user),
      community: {
        id: result.community.id,
        name: result.community.community_name,
        registrationStatus: result.community.registration_status,
      },
    },
  });
}));

// POST /api/auth/login
router.post('/login', asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email and password are required' });
  }

  const user = await queryOne(
    `SELECT * FROM ${SCHEMA}.users WHERE email = $1`,
    [email.toLowerCase().trim()]
  );

  if (!user) {
    return res.status(401).json({ success: false, message: 'Invalid email or password' });
  }

  const isValid = await bcrypt.compare(password, user.password_hash);
  if (!isValid) {
    return res.status(401).json({ success: false, message: 'Invalid email or password' });
  }

  if (!user.is_active) {
    return res.status(403).json({ success: false, message: 'Account has been deactivated' });
  }

  if (user.user_type !== 'admin' && !user.is_approved) {
    return res.status(403).json({
      success: false,
      message: 'Your account is pending admin approval',
      userType: user.user_type,
    });
  }

  const token = generateToken(user);
  await query(`UPDATE ${SCHEMA}.users SET last_login = NOW() WHERE id = $1`, [user.id]);

  return res.json({
    success: true,
    message: 'Login successful',
    data: { token, user: formatUser(user) },
  });
}));

// GET /api/auth/profile
router.get('/profile', asyncHandler(async (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Authentication required' });

  let decoded;
  try { decoded = jwt.verify(token, process.env.JWT_SECRET); }
  catch { return res.status(401).json({ success: false, message: 'Invalid or expired token' }); }

  const user = await queryOne(`SELECT * FROM ${SCHEMA}.users WHERE id = $1`, [decoded.userId]);
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });

  return res.json({ success: true, data: formatUser(user) });
}));

// PUT /api/auth/profile
router.put('/profile', asyncHandler(async (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Authentication required' });

  let decoded;
  try { decoded = jwt.verify(token, process.env.JWT_SECRET); }
  catch { return res.status(401).json({ success: false, message: 'Invalid or expired token' }); }

  const { firstName, lastName, phoneNumber } = req.body;
  const updated = await queryOne(
    `UPDATE ${SCHEMA}.users SET first_name = COALESCE($1, first_name), last_name = COALESCE($2, last_name),
     phone_number = COALESCE($3, phone_number), updated_at = NOW() WHERE id = $4 RETURNING *`,
    [firstName || null, lastName || null, phoneNumber || null, decoded.userId]
  );
  return res.json({ success: true, message: 'Profile updated', data: formatUser(updated) });
}));

// POST /api/auth/change-password
router.post('/change-password', asyncHandler(async (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Authentication required' });

  let decoded;
  try { decoded = jwt.verify(token, process.env.JWT_SECRET); }
  catch { return res.status(401).json({ success: false, message: 'Invalid or expired token' }); }

  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword)
    return res.status(400).json({ success: false, message: 'Current and new password required' });

  const user = await queryOne(`SELECT * FROM ${SCHEMA}.users WHERE id = $1`, [decoded.userId]);
  const isValid = await bcrypt.compare(currentPassword, user.password_hash);
  if (!isValid) return res.status(401).json({ success: false, message: 'Current password is incorrect' });

  const newHash = await bcrypt.hash(newPassword, 12);
  await query(`UPDATE ${SCHEMA}.users SET password_hash = $1, updated_at = NOW() WHERE id = $2`, [newHash, decoded.userId]);
  return res.json({ success: true, message: 'Password changed successfully' });
}));

// GET /api/auth/verify-token
router.get('/verify-token', asyncHandler(async (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'No token provided' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await queryOne(`SELECT id FROM ${SCHEMA}.users WHERE id = $1 AND is_active = true`, [decoded.userId]);
    if (!user) return res.status(401).json({ success: false, message: 'User not found or inactive' });
    return res.json({ success: true, message: 'Token is valid' });
  } catch {
    return res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
}));

// POST /api/auth/logout
router.post('/logout', asyncHandler(async (req, res) => {
  return res.json({ success: true, message: 'Logged out successfully' });
}));

module.exports = router;