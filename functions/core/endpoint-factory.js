// ========================================================================
// Endpoint Factory - Creates Standardized HTTP Cloud Functions
// ========================================================================

const { onRequest } = require('firebase-functions/v2/https');
const { FUNCTIONS_CONFIG } = require('../utils/constants');
const { corsHandler, errorHandler, authMiddleware, requestLogger } = require('./middleware');
const { responseBuilder } = require('./response-builder');
const { logger } = require('../utils/logger');

/**
 * Creates a standardized HTTP Cloud Function endpoint
 *
 * @param {object} config - Endpoint configuration
 * @param {string} config.name - Endpoint name for logging
 * @param {string[]} config.secrets - Secret names to inject
 * @param {number} config.timeout - Timeout in seconds (default: from FUNCTIONS_CONFIG)
 * @param {string} config.memory - Memory allocation (default: from FUNCTIONS_CONFIG)
 * @param {boolean} config.requiresAuth - Whether to verify Firebase ID token
 * @param {object} config.schema - Validation schema with validate(data) method
 * @param {Function[]} config.middleware - Additional middleware functions
 *
 * @param {Function} handler - Async function (data, context) => result
 *   - data: Validated request data (from body for POST, query for GET)
 *   - context: { executionId, req, res, auth? }
 *   - Returns: Object to be sent as JSON response
 *
 * @returns {HttpsFunction} Firebase Cloud Function
 *
 * @example
 * const myEndpoint = createEndpoint({
 *   name: 'myEndpoint',
 *   secrets: ['MY_SECRET'],
 *   requiresAuth: true,
 *   schema: myValidationSchema
 * }, async (data, ctx) => {
 *   // ctx.auth is available when requiresAuth: true
 *   const result = await myService.doSomething(data);
 *   return { result };
 * });
 */
function createEndpoint(config, handler) {
  const {
    name,
    secrets = [],
    timeout = FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory = FUNCTIONS_CONFIG.MEMORY,
    cpu = FUNCTIONS_CONFIG.CPU,
    minInstances = FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances = FUNCTIONS_CONFIG.MAX_INSTANCES,
    requiresAuth = false,
    schema = null,
    middleware = []
  } = config;

  return onRequest(
    {
      region: FUNCTIONS_CONFIG.REGION,
      timeoutSeconds: timeout,
      memory: memory,
      cpu: cpu,
      minInstances: minInstances,
      maxInstances: maxInstances,
      secrets: secrets
    },
    async (req, res) => {
      await corsHandler(req, res, async () => {
        const executionId = `${name}-${Date.now()}`;
        const getElapsedTime = requestLogger.startTimer();

        // Build context object
        const context = {
          executionId,
          req,
          res
        };

        try {
          // Log incoming request
          logger.startFunction(name, executionId);
          requestLogger.logRequest(req, executionId);

          // Optional authentication
          if (requiresAuth) {
            context.auth = await authMiddleware.verify(req, executionId);
          }

          // Get request data
          let data = req.method === 'GET' ? req.query : req.body;

          // Optional schema validation
          if (schema && typeof schema.validate === 'function') {
            data = schema.validate(data);
            logger.info('Request validation passed', executionId);
          }

          // Run custom middleware
          for (const mw of middleware) {
            await mw(context, data);
          }

          // Execute handler
          const result = await handler(data, context);

          // Log and send success response
          const elapsed = getElapsedTime();
          requestLogger.logResponse(200, elapsed, executionId);

          responseBuilder.success(res, result);

        } catch (error) {
          // Log and send error response
          const elapsed = getElapsedTime();
          requestLogger.logResponse(error.statusCode || 500, elapsed, executionId);

          errorHandler.handle(error, res, executionId);
        }
      });
    }
  );
}

/**
 * Creates a webhook endpoint with signature verification support
 *
 * @param {object} config - Endpoint configuration (same as createEndpoint)
 * @param {Function} handler - Async function (rawEvent, context) => result
 *
 * @returns {HttpsFunction} Firebase Cloud Function
 */
function createWebhookEndpoint(config, handler) {
  const {
    name,
    secrets = [],
    timeout = FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory = FUNCTIONS_CONFIG.MEMORY
  } = config;

  return onRequest(
    {
      region: FUNCTIONS_CONFIG.REGION,
      timeoutSeconds: timeout,
      memory: memory,
      cpu: FUNCTIONS_CONFIG.CPU,
      minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
      maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
      secrets: secrets
    },
    async (req, res) => {
      const executionId = `${name}-${Date.now()}`;
      const getElapsedTime = requestLogger.startTimer();

      const context = {
        executionId,
        req,
        res,
        headers: req.headers
      };

      try {
        logger.startFunction(name, executionId);
        logger.webhook('received', req.body?.event || 'unknown', executionId);

        // Execute webhook handler
        const result = await handler(req.body, context);

        // Log and send success
        const elapsed = getElapsedTime();
        requestLogger.logResponse(200, elapsed, executionId);

        responseBuilder.success(res, result || { message: 'Webhook processed' });

      } catch (error) {
        const elapsed = getElapsedTime();
        requestLogger.logResponse(error.statusCode || 500, elapsed, executionId);

        errorHandler.handle(error, res, executionId);
      }
    }
  );
}

module.exports = {
  createEndpoint,
  createWebhookEndpoint
};
