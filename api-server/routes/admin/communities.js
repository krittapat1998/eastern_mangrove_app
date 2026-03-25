const express = require('express');
const router = express.Router();
const db = require('../../config/database');

// GET /admin/communities/pending - Get pending community registrations
router.get('/communities/pending', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        c.*,
        u.email as user_email,
        u.first_name,
        u.last_name,
        u.created_at as user_created_at
      FROM communities c
      LEFT JOIN users u ON c.email = u.email
      WHERE c.registration_status = 'pending'
      ORDER BY c.created_at DESC
    `);

    res.json({
      success: true,
      data: result.rows,
      count: result.rows.length
    });

  } catch (error) {
    console.error('Error fetching pending communities:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลคำขอลงทะเบียน'
    });
  }
});

// GET /admin/communities - Get all communities with filters
router.get('/communities', async (req, res) => {
  try {
    const { status, search, page = 1, limit = 20 } = req.query;
    
    let query = `
      SELECT 
        c.*,
        u.id as user_id,
        u.email as user_email,
        u.first_name,
        u.last_name,
        u.is_active as user_active,
        COUNT(*) OVER() as total_count
      FROM communities c
      LEFT JOIN users u ON c.email = u.email
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;

    // Filter by status
    if (status && status !== 'all') {
      query += ` AND c.registration_status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    // Search filter
    if (search) {
      query += ` AND (
        c.community_name ILIKE $${paramIndex} OR
        c.email ILIKE $${paramIndex} OR
        c.location ILIKE $${paramIndex} OR
        c.contact_person ILIKE $${paramIndex}
      )`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    // Pagination
    const offset = (page - 1) * limit;
    query += ` ORDER BY c.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    const totalCount = result.rows.length > 0 ? parseInt(result.rows[0].total_count) : 0;
    const totalPages = Math.ceil(totalCount / limit);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalCount,
        totalPages
      }
    });

  } catch (error) {
    console.error('Error fetching communities:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลชุมชน'
    });
  }
});

// PUT /admin/communities/:id/approve - Approve community registration
router.put('/communities/:id/approve', async (req, res) => {
  const { id } = req.params;
  const { notes } = req.body; // Optional admin notes

  try {
    // Start transaction
    await db.query('BEGIN');

    // Get community details
    const communityResult = await db.query(
      'SELECT * FROM communities WHERE id = $1',
      [id]
    );

    if (communityResult.rows.length === 0) {
      await db.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบชุมชนที่ต้องการอนุมัติ'
      });
    }

    const community = communityResult.rows[0];

    if (community.registration_status !== 'pending') {
      await db.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        error: 'Invalid status',
        message: 'ชุมชนนี้ได้รับการพิจารณาแล้ว'
      });
    }

    // Update community status to approved
    await db.query(
      `UPDATE communities 
       SET registration_status = 'approved',
           approved_by = $1,
           approved_at = NOW(),
           updated_at = NOW()
       WHERE id = $2`,
      [req.user.id, id]
    );

    // Activate the associated user account
    await db.query(
      `UPDATE users 
       SET is_active = true,
           updated_at = NOW()
       WHERE email = $1 AND user_type = 'community'`,
      [community.email]
    );

    // Log the approval action
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, 'approve_community', 'community', $2, $3, NOW())`,
      [req.user.id, id, notes || 'อนุมัติคำขอลงทะเบียนชุมชน']
    );

    await db.query('COMMIT');

    res.json({
      success: true,
      message: 'อนุมัติคำขอลงทะเบียนชุมชนเรียบร้อยแล้ว',
      data: {
        communityId: id,
        communityName: community.community_name,
        approvedAt: new Date()
      }
    });

  } catch (error) {
    await db.query('ROLLBACK');
    console.error('Error approving community:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการอนุมัติคำขอลงทะเบียน'
    });
  }
});

// PUT /admin/communities/:id/reject - Reject community registration
router.put('/communities/:id/reject', async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body; // Rejection reason

  if (!reason || reason.trim() === '') {
    return res.status(400).json({
      success: false,
      error: 'Validation error',
      message: 'กรุณาระบุเหตุผลในการปฏิเสธ'
    });
  }

  try {
    // Start transaction
    await db.query('BEGIN');

    // Get community details
    const communityResult = await db.query(
      'SELECT * FROM communities WHERE id = $1',
      [id]
    );

    if (communityResult.rows.length === 0) {
      await db.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบชุมชนที่ต้องการปฏิเสธ'
      });
    }

    const community = communityResult.rows[0];

    if (community.registration_status !== 'pending') {
      await db.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        error: 'Invalid status',
        message: 'ชุมชนนี้ได้รับการพิจารณาแล้ว'
      });
    }

    // Update community status to rejected
    await db.query(
      `UPDATE communities 
       SET registration_status = 'rejected',
           rejection_reason = $1,
           rejected_by = $2,
           rejected_at = NOW(),
           updated_at = NOW()
       WHERE id = $3`,
      [reason, req.user.id, id]
    );

    // Keep user account inactive (don't activate)
    // Optionally, we could delete the user account, but keeping it for records

    // Log the rejection action
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, 'reject_community', 'community', $2, $3, NOW())`,
      [req.user.id, id, reason]
    );

    await db.query('COMMIT');

    res.json({
      success: true,
      message: 'ปฏิเสธคำขอลงทะเบียนชุมชนเรียบร้อยแล้ว',
      data: {
        communityId: id,
        communityName: community.community_name,
        rejectedAt: new Date(),
        reason
      }
    });

  } catch (error) {
    await db.query('ROLLBACK');
    console.error('Error rejecting community:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการปฏิเสธคำขอลงทะเบียน'
    });
  }
});


