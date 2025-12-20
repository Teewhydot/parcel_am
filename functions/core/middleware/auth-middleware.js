// ========================================================================
// Firebase Authentication Middleware
// ========================================================================

const admin = require('firebase-admin');
const { logger } = require('../../utils/logger');
const { AuthenticationError } = require('./error-handler');

/**
 * Authentication middleware for verifying Firebase ID tokens
 */
class AuthMiddleware {
  /**
   * Verify Firebase ID token from Authorization header
   * @param {Request} req - Express request object
   * @param {string} executionId - Execution ID for logging
   * @returns {Promise<{uid: string, token: object}>} Decoded token data
   * @throws {AuthenticationError} If token is missing or invalid
   */
  async verify(req, executionId = null) {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      logger.warning('Missing Authorization header', executionId);
      throw new AuthenticationError('Authorization header is required');
    }

    if (!authHeader.startsWith('Bearer ')) {
      logger.warning('Invalid Authorization header format', executionId);
      throw new AuthenticationError('Authorization header must be Bearer token');
    }

    const idToken = authHeader.split('Bearer ')[1];

    if (!idToken || idToken.trim() === '') {
      logger.warning('Empty ID token', executionId);
      throw new AuthenticationError('Token is required');
    }

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);

      logger.info(`User authenticated: ${decodedToken.uid}`, executionId);

      return {
        uid: decodedToken.uid,
        email: decodedToken.email,
        token: decodedToken
      };
    } catch (error) {
      logger.error('Token verification failed', executionId, error);

      if (error.code === 'auth/id-token-expired') {
        throw new AuthenticationError('Token has expired');
      }

      if (error.code === 'auth/id-token-revoked') {
        throw new AuthenticationError('Token has been revoked');
      }

      throw new AuthenticationError('Invalid or expired token');
    }
  }

  /**
   * Verify that authenticated user matches the requested userId
   * @param {object} auth - Auth context from verify()
   * @param {string} userId - User ID to match
   * @param {string} executionId - Execution ID for logging
   * @throws {AuthenticationError} If user IDs don't match
   */
  verifyUserMatch(auth, userId, executionId = null) {
    if (!auth || !auth.uid) {
      throw new AuthenticationError('Not authenticated');
    }

    if (auth.uid !== userId) {
      logger.warning(`User ID mismatch: ${auth.uid} !== ${userId}`, executionId);
      throw new AuthenticationError('Unauthorized: User ID mismatch');
    }
  }
}

const authMiddleware = new AuthMiddleware();

module.exports = { AuthMiddleware, authMiddleware };
