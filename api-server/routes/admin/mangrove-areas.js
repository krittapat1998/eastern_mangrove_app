const express = require('express');
const router = express.Router();
const db = require('../../config/database');


// GET /admin/mangrove-areas - Get all mangrove areas
router.get('/mangrove-areas', async (req, res) => {
  try {
    const { province, search } = req.query;
    
    let query = `
      SELECT 
        ma.*,
        c.community_name,
        c.email as community_email
      FROM mangrove_areas ma
      LEFT JOIN communities c ON ma.community_id = c.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (province) {
      params.push(province);
      query += ` AND ma.province = $${params.length}`;
    }
    
    if (search) {
      params.push(`%${search}%`);
      query += ` AND (ma.area_name ILIKE $${params.length} OR ma.location ILIKE $${params.length})`;
    }
    
    query += ` ORDER BY ma.province, ma.area_name`;
    
    const result = await db.query(query, params);
    
    res.json({
      success: true,
      message: 'ดึงข้อมูลพื้นที่ป่าชายเลนสำเร็จ',
      data: result.rows
    });
    
  } catch (error) {
    console.error('Error getting mangrove areas:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล: ' + error.message
    });
  }
});

// GET /admin/mangrove-areas/:id - Get single mangrove area
router.get('/mangrove-areas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await db.query(`
      SELECT 
        ma.*,
        c.community_name,
        c.email as community_email
      FROM mangrove_areas ma
      LEFT JOIN communities c ON ma.community_id = c.id
      WHERE ma.id = $1
    `, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลพื้นที่ป่าชายเลน'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
    
  } catch (error) {
    console.error('Error getting mangrove area:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล: ' + error.message
    });
  }
});

// Helper function to convert string to array for array fields
const stringToArray = (value) => {
  if (!value) return null;
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    // Split by comma and trim whitespace
    return value.split(',').map(item => item.trim()).filter(item => item.length > 0);
  }
  return null;
};

// POST /admin/mangrove-areas - Create new mangrove area
router.post('/mangrove-areas', async (req, res) => {
  try {
    const {
      community_id,
      area_name,
      location,
      province,
      size_hectares,
      mangrove_species,
      conservation_status,
      latitude,
      longitude,
      description,
      established_year,
      managing_organization,
      threats,
      conservation_activities
    } = req.body;
    
    // Validation
    if (!area_name || !location || !province) {
      return res.status(400).json({
        success: false,
        message: 'กรุณากรอกข้อมูลที่จำเป็น (ชื่อพื้นที่, สถานที่, จังหวัด)'
      });
    }
    
    const result = await db.query(`
      INSERT INTO mangrove_areas (
        community_id,
        area_name,
        location,
        province,
        size_hectares,
        mangrove_species,
        conservation_status,
        latitude,
        longitude,
        description,
        established_year,
        managing_organization,
        threats,
        conservation_activities
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *
    `, [
      community_id || null,
      area_name,
      location,
      province,
      size_hectares || null,
      stringToArray(mangrove_species),
      conservation_status || null,
      latitude || null,
      longitude || null,
      description || null,
      established_year || null,
      managing_organization || null,
      stringToArray(threats),
      stringToArray(conservation_activities)
    ]);
    
    res.status(201).json({
      success: true,
      message: 'เพิ่มพื้นที่ป่าชายเลนสำเร็จ',
      data: result.rows[0]
    });
    
  } catch (error) {
    console.error('Error creating mangrove area:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการเพิ่มพื้นที่: ' + error.message
    });
  }
});

// PUT /admin/mangrove-areas/:id - Update mangrove area
router.put('/mangrove-areas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      community_id,
      area_name,
      location,
      province,
      size_hectares,
      mangrove_species,
      conservation_status,
      latitude,
      longitude,
      description,
      established_year,
      managing_organization,
      threats,
      conservation_activities
    } = req.body;
    
    // Check if area exists
    const existingArea = await db.query('SELECT id FROM mangrove_areas WHERE id = $1', [id]);
    
    if (existingArea.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลพื้นที่ป่าชายเลน'
      });
    }
    
    // Validation
    if (!area_name || !location || !province) {
      return res.status(400).json({
        success: false,
        message: 'กรุณากรอกข้อมูลที่จำเป็น (ชื่อพื้นที่, สถานที่, จังหวัด)'
      });
    }
    
    const result = await db.query(`
      UPDATE mangrove_areas
      SET
        community_id = $2,
        area_name = $3,
        location = $4,
        province = $5,
        size_hectares = $6,
        mangrove_species = $7,
        conservation_status = $8,
        latitude = $9,
        longitude = $10,
        description = $11,
        established_year = $12,
        managing_organization = $13,
        threats = $14,
        conservation_activities = $15,
        updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `, [
      id,
      community_id || null,
      area_name,
      location,
      province,
      size_hectares || null,
      stringToArray(mangrove_species),
      conservation_status || null,
      latitude || null,
      longitude || null,
      description || null,
      established_year || null,
      managing_organization || null,
      stringToArray(threats),
      stringToArray(conservation_activities)
    ]);
    
    res.json({
      success: true,
      message: 'แก้ไขข้อมูลพื้นที่สำเร็จ',
      data: result.rows[0]
    });
    
  } catch (error) {
    console.error('Error updating mangrove area:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการแก้ไขข้อมูล: ' + error.message
    });
  }
});

// DELETE /admin/mangrove-areas/:id - Delete mangrove area
router.delete('/mangrove-areas/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if area exists
    const existingArea = await db.query('SELECT id FROM mangrove_areas WHERE id = $1', [id]);
    
    if (existingArea.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลพื้นที่ป่าชายเลน'
      });
    }
    
    await db.query('DELETE FROM mangrove_areas WHERE id = $1', [id]);
    
    res.json({
      success: true,
      message: 'ลบพื้นที่ป่าชายเลนสำเร็จ'
    });
    
  } catch (error) {
    console.error('Error deleting mangrove area:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการลบพื้นที่: ' + error.message
    });
  }
});

module.exports = router;


module.exports = router;
