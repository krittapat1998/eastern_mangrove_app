const express = require('express');
const db = require('../../config/database');
const { authenticateToken } = require('../../middleware/auth');

const router = express.Router();

// Get all ecosystem services for a community
router.get('/services', authenticateToken, async (req, res, next) => {
  try {
    const userEmail = req.user.email;
    
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

    // Get ecosystem services
    const result = await db.query(`
      SELECT 
        id,
        category,
        service_type,
        service_name,
        quantity,
        unit,
        unit_price,
        participants,
        price_per_person,
        economic_value,
        year,
        month,
        description,
        beneficiaries_count,
        created_at,
        updated_at
      FROM ecosystem_services
      WHERE community_id = $1
      ORDER BY year DESC, month DESC, created_at DESC
    `, [communityId]);

    res.status(200).json({
      success: true,
      message: 'ดึงข้อมูลบริการนิเวศสำเร็จ',
      data: result.rows
    });

  } catch (error) {
    console.error('❌ Get ecosystem services error:', error);
    next(error);
  }
});

// Create ecosystem service entry
router.post('/services', authenticateToken, async (req, res, next) => {
  try {
    const userEmail = req.user.email;
    const {
      category,
      serviceType,
      serviceName,
      quantity,
      unit,
      unitPrice,
      participants,
      pricePerPerson,
      economicValue,
      year,
      month,
      description,
      beneficiariesCount
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

    // Insert ecosystem service
    const result = await db.query(`
      INSERT INTO ecosystem_services (
        community_id,
        category,
        service_type,
        service_name,
        quantity,
        unit,
        unit_price,
        participants,
        price_per_person,
        economic_value,
        year,
        month,
        description,
        beneficiaries_count
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *
    `, [
      communityId,
      category || 'resource',
      serviceType,
      serviceName,
      quantity || 0,
      unit,
      unitPrice || 0,
      participants || 0,
      pricePerPerson || 0,
      economicValue || 0,
      year,
      month,
      description || null,
      beneficiariesCount || 0
    ]);

    res.status(201).json({
      success: true,
      message: 'บันทึกข้อมูลบริการนิเวศสำเร็จ',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('❌ Create ecosystem service error:', error);
    next(error);
  }
});

// Update ecosystem service entry
router.put('/services/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userEmail = req.user.email;
    const {
      category,
      serviceType,
      serviceName,
      quantity,
      unit,
      unitPrice,
      participants,
      pricePerPerson,
      economicValue,
      year,
      month,
      description,
      beneficiariesCount
    } = req.body;

    // Check ownership
    const checkResult = await db.query(`
      SELECT es.* FROM ecosystem_services es
      JOIN communities c ON es.community_id = c.id
      WHERE es.id = $1 AND c.email = $2
    `, [id, userEmail]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลหรือคุณไม่มีสิทธิ์แก้ไข'
      });
    }

    // Update data
    const result = await db.query(`
      UPDATE ecosystem_services SET
        category = $1,
        service_type = $2,
        service_name = $3,
        quantity = $4,
        unit = $5,
        unit_price = $6,
        participants = $7,
        price_per_person = $8,
        economic_value = $9,
        year = $10,
        month = $11,
        description = $12,
        beneficiaries_count = $13,
        updated_at = NOW()
      WHERE id = $14
      RETURNING *
    `, [
      category || 'resource',
      serviceType,
      serviceName,
      quantity || 0,
      unit,
      unitPrice || 0,
      participants || 0,
      pricePerPerson || 0,
      economicValue || 0,
      year,
      month,
      description || null,
      beneficiariesCount || 0,
      id
    ]);

    res.status(200).json({
      success: true,
      message: 'แก้ไขข้อมูลบริการนิเวศสำเร็จ',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('❌ Update ecosystem service error:', error);
    next(error);
  }
});

// Delete ecosystem service entry
router.delete('/services/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userEmail = req.user.email;

    // Check ownership
    const checkResult = await db.query(`
      SELECT es.* FROM ecosystem_services es
      JOIN communities c ON es.community_id = c.id
      WHERE es.id = $1 AND c.email = $2
    `, [id, userEmail]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลหรือคุณไม่มีสิทธิ์ลบ'
      });
    }

    // Delete data
    await db.query('DELETE FROM ecosystem_services WHERE id = $1', [id]);

    res.status(200).json({
      success: true,
      message: 'ลบข้อมูลบริการนิเวศสำเร็จ'
    });

  } catch (error) {
    console.error('❌ Delete ecosystem service error:', error);
    next(error);
  }
});

module.exports = router;
