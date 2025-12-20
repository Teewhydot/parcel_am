// ========================================================================
// Domain Layer - Barrel Export
// ========================================================================

const {
  handleSuccessfulPayment,
  handleFailedPayment,
  handleAbandonedPayment
} = require('./payment');

const { walletService, WalletService } = require('./wallet');

module.exports = {
  // Payment handlers
  handleSuccessfulPayment,
  handleFailedPayment,
  handleAbandonedPayment,

  // Wallet service
  walletService,
  WalletService
};
