const express = require('express');
const { asyncHandler } = require('../middleware/errorHandler');

const router = express.Router();

// POST /api/upload
router.post('/', asyncHandler(async (req, res) => {
  // Placeholder — file upload handled separately if needed
  return res.status(501).json({ success: false, message: 'File upload not yet configured on this server' });
}));

module.exports = router;
