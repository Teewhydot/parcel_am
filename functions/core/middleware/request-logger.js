// ========================================================================
// Request Logger Middleware
// ========================================================================

const { logger } = require('../../utils/logger');

/**
 * Request logging middleware
 */
class RequestLogger {
  /**
   * Log incoming request details
   * @param {Request} req - Express request object
   * @param {string} executionId - Execution ID for tracking
   */
  logRequest(req, executionId) {
    const logData = {
      method: req.method,
      path: req.path,
      query: Object.keys(req.query || {}).length > 0 ? req.query : undefined,
      bodyKeys: req.body ? Object.keys(req.body) : [],
      hasAuth: !!req.headers.authorization,
      ip: req.ip || req.headers['x-forwarded-for']
    };

    logger.info('Incoming request', executionId, logData);
  }

  /**
   * Log response details
   * @param {number} statusCode - HTTP status code
   * @param {number} duration - Request duration in ms
   * @param {string} executionId - Execution ID for tracking
   */
  logResponse(statusCode, duration, executionId) {
    const logData = {
      statusCode,
      duration: `${duration}ms`
    };

    if (statusCode >= 400) {
      logger.warning('Request completed with error', executionId, logData);
    } else {
      logger.success('Request completed successfully', executionId, logData);
    }
  }

  /**
   * Create a timer for measuring request duration
   * @returns {Function} Function that returns elapsed time in ms
   */
  startTimer() {
    const start = Date.now();
    return () => Date.now() - start;
  }
}

const requestLogger = new RequestLogger();

module.exports = { RequestLogger, requestLogger };