// POST /admin/communities/check-duplicate - Check if community name or email already exists
router.post('/communities/check-duplicate', async (req, res) => {
  const { communityName, email } = req.body;

  try {
    // Check if community name or email already exists
    const checkResult = await db.query(
      'SELECT id, community_name, email FROM communities WHERE LOWER(community_name) = LOWER($1) OR LOWER(email) = LOWER($2)',
      [communityName, email]
    );

    if (checkResult.rows.length > 0) {
      const duplicate = checkResult.rows[0];
      let duplicateFields = [];
      
      if (duplicate.community_name.toLowerCase() === communityName.toLowerCase()) {
        duplicateFields.push('ชื่อชุมชน');
      }
      if (duplicate.email.toLowerCase() === email.toLowerCase()) {
        duplicateFields.push('อีเมล');
      }

      return res.status(200).json({
        success: true,
        isDuplicate: true,
        message: `${duplicateFields.join(' และ ')} นี้มีอยู่ในระบบแล้ว`,
        duplicateFields: duplicateFields
      });
    }

    return res.status(200).json({
      success: true,
      isDuplicate: false,
      message: 'ข้อมูลไม่ซ้ำกัน สามารถใช้งานได้'
    });
  } catch (error) {
    console.error('Error checking duplicate:', error);
    return res.status(500).json({
      success: false,
      error: 'Server error',
      message: 'เกิดข้อผิดพลาดในการตรวจสอบข้อมูล'
    });
  }
});

