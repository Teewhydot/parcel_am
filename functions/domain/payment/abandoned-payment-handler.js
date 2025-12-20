// ========================================================================
// Abandoned Payment Handler
// ========================================================================

const { TRANSACTION_TYPES } = require('../../utils/constants');
const { logger } = require('../../utils/logger');
const { dbHelper } = require('../../utils/database');

/**
 * Handles abandoned payment webhook events
 * - Finds the transaction document
 * - Updates transaction status to 'abandoned'
 *
 * @param {Object} processedEvent - The processed webhook event
 * @param {string} processedEvent.reference - Payment reference
 * @param {number} processedEvent.amount - Payment amount
 * @param {string} processedEvent.paidAt - Payment timestamp
 * @param {string} executionId - Execution ID for logging
 */
async function handleAbandonedPayment(processedEvent, executionId) {
  logger.info('handleAbandonedPayment started', executionId, {
    reference: processedEvent.reference,
    amount: processedEvent.amount
  });

  const { reference, amount, paidAt } = processedEvent;

  logger.info('Finding document with prefix', executionId, { reference });
  const { actualReference, transactionType } = await dbHelper.findDocumentWithPrefix(reference, executionId);
  logger.info('Document found', executionId, { actualReference, transactionType });

  const config = TRANSACTION_TYPES[transactionType] || TRANSACTION_TYPES['food_order'];

  if (!config) {
    logger.error(`No configuration found for transaction type: ${transactionType}`, executionId);
    return;
  }
  logger.info('Transaction type config found', executionId, {
    transactionType,
    collectionName: config.collectionName
  });

  const updateData = {
    status: 'abandoned',
    time_created: paidAt,
    amount: amount,
  };

  logger.info('Updating document to abandoned status', executionId, {
    collection: config.collectionName,
    reference: actualReference
  });
  await dbHelper.updateDocument(config.collectionName, actualReference, updateData, executionId);
  logger.info(`Payment abandoned for ${reference}`, executionId);
  logger.success('handleAbandonedPayment completed', executionId);
}

module.exports = {
  handleAbandonedPayment
};
