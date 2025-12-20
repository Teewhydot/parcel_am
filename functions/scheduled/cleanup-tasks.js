// ========================================================================
// Cleanup Tasks
// ========================================================================

const { createScheduledTask } = require('../core/scheduled-task-factory');
const { dbHelper } = require('../utils/database');
const { logger } = require('../utils/logger');

/**
 * Cleanup Old Pending Transactions
 * Runs every 24 hours to mark old pending transactions as expired
 */
const cleanupOldPendingTransactions = createScheduledTask({
  name: 'cleanupOldPendingTransactions',
  schedule: 'every 24 hours'
}, async (context, executionId) => {
  // Clean up transactions older than 7 days
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  const oldPendingFundingOrders = await dbHelper.queryDocuments('funding_orders',
    [
      { field: 'status', operator: '==', value: 'pending' },
      { field: 'time_created', operator: '<', value: sevenDaysAgo.toISOString() }
    ],
    null, 100, executionId
  );

  const oldPendingWithdrawals = await dbHelper.queryDocuments('withdrawals',
    [
      { field: 'status', operator: '==', value: 'pending' },
      { field: 'time_created', operator: '<', value: sevenDaysAgo.toISOString() }
    ],
    null, 100, executionId
  );

  const allOldPending = [...oldPendingFundingOrders, ...oldPendingWithdrawals];

  logger.info(`Found ${allOldPending.length} old pending transactions to cleanup`, executionId);

  const batch = dbHelper.createBatch();
  let cleanedCount = 0;

  for (const transaction of allOldPending) {
    const collection = transaction.id.startsWith('F-') ? 'funding_orders' : 'withdrawals';
    dbHelper.batchUpdate(batch, collection, transaction.id, {
      status: 'expired',
      expiredAt: dbHelper.getServerTimestamp()
    });
    cleanedCount++;
  }

  if (cleanedCount > 0) {
    await dbHelper.commitBatch(batch, cleanedCount, executionId);
  }

  logger.success(`Cleanup completed: ${cleanedCount} transactions marked as expired`, executionId);
});

module.exports = {
  cleanupOldPendingTransactions
};
