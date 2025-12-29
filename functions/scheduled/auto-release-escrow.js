// ========================================================================
// Auto-Release Escrow Scheduled Task
// ========================================================================
// Runs hourly to check for parcels awaiting confirmation and:
// - At 24 hours: Send reminder notification to sender
// - At 48 hours: Auto-release payment to courier
// ========================================================================

const { createScheduledTask } = require('../core/scheduled-task-factory');
const { dbHelper } = require('../utils/database');
const { logger } = require('../utils/logger');
const { notificationService } = require('../services/notification-service');

/**
 * Auto-Release Escrow Task
 * Runs every hour to check for parcels awaiting confirmation
 */
const autoReleaseEscrow = createScheduledTask({
  name: 'autoReleaseEscrow',
  schedule: 'every 1 hours',
  secrets: []
}, async (context, executionId) => {
  logger.info('Starting auto-release escrow check', executionId);

  // Get current time
  const now = new Date();
  const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const fortyEightHoursAgo = new Date(now.getTime() - 48 * 60 * 60 * 1000);

  // Query parcels with status 'awaiting_confirmation'
  const awaitingParcels = await dbHelper.queryDocuments('parcels',
    [
      { field: 'status', operator: '==', value: 'awaiting_confirmation' }
    ],
    null, 100, executionId
  );

  logger.info(`Found ${awaitingParcels.length} parcels awaiting confirmation`, executionId);

  let remindersSent = 0;
  let autoReleased = 0;
  let errors = 0;

  for (const parcel of awaitingParcels) {
    const parcelId = parcel.id;
    const parcelData = parcel.data;

    try {
      // Get the awaitingConfirmationAt timestamp
      let awaitingConfirmationAt = parcelData.awaitingConfirmationAt;

      // Convert Firestore Timestamp to Date if necessary
      if (awaitingConfirmationAt && awaitingConfirmationAt.toDate) {
        awaitingConfirmationAt = awaitingConfirmationAt.toDate();
      } else if (awaitingConfirmationAt && typeof awaitingConfirmationAt === 'string') {
        awaitingConfirmationAt = new Date(awaitingConfirmationAt);
      }

      if (!awaitingConfirmationAt) {
        logger.warning(`Parcel ${parcelId} has no awaitingConfirmationAt timestamp`, executionId);
        continue;
      }

      // Check if 48 hours have passed - auto-release payment
      if (awaitingConfirmationAt <= fortyEightHoursAgo) {
        await handleAutoRelease(parcelId, parcelData, executionId);
        autoReleased++;
      }
      // Check if 24 hours have passed but not yet 48 - send reminder
      else if (awaitingConfirmationAt <= twentyFourHoursAgo && !parcelData.reminderSent) {
        await sendReminderNotification(parcelId, parcelData, executionId);
        remindersSent++;
      }

    } catch (error) {
      logger.error(`Error processing parcel ${parcelId}`, executionId, error);
      errors++;
    }
  }

  logger.success(
    `Auto-release check completed: ${remindersSent} reminders sent, ${autoReleased} auto-released, ${errors} errors`,
    executionId
  );
});

/**
 * Send 24-hour reminder notification to sender
 */
async function sendReminderNotification(parcelId, parcelData, executionId) {
  const senderId = parcelData.senderId;
  if (!senderId) {
    logger.warning(`No senderId for parcel ${parcelId}`, executionId);
    return;
  }

  const parcelDescription = parcelData.description || `Parcel #${parcelId.substring(0, 8)}`;
  const receiverName = parcelData.receiver?.name || 'the receiver';

  const title = 'Reminder: Confirm Delivery';
  const body = `Your parcel "${parcelDescription}" is awaiting confirmation. Please contact ${receiverName} to verify delivery. Payment will be auto-released in 24 hours if no action is taken.`;

  const data = {
    type: 'delivery_confirmation_reminder',
    parcelId: parcelId,
    action: 'confirm_delivery'
  };

  await notificationService.sendNotificationToUser(senderId, title, body, data, executionId);

  // Mark that reminder was sent
  await dbHelper.updateDocument('parcels', parcelId, {
    reminderSent: true,
    reminderSentAt: dbHelper.getServerTimestamp()
  }, executionId);

  logger.info(`24-hour reminder sent for parcel ${parcelId}`, executionId);
}

/**
 * Auto-release payment after 48 hours
 */
async function handleAutoRelease(parcelId, parcelData, executionId) {
  const escrowId = parcelData.escrowId;
  const senderId = parcelData.senderId;
  const travelerId = parcelData.travelerId;

  if (!escrowId) {
    logger.warning(`No escrowId for parcel ${parcelId}, cannot auto-release`, executionId);
    return;
  }

  logger.info(`Auto-releasing escrow for parcel ${parcelId}`, executionId);

  // Get escrow details
  const { data: escrowData } = await dbHelper.getDocument('escrows', escrowId, executionId);

  if (!escrowData) {
    logger.error(`Escrow ${escrowId} not found for parcel ${parcelId}`, executionId);
    return;
  }

  if (escrowData.status === 'released') {
    logger.info(`Escrow ${escrowId} already released`, executionId);
    return;
  }

  const amount = escrowData.amount || parcelData.price || 0;
  const currency = escrowData.currency || parcelData.currency || 'NGN';

  // Update escrow status
  await dbHelper.updateDocument('escrows', escrowId, {
    status: 'released',
    releasedAt: dbHelper.getServerTimestamp(),
    releaseType: 'auto',
    autoReleasedReason: 'No confirmation within 48 hours'
  }, executionId);

  // Update parcel status to delivered
  await dbHelper.updateDocument('parcels', parcelId, {
    status: 'delivered',
    deliveredAt: dbHelper.getServerTimestamp(),
    autoReleased: true,
    autoReleasedAt: dbHelper.getServerTimestamp()
  }, executionId);

  // Credit the courier's wallet
  if (travelerId) {
    await creditCourierWallet(travelerId, amount, currency, parcelId, executionId);
  }

  // Notify sender that payment was auto-released
  if (senderId) {
    const parcelDescription = parcelData.description || `Parcel #${parcelId.substring(0, 8)}`;

    await notificationService.sendNotificationToUser(
      senderId,
      'Payment Auto-Released',
      `Payment of ${currency} ${amount.toLocaleString()} for "${parcelDescription}" has been auto-released to the courier after 48 hours.`,
      {
        type: 'escrow_auto_released',
        parcelId: parcelId,
        amount: amount.toString(),
        currency: currency
      },
      executionId
    );
  }

  // Notify courier that payment was received
  if (travelerId) {
    await notificationService.sendNotificationToUser(
      travelerId,
      'Payment Received',
      `You have received ${currency} ${amount.toLocaleString()} for delivering a parcel. The payment has been credited to your wallet.`,
      {
        type: 'payment_released',
        parcelId: parcelId,
        amount: amount.toString(),
        currency: currency
      },
      executionId
    );
  }

  // Log the auto-release event
  await dbHelper.addDocument('parcel_events', {
    parcelId: parcelId,
    eventType: 'escrow_auto_released',
    escrowId: escrowId,
    amount: amount,
    currency: currency,
    senderId: senderId,
    travelerId: travelerId,
    timestamp: dbHelper.getServerTimestamp()
  }, executionId);

  logger.success(`Auto-released escrow ${escrowId} for parcel ${parcelId}`, executionId);
}

/**
 * Credit the courier's wallet with the released escrow amount
 */
async function creditCourierWallet(travelerId, amount, currency, parcelId, executionId) {
  try {
    // Get current wallet balance
    const { data: userData } = await dbHelper.getDocument('users', travelerId, executionId);

    const currentBalance = userData?.walletBalance || 0;
    const newBalance = currentBalance + amount;

    // Update wallet balance
    await dbHelper.updateDocument('users', travelerId, {
      walletBalance: newBalance,
      lastWalletUpdate: dbHelper.getServerTimestamp()
    }, executionId);

    // Create wallet transaction record
    await dbHelper.addDocument(`users/${travelerId}/wallet_transactions`, {
      type: 'credit',
      amount: amount,
      currency: currency,
      description: `Delivery payment for parcel ${parcelId.substring(0, 8)}`,
      parcelId: parcelId,
      balanceBefore: currentBalance,
      balanceAfter: newBalance,
      status: 'completed',
      createdAt: dbHelper.getServerTimestamp()
    }, executionId);

    logger.success(`Credited ${currency} ${amount} to courier ${travelerId}`, executionId);
  } catch (error) {
    logger.error(`Failed to credit courier wallet: ${travelerId}`, executionId, error);
    throw error;
  }
}

module.exports = {
  autoReleaseEscrow
};
