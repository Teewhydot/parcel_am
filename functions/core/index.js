// ========================================================================
// Core Framework Barrel Export
// ========================================================================

const { createEndpoint, createWebhookEndpoint } = require('./endpoint-factory');
const { createScheduledTask } = require('./scheduled-task-factory');
const { ResponseBuilder, responseBuilder } = require('./response-builder');

// Re-export middleware
const middleware = require('./middleware');

module.exports = {
  // Factories
  createEndpoint,
  createWebhookEndpoint,
  createScheduledTask,

  // Response builder
  ResponseBuilder,
  responseBuilder,

  // Middleware (all exports)
  ...middleware
};
