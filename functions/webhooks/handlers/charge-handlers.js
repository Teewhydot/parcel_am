// ========================================================================
// Charge Event Handlers
// ========================================================================

const {
  handleSuccessfulPayment,
  handleFailedPayment,
  handleAbandonedPayment
} = require('../../domain/payment');
const { logger } = require('../../utils/logger');

/**
 * Handle charge.success event
 * @param {Object} processedEvent - Processed event data
 * @param {string} executionId - Execution ID for logging
 */
async function handleChargeSuccess(processedEvent, executionId) {
  console.log('✅ Handling SUCCESSFUL payment');
  console.log('  - Reference:', processedEvent.reference);

  logger.info('Handling successful payment', executionId, {
    reference: processedEvent.reference
  });

  await handleSuccessfulPayment(processedEvent, executionId);
}

/**
 * Handle charge.failed event
 * @param {Object} processedEvent - Processed event data
 * @param {string} executionId - Execution ID for logging
 */
async function handleChargeFailed(processedEvent, executionId) {
  console.log('❌ Handling FAILED payment');
  console.log('  - Reference:', processedEvent.reference);

  logger.info('Handling failed payment', executionId, {
    reference: processedEvent.reference
  });

  await handleFailedPayment(processedEvent, executionId);
}

/**
 * Handle charge.abandoned event
 * @param {Object} processedEvent - Processed event data
 * @param {string} executionId - Execution ID for logging
 */
async function handleChargeAbandoned(processedEvent, executionId) {
  console.log('⚠️ Handling ABANDONED payment');
  console.log('  - Reference:', processedEvent.reference);

  logger.info('Handling abandoned payment', executionId, {
    reference: processedEvent.reference
  });

  await handleAbandonedPayment(processedEvent, executionId);
}

module.exports = {
  handleChargeSuccess,
  handleChargeFailed,
  handleChargeAbandoned
};
