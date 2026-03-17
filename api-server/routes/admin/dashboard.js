const express = require('express');
const router = express.Router();
const db = require('../../config/database');

// GET /admin/dashboard/stats - Dashboard statistics
router.get('/dashboard/stats', async (req, res) => {
  try {
    // Get total communities by status
    const communitiesStats = await db.query(`
      SELECT 
        registration_status,
        COUNT(*) as count
      FROM communities
      GROUP BY registration_status
    `);

    // Get total users by type
    const usersStats = await db.query(`
      SELECT 
        user_type,
        is_active,
        COUNT(*) as count
      FROM users
      GROUP BY user_type, is_active
    `);

    // Get recent registrations (last 30 days)
    const recentRegistrations = await db.query(`
      SELECT COUNT(*) as count
      FROM communities
      WHERE created_at >= NOW() - INTERVAL '30 days'
    `);

    // Get total pollution reports
    const pollutionStats = await db.query(`
      SELECT 
        status,
        COUNT(*) as count
      FROM pollution_reports
      GROUP BY status
    `);

    // Format the response
    const stats = {
      communities: {
        total: 0,
        pending: 0,
        approved: 0,
        rejected: 0
      },
      users: {
        total: 0,
        active: 0,
        inactive: 0,
        byType: {}
      },
      recentRegistrations: parseInt(recentRegistrations.rows[0]?.count || 0),
      pollutionReports: {
        total: 0,
        byStatus: {}
      }
    };

    // Process community stats
    communitiesStats.rows.forEach(row => {
      stats.communities[row.registration_status] = parseInt(row.count);
      stats.communities.total += parseInt(row.count);
    });

    // Process user stats
    usersStats.rows.forEach(row => {
      const count = parseInt(row.count);
      stats.users.total += count;
      
      if (row.is_active) {
        stats.users.active += count;
      } else {
        stats.users.inactive += count;
      }

      if (!stats.users.byType[row.user_type]) {
        stats.users.byType[row.user_type] = 0;
      }
      stats.users.byType[row.user_type] += count;
    });

    // Process pollution report stats
    pollutionStats.rows.forEach(row => {
      stats.pollutionReports.byStatus[row.status] = parseInt(row.count);
      stats.pollutionReports.total += parseInt(row.count);
    });

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({
      success: false,
      error: 'Database error',
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูลสถิติ'
    });
  }
});

module.exports = router;
