// ========================================================================
// Middleware Barrel Export
// ========================================================================

const { corsHandler } = require('./cors-handler');
const {
  ErrorHandler,
  errorHandler,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  RateLimitError,
  BadRequestError
} = require('./error-handler');
const { AuthMiddleware, authMiddleware } = require('./auth-middleware');
const { RequestLogger, requestLogger } = require('./request-logger');

module.exports = {
  // CORS
  corsHandler,

  // Error handling
  ErrorHandler,
  errorHandler,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  RateLimitError,
  BadRequestError,

  // Authentication
  AuthMiddleware,
  authMiddleware,

  // Logging
  RequestLogger,
  requestLogger
};
