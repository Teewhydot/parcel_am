// ========================================================================
// Centralized Error Handler Middleware
// ========================================================================

const { logger } = require('../../utils/logger');
const { ValidationError } = require('../../utils/validation');

/**
 * Custom error classes for different error types
 */
class AuthenticationError extends Error {
  constructor(message = 'Authentication required') {
    super(message);
    this.name = 'AuthenticationError';
    this.statusCode = 401;
  }
}

class AuthorizationError extends Error {
  constructor(message = 'Access denied') {
    super(message);
    this.name = 'AuthorizationError';
    this.statusCode = 403;
  }
}

class NotFoundError extends Error {
  constructor(message = 'Resource not found') {
    super(message);
    this.name = 'NotFoundError';
    this.statusCode = 404;
  }
}

class RateLimitError extends Error {
  constructor(message = 'Rate limit exceeded', retryAfter = 60) {
    super(message);
    this.name = 'RateLimitError';
    this.statusCode = 429;
    this.retryAfter = retryAfter;
  }
}

class BadRequestError extends Error {
  constructor(message = 'Bad request') {
    super(message);
    this.name = 'BadRequestError';
    this.statusCode = 400;
  }
}

/**
 * Error handler that sends appropriate HTTP responses
 */
class ErrorHandler {
  /**
   * Handle an error and send HTTP response
   * @param {Error} error - The error to handle
   * @param {Response} res - Express response object
   * @param {string} executionId - Execution ID for logging
   */
  handle(error, res, executionId) {
    logger.error('Request failed', executionId, error);

    // Validation errors
    if (error instanceof ValidationError) {
      return res.status(400).json({
        success: false,
        error: 'Validation Error',
        message: error.message,
        field: error.field || null
      });
    }

    // Authentication errors
    if (error instanceof AuthenticationError) {
      return res.status(401).json({
        success: false,
        error: 'Authentication Required',
        message: error.message
      });
    }

    // Authorization errors
    if (error instanceof AuthorizationError) {
      return res.status(403).json({
        success: false,
        error: 'Access Denied',
        message: error.message
      });
    }

    // Not found errors
    if (error instanceof NotFoundError) {
      return res.status(404).json({
        success: false,
        error: 'Not Found',
        message: error.message
      });
    }

    // Rate limit errors
    if (error instanceof RateLimitError) {
      return res.status(429).json({
        success: false,
        error: 'Rate Limit Exceeded',
        message: error.message,
        retryAfter: error.retryAfter
      });
    }

    // Bad request errors
    if (error instanceof BadRequestError) {
      return res.status(400).json({
        success: false,
        error: 'Bad Request',
        message: error.message
      });
    }

    // Handle errors with custom statusCode property
    if (error.statusCode && typeof error.statusCode === 'number') {
      return res.status(error.statusCode).json({
        success: false,
        error: error.name || 'Error',
        message: error.message
      });
    }

    // Default: Internal Server Error
    const isProduction = process.env.NODE_ENV === 'production';
    return res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: isProduction ? 'An unexpected error occurred' : error.message
    });
  }
}

const errorHandler = new ErrorHandler();

module.exports = {
  ErrorHandler,
  errorHandler,
  // Export error classes for use in endpoints
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  RateLimitError,
  BadRequestError
};
