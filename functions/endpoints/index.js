// ========================================================================
// Endpoints - Barrel Export
// ========================================================================

const {
  createPaystackTransaction,
  verifyPaystackPayment,
  getTransactionStatus
} = require('./transaction-endpoints');

const {
  resolveBankAccount,
  createTransferRecipient
} = require('./bank-endpoints');

const { initiateWithdrawal } = require('./withdrawal-endpoints');

const {
  sendEmail,
  checkFCMConfig,
  sendFCMNotification
} = require('./notification-endpoints');

const { paystackWebhook } = require('./webhook-endpoints');

module.exports = {
  // Transaction endpoints
  createPaystackTransaction,
  verifyPaystackPayment,
  getTransactionStatus,

  // Bank endpoints
  resolveBankAccount,
  createTransferRecipient,

  // Withdrawal endpoints
  initiateWithdrawal,

  // Notification endpoints
  sendEmail,
  checkFCMConfig,
  sendFCMNotification,

  // Webhook endpoints
  paystackWebhook
};
