const express = require('express');
const router = express.Router();
const db = require('../../config/database');

// GET /admin/users - Get all users with filters
router.get('/users', async (req, res) => {
  try {
    const { userType, status, search, page = 1, limit = 20 } = req.query;
    
    let query = `
      SELECT 
        u.*,
        c.community_name,
        c.registration_status as community_status,
        COUNT(*) OVER() as total_count
      FROM users u
      LEFT JOIN communities c ON u.email = c.email AND u.user_type = 'community'
      WHERE 1=1
    `;
    
    const params = [];
    let paramIndex = 1;

    // Filter by user type
    if (userType && userType !== 'all') {
      query += ` AND u.user_type = $${paramIndex}`;
      params.push(userType);
      paramIndex++;
    }

    // Filter by active status
    if (status === 'active') {
      query += ` AND u.is_active = true`;
    } else if (status === 'inactive') {
      query += ` AND u.is_active = false`;
    }

    // Search filter
    if (search) {
      query += ` AND (
        u.email ILIKE $${paramIndex} OR
        u.first_name ILIKE $${paramIndex} OR
        u.last_name ILIKE $${paramIndex} OR
        c.community_name ILIKE $${paramIndex}
      )`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    // Pagination
    const offset = (page - 1) * limit;
    query += ` ORDER BY u.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    const totalCount = result.rows.length > 0 ? parseInt(result.rows[0].total_count) : 0;
    const totalPages = Math.ceil(totalCount / limit);

    // Remove password_hash from response
    const users = result.rows.map(user => {
      const { password_hash, ...userWithoutPassword } = user;
      return userWithoutPassword;
    });

    res.json({
      success: true,
      data: users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalCount,
        totalPages
      }
    });

  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้งาน'
    });
  }
});

// PUT /admin/users/:id/toggle-status - Toggle user active status
router.put('/users/:id/toggle-status', async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  try {
    // Get current user status
    const userResult = await db.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบผู้ใช้งานที่ต้องการ'
      });
    }

    const user = userResult.rows[0];
    const newStatus = !user.is_active;

    // Don't allow disabling admin users
    if (user.user_type === 'admin' && !newStatus) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden',
        message: 'ไม่สามารถปิดการใช้งานบัญชี Admin ได้'
      });
    }

    // Update user status
    await db.query(
      `UPDATE users 
       SET is_active = $1,
           updated_at = NOW()
       WHERE id = $2`,
      [newStatus, id]
    );

    // Log the action
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, $2, 'user', $3, $4, NOW())`,
      [
        req.user.id,
        newStatus ? 'activate_user' : 'deactivate_user',
        id,
        reason || (newStatus ? 'เปิดใช้งานบัญชีผู้ใช้' : 'ปิดใช้งานบัญชีผู้ใช้')
      ]
    );

    res.json({
      success: true,
      message: newStatus ? 'เปิดใช้งานบัญชีผู้ใช้เรียบร้อยแล้ว' : 'ปิดใช้งานบัญชีผู้ใช้เรียบร้อยแล้ว',
      data: {
        userId: id,
        email: user.email,
        isActive: newStatus
      }
    });

  } catch (error) {
    console.error('Error toggling user status:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการเปลี่ยนสถานะผู้ใช้งาน'
    });
  }
});

// GET /admin/actions - Get admin action logs
router.get('/actions', async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    
    const offset = (page - 1) * limit;
    
    const result = await db.query(`
      SELECT 
        aa.*,
        u.email as admin_email,
        u.first_name,
        u.last_name,
        COUNT(*) OVER() as total_count
      FROM admin_actions aa
      JOIN users u ON aa.admin_id = u.id
      ORDER BY aa.created_at DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);

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
    console.error('Error fetching admin actions:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล log การทำงาน'
    });
  }
});

// PUT /admin/users/:id/reset-password - Reset user password
router.put('/users/:id/reset-password', async (req, res) => {
  const { id } = req.params;
  const { newPassword } = req.body;

  // Validate password
  if (!newPassword || newPassword.length < 8) {
    return res.status(400).json({
      success: false,
      error: 'Validation error',
      message: 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร'
    });
  }

  try {
    // Get user
    const userResult = await db.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Not found',
        message: 'ไม่พบผู้ใช้งานที่ต้องการ'
      });
    }

    const user = userResult.rows[0];

    // Don't allow resetting admin password
    if (user.user_type === 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Forbidden',
        message: 'ไม่สามารถรีเซ็ตรหัสผ่าน Admin ได้'
      });
    }

    // Hash new password
    const bcrypt = require('bcrypt');
    const password_hash = await bcrypt.hash(newPassword, 12);

    // Update password
    await db.query(
      `UPDATE users 
       SET password_hash = $1,
           updated_at = NOW()
       WHERE id = $2`,
      [password_hash, id]
    );

    // Log the action
    await db.query(
      `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, notes, created_at)
       VALUES ($1, 'reset_password', 'user', $2, $3, NOW())`,
      [req.user.id, id, `รีเซ็ตรหัสผ่านสำหรับ ${user.email}`]
    );

    res.json({
      success: true,
      message: 'รีเซ็ตรหัสผ่านเรียบร้อยแล้ว',
      data: {
        userId: id,
        email: user.email
      }
    });

  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการรีเซ็ตรหัสผ่าน'
    });
  }
});


module.exports = router;
