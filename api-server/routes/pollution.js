const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get all pollution reports for a community
router.get('/reports', authenticateToken, async (req, res, next) => {
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

    // Get pollution reports
    const result = await db.query(`
      SELECT 
        id,
        report_type,
        pollution_source,
        severity_level,
        description,
        latitude,
        longitude,
        report_date,
        status,
        photos,
        created_at,
        updated_at
      FROM pollution_reports
      WHERE community_id = $1
      ORDER BY report_date DESC, created_at DESC
    `, [communityId]);

    res.status(200).json({
      success: true,
      message: 'ดึงข้อมูลรายงานมลพิษสำเร็จ',
      data: result.rows
    });

  } catch (error) {
    console.error('❌ Get pollution reports error:', error);
    next(error);
  }
});

// Create pollution report
router.post('/reports', authenticateToken, async (req, res, next) => {
  try {
    const userEmail = req.user.email;
    const {
      reportType,
      pollutionSource,
      severityLevel,
      description,
      latitude,
      longitude,
      reportDate,
      status,
      photos
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

    // Report type is already in correct English format from frontend
    // No mapping needed - use reportType directly
    const dbReportType = reportType;

    // Insert pollution report
    const result = await db.query(`
      INSERT INTO pollution_reports (
        community_id,
        report_type,
        pollution_source,
        severity_level,
        description,
        latitude,
        longitude,
        report_date,
        status,
        photos
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *
    `, [
      communityId,
      dbReportType,
      pollutionSource,
      severityLevel || 'medium',
      description,
      latitude || null,
      longitude || null,
      reportDate || new Date(),
      status || 'pending',
      Array.isArray(photos) && photos.length > 0 ? photos : null
    ]);

    res.status(201).json({
      success: true,
      message: 'บันทึกรายงานมลพิษสำเร็จ',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('❌ Create pollution report error:', error);
    next(error);
  }
});

// Update pollution report
router.put('/reports/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userEmail = req.user.email;
    const {
      reportType,
      pollutionSource = 'ไม่ระบุ',
      severityLevel,
      description,
      latitude,
      longitude,
      reportDate = new Date().toISOString(),
      status,
      photos
    } = req.body;

    // Check ownership
    const checkResult = await db.query(`
      SELECT pr.* FROM pollution_reports pr
      JOIN communities c ON pr.community_id = c.id
      WHERE pr.id = $1 AND c.email = $2
    `, [id, userEmail]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลหรือคุณไม่มีสิทธิ์แก้ไข'
      });
    }

    // Map report type from frontend format to database format
    const reportTypeMap = {
      'water': 'น้ำเสีย',
      'air': 'อากาศเสีย',
      'solid_waste': 'ขยะ',
      'chemical': 'สารเคมี',
      'noise': 'เสียงดัง',
      'oil_spill': 'น้ำมันรั่วไหล',
      'other': 'อื่นๆ'
    };
    const dbReportType = reportTypeMap[reportType] || reportType; // Allow pass-through if already in DB format

    // Handle photos array properly
    const photosArray = Array.isArray(photos) && photos.length > 0 ? photos : null;

    // Update report
    const result = await db.query(`
      UPDATE pollution_reports SET
        report_type = $1,
        pollution_source = $2,
        severity_level = $3,
        description = $4,
        latitude = $5,
        longitude = $6,
        report_date = $7,
        status = $8,
        photos = $9,
        updated_at = NOW()
      WHERE id = $10
      RETURNING *
    `, [
      dbReportType,
      pollutionSource,
      severityLevel,
      description,
      latitude || null,
      longitude || null,
      reportDate,
      status,
      photosArray,
      id
    ]);

    res.status(200).json({
      success: true,
      message: 'แก้ไขรายงานมลพิษสำเร็จ',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('❌ Update pollution report error:', error);
    next(error);
  }
});

// Delete pollution report
router.delete('/reports/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userEmail = req.user.email;

    // Check ownership
    const checkResult = await db.query(`
      SELECT pr.* FROM pollution_reports pr
      JOIN communities c ON pr.community_id = c.id
      WHERE pr.id = $1 AND c.email = $2
    `, [id, userEmail]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบข้อมูลหรือคุณไม่มีสิทธิ์ลบ'
      });
    }

    // Delete report
    await db.query('DELETE FROM pollution_reports WHERE id = $1', [id]);

    res.status(200).json({
      success: true,
      message: 'ลบรายงานมลพิษสำเร็จ'
    });

  } catch (error) {
    console.error('❌ Delete pollution report error:', error);
    next(error);
  }
});

module.exports = router;
