// Custom error classes
class AppError extends Error {
  constructor(message, statusCode, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;

    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message, errors = []) {
    super(message, 400);
    this.errors = errors;
  }
}

class NotFoundError extends AppError {
  constructor(resource) {
    super(`${resource} not found`, 404);
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized access') {
    super(message, 401);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Access forbidden') {
    super(message, 403);
  }
}

// Error handler middleware
function errorHandler(err, req, res, next) {
  // Default to 500 server error
  let { statusCode = 500, message } = err;

  // Log error details (in production, use proper logging service)
  if (process.env.NODE_ENV === 'development') {
    console.error('Error Details:', {
      message: err.message,
      stack: err.stack,
      url: req.originalUrl,
      method: req.method,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      body: req.body,
      params: req.params,
      query: req.query
    });
  } else {
    console.error('Error:', {
      message: err.message,
      statusCode,
      url: req.originalUrl,
      method: req.method,
      ip: req.ip
    });
  }

  // Handle specific error types
  if (err.name === 'CastError') {
    statusCode = 400;
    message = 'Invalid ID format';
  }

  if (err.code === '23505') { // PostgreSQL unique violation
    statusCode = 409;
    message = 'Resource already exists';
  }

  if (err.code === '23503') { // PostgreSQL foreign key violation
    statusCode = 400;
    message = 'Referenced resource does not exist';
  }

  if (err.code === '23502') { // PostgreSQL not null violation
    statusCode = 400;
    message = 'Required field is missing';
  }

  if (err.code === '42P01') { // PostgreSQL table does not exist
    statusCode = 500;
    message = 'Database configuration error';
  }

  // Handle validation errors
  if (err instanceof ValidationError) {
    return res.status(statusCode).json({
      error: 'Validation failed',
      message: err.message,
      errors: err.errors,
      timestamp: new Date().toISOString(),
      path: req.originalUrl
    });
  }

  // Handle operational errors
  if (err.isOperational) {
    return res.status(statusCode).json({
      error: err.constructor.name.replace('Error', '').toLowerCase(),
      message,
      timestamp: new Date().toISOString(),
      path: req.originalUrl
    });
  }

  // Handle programming errors and unknown errors
  if (process.env.NODE_ENV === 'production') {
    message = 'Something went wrong!';
  }

  return res.status(statusCode).json({
    error: 'server_error',
    message,
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}

// Async wrapper to catch errors
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// 404 handler
function notFound(req, res, next) {
  const error = new NotFoundError(`Route ${req.originalUrl} not found`);
  next(error);
}

module.exports = {
  AppError,
  ValidationError,
  NotFoundError,
  UnauthorizedError,
  ForbiddenError,
  errorHandler,
  asyncHandler,
  notFound
};