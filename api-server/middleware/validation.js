const Joi = require('joi');

// Validation schemas
const schemas = {
  // User registration validation
  userRegistration: Joi.object({
    email: Joi.string().email().required().messages({
      'string.email': 'Please provide a valid email address',
      'any.required': 'Email is required'
    }),
    password: Joi.string().min(6).required().messages({
      'string.min': 'Password must be at least 6 characters long',
      'any.required': 'Password is required'
    }),
    firstName: Joi.string().min(2).max(50).required().messages({
      'string.min': 'First name must be at least 2 characters long',
      'string.max': 'First name cannot exceed 50 characters',
      'any.required': 'First name is required'
    }),
    lastName: Joi.string().min(2).max(50).required().messages({
      'string.min': 'Last name must be at least 2 characters long',
      'string.max': 'Last name cannot exceed 50 characters',
      'any.required': 'Last name is required'
    }),
    userType: Joi.string().valid('admin', 'community', 'public').required().messages({
      'any.only': 'User type must be admin, community, or public',
      'any.required': 'User type is required'
    }),
    phoneNumber: Joi.string().pattern(/^[0-9+\-\s()]+$/).optional().messages({
      'string.pattern.base': 'Please provide a valid phone number'
    })
  }),

  // User login validation
  userLogin: Joi.object({
    email: Joi.string().email().required().messages({
      'string.email': 'Please provide a valid email address',
      'any.required': 'Email is required'
    }),
    password: Joi.string().required().messages({
      'any.required': 'Password is required'
    })
  }),

  // Community registration validation
  communityRegistration: Joi.object({
    communityName: Joi.string().min(3).max(100).required().messages({
      'string.min': 'Community name must be at least 3 characters long',
      'string.max': 'Community name cannot exceed 100 characters',
      'any.required': 'Community name is required'
    }),
    location: Joi.string().min(5).max(200).required().messages({
      'string.min': 'Location must be at least 5 characters long',
      'string.max': 'Location cannot exceed 200 characters',
      'any.required': 'Location is required'
    }),
    contactPerson: Joi.string().min(2).max(100).required().messages({
      'string.min': 'Contact person must be at least 2 characters long',
      'string.max': 'Contact person cannot exceed 100 characters',
      'any.required': 'Contact person is required'
    }),
    phoneNumber: Joi.string().pattern(/^[0-9+\-\s()]+$/).required().messages({
      'string.pattern.base': 'Please provide a valid phone number',
      'any.required': 'Phone number is required'
    }),
    email: Joi.string().email().required().messages({
      'string.email': 'Please provide a valid email address',
      'any.required': 'Email is required'
    }),
    password: Joi.string().min(8).required().messages({
      'string.min': 'Password must be at least 8 characters long',
      'any.required': 'Password is required'
    }),
    description: Joi.string().max(500).optional().messages({
      'string.max': 'Description cannot exceed 500 characters'
    }),
    establishedYear: Joi.number().integer().min(1900).max(new Date().getFullYear()).optional().messages({
      'number.min': 'Established year cannot be before 1900',
      'number.max': 'Established year cannot be in the future'
    }),
    memberCount: Joi.number().integer().min(1).optional().messages({
      'number.min': 'Member count must be at least 1'
    }),
    photoType: Joi.string().valid('profile', 'community', 'activity', 'mangrove').optional().messages({
      'any.only': 'Photo type must be profile, community, activity, or mangrove'
    })
  })
};

// Validation middleware factory
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Please check your input data',
        details: errors
      });
    }
    
    next();
  };
};

// Export validation middleware
module.exports = {
  validate,
  schemas
};