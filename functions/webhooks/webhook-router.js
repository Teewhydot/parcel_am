// ========================================================================
// Webhook Router - Event-based routing for Paystack webhooks
// ========================================================================

const { logger } = require('../utils/logger');

/**
 * WebhookRouter - Registry pattern for webhook event handling
 * Allows registration of handlers for specific event types
 */
class WebhookRouter {
  constructor() {
    this.handlers = new Map();
  }

  /**
   * Register a handler for a specific event type
   * @param {string} eventType - The event type (e.g., 'charge.success')
   * @param {Function} handler - The handler function (processedEvent, executionId) => Promise<void>
   * @returns {WebhookRouter} Returns this for chaining
   */
  register(eventType, handler) {
    if (typeof handler !== 'function') {
      throw new Error(`Handler for ${eventType} must be a function`);
    }
    this.handlers.set(eventType, handler);
    return this;
  }

  /**
   * Register multiple handlers at once
   * @param {Object} handlers - Object mapping event types to handlers
   * @returns {WebhookRouter} Returns this for chaining
   */
  registerAll(handlers) {
    for (const [eventType, handler] of Object.entries(handlers)) {
      this.register(eventType, handler);
    }
    return this;
  }

  /**
   * Check if a handler is registered for an event type
   * @param {string} eventType - The event type
   * @returns {boolean}
   */
  hasHandler(eventType) {
    return this.handlers.has(eventType);
  }

  /**
   * Get the handler for an event type
   * @param {string} eventType - The event type
   * @returns {Function|undefined}
   */
  getHandler(eventType) {
    return this.handlers.get(eventType);
  }

  /**
   * Route an event to its handler
   * @param {string} eventType - The event type
   * @param {Object} processedEvent - The processed event data
   * @param {string} executionId - Execution ID for logging
   * @returns {Promise<Object>} Result of handling
   */
  async route(eventType, processedEvent, executionId) {
    const handler = this.handlers.get(eventType);

    if (!handler) {
      logger.info(`Unhandled webhook event type: ${eventType}`, executionId, {
        eventType,
        reference: processedEvent?.reference
      });
      return {
        handled: false,
        reason: 'no_handler_registered'
      };
    }

    try {
      console.log(`🔀 Routing to handler for: ${eventType}`);
      logger.info(`Routing webhook to handler`, executionId, { eventType });

      await handler(processedEvent, executionId);

      return {
        handled: true,
        eventType
      };
    } catch (error) {
      logger.error(`Handler failed for ${eventType}`, executionId, error);
      throw error;
    }
  }

  /**
   * Get list of registered event types
   * @returns {string[]}
   */
  getRegisteredEvents() {
    return Array.from(this.handlers.keys());
  }
}

// Export class and singleton instance
const webhookRouter = new WebhookRouter();

module.exports = {
  WebhookRouter,
  webhookRouter
};
