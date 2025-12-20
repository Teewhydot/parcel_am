// ========================================================================
// Standardized Response Builder
// ========================================================================

/**
 * Builder for standardized HTTP responses
 */
class ResponseBuilder {
  /**
   * Send a success response
   * @param {Response} res - Express response object
   * @param {object} data - Response data
   * @param {number} statusCode - HTTP status code (default: 200)
   */
  success(res, data = {}, statusCode = 200) {
    return res.status(statusCode).json({
      success: true,
      ...data
    });
  }

  /**
   * Send a created response (201)
   * @param {Response} res - Express response object
   * @param {object} data - Response data
   */
  created(res, data = {}) {
    return this.success(res, data, 201);
  }

  /**
   * Send a no content response (204)
   * @param {Response} res - Express response object
   */
  noContent(res) {
    return res.status(204).send();
  }

  /**
   * Send an accepted response (202) for async operations
   * @param {Response} res - Express response object
   * @param {object} data - Response data
   */
  accepted(res, data = {}) {
    return this.success(res, data, 202);
  }

  /**
   * Send an error response
   * @param {Response} res - Express response object
   * @param {string} message - Error message
   * @param {number} statusCode - HTTP status code (default: 400)
   * @param {object} details - Additional error details
   */
  error(res, message, statusCode = 400, details = null) {
    const response = {
      success: false,
      error: message
    };

    if (details) {
      response.details = details;
    }

    return res.status(statusCode).json(response);
  }

  /**
   * Send a bad request error (400)
   * @param {Response} res - Express response object
   * @param {string} message - Error message
   */
  badRequest(res, message = 'Bad request') {
    return this.error(res, message, 400);
  }

  /**
   * Send an unauthorized error (401)
   * @param {Response} res - Express response object
   * @param {string} message - Error message
   */
  unauthorized(res, message = 'Unauthorized') {
    return this.error(res, message, 401);
  }

  /**
   * Send a forbidden error (403)
   * @param {Response} res - Express response object
   * @param {string} message - Error message
   */
  forbidden(res, message = 'Forbidden') {
    return this.error(res, message, 403);
  }

  /**
   * Send a not found error (404)
   * @param {Response} res - Express response object
   * @param {string} message - Error message
   */
  notFound(res, message = 'Not found') {
    return this.error(res, message, 404);
  }

  /**
   * Send an internal server error (500)
   * @param {Response} res - Express response object
   * @param {string} message - Error message
   */
  serverError(res, message = 'Internal server error') {
    return this.error(res, message, 500);
  }
}

const responseBuilder = new ResponseBuilder();

module.exports = { ResponseBuilder, responseBuilder };
