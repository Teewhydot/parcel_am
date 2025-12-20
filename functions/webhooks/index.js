// ========================================================================
// Webhooks - Initialize router with all handlers
// ========================================================================

const { webhookRouter, WebhookRouter } = require('./webhook-router');
const {
  handleChargeSuccess,
  handleChargeFailed,
  handleChargeAbandoned,
  handleTransferSuccess,
  handleTransferFailed,
  handleTransferReversed
} = require('./handlers');

// Register all webhook handlers
webhookRouter
  // Charge events (payment)
  .register('charge.success', handleChargeSuccess)
  .register('charge.failed', handleChargeFailed)
  .register('charge.abandoned', handleChargeAbandoned)
  // Transfer events (withdrawal)
  .register('transfer.success', handleTransferSuccess)
  .register('transfer.failed', handleTransferFailed)
  .register('transfer.reversed', handleTransferReversed);

console.log('📡 Webhook router initialized with handlers:', webhookRouter.getRegisteredEvents());

module.exports = {
  webhookRouter,
  WebhookRouter
};
