// ========================================================================
// Parcel Triggers - Firestore Document Triggers for Parcel Updates
// ========================================================================

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { FUNCTIONS_CONFIG } = require('../utils/constants');
const { logger } = require('../utils/logger');
const { dbHelper } = require('../utils/database');
const { notificationService } = require('../services/notification-service');

/**
 * Trigger: onParcelAwaitingConfirmation
 *
 * Fires when a parcel document is updated in Firestore.
 * When status changes to 'awaiting_confirmation':
 * - Sends push notification to the sender
 * - Sets the awaitingConfirmationAt timestamp
 *
 * Status Flow: arrived -> awaiting_confirmation -> delivered
 */
const onParcelAwaitingConfirmation = onDocumentUpdated(
  {
    document: 'parcels/{parcelId}',
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
  },
  async (event) => {
    const executionId = `parcel-confirm-trigger-${Date.now()}`;

    try {
      logger.startFunction('onParcelAwaitingConfirmation', executionId);

      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const parcelId = event.params.parcelId;

      // Check if status changed to 'awaiting_confirmation'
      if (beforeData.status === afterData.status) {
        logger.info('Status unchanged, skipping trigger', executionId);
        return;
      }

      if (afterData.status !== 'awaiting_confirmation') {
        logger.info(`Status changed to ${afterData.status}, not awaiting_confirmation`, executionId);
        return;
      }

      logger.info(`Parcel ${parcelId} status changed to awaiting_confirmation`, executionId);

      // Get sender information
      const senderId = afterData.senderId;
      if (!senderId) {
        logger.warning(`No senderId found for parcel ${parcelId}`, executionId);
        return;
      }

      // Set the awaitingConfirmationAt timestamp
      await dbHelper.updateDocument('parcels', parcelId, {
        awaitingConfirmationAt: dbHelper.getServerTimestamp()
      }, executionId);

      logger.info(`Set awaitingConfirmationAt timestamp for parcel ${parcelId}`, executionId);

      // Get receiver name for the notification
      const receiverName = afterData.receiver?.name || 'the receiver';
      const receiverPhone = afterData.receiver?.phoneNumber || '';

      // Get parcel description
      const parcelDescription = afterData.description || `Parcel #${parcelId.substring(0, 8)}`;

      // Send notification to sender
      const notificationTitle = 'Parcel Delivered - Please Confirm';
      const notificationBody = `Your parcel "${parcelDescription}" has been marked as delivered by the courier. Please contact ${receiverName}${receiverPhone ? ` (${receiverPhone})` : ''} to verify delivery before releasing payment.`;

      const notificationData = {
        type: 'delivery_confirmation_required',
        parcelId: parcelId,
        action: 'confirm_delivery',
        receiverName: receiverName,
        receiverPhone: receiverPhone
      };

      const result = await notificationService.sendNotificationToUser(
        senderId,
        notificationTitle,
        notificationBody,
        notificationData,
        executionId
      );

      if (result.success) {
        logger.success(`Notification sent to sender ${senderId} for parcel ${parcelId}`, executionId);
      } else {
        logger.warning(`Failed to send notification to sender ${senderId}: ${result.reason || result.error}`, executionId);
      }

      // Also log this event for audit purposes
      await dbHelper.addDocument('parcel_events', {
        parcelId: parcelId,
        eventType: 'awaiting_confirmation_notification_sent',
        senderId: senderId,
        notificationResult: result,
        timestamp: dbHelper.getServerTimestamp()
      }, executionId);

      logger.success(`Trigger completed for parcel ${parcelId}`, executionId);

    } catch (error) {
      logger.error('Error in onParcelAwaitingConfirmation trigger', executionId, error);
      throw error;
    }
  }
);

module.exports = {
  onParcelAwaitingConfirmation
};
