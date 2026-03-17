const express = require('express');

// Community group router - all routes require authentication
// URLs stay the same as before (mounted separately in server.js):
//   /api/community  → profile.js
//   /api/economic   → economic.js
//   /api/ecosystem  → ecosystem.js
//   /api/pollution  → pollution.js

module.exports = {
  profile:   require('./profile'),
  economic:  require('./economic'),
  ecosystem: require('./ecosystem'),
  pollution: require('./pollution'),
};
