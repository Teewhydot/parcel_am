// ========================================================================
// Successful Payment Handler
// ========================================================================

const admin = require('firebase-admin');
const { TRANSACTION_TYPES } = require('../../utils/constants');
const { logger } = require('../../utils/logger');
const { dbHelper } = require('../../utils/database');
const { notificationService } = require('../../services/notification-service');
const { walletService } = require('../wallet/wallet-service');

/**
 * Handles successful payment webhook events
 * - Finds the transaction document
 * - Validates idempotency (prevents duplicate processing)
 * - Updates transaction status atomically with wallet balance
 * - Sends success notification
 *
 * @param {Object} processedEvent - The processed webhook event
 * @param {string} processedEvent.reference - Payment reference
 * @param {number} processedEvent.amount - Payment amount
 * @param {string} processedEvent.paidAt - Payment timestamp
 * @param {string} processedEvent.userId - User ID
 * @param {string} processedEvent.userName - User name
 * @param {Object} processedEvent.bookingDetails - Additional booking details
 * @param {string} executionId - Execution ID for logging
 */
async function handleSuccessfulPayment(processedEvent, executionId) {
  const db = admin.firestore();

  console.log('💰 === HANDLE SUCCESSFUL PAYMENT ===');
  console.log('Reference:', processedEvent.reference);
  console.log('Amount:', processedEvent.amount);
  console.log('User ID:', processedEvent.userId);

  logger.info('handleSuccessfulPayment started', executionId, {
    reference: processedEvent.reference,
    amount: processedEvent.amount,
    userId: processedEvent.userId
  });

  const { reference, amount, paidAt, userId, userName, bookingDetails } = processedEvent;

  // Find document and update status
  console.log('🔍 Finding document in database...');

  logger.info('Finding document with prefix', executionId, { reference });
  const { actualReference, transactionType, orderDetails, userEmail } = await dbHelper.findDocumentWithPrefix(reference, executionId);

  console.log('✅ Document found:');
  console.log('  - Actual Reference:', actualReference);
  console.log('  - Transaction Type:', transactionType);
  console.log('  - Has Order Details:', !!orderDetails);

  logger.info('Document found', executionId, {
    actualReference,
    transactionType,
    hasOrderDetails: !!orderDetails
  });

  // Update transaction status - default to funding if transactionType not found
  const config = TRANSACTION_TYPES[transactionType] || TRANSACTION_TYPES['funding'];

  if (!config) {
    logger.error(`No configuration found for transaction type: ${transactionType}`, executionId);
    return;
  }

  // ========================================================================
  // IDEMPOTENCY CHECK: Verify transaction hasn't already been processed
  // ========================================================================
  console.log('🔍 Checking transaction status for idempotency...');
  logger.info('Checking current transaction status', executionId, {
    collection: config.collectionName,
    reference: actualReference
  });

  const { doc: existingDoc, data: existingData } = await dbHelper.getDocument(
    config.collectionName,
    actualReference,
    executionId
  );

  if (existingData && existingData.status === 'confirmed') {
    console.log('⚠️  DUPLICATE WEBHOOK DETECTED - Transaction already confirmed');
    console.log('  - Reference:', actualReference);
    console.log('  - Current Status:', existingData.status);
    console.log('  - Verified At:', existingData.verified_at);

    logger.warning('Duplicate webhook ignored - transaction already confirmed', executionId, {
      reference: actualReference,
      currentStatus: existingData.status,
      verifiedAt: existingData.verified_at,
      amount: existingData.amount
    });

    // Return early - this webhook has already been processed (idempotent behavior)
    return;
  }

  console.log('✅ Transaction not yet confirmed - proceeding with processing');
  logger.info(`Transaction status: ${existingData?.status || 'not found'} - safe to process`, executionId);
  logger.info('Transaction type config found', executionId, {
    transactionType,
    collectionName: config.collectionName
  });

  const updateData = {
    status: 'confirmed',
    time_created: paidAt,
    amount: amount,
    verified_at: dbHelper.getServerTimestamp()
  };

  if (config.transactionType === 'service') {
    updateData.updatedAt = paidAt;
    logger.info('Added updatedAt field for service transaction', executionId);
  }

  // ========================================================================
  // ATOMIC TRANSACTION: Update transaction status and wallet balance
  // All operations succeed or all fail - no partial updates
  // ========================================================================
  console.log('💾 Starting atomic transaction...');
  logger.info('Starting atomic Firestore transaction', executionId, {
    collection: config.collectionName,
    reference: actualReference,
    transactionType,
    hasUserId: !!userId
  });

  try {
    await db.runTransaction(async (transaction) => {
      // Get document reference
      const transactionDocRef = db.collection(config.collectionName).doc(actualReference);

      console.log('  📄 Step 1: Updating transaction status to CONFIRMED...');

      // Update transaction status
      transaction.update(transactionDocRef, updateData);

      logger.info('Transaction document update queued', executionId, {
        reference: actualReference,
        status: 'confirmed'
      });

      // Update wallet balance if this is a funding transaction
      if (transactionType === 'funding' && userId) {
        await walletService.updateBalanceInTransaction(transaction, userId, amount, executionId);
      } else if (transactionType === 'funding' && !userId) {
        console.log('  ⚠️  Skipping wallet update: missing user ID');
        logger.warning('Cannot update wallet: missing userId', executionId);
      } else {
        console.log('  ⏭️  Skipping wallet update (not a funding transaction)');
        logger.info(`Skipping wallet update for ${transactionType}`, executionId);
      }

      console.log('  🔄 Committing atomic transaction...');
    });

    console.log('✅ Atomic transaction committed successfully');
    logger.success('Transaction and wallet updated atomically', executionId, {
      reference: actualReference,
      amount,
      userId: userId || 'N/A'
    });

  } catch (error) {
    console.error('❌ Atomic transaction FAILED - all changes rolled back');
    console.error('  Error:', error.message);

    logger.error('Atomic transaction failed - rollback complete', executionId, error, {
      reference: actualReference,
      transactionType,
      userId: userId || 'N/A',
      amount
    });

    // Re-throw to prevent notification from being sent if transaction failed
    throw error;
  }

  // Send success notification
  logger.info('Generating notification data', executionId, { transactionType });
  const notificationData = notificationService.generateNotificationData(
    transactionType, orderDetails, actualReference, amount, true
  );
  logger.info('Notification data generated', executionId);

  if (userId && config) {
    console.log('🔔 Sending notification to user...');
    console.log('  - User ID:', userId);
    console.log('  - Title:', config.notificationTitle.success);

    logger.info('Sending notification to user', executionId, {
      userId,
      title: config.notificationTitle.success
    });
    await notificationService.sendNotificationToUser(
      userId,
      config.notificationTitle.success,
      `Your ${transactionType.replace('_', ' ')} payment of ₦${amount.toLocaleString()} has been confirmed!`,
      notificationData,
      executionId
    );
    console.log('✅ Notification sent successfully');

    logger.info('Notification sent successfully', executionId);
  } else {
    console.log('⚠️ Notification not sent (missing user ID or config)');
    logger.warning('Notification not sent', executionId, {
      hasUserId: !!userId,
      hasConfig: !!config
    });
  }

  console.log('🎉 SUCCESSFUL PAYMENT HANDLED COMPLETELY');
  console.log('=== END HANDLE SUCCESSFUL PAYMENT ===');

  logger.success('handleSuccessfulPayment completed', executionId);
}

module.exports = {
  handleSuccessfulPayment
};
