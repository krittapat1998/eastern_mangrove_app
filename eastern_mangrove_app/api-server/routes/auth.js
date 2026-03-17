const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { query, queryOne, transaction } = require('../config/database');
const { userValidation, communityValidation } = require('../middleware/validation');
const { asyncHandler, ValidationError, UnauthorizedError } = require('../middleware/errorHandler');

const router = express.Router();

// Helper function to generate JWT token
function generateToken(user) {
  return jwt.sign(
    {
      userId: user.id,
      username: user.username,
      userType: user.user_type
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

// Register endpoint
router.post('/register', userValidation.register, asyncHandler(async (req, res) => {
  const { username, email, password, user_type } = req.body;

  // Check if user already exists
  const existingUser = await queryOne(
    'SELECT id FROM users WHERE username = $1 OR email = $2',
    [username, email]
  );

  if (existingUser) {
    throw new ValidationError('User already exists', [
      { field: 'username', message: 'Username or email already taken' }
    ]);
  }

  // Hash password
  const saltRounds = 12;
  const password_hash = await bcrypt.hash(password, saltRounds);

  // Create user
  const newUser = await queryOne(
    `INSERT INTO users (username, email, password_hash, user_type) 
     VALUES ($1, $2, $3, $4) 
     RETURNING id, username, email, user_type, is_active, is_approved, created_at`,
    [username, email, password_hash, user_type]
  );

  res.status(201).json({
    message: 'User registered successfully',
    user: {
      id: newUser.id,
      username: newUser.username,
      email: newUser.email,
      user_type: newUser.user_type,
      is_active: newUser.is_active,
      is_approved: newUser.is_approved,
      created_at: newUser.created_at
    }
  });
}));

// Community registration endpoint
router.post('/register/community', communityValidation.register, asyncHandler(async (req, res) => {
  const {
    username, email, password,
    community_name, village_name, sub_district, district, province,
    contact_person, phone, description, latitude, longitude
  } = req.body;

  // Use transaction to ensure data consistency
  const result = await transaction(async (client) => {
    // Check if user already exists
    const existingUser = await client.query(
      'SELECT id FROM users WHERE username = $1 OR email = $2',
      [username, email]
    );

    if (existingUser.rows.length > 0) {
      throw new ValidationError('User already exists', [
        { field: 'username', message: 'Username or email already taken' }
      ]);
    }

    // Hash password
    const password_hash = await bcrypt.hash(password, 12);

    // Create user
    const newUser = await client.query(
      `INSERT INTO users (username, email, password_hash, user_type) 
       VALUES ($1, $2, $3, 'community') 
       RETURNING id, username, email, user_type, is_active, is_approved, created_at`,
      [username, email, password_hash]
    );

    const user = newUser.rows[0];

    // Create community record
    const newCommunity = await client.query(
      `INSERT INTO communities (
         user_id, community_name, village_name, sub_district, district, province,
         contact_person, phone, description, latitude, longitude
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING id, community_name, registration_status, created_at`,
      [
        user.id, community_name, village_name, sub_district, district, province,
        contact_person, phone, description, latitude, longitude
      ]
    );

    const community = newCommunity.rows[0];

    return { user, community };
  });

  res.status(201).json({
    message: 'Community registration submitted successfully',
    user: {
      id: result.user.id,
      username: result.user.username,
      email: result.user.email,
      user_type: result.user.user_type,
      is_active: result.user.is_active,
      is_approved: result.user.is_approved,
      created_at: result.user.created_at
    },
    community: {
      id: result.community.id,
      name: result.community.community_name,
      registration_status: result.community.registration_status,
      created_at: result.community.created_at
    }
  });
}));

// Login endpoint
router.post('/login', userValidation.login, asyncHandler(async (req, res) => {
  const { username, password } = req.body;

  // Find user by username or email
  const user = await queryOne(
    'SELECT id, username, email, password_hash, user_type, is_active, is_approved FROM users WHERE username = $1 OR email = $1',
    [username]
  );

  if (!user) {
    throw new UnauthorizedError('Invalid username or password');
  }

  // Check password
  const isValidPassword = await bcrypt.compare(password, user.password_hash);
  if (!isValidPassword) {
    throw new UnauthorizedError('Invalid username or password');
  }

  // Check if user is active
  if (!user.is_active) {
    throw new UnauthorizedError('Account has been deactivated');
  }

  // For non-admin users, check if approved
  if (user.user_type !== 'admin' && !user.is_approved) {
    return res.status(403).json({
      error: 'Account not approved',
      message: 'Your account is pending admin approval',
      user_type: user.user_type
    });
  }

  // Generate token
  const token = generateToken(user);

  // Get additional info based on user type
  let additionalData = {};
  
  if (user.user_type === 'community') {
    const community = await queryOne(
      'SELECT id, community_name, registration_status FROM communities WHERE user_id = $1',
      [user.id]
    );
    additionalData.community = community;
  }

  res.json({
    message: 'Login successful',
    token,
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      user_type: user.user_type,
      is_active: user.is_active,
      is_approved: user.is_approved
    },
    ...additionalData
  });
}));

// Refresh token endpoint
router.post('/refresh', asyncHandler(async (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    throw new UnauthorizedError('Refresh token required');
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get fresh user data
    const user = await queryOne(
      'SELECT id, username, email, user_type, is_active, is_approved FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (!user || !user.is_active) {
      throw new UnauthorizedError('User not found or inactive');
    }

    // Generate new token
    const newToken = generateToken(user);

    res.json({
      message: 'Token refreshed successfully',
      token: newToken,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        user_type: user.user_type,
        is_active: user.is_active,
        is_approved: user.is_approved
      }
    });
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      throw new UnauthorizedError('Invalid or expired token');
    }
    throw err;
  }
}));

// Check username availability
router.get('/check-username/:username', asyncHandler(async (req, res) => {
  const { username } = req.params;

  const existingUser = await queryOne(
    'SELECT id FROM users WHERE username = $1',
    [username]
  );

  res.json({
    available: !existingUser,
    message: existingUser ? 'Username is already taken' : 'Username is available'
  });
}));

// Check email availability
router.get('/check-email/:email', asyncHandler(async (req, res) => {
  const { email } = req.params;

  const existingUser = await queryOne(
    'SELECT id FROM users WHERE email = $1',
    [email]
  );

  res.json({
    available: !existingUser,
    message: existingUser ? 'Email is already registered' : 'Email is available'
  });
}));

module.exports = router;