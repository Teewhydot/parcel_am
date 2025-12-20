// ========================================================================
// Scheduled Task Factory - Creates Standardized Scheduled Cloud Functions
// ========================================================================

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FUNCTIONS_CONFIG } = require('../utils/constants');
const { logger } = require('../utils/logger');

/**
 * Creates a standardized scheduled Cloud Function
 *
 * @param {object} config - Task configuration
 * @param {string} config.name - Task name for logging
 * @param {string} config.schedule - Cron schedule expression
 * @param {string[]} config.secrets - Secret names to inject
 * @param {number} config.timeout - Timeout in seconds
 * @param {string} config.memory - Memory allocation
 * @param {string} config.timezone - Timezone for schedule (default: UTC)
 *
 * @param {Function} handler - Async function (context, executionId) => void
 *
 * @returns {ScheduledFunction} Firebase Scheduled Cloud Function
 *
 * @example
 * const myTask = createScheduledTask({
 *   name: 'dailyCleanup',
 *   schedule: 'every 24 hours'
 * }, async (context, executionId) => {
 *   await cleanupService.run();
 * });
 */
function createScheduledTask(config, handler) {
  const {
    name,
    schedule,
    secrets = [],
    timeout = FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory = FUNCTIONS_CONFIG.MEMORY,
    timezone = 'UTC'
  } = config;

  return onSchedule(
    {
      schedule: schedule,
      timeZone: timezone,
      region: FUNCTIONS_CONFIG.REGION,
      timeoutSeconds: timeout,
      memory: memory,
      cpu: FUNCTIONS_CONFIG.CPU,
      maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
      secrets: secrets
    },
    async (context) => {
      const executionId = `${name}-${Date.now()}`;
      const startTime = Date.now();

      try {
        logger.startFunction(name, executionId);
        logger.info(`Scheduled task started: ${schedule}`, executionId);

        // Execute handler
        await handler(context, executionId);

        // Log success
        const duration = Date.now() - startTime;
        logger.success(`Scheduled task completed in ${duration}ms`, executionId);

      } catch (error) {
        const duration = Date.now() - startTime;
        logger.critical(`Scheduled task failed after ${duration}ms`, executionId, error);

        // Rethrow to mark function as failed in Cloud Functions
        throw error;
      }
    }
  );
}

module.exports = { createScheduledTask };
