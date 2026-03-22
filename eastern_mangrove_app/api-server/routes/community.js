const express = require('express');
const { query, queryOne } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

const router = express.Router();
const SCHEMA = 'eastern_mangrove_communities';

// GET /api/community/profile
router.get('/profile', asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const community = await queryOne(
    `SELECT * FROM ${SCHEMA}.communities 
     WHERE email = (SELECT email FROM ${SCHEMA}.users WHERE id = $1)`,
    [userId]
  );

  if (!community) {
    return res.status(404).json({ success: false, message: 'Community profile not found' });
  }

  return res.json({ success: true, data: community });
}));

// PUT /api/community/profile
router.put('/profile', asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    communityName, location, contactPerson, phoneNumber,
    description, establishedYear, memberCount, websiteUrl,
    villageName, subDistrict, district, province,
    conservationStatus,
  } = req.body;

  const userEmail = (await queryOne(`SELECT email FROM ${SCHEMA}.users WHERE id = $1`, [userId]))?.email;

  const updated = await queryOne(
    `UPDATE ${SCHEMA}.communities SET
       community_name = COALESCE($1, community_name),
       location = COALESCE($2, location),
       contact_person = COALESCE($3, contact_person),
       phone_number = COALESCE($4, phone_number),
       description = COALESCE($5, description),
       established_year = COALESCE($6, established_year),
       member_count = COALESCE($7, member_count),
       website_url = COALESCE($8, website_url),
       village_name = COALESCE($9, village_name),
       sub_district = COALESCE($10, sub_district),
       district = COALESCE($11, district),
       province = COALESCE($12, province),
       conservation_status = COALESCE($13, conservation_status),
       updated_at = NOW()
     WHERE email = $14 RETURNING *`,
    [communityName, location, contactPerson, phoneNumber, description,
     establishedYear, memberCount, websiteUrl, villageName, subDistrict,
     district, province, conservationStatus, userEmail]
  );

  return res.json({ success: true, message: 'Community profile updated', data: updated });
}));

// GET /api/community/economic-data
router.get('/economic-data', asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const userEmail = (await queryOne(`SELECT email FROM ${SCHEMA}.users WHERE id = $1`, [userId]))?.email;
  const community = await queryOne(`SELECT id FROM ${SCHEMA}.communities WHERE email = $1`, [userEmail]);

  if (!community) {
    return res.json({ success: true, economic_data: [] });
  }

  const result = await query(
    `SELECT * FROM ${SCHEMA}.economic_data WHERE community_id = $1 ORDER BY year DESC, quarter DESC`,
    [community.id]
  );

  return res.json({ success: true, economic_data: result.rows });
}));

// GET /api/community/pollution-reports
router.get('/pollution-reports', asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const userEmail = (await queryOne(`SELECT email FROM ${SCHEMA}.users WHERE id = $1`, [userId]))?.email;
  const community = await queryOne(`SELECT id FROM ${SCHEMA}.communities WHERE email = $1`, [userEmail]);

  if (!community) {
    return res.json({ success: true, reports: [] });
  }

  const result = await query(
    `SELECT * FROM ${SCHEMA}.pollution_reports WHERE community_id = $1 ORDER BY report_date DESC`,
    [community.id]
  );

  return res.json({ success: true, reports: result.rows });
}));

module.exports = router;
