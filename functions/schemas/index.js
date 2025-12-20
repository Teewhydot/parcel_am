// ========================================================================
// Schemas Barrel Export
// ========================================================================

const {
  createTransactionSchema,
  verifyPaymentSchema,
  transactionStatusSchema
} = require('./transaction-schemas');

const {
  resolveBankAccountSchema,
  createTransferRecipientSchema
} = require('./bank-schemas');

const {
  initiateWithdrawalSchema,
  MIN_WITHDRAWAL_AMOUNT,
  MAX_WITHDRAWAL_AMOUNT
} = require('./withdrawal-schemas');

const {
  sendEmailSchema,
  sendFCMNotificationSchema,
  checkFCMConfigSchema
} = require('./notification-schemas');

module.exports = {
  // Transaction schemas
  createTransactionSchema,
  verifyPaymentSchema,
  transactionStatusSchema,

  // Bank schemas
  resolveBankAccountSchema,
  createTransferRecipientSchema,

  // Withdrawal schemas
  initiateWithdrawalSchema,
  MIN_WITHDRAWAL_AMOUNT,
  MAX_WITHDRAWAL_AMOUNT,

  // Notification schemas
  sendEmailSchema,
  sendFCMNotificationSchema,
  checkFCMConfigSchema
};
