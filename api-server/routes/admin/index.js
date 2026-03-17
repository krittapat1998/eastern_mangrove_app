const express = require('express');
const router = express.Router();
const { authenticateToken, requireAdmin } = require('../../middleware/auth');

// Apply authentication and admin requirement to all admin routes
router.use(authenticateToken);
router.use(requireAdmin);

// Mount sub-routes
router.use('/', require('./dashboard'));       // GET /admin/dashboard/stats
router.use('/', require('./communities'));     // GET|POST|PUT|DELETE /admin/communities
router.use('/', require('./users'));           // GET|PUT /admin/users + /admin/actions
router.use('/', require('./mangrove-areas')); // GET|POST|PUT|DELETE /admin/mangrove-areas

module.exports = router;
