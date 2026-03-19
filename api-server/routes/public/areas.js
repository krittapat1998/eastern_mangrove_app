const express = require('express');
const db = require('../../config/database');

const router = express.Router();

// Get all mangrove areas (public access)
router.get('/areas', async (req, res, next) => {
  try {
    const result = await db.query(`
      SELECT 
        ma.id,
        ma.area_name,
        ma.location,
        ma.province,
        ma.size_hectares,
        ma.mangrove_species,
        ma.conservation_status,
        ma.latitude,
        ma.longitude,
        ma.description,
        ma.established_year,
        ma.managing_organization,
        c.community_name,
        c.contact_person,
        c.phone_number,
        ma.created_at,
        ma.updated_at
      FROM mangrove_areas ma
      LEFT JOIN communities c ON ma.community_id = c.id
      WHERE c.registration_status = 'approved' OR ma.community_id IS NULL
      ORDER BY ma.province, ma.area_name
    `);

    res.status(200).json({
      success: true,
      message: 'ดึงข้อมูลพื้นที่ป่าชายเลนสำเร็จ',
      data: result.rows
    });

  } catch (error) {
    console.error('❌ Get mangrove areas error:', error);
    next(error);
  }
});

// Get statistics for public dashboard
router.get('/statistics', async (req, res, next) => {
  try {
    // Get community count
    const communitiesResult = await db.query(`
      SELECT COUNT(*) as total_communities
      FROM communities
      WHERE registration_status = 'approved'
    `);

    // Get total mangrove area
    const areasResult = await db.query(`
      SELECT 
        COUNT(*) as total_areas,
        COALESCE(SUM(size_hectares), 0) as total_hectares
      FROM mangrove_areas
    `);

    // Get total ecosystem services value (last 12 months)
    const servicesResult = await db.query(`
      SELECT COALESCE(SUM(economic_value), 0) as total_value
      FROM ecosystem_services
      WHERE created_at >= NOW() - INTERVAL '12 months'
    `);

    // Get pollution reports count
    const pollutionResult = await db.query(`
      SELECT 
        COUNT(*) as total_reports,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_reports
      FROM pollution_reports
      WHERE created_at >= NOW() - INTERVAL '12 months'
    `);

    // Get monthly visitor statistics (from ecosystem services)
    const visitorsResult = await db.query(`
      SELECT 
        year,
        month,
        SUM(beneficiaries_count) as visitor_count,
        SUM(economic_value) as revenue
      FROM ecosystem_services
      WHERE service_type IN ('ecotourism', 'education', 'recreation')
        AND year = EXTRACT(YEAR FROM NOW())
      GROUP BY year, month
      ORDER BY month DESC
      LIMIT 12
    `);

    res.status(200).json({
      success: true,
      message: 'ดึงสถิติสำเร็จ',
      data: {
        communities: {
          total: parseInt(communitiesResult.rows[0].total_communities)
        },
        mangroveAreas: {
          totalAreas: parseInt(areasResult.rows[0].total_areas),
          totalHectares: parseFloat(areasResult.rows[0].total_hectares)
        },
        ecosystemServices: {
          totalValue: parseFloat(servicesResult.rows[0].total_value)
        },
        pollution: {
          totalReports: parseInt(pollutionResult.rows[0].total_reports),
          resolvedReports: parseInt(pollutionResult.rows[0].resolved_reports)
        },
        monthlyVisitors: visitorsResult.rows
      }
    });

  } catch (error) {
    console.error('❌ Get statistics error:', error);
    next(error);
  }
});

// Get service summary for public (12 months data - all service types)
router.get('/service-summary', async (req, res, next) => {
  try {
    const result = await db.query(`
      SELECT 
        year,
        month,
        SUM(beneficiaries_count) as total_visitors,
        SUM(economic_value) as total_revenue,
        COUNT(*) as service_count,
        COUNT(DISTINCT community_id) as active_communities
      FROM ecosystem_services
      WHERE MAKE_DATE(year, month, 1) >= DATE_TRUNC('month', NOW() - INTERVAL '11 months')
        AND MAKE_DATE(year, month, 1) <= DATE_TRUNC('month', NOW())
      GROUP BY year, month
      ORDER BY year ASC, month ASC
    `);

    res.status(200).json({
      success: true,
      message: 'ดึงสรุปการให้บริการสำเร็จ',
      data: result.rows
    });

  } catch (error) {
    console.error('❌ Get service summary error:', error);
    next(error);
  }
});

// Get service breakdown by type per month (12 months)
router.get('/service-breakdown', async (req, res, next) => {
  try {
    const result = await db.query(`
      SELECT
        year,
        month,
        service_type,
        SUM(beneficiaries_count) as visitors,
        SUM(economic_value) as revenue,
        COUNT(*) as count
      FROM ecosystem_services
      WHERE MAKE_DATE(year, month, 1) >= DATE_TRUNC('month', NOW() - INTERVAL '11 months')
        AND MAKE_DATE(year, month, 1) <= DATE_TRUNC('month', NOW())
      GROUP BY year, month, service_type
      ORDER BY year ASC, month ASC, revenue DESC
    `);

    res.status(200).json({
      success: true,
      message: 'ดึงข้อมูลรายละเอียดบริการสำเร็จ',
      data: result.rows
    });

  } catch (error) {
    console.error('❌ Get service breakdown error:', error);
    next(error);
  }
});

module.exports = router;