// POST /admin/communities - Create new community with user account
router.post('/communities', async (req, res) => {
  const {
    communityName,
    location,
    villageName,
    subDistrict,
    district,
    province,
    contactPerson,
    phoneNumber,
    email,
    password,
    description,
    establishedYear,
    memberCount
  } = req.body;

  // Validate required fields
  if (!communityName || !contactPerson || !phoneNumber || !email || !password) {
    return res.status(400).json({
      success: false,
      error: 'Validation error',
      message: 'กรุณากรอกข้อมูลให้ครบถ้วน'
    });
  }

  // Validate password
  if (password.length < 8) {
    return res.status(400).json({
      success: false,
      error: 'Validation error',
      message: 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร'
    });
  }

  try {
    // Start transaction
    await db.query('BEGIN');

    // Check if community name already exists
    const checkCommunity = await db.query(
      'SELECT id FROM communities WHERE community_name = $1 OR email = $2',
      [communityName, email]
    );

    if (checkCommunity.rows.length > 0) {
      await db.query('ROLLBACK');
      return res.status(409).json({
        success: false,
        error: 'Duplicate entry',
        message: 'มีชุมชนที่ใช้ชื่อหรืออีเมลนี้อยู่แล้ว'
      });
    }

    // Check if user email already exists
    const checkUser = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (checkUser.rows.length > 0) {
      await db.query('ROLLBACK');
      return res.status(409).json({
        success: false,
        error: 'Duplicate entry',
        message: 'มีผู้ใช้งานที่ใช้อีเมลนี้อยู่แล้ว'
      });
    }

    // Hash password
    const bcrypt = require('bcrypt');
    const password_hash = await bcrypt.hash(password, 12);

    // Create user account (active by default when created by admin)
    const userResult = await db.query(
      `INSERT INTO users (email, password_hash, first_name, last_name, user_type, phone_number, is_active, email_verified, created_at)
       VALUES ($1, $2, $3, $4, 'community', $5, true, true, NOW())
       RETURNING id`,
      [email, password_hash, contactPerson, communityName, phoneNumber]
    );

    const userId = userResult.rows[0].id;

    // Build location string from parts if not provided directly
    const locationStr = location || [
      villageName ? `หมู่บ้าน${villageName}` : '',
      subDistrict ? `ตำบล${subDistrict}` : '',
      district ? `อำเภอ${district}` : '',
      province ? `จังหวัด${province}` : ''
    ].filter(Boolean).join(' ') || '';

    // Create community (approved by default when created by admin)
    const communityResult = await db.query(
      `INSERT INTO communities (
        community_name, location, village_name, sub_district, district, province,
        contact_person, phone_number, email, description, 
        established_year, member_count, registration_status, approved_by, approved_at, created_at, updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'approved', $13, NOW(), NOW(), NOW())
      RETURNING id`,
      [
        communityName,
        locationStr,
        villageName || null,
        subDistrict || null,
        district || null,
        province || null,
        contactPerson,
        phoneNumber,
        email,
        description || null,
        establishedYear || null,
        memberCount || null,
        req.user.id
      ]
    );

    const communityId = communityResult.rows[0].id;

    // Log the action
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, 'create_community', 'community', $2, $3, NOW())`,
      [req.user.id, communityId, `สร้างชุมชน ${communityName}`]
    );

    await db.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'สร้างชุมชนเรียบร้อยแล้ว',
      data: {
        communityId,
        userId,
        communityName,
        email
      }
    });

  } catch (error) {
    await db.query('ROLLBACK');
    console.error('Error creating community:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการสร้างชุมชน'
    });
  }
});

// PUT /admin/communities/:id - Update community information
router.put('/communities/:id', async (req, res) => {
  const { id } = req.params;
  const {
    communityName,
    location,
    villageName,
    subDistrict,
    district,
    province,
    contactPerson,
    phoneNumber,
    email,
    description,
    establishedYear,
    memberCount
  } = req.body;

  try {
    // Check if community exists
    const checkCommunity = await db.query(
      'SELECT * FROM communities WHERE id = $1',
      [id]
    );

    if (checkCommunity.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบชุมชนที่ต้องการแก้ไข'
      });
    }

    const oldCommunity = checkCommunity.rows[0];

    // If email is changing, check for duplicates (excluding current community)
    if (email && email !== oldCommunity.email) {
      const checkEmail = await db.query(
        'SELECT id FROM communities WHERE email = $1 AND id != $2',
        [email, id]
      );

      if (checkEmail.rows.length > 0) {
        return res.status(409).json({
          success: false,
          error: 'Duplicate entry',
          message: 'มีชุมชนอื่นที่ใช้อีเมลนี้อยู่แล้ว'
        });
      }

      // Also update user email if email is changing
      await db.query(
        'UPDATE users SET email = $1, updated_at = NOW() WHERE email = $2 AND user_type = $3',
        [email, oldCommunity.email, 'community']
      );
    }

    // If community name is changing, check for duplicates
    if (communityName && communityName !== oldCommunity.community_name) {
      const checkName = await db.query(
        'SELECT id FROM communities WHERE community_name = $1 AND id != $2',
        [communityName, id]
      );

      if (checkName.rows.length > 0) {
        return res.status(409).json({
          success: false,
          error: 'Duplicate entry',
          message: 'มีชุมชนที่ใช้ชื่อนี้อยู่แล้ว'
        });
      }
    }

    // Build update query dynamically
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (communityName) {
      updates.push(`community_name = $${paramIndex++}`);
      values.push(communityName);
    }
    if (location || (province && district && subDistrict)) {
      const locationStr = location || [
        villageName ? `หมู่บ้าน${villageName}` : '',
        subDistrict ? `ตำบล${subDistrict}` : '',
        district ? `อำเภอ${district}` : '',
        province ? `จังหวัด${province}` : ''
      ].filter(Boolean).join(' ');
      updates.push(`location = $${paramIndex++}`);
      values.push(locationStr);
    }
    if (villageName !== undefined) {
      updates.push(`village_name = $${paramIndex++}`);
      values.push(villageName || null);
    }
    if (subDistrict !== undefined) {
      updates.push(`sub_district = $${paramIndex++}`);
      values.push(subDistrict || null);
    }
    if (district !== undefined) {
      updates.push(`district = $${paramIndex++}`);
      values.push(district || null);
    }
    if (province !== undefined) {
      updates.push(`province = $${paramIndex++}`);
      values.push(province || null);
    }
    if (contactPerson) {
      updates.push(`contact_person = $${paramIndex++}`);
      values.push(contactPerson);
    }
    if (phoneNumber) {
      updates.push(`phone_number = $${paramIndex++}`);
      values.push(phoneNumber);
    }
    if (email) {
      updates.push(`email = $${paramIndex++}`);
      values.push(email);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      values.push(description);
    }
    if (establishedYear !== undefined) {
      updates.push(`established_year = $${paramIndex++}`);
      values.push(establishedYear);
    }
    if (memberCount !== undefined) {
      updates.push(`member_count = $${paramIndex++}`);
      values.push(memberCount);
    }

    updates.push(`updated_at = NOW()`);
    values.push(id);

    // Update community
    await db.query(
      `UPDATE communities SET ${updates.join(', ')} WHERE id = $${paramIndex}`,
      values
    );

    // Log the action
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, 'update_community', 'community', $2, $3, NOW())`,
      [req.user.id, id, `แก้ไขข้อมูลชุมชน ${communityName || oldCommunity.community_name}`]
    );

    res.json({
      success: true,
      message: 'แก้ไขข้อมูลชุมชนเรียบร้อยแล้ว',
      data: {
        communityId: id,
        communityName: communityName || oldCommunity.community_name
      }
    });

  } catch (error) {
    console.error('Error updating community:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการแก้ไขข้อมูลชุมชน'
    });
  }
});

