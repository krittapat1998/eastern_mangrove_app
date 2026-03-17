// Error handling middleware
const errorHandler = (err, req, res, next) => {
  console.error('Error Stack:', err.stack);
  
  // Default error
  let error = {
    statusCode: err.statusCode || 500,
    message: err.message || 'Internal Server Error'
  };
  
  // PostgreSQL errors
  if (err.code) {
    switch (err.code) {
      case '23505': // Unique constraint violation
        if (err.constraint?.includes('email')) {
          error = {
            statusCode: 409,
            message: 'Email address already exists'
          };
        } else {
          error = {
            statusCode: 409,
            message: 'Duplicate entry detected'
          };
        }
        break;
      case '23503': // Foreign key violation
        error = {
          statusCode: 400,
          message: 'Referenced resource does not exist'
        };
        break;
      case '23514': // Check constraint violation
        error = {
          statusCode: 400,
          message: 'Data validation failed'
        };
        break;
      case '42P01': // Undefined table
        error = {
          statusCode: 500,
          message: process.env.NODE_ENV === 'development' ? 
            'Database table not found' : 'Internal server error'
        };
        break;
      default:
        error = {
          statusCode: 500,
          message: process.env.NODE_ENV === 'development' ? 
            `Database error: ${err.message}` : 'Database operation failed'
        };
    }
  }
  
  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error = {
      statusCode: 401,
      message: 'Invalid authentication token'
    };
  }
  
  if (err.name === 'TokenExpiredError') {
    error = {
      statusCode: 401,
      message: 'Authentication token has expired'
    };
  }
  
  // Validation errors
  if (err.name === 'ValidationError') {
    error = {
      statusCode: 400,
      message: 'Input validation failed',
      details: err.details
    };
  }
  
  // Rate limiting errors
  if (err.message && err.message.includes('Too many requests')) {
    error = {
      statusCode: 429,
      message: 'Too many requests, please try again later'
    };
  }
  
  res.status(error.statusCode).json({
    success: false,
    error: error.message,
    ...(error.details && { details: error.details }),
    ...(process.env.NODE_ENV === 'development' && { 
      stack: err.stack,
      originalError: err.message 
    })
  });
};

// Not found middleware
const notFound = (req, res, next) => {
  const error = new Error(`Route ${req.originalUrl} not found`);
  error.statusCode = 404;
  next(error);
};

module.exports = {
  errorHandler,
  notFound
};