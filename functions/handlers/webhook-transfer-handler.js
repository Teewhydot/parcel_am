// ========================================================================
// Webhook Transfer Handler - Process Paystack Transfer Events
// ========================================================================

const admin = require('firebase-admin');
const { logger } = require('../utils/logger');
const { notificationService } = require('../services/notification-service');
const { deductHeldBalance, releaseHeldBalance } = require('./withdrawal-handler');

/**
 * Check if webhook event has already been processed (deduplication)
 */
async function checkWebhookProcessed(eventId, executionId) {
  try {
    const webhookRef = admin.firestore()
      .collection('processed_webhooks')
      .doc(eventId);

    const webhookDoc = await webhookRef.get();

    if (webhookDoc.exists) {
      logger.info('Webhook already processed (duplicate)', executionId, {
        eventId,
        processedAt: webhookDoc.data().processedAt
      });
      return true;
    }

    // Mark as processed with TTL (7 days)
    const ttlDate = new Date();
    ttlDate.setDate(ttlDate.getDate() + 7);

    await webhookRef.set({
      eventId,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      ttl: admin.firestore.Timestamp.fromDate(ttlDate),
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return false;
  } catch (error) {
    logger.error('Error checking webhook deduplication', executionId, error);
    // On error, allow processing (fail open to not miss events)
    return false;
  }
}

/**
 * Process transfer.success webhook event
 */
async function handleTransferSuccess(eventData, executionId) {
  try {
    const { reference, transfer_code, amount, recipient, reason } = eventData.data;

    logger.info('Processing transfer.success event', executionId, {
      reference,
      transferCode: transfer_code,
      amount: amount / 100, // Convert from kobo
      recipient: recipient?.recipient_code
    });

    // Find withdrawal order by reference
    const withdrawalRef = admin.firestore()
      .collection('withdrawal_orders')
      .doc(reference);

    const withdrawalDoc = await withdrawalRef.get();

    if (!withdrawalDoc.exists) {
      logger.error('Withdrawal order not found for transfer success', executionId, {
        reference,
        transferCode: transfer_code
      });
      throw new Error(`Withdrawal order not found: ${reference}`);
    }

    const withdrawalOrder = withdrawalDoc.data();
    const { userId, amount: withdrawalAmount } = withdrawalOrder;

    // Use Firestore transaction for atomic updates
    await admin.firestore().runTransaction(async (transaction) => {
      // 1. Update withdrawal order status to 'success'
      transaction.update(withdrawalRef, {
        status: 'success',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          ...withdrawalOrder.metadata,
          successAt: new Date().toISOString(),
          paystackTransferCode: transfer_code
        }
      });

      // 2. Find and update transaction record
      const transactionQuery = await admin.firestore()
        .collection('transactions')
        .where('referenceId', '==', reference)
        .where('type', '==', 'withdrawal')
        .limit(1)
        .get();

      if (!transactionQuery.empty) {
        const transactionDoc = transactionQuery.docs[0];
        transaction.update(transactionDoc.ref, {
          status: 'completed',
          metadata: {
            ...transactionDoc.data().metadata,
            completedAt: new Date().toISOString(),
            transferCode: transfer_code
          }
        });
      }
    });

    // 3. Deduct held balance atomically (outside main transaction to avoid conflicts)
    await deductHeldBalance(userId, withdrawalAmount, reference, executionId);

    // 4. Send success notification to user
    try {
      const expectedArrivalTime = 'within 24 hours';
      await notificationService.sendWithdrawalSuccessNotification({
        userId,
        amount: withdrawalAmount,
        bankAccountName: withdrawalOrder.bankAccount.accountName,
        bankName: withdrawalOrder.bankAccount.bankName,
        reference,
        expectedArrivalTime
      }, executionId);
    } catch (notifError) {
      logger.error('Failed to send success notification', executionId, notifError);
      // Don't fail the entire operation if notification fails
    }

    logger.success('Transfer success processed', executionId, {
      reference,
      amount: withdrawalAmount,
      userId
    });

    return { success: true };
  } catch (error) {
    logger.error('Failed to process transfer.success', executionId, error);
    throw error;
  }
}

/**
 * Process transfer.failed webhook event
 */
async function handleTransferFailed(eventData, executionId) {
  try {
    const { reference, transfer_code, amount, recipient, reason } = eventData.data;
    const failureReason = eventData.data.message || 'Transfer failed';

    logger.info('Processing transfer.failed event', executionId, {
      reference,
      transferCode: transfer_code,
      failureReason
    });

    // Find withdrawal order by reference
    const withdrawalRef = admin.firestore()
      .collection('withdrawal_orders')
      .doc(reference);

    const withdrawalDoc = await withdrawalRef.get();

    if (!withdrawalDoc.exists) {
      logger.error('Withdrawal order not found for transfer failure', executionId, {
        reference,
        transferCode: transfer_code
      });
      throw new Error(`Withdrawal order not found: ${reference}`);
    }

    const withdrawalOrder = withdrawalDoc.data();
    const { userId, amount: withdrawalAmount } = withdrawalOrder;

    // Use Firestore transaction for atomic updates
    await admin.firestore().runTransaction(async (transaction) => {
      // 1. Update withdrawal order status to 'failed'
      transaction.update(withdrawalRef, {
        status: 'failed',
        failureReason,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          ...withdrawalOrder.metadata,
          failedAt: new Date().toISOString(),
          paystackTransferCode: transfer_code,
          paystackFailureReason: failureReason
        }
      });

      // 2. Find and update transaction record
      const transactionQuery = await admin.firestore()
        .collection('transactions')
        .where('referenceId', '==', reference)
        .where('type', '==', 'withdrawal')
        .limit(1)
        .get();

      if (!transactionQuery.empty) {
        const transactionDoc = transactionQuery.docs[0];
        transaction.update(transactionDoc.ref, {
          status: 'failed',
          metadata: {
            ...transactionDoc.data().metadata,
            failedAt: new Date().toISOString(),
            transferCode: transfer_code,
            failureReason
          }
        });
      }
    });

    // 3. Release held funds back to available balance
    await releaseHeldBalance(userId, withdrawalAmount, reference, executionId);

    // 4. Send failure notification to user
    try {
      await notificationService.sendWithdrawalFailedNotification({
        userId,
        amount: withdrawalAmount,
        bankAccountName: withdrawalOrder.bankAccount.accountName,
        reference,
        reason: failureReason
      }, executionId);
    } catch (notifError) {
      logger.error('Failed to send failure notification', executionId, notifError);
      // Don't fail the entire operation if notification fails
    }

    logger.success('Transfer failure processed', executionId, {
      reference,
      amount: withdrawalAmount,
      userId,
      reason: failureReason
    });

    return { success: true };
  } catch (error) {
    logger.error('Failed to process transfer.failed', executionId, error);
    throw error;
  }
}

/**
 * Process transfer.reversed webhook event
 */
async function handleTransferReversed(eventData, executionId) {
  try {
    const { reference, transfer_code, amount, recipient, reason } = eventData.data;
    const reversalReason = eventData.data.message || 'Transfer reversed by Paystack';

    logger.info('Processing transfer.reversed event', executionId, {
      reference,
      transferCode: transfer_code,
      reversalReason
    });

    // Find withdrawal order by reference
    const withdrawalRef = admin.firestore()
      .collection('withdrawal_orders')
      .doc(reference);

    const withdrawalDoc = await withdrawalRef.get();

    if (!withdrawalDoc.exists) {
      logger.error('Withdrawal order not found for transfer reversal', executionId, {
        reference,
        transferCode: transfer_code
      });
      throw new Error(`Withdrawal order not found: ${reference}`);
    }

    const withdrawalOrder = withdrawalDoc.data();
    const { userId, amount: withdrawalAmount } = withdrawalOrder;

    // Use Firestore transaction for atomic updates
    const reversalTransactionId = await admin.firestore().runTransaction(async (transaction) => {
      // 1. Update withdrawal order status to 'reversed'
      transaction.update(withdrawalRef, {
        status: 'reversed',
        reversalReason,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          ...withdrawalOrder.metadata,
          reversedAt: new Date().toISOString(),
          paystackTransferCode: transfer_code,
          paystackReversalReason: reversalReason
        }
      });

      // 2. Update original withdrawal transaction to 'cancelled'
      const transactionQuery = await admin.firestore()
        .collection('transactions')
        .where('referenceId', '==', reference)
        .where('type', '==', 'withdrawal')
        .limit(1)
        .get();

      if (!transactionQuery.empty) {
        const transactionDoc = transactionQuery.docs[0];
        transaction.update(transactionDoc.ref, {
          status: 'cancelled',
          metadata: {
            ...transactionDoc.data().metadata,
            cancelledAt: new Date().toISOString(),
            transferCode: transfer_code,
            reversalReason
          }
        });
      }

      // 3. Create reversal (refund) transaction
      const reversalTxnRef = admin.firestore().collection('transactions').doc();
      const reversalTransaction = {
        walletId: userId,
        userId,
        amount: withdrawalAmount,
        type: 'refund',
        status: 'completed',
        currency: 'NGN',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        description: `Reversal of withdrawal to ${withdrawalOrder.bankAccount.bankName}`,
        referenceId: `${reference}-REVERSAL`,
        metadata: {
          originalWithdrawalReference: reference,
          reversalReason,
          transferCode: transfer_code,
          bankAccount: withdrawalOrder.bankAccount
        },
        idempotencyKey: `${reference}-REVERSAL`
      };

      transaction.set(reversalTxnRef, reversalTransaction);

      return reversalTxnRef.id;
    });

    // 4. Release held funds back to available balance
    await releaseHeldBalance(userId, withdrawalAmount, reference, executionId);

    // 5. Send reversal notification to user
    try {
      await notificationService.sendWithdrawalReversedNotification({
        userId,
        amount: withdrawalAmount,
        bankAccountName: withdrawalOrder.bankAccount.accountName,
        reference,
        reason: reversalReason,
        reversalTransactionId
      }, executionId);
    } catch (notifError) {
      logger.error('Failed to send reversal notification', executionId, notifError);
      // Don't fail the entire operation if notification fails
    }

    logger.success('Transfer reversal processed', executionId, {
      reference,
      amount: withdrawalAmount,
      userId,
      reason: reversalReason,
      reversalTransactionId
    });

    return { success: true };
  } catch (error) {
    logger.error('Failed to process transfer.reversed', executionId, error);
    throw error;
  }
}

/**
 * Main entry point for processing transfer webhook events
 */
async function processTransferWebhook(eventData, executionId) {
  try {
    const { event, data } = eventData;

    logger.info('Processing transfer webhook', executionId, {
      event,
      reference: data.reference,
      transferCode: data.transfer_code
    });

    // Check for duplicate webhook (deduplication)
    const eventId = `${event}-${data.reference}-${data.transfer_code}`;
    const alreadyProcessed = await checkWebhookProcessed(eventId, executionId);

    if (alreadyProcessed) {
      logger.info('Skipping duplicate webhook', executionId, { eventId });
      return { success: true, duplicate: true };
    }

    // Route to appropriate handler based on event type
    switch (event) {
      case 'transfer.success':
        return await handleTransferSuccess(eventData, executionId);

      case 'transfer.failed':
        return await handleTransferFailed(eventData, executionId);

      case 'transfer.reversed':
        return await handleTransferReversed(eventData, executionId);

      default:
        logger.warning('Unknown transfer event type', executionId, { event });
        return { success: false, error: 'Unknown event type' };
    }
  } catch (error) {
    logger.error('Transfer webhook processing failed', executionId, error, {
      event: eventData.event,
      reference: eventData.data?.reference
    });
    throw error;
  }
}

module.exports = {
  processTransferWebhook,
  handleTransferSuccess,
  handleTransferFailed,
  handleTransferReversed,
  checkWebhookProcessed
};
