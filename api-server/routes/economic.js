const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get all economic data for a community
router.get('/data', authenticateToken, async (req, res, next) => {
  try {
    const userEmail = req.user.email;
    
    // Find community ID from user email
    const communityResult = await db.query(`
      SELECT id FROM communities 
      WHERE email = $1 AND registration_status = 'approved'
    `, [userEmail]);

    if (communityResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลชุมชน'
      });
    }

    const communityId = communityResult.rows[0].id;

    // Get economic data
    const result = await db.query(`
      SELECT 
        id,
        year,
        quarter,
        income_fishery,
        income_tourism,
        income_agriculture,
        income_others,
        total_income,
        employment_count,
        notes,
        created_at,
        updated_at
      FROM economic_data
      WHERE community_id = $1
      ORDER BY year DESC, quarter DESC
    `, [communityId]);

    res.status(200).json({
      success: true,
      message: 'ดึงข้อมูลเศรษฐกิจสำเร็จ',
      data: result.rows
    });

  } catch (error) {
    console.error('❌ Get economic data error:', error);
    next(error);
  }
});

// Create economic data entry
router.post('/data', authenticateToken, async (req, res, next) => {
  try {
    const userEmail = req.user.email;
    const {
      year,
      quarter,
      incomeFishery,
      incomeTourism,
      incomeAgriculture,
      incomeOthers,
      employmentCount,
      notes
    } = req.body;

    // Find community ID
    const communityResult = await db.query(`
      SELECT id FROM communities 
      WHERE email = $1 AND registration_status = 'approved'
    `, [userEmail]);

    if (communityResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลชุมชน'
      });
    }

    const communityId = communityResult.rows[0].id;

    // Insert economic data
    const result = await db.query(`
      INSERT INTO economic_data (
        community_id,
        year,
        quarter,
        income_fishery,
        income_tourism,
        income_agriculture,
        income_others,
        employment_count,
        notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [
      communityId,
      year,
      quarter,
      incomeFishery || 0,
      incomeTourism || 0,
      incomeAgriculture || 0,
      incomeOthers || 0,
      employmentCount || 0,
      notes || null
    ]);

    res.status(201).json({
      success: true,
      message: 'บันทึกข้อมูลเศรษฐกิจสำเร็จ',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('❌ Create economic data error:', error);
    next(error);
  }
});

// Update economic data entry
router.put('/data/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userEmail = req.user.email;
    const {
      year,
      quarter,
      incomeFishery,
      incomeTourism,
      incomeAgriculture,
      incomeOthers,
      employmentCount,
      notes
    } = req.body;

    // Check ownership
    const checkResult = await db.query(`
      SELECT ed.* FROM economic_data ed
      JOIN communities c ON ed.community_id = c.id
      WHERE ed.id = $1 AND c.email = $2
    `, [id, userEmail]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลหรือคุณไม่มีสิทธิ์แก้ไข'
      });
    }

    // Update data
    const result = await db.query(`
      UPDATE economic_data SET
        year = $1,
        quarter = $2,
        income_fishery = $3,
        income_tourism = $4,
        income_agriculture = $5,
        income_others = $6,
        employment_count = $7,
        notes = $8,
        updated_at = NOW()
      WHERE id = $9
      RETURNING *
    `, [
      year,
      quarter,
      incomeFishery || 0,
      incomeTourism || 0,
      incomeAgriculture || 0,
      incomeOthers || 0,
      employmentCount || 0,
      notes || null,
      id
    ]);

    res.status(200).json({
      success: true,
      message: 'แก้ไขข้อมูลเศรษฐกิจสำเร็จ',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('❌ Update economic data error:', error);
    next(error);
  }
});

// Delete economic data entry
router.delete('/data/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userEmail = req.user.email;

    // Check ownership
    const checkResult = await db.query(`
      SELECT ed.* FROM economic_data ed
      JOIN communities c ON ed.community_id = c.id
      WHERE ed.id = $1 AND c.email = $2
    `, [id, userEmail]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลหรือคุณไม่มีสิทธิ์ลบ'
      });
    }

    // Delete data
    await db.query('DELETE FROM economic_data WHERE id = $1', [id]);

    res.status(200).json({
      success: true,
      message: 'ลบข้อมูลเศรษฐกิจสำเร็จ'
    });

  } catch (error) {
    console.error('❌ Delete economic data error:', error);
    next(error);
  }
});

module.exports = router;