// PUT /admin/communities/:id/toggle-status - Toggle community user active status
router.put('/communities/:id/toggle-status', async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  try {
    // Get community with user info
    const communityResult = await db.query(
      `SELECT c.*, u.id as user_id, u.is_active as user_active, u.email as user_email
       FROM communities c
       LEFT JOIN users u ON u.email = c.email
       WHERE c.id = $1`,
      [id]
    );

    if (communityResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบชุมชนที่ต้องการ'
      });
    }

    const community = communityResult.rows[0];
    const userId = community.user_id;
    
    if (!userId) {
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบบัญชีผู้ใช้ของชุมชนนี้'
      });
    }

    const newStatus = !community.user_active;

    // Update user status
    await db.query(
      `UPDATE users 
       SET is_active = $1,
           updated_at = NOW()
       WHERE id = $2`,
      [newStatus, userId]
    );

    // Log the action
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, $2, 'community', $3, $4, NOW())`,
      [
        req.user.id,
        newStatus ? 'activate_community_user' : 'deactivate_community_user',
        id,
        reason || (newStatus ? `เปิดใช้งานชุมชน ${community.community_name}` : `ระงับการใช้งานชุมชน ${community.community_name}`)
      ]
    );

    res.json({
      success: true,
      message: newStatus ? 'เปิดใช้งานชุมชนเรียบร้อยแล้ว' : 'ระงับการใช้งานชุมชนเรียบร้อยแล้ว',
      data: {
        communityId: id,
        communityName: community.community_name,
        userId: userId,
        isActive: newStatus
      }
    });

  } catch (error) {
    console.error('Error toggling community status:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการเปลี่ยนสถานะชุมชน'
    });
  }
});

// DELETE /admin/communities/:id - Delete community and associated user
router.delete('/communities/:id', async (req, res) => {
  const { id } = req.params;

  try {
    await db.query('BEGIN');

    // Get community with user info
    const communityResult = await db.query(
      `SELECT c.*, u.id as user_id, u.email as user_email
       FROM communities c
       LEFT JOIN users u ON u.email = c.email
       WHERE c.id = $1`,
      [id]
    );

    if (communityResult.rows.length === 0) {
      await db.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบชุมชนที่ต้องการลบ'
      });
    }

    const community = communityResult.rows[0];
    const userId = community.user_id;

    // Log the action before deletion
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, 'delete_community', 'community', $2, $3, NOW())`,
      [req.user.id, id, `ลบชุมชน ${community.community_name}`]
    );

    // Delete related data (CASCADE should handle most, but being explicit)
    // Note: Depends on your database CASCADE settings
    await db.query('DELETE FROM ecosystem_services WHERE community_id = $1', [id]);
    await db.query('DELETE FROM community_activities WHERE community_id = $1', [id]);
    await db.query('DELETE FROM pollution_reports WHERE community_id = $1', [id]);
    await db.query('DELETE FROM mangrove_areas WHERE community_id = $1', [id]);
    
    // Delete community
    await db.query('DELETE FROM communities WHERE id = $1', [id]);
    
    // Delete associated user account if exists
    if (userId) {
      await db.query('DELETE FROM users WHERE id = $1', [userId]);
    }

    await db.query('COMMIT');

    res.json({
      success: true,
      message: 'ลบชุมชนเรียบร้อยแล้ว',
      data: {
        communityId: id,
        communityName: community.community_name,
        deletedUserId: userId
      }
    });

  } catch (error) {
    await db.query('ROLLBACK');
    console.error('Error deleting community:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการลบชุมชน: ' + error.message
    });
  }
});

// ============================================
// MANGROVE AREAS MANAGEMENT
// ============================================

module.exports = router;
