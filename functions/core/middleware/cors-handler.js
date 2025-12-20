// ========================================================================
// CORS Handler Middleware
// ========================================================================

const cors = require('cors')({ origin: true });

/**
 * Wraps a handler with CORS support
 * @param {Request} req - Express request
 * @param {Response} res - Express response
 * @param {Function} handler - Async handler to execute after CORS
 * @returns {Promise<void>}
 */
function corsHandler(req, res, handler) {
  return new Promise((resolve, reject) => {
    cors(req, res, async () => {
      try {
        await handler();
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  });
}

module.exports = { corsHandler };
