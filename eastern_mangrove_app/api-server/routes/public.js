const express = require('express');
const { query, queryOne } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

const router = express.Router();
const SCHEMA = 'eastern_mangrove_communities';

// GET /api/public/statistics
router.get('/statistics', asyncHandler(async (req, res) => {
  const [commResult, pollResult] = await Promise.all([
    query(`SELECT COUNT(*) FROM ${SCHEMA}.communities WHERE registration_status = 'approved'`),
    query(`SELECT COUNT(*) FROM ${SCHEMA}.pollution_reports`),
  ]);

  return res.json({
    success: true,
    data: {
      approvedCommunities: parseInt(commResult.rows[0].count),
      totalPollutionReports: parseInt(pollResult.rows[0].count),
    },
  });
}));

// GET /api/public/areas
router.get('/areas', asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT id, community_name, location, province, district, coordinates, conservation_status, description
     FROM ${SCHEMA}.communities WHERE registration_status = 'approved' ORDER BY community_name`
  );
  return res.json({ success: true, data: result.rows });
}));

module.exports = router;
