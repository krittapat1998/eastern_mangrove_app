const jwt = require('jsonwebtoken');
const { queryOne } = require('../config/database');

// Middleware to authenticate JWT tokens
async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      error: 'Access token required',
      message: 'Please provide a valid authentication token'
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Verify user still exists and is active
    const user = await queryOne(
      'SELECT id, username, email, user_type, is_active, is_approved FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (!user) {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'User not found'
      });
    }

    if (!user.is_active) {
      return res.status(401).json({
        error: 'Account deactivated',
        message: 'Your account has been deactivated'
      });
    }

    if (user.user_type !== 'admin' && !user.is_approved) {
      return res.status(401).json({
        error: 'Account not approved',
        message: 'Your account is pending approval'
      });
    }

    // Add user info to request object
    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'The provided token is invalid'
      });
    } else if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expired',
        message: 'The provided token has expired'
      });
    } else {
      console.error('Authentication error:', err);
      return res.status(500).json({
        error: 'Authentication error',
        message: 'An error occurred during authentication'
      });
    }
  }
}

// Middleware to check user roles
function requireRole(roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'Please authenticate first'
      });
    }

    // Convert single role to array
    const allowedRoles = Array.isArray(roles) ? roles : [roles];

    if (!allowedRoles.includes(req.user.user_type)) {
      return res.status(403).json({
        error: 'Insufficient permissions',
        message: `Access denied. Required role(s): ${allowedRoles.join(', ')}`
      });
    }

    next();
  };
}

// Middleware to check if user is admin
function requireAdmin(req, res, next) {
  return requireRole('admin')(req, res, next);
}

// Middleware to check if user is community
function requireCommunity(req, res, next) {
  return requireRole('community')(req, res, next);
}

// Middleware to check if user is community or admin
function requireCommunityOrAdmin(req, res, next) {
  return requireRole(['community', 'admin'])(req, res, next);
}

// Middleware to check if user owns the resource or is admin
async function requireOwnershipOrAdmin(resourceType) {
  return async (req, res, next) => {
    try {
      // Admin can access everything
      if (req.user.user_type === 'admin') {
        return next();
      }

      const resourceId = req.params.id || req.params.communityId;
      
      if (!resourceId) {
        return res.status(400).json({
          error: 'Bad request',
          message: 'Resource ID is required'
        });
      }

      let ownershipQuery;
      let queryParams;

      switch (resourceType) {
        case 'community':
          // Check if community belongs to user
          ownershipQuery = 'SELECT user_id FROM communities WHERE id = $1';
          queryParams = [resourceId];
          break;
        case 'economic_data':
          ownershipQuery = `
            SELECT c.user_id 
            FROM economic_data ed 
            JOIN communities c ON ed.community_id = c.id 
            WHERE ed.id = $1
          `;
          queryParams = [resourceId];
          break;
        case 'pollution_report':
          ownershipQuery = `
            SELECT c.user_id 
            FROM pollution_reports pr 
            JOIN communities c ON pr.community_id = c.id 
            WHERE pr.id = $1
          `;
          queryParams = [resourceId];
          break;
        default:
          return res.status(500).json({
            error: 'Server error',
            message: 'Invalid resource type'
          });
      }

      const result = await queryOne(ownershipQuery, queryParams);

      if (!result) {
        return res.status(404).json({
          error: 'Resource not found',
          message: 'The requested resource does not exist'
        });
      }

      if (result.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'Access denied',
          message: 'You do not have permission to access this resource'
        });
      }

      next();
    } catch (err) {
      console.error('Ownership check error:', err);
      return res.status(500).json({
        error: 'Server error',
        message: 'An error occurred while checking resource ownership'
      });
    }
  };
}

module.exports = {
  authenticateToken,
  requireRole,
  requireAdmin,
  requireCommunity,
  requireCommunityOrAdmin,
  requireOwnershipOrAdmin
};