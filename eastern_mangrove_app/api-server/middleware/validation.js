const { body, param, query, validationResult } = require('express-validator');
const { ValidationError } = require('./errorHandler');

// Helper function to handle validation results
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(error => ({
      field: error.path,
      message: error.msg,
      value: error.value
    }));
    
    throw new ValidationError('Validation failed', formattedErrors);
  }
  
  next();
}

// User validation rules
const userValidation = {
  register: [
    body('username')
      .isLength({ min: 3, max: 50 })
      .withMessage('Username must be between 3 and 50 characters')
      .matches(/^[a-zA-Z0-9_]+$/)
      .withMessage('Username can only contain letters, numbers, and underscores'),
    
    body('email')
      .isEmail()
      .withMessage('Please provide a valid email address')
      .normalizeEmail(),
    
    body('password')
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters long')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
    
    body('user_type')
      .isIn(['admin', 'community', 'public'])
      .withMessage('User type must be admin, community, or public'),
    
    handleValidationErrors
  ],

  login: [
    body('username')
      .notEmpty()
      .withMessage('Username is required'),
    
    body('password')
      .notEmpty()
      .withMessage('Password is required'),
    
    handleValidationErrors
  ]
};

// Community validation rules
const communityValidation = {
  register: [
    body('community_name')
      .isLength({ min: 3, max: 255 })
      .withMessage('Community name must be between 3 and 255 characters'),
    
    body('village_name')
      .optional()
      .isLength({ max: 255 })
      .withMessage('Village name must not exceed 255 characters'),
    
    body('sub_district')
      .optional()
      .isLength({ max: 255 })
      .withMessage('Sub-district must not exceed 255 characters'),
    
    body('district')
      .optional()
      .isLength({ max: 255 })
      .withMessage('District must not exceed 255 characters'),
    
    body('province')
      .isIn(['ระเอง', 'สัตหีบ', 'ระยอง', 'จันทบุรี', 'ตราด'])
      .withMessage('Province must be one of: ระเอง, สัตหีบ, ระยอง, จันทบุรี, ตราด'),
    
    body('contact_person')
      .isLength({ min: 2, max: 255 })
      .withMessage('Contact person name must be between 2 and 255 characters'),
    
    body('phone')
      .matches(/^[0-9-+().\s]+$/)
      .withMessage('Please provide a valid phone number'),
    
    body('email')
      .isEmail()
      .withMessage('Please provide a valid email address')
      .normalizeEmail(),
    
    body('description')
      .optional()
      .isLength({ max: 1000 })
      .withMessage('Description must not exceed 1000 characters'),
    
    body('latitude')
      .optional()
      .isFloat({ min: -90, max: 90 })
      .withMessage('Latitude must be between -90 and 90'),
    
    body('longitude')
      .optional()
      .isFloat({ min: -180, max: 180 })
      .withMessage('Longitude must be between -180 and 180'),
    
    handleValidationErrors
  ],

  update: [
    body('community_name')
      .optional()
      .isLength({ min: 3, max: 255 })
      .withMessage('Community name must be between 3 and 255 characters'),
    
    body('contact_person')
      .optional()
      .isLength({ min: 2, max: 255 })
      .withMessage('Contact person name must be between 2 and 255 characters'),
    
    body('phone')
      .optional()
      .matches(/^[0-9-+().\s]+$/)
      .withMessage('Please provide a valid phone number'),
    
    body('description')
      .optional()
      .isLength({ max: 1000 })
      .withMessage('Description must not exceed 1000 characters'),
    
    handleValidationErrors
  ]
};

// Economic data validation rules
const economicDataValidation = {
  create: [
    body('year')
      .isInt({ min: 2020, max: new Date().getFullYear() + 1 })
      .withMessage(`Year must be between 2020 and ${new Date().getFullYear() + 1}`),
    
    body('quarter')
      .isInt({ min: 1, max: 4 })
      .withMessage('Quarter must be between 1 and 4'),
    
    body('income_fishery')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Fishery income must be a positive number'),
    
    body('income_tourism')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Tourism income must be a positive number'),
    
    body('income_agriculture')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Agriculture income must be a positive number'),
    
    body('income_others')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Other income must be a positive number'),
    
    body('employment_count')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Employment count must be a positive integer'),
    
    handleValidationErrors
  ]
};

// Pollution report validation rules
const pollutionReportValidation = {
  create: [
    body('report_type')
      .isIn(['Water Pollution', 'Air Pollution', 'Solid Waste', 'Chemical Pollution', 'Noise Pollution', 'Oil Spill'])
      .withMessage('Invalid report type'),
    
    body('pollution_source')
      .isLength({ min: 3, max: 255 })
      .withMessage('Pollution source must be between 3 and 255 characters'),
    
    body('severity_level')
      .isIn(['low', 'medium', 'high', 'critical'])
      .withMessage('Severity level must be low, medium, high, or critical'),
    
    body('description')
      .isLength({ min: 10, max: 1000 })
      .withMessage('Description must be between 10 and 1000 characters'),
    
    body('latitude')
      .optional()
      .isFloat({ min: -90, max: 90 })
      .withMessage('Latitude must be between -90 and 90'),
    
    body('longitude')
      .optional()
      .isFloat({ min: -180, max: 180 })
      .withMessage('Longitude must be between -180 and 180'),
    
    body('report_date')
      .isISO8601()
      .withMessage('Report date must be a valid date'),
    
    handleValidationErrors
  ]
};

// Parameter validation
const paramValidation = {
  id: [
    param('id')
      .isInt({ min: 1 })
      .withMessage('ID must be a positive integer'),
    
    handleValidationErrors
  ]
};

// Query validation
const queryValidation = {
  pagination: [
    query('page')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Page must be a positive integer'),
    
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100'),
    
    handleValidationErrors
  ]
};

module.exports = {
  userValidation,
  communityValidation,
  economicDataValidation,
  pollutionReportValidation,
  paramValidation,
  queryValidation,
  handleValidationErrors
};