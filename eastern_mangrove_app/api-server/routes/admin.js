const express = require('express');
const { query, queryOne } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');

const router = express.Router();
const SCHEMA = 'eastern_mangrove_communities';

// Middleware: admin only
function adminOnly(req, res, next) {
  if (req.user?.user_type !== 'admin') {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  next();
}

router.use(adminOnly);

// GET /api/admin/dashboard/stats
router.get('/dashboard/stats', asyncHandler(async (req, res) => {
  const [usersResult, commResult, pendingResult, pollResult] = await Promise.all([
    query(`SELECT COUNT(*) FROM ${SCHEMA}.users`),
    query(`SELECT COUNT(*) FROM ${SCHEMA}.communities WHERE registration_status = 'approved'`),
    query(`SELECT COUNT(*) FROM ${SCHEMA}.communities WHERE registration_status = 'pending'`),
    query(`SELECT COUNT(*) FROM ${SCHEMA}.pollution_reports WHERE status = 'reported'`),
  ]);

  return res.json({
    success: true,
    data: {
      totalUsers: parseInt(usersResult.rows[0].count),
      approvedCommunities: parseInt(commResult.rows[0].count),
      pendingCommunities: parseInt(pendingResult.rows[0].count),
      openPollutionReports: parseInt(pollResult.rows[0].count),
    },
  });
}));

// GET /api/admin/communities/pending
router.get('/communities/pending', asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT * FROM ${SCHEMA}.communities WHERE registration_status = 'pending' ORDER BY created_at ASC`
  );
  return res.json({ success: true, data: result.rows });
}));

// GET /api/admin/communities
router.get('/communities', asyncHandler(async (req, res) => {
  const { status, page = 1, limit = 20 } = req.query;
  const offset = (parseInt(page) - 1) * parseInt(limit);

  let whereClause = '';
  const params = [parseInt(limit), offset];
  if (status) {
    whereClause = 'WHERE registration_status = $3';
    params.push(status);
  }

  const result = await query(
    `SELECT * FROM ${SCHEMA}.communities ${whereClause} ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
    params
  );
  return res.json({ success: true, data: result.rows });
}));

// GET /api/admin/users
router.get('/users', asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT id, email, first_name, last_name, user_type, is_active, is_approved, created_at
     FROM ${SCHEMA}.users ORDER BY created_at DESC`
  );
  return res.json({ success: true, data: result.rows });
}));

// POST /api/admin/communities/:communityId/approve
router.post('/communities/:communityId/approve', asyncHandler(async (req, res) => {
  const { communityId } = req.params;
  const updated = await queryOne(
    `UPDATE ${SCHEMA}.communities SET registration_status = 'approved', approved_by = $1, approved_at = NOW()
     WHERE id = $2 RETURNING *`,
    [req.user.id, communityId]
  );
  if (!updated) return res.status(404).json({ success: false, message: 'Community not found' });

  // Also approve the linked user account
  await query(
    `UPDATE ${SCHEMA}.users SET is_approved = true WHERE email = $1`,
    [updated.email]
  );

  return res.json({ success: true, message: 'Community approved', data: updated });
}));

// POST /api/admin/communities/:communityId/reject
router.post('/communities/:communityId/reject', asyncHandler(async (req, res) => {
  const { communityId } = req.params;
  const { reason } = req.body;
  const updated = await queryOne(
    `UPDATE ${SCHEMA}.communities SET registration_status = 'rejected', rejected_by = $1, rejected_at = NOW(), rejection_reason = $2
     WHERE id = $3 RETURNING *`,
    [req.user.id, reason || null, communityId]
  );
  if (!updated) return res.status(404).json({ success: false, message: 'Community not found' });
  return res.json({ success: true, message: 'Community rejected', data: updated });
}));

// POST /api/admin/communities/:communityId/toggle-status
router.post('/communities/:communityId/toggle-status', asyncHandler(async (req, res) => {
  const { communityId } = req.params;
  const community = await queryOne(`SELECT * FROM ${SCHEMA}.communities WHERE id = $1`, [communityId]);
  if (!community) return res.status(404).json({ success: false, message: 'Community not found' });

  const newStatus = community.registration_status === 'approved' ? 'rejected' : 'approved';
  const updated = await queryOne(
    `UPDATE ${SCHEMA}.communities SET registration_status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
    [newStatus, communityId]
  );
  return res.json({ success: true, message: `Community status set to ${newStatus}`, data: updated });
}));

// GET /api/admin/actions
router.get('/actions', asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT * FROM ${SCHEMA}.activity_logs ORDER BY created_at DESC LIMIT 100`
  );
  return res.json({ success: true, data: result.rows });
}));

// POST /api/admin/users/:userId/reset-password
router.post('/users/:userId/reset-password', asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { newPassword } = req.body;
  if (!newPassword) return res.status(400).json({ success: false, message: 'New password required' });

  const bcrypt = require('bcrypt');
  const hash = await bcrypt.hash(newPassword, 12);
  await query(`UPDATE ${SCHEMA}.users SET password_hash = $1 WHERE id = $2`, [hash, userId]);
  return res.json({ success: true, message: 'Password reset successfully' });
}));

// GET /api/admin/communities (with check-duplicate support via query)
router.get('/communities/check-duplicate', asyncHandler(async (req, res) => {
  const { name, email } = req.query;
  const existing = await queryOne(
    `SELECT id FROM ${SCHEMA}.communities WHERE community_name = $1 OR email = $2`,
    [name, email]
  );
  return res.json({ success: true, isDuplicate: !!existing });
}));

// GET /api/admin/communities/:communityId
router.get('/communities/:communityId', asyncHandler(async (req, res) => {
  const { communityId } = req.params;
  const community = await queryOne(`SELECT * FROM ${SCHEMA}.communities WHERE id = $1`, [communityId]);
  if (!community) return res.status(404).json({ success: false, message: 'Community not found' });
  return res.json({ success: true, data: community });
}));

// PUT /api/admin/communities/:communityId
router.put('/communities/:communityId', asyncHandler(async (req, res) => {
  const { communityId } = req.params;
  const { communityName, description, conservationStatus } = req.body;
  const updated = await queryOne(
    `UPDATE ${SCHEMA}.communities SET
       community_name = COALESCE($1, community_name),
       description = COALESCE($2, description),
       conservation_status = COALESCE($3, conservation_status),
       updated_at = NOW()
     WHERE id = $4 RETURNING *`,
    [communityName, description, conservationStatus, communityId]
  );
  if (!updated) return res.status(404).json({ success: false, message: 'Community not found' });
  return res.json({ success: true, data: updated });
}));

// DELETE /api/admin/communities/:communityId
router.delete('/communities/:communityId', asyncHandler(async (req, res) => {
  const { communityId } = req.params;
  await query(`DELETE FROM ${SCHEMA}.communities WHERE id = $1`, [communityId]);
  return res.json({ success: true, message: 'Community deleted' });
}));

module.exports = router;
