// ========================================================================
// Transfer Event Handlers
// ========================================================================

const { processTransferWebhook } = require('../../handlers/webhook-transfer-handler');
const { logger } = require('../../utils/logger');

/**
 * Handle transfer.success event
 * Delegates to the existing transfer webhook handler
 * @param {Object} rawEvent - The raw webhook event (not processed)
 * @param {string} executionId - Execution ID for logging
 */
async function handleTransferSuccess(rawEvent, executionId) {
  console.log('💸 Handling TRANSFER SUCCESS');
  console.log('  - Reference:', rawEvent.data?.reference);
  console.log('  - Transfer Code:', rawEvent.data?.transfer_code);

  logger.info('Handling transfer success event', executionId, {
    reference: rawEvent.data?.reference,
    transferCode: rawEvent.data?.transfer_code
  });

  await processTransferWebhook(rawEvent, executionId);
}

/**
 * Handle transfer.failed event
 * Delegates to the existing transfer webhook handler
 * @param {Object} rawEvent - The raw webhook event (not processed)
 * @param {string} executionId - Execution ID for logging
 */
async function handleTransferFailed(rawEvent, executionId) {
  console.log('❌ Handling TRANSFER FAILED');
  console.log('  - Reference:', rawEvent.data?.reference);
  console.log('  - Transfer Code:', rawEvent.data?.transfer_code);

  logger.info('Handling transfer failed event', executionId, {
    reference: rawEvent.data?.reference,
    transferCode: rawEvent.data?.transfer_code
  });

  await processTransferWebhook(rawEvent, executionId);
}

/**
 * Handle transfer.reversed event
 * Delegates to the existing transfer webhook handler
 * @param {Object} rawEvent - The raw webhook event (not processed)
 * @param {string} executionId - Execution ID for logging
 */
async function handleTransferReversed(rawEvent, executionId) {
  console.log('🔄 Handling TRANSFER REVERSED');
  console.log('  - Reference:', rawEvent.data?.reference);
  console.log('  - Transfer Code:', rawEvent.data?.transfer_code);

  logger.info('Handling transfer reversed event', executionId, {
    reference: rawEvent.data?.reference,
    transferCode: rawEvent.data?.transfer_code
  });

  await processTransferWebhook(rawEvent, executionId);
}

module.exports = {
  handleTransferSuccess,
  handleTransferFailed,
  handleTransferReversed
};
