// ========================================================================
// ParcelAm Firebase Functions - Assembly Layer
// ========================================================================
// This file is the entry point for all Firebase Cloud Functions.
// All business logic is extracted into modular, reusable components.
// ========================================================================

// Load environment variables
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

// Initialize Firebase Admin
const admin = require('firebase-admin');
admin.initializeApp();
admin.firestore().settings({ ignoreUndefinedProperties: true });

// ========================================================================
// Import Pre-Configured Endpoints
// ========================================================================
const {
  createPaystackTransaction,
  verifyPaystackPayment,
  getTransactionStatus,
  resolveBankAccount,
  createTransferRecipient,
  initiateWithdrawal,
  sendEmail,
  sendFCMNotification,
  checkFCMConfig,
  paystackWebhook
} = require('./endpoints');

// ========================================================================
// Import Scheduled Tasks
// ========================================================================
const {
  verifyPendingTransactions,
  cleanupOldPendingTransactions,
  autoReleaseEscrow
} = require('./scheduled');

// ========================================================================
// Import Triggers
// ========================================================================
const {
  onParcelAwaitingConfirmation,
  onParcelStatusUpdate,
  onChatMessageNotification,
  onChatPageUpdated
} = require('./triggers');

// ========================================================================
// Export All Cloud Functions
// ========================================================================

// Transaction endpoints
exports.createPaystackTransaction = createPaystackTransaction;
exports.verifyPaystackPayment = verifyPaystackPayment;
exports.getTransactionStatus = getTransactionStatus;

// Bank endpoints
exports.resolveBankAccount = resolveBankAccount;
exports.createTransferRecipient = createTransferRecipient;

// Withdrawal endpoints
exports.initiateWithdrawal = initiateWithdrawal;

// Notification endpoints
exports.sendEmail = sendEmail;
exports.sendFCMNotification = sendFCMNotification;
exports.checkFCMConfig = checkFCMConfig;

// Webhook endpoints
exports.paystackWebhook = paystackWebhook;

// Scheduled tasks
exports.verifyPendingTransactions = verifyPendingTransactions;
exports.cleanupOldPendingTransactions = cleanupOldPendingTransactions;
exports.autoReleaseEscrow = autoReleaseEscrow;

// Triggers
exports.onParcelAwaitingConfirmation = onParcelAwaitingConfirmation;
exports.onParcelStatusUpdate = onParcelStatusUpdate;
exports.onChatMessageNotification = onChatMessageNotification;
exports.onChatPageUpdated = onChatPageUpdated;

// ========================================================================
// Startup Complete
// ========================================================================
console.log('='.repeat(50));
console.log('ParcelAm Firebase Functions - Lego Brick Architecture');
console.log('='.repeat(50));
console.log('All endpoints loaded and ready');
