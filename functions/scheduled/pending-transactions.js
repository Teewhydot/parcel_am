// ========================================================================
// Pending Transactions Verification Task
// ========================================================================

const { createScheduledTask } = require('../core/scheduled-task-factory');
const { paymentService } = require('../services/payment-service');
const { dbHelper } = require('../utils/database');
const { logger } = require('../utils/logger');
const { handleSuccessfulPayment } = require('../domain/payment');

/**
 * Verify Pending Transactions
 * Runs every 10 minutes to check if any pending transactions have been paid
 */
const verifyPendingTransactions = createScheduledTask({
  name: 'verifyPendingTransactions',
  schedule: 'every 10 minutes',
  secrets: ['PAYSTACK_SECRET_KEY']
}, async (context, executionId) => {
  // Get pending transactions from the last 24 hours
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const pendingFundingOrders = await dbHelper.queryDocuments('funding_orders',
    [
      { field: 'status', operator: '==', value: 'pending' },
      { field: 'time_created', operator: '>=', value: oneDayAgo.toISOString() }
    ],
    null, 50, executionId
  );

  const pendingWithdrawals = await dbHelper.queryDocuments('withdrawals',
    [
      { field: 'status', operator: '==', value: 'pending' },
      { field: 'time_created', operator: '>=', value: oneDayAgo.toISOString() }
    ],
    null, 50, executionId
  );

  const allPending = [...pendingFundingOrders, ...pendingWithdrawals];

  logger.info(`Found ${allPending.length} pending transactions to verify`, executionId);

  let verifiedCount = 0;
  for (const transaction of allPending) {
    try {
      const originalReference = paymentService.extractOriginalReference(transaction.id);
      const verificationResult = await paymentService.verifyTransaction(
        originalReference,
        `${executionId}-${transaction.id}`
      );

      if (verificationResult.success && verificationResult.status === 'success') {
        await handleSuccessfulPayment({
          reference: originalReference,
          amount: verificationResult.amount,
          paidAt: verificationResult.paidAt,
          userId: transaction.data.userId,
          userName: transaction.data.userName,
          bookingDetails: transaction.data.bookingDetails || {}
        }, `${executionId}-${transaction.id}`);

        verifiedCount++;
      }
    } catch (error) {
      logger.error(`Failed to verify transaction ${transaction.id}`, executionId, error);
    }
  }

  logger.success(`Verification completed: ${verifiedCount}/${allPending.length} transactions verified`, executionId);
});

module.exports = {
  verifyPendingTransactions
};
