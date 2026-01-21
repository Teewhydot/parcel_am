// ========================================================================
// Parcel Triggers - Firestore Document Triggers for Parcel Updates
// ========================================================================

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { FUNCTIONS_CONFIG } = require('../utils/constants');
const { logger } = require('../utils/logger');
const { dbHelper } = require('../utils/database');
const { notificationService } = require('../services/notification-service');

/**
 * Status notification configurations
 * Maps parcel status to notification content for the sender
 */
const STATUS_NOTIFICATIONS = {
  picked_up: {
    title: 'Parcel Picked Up',
    getBody: (description, travelerName) =>
      `Your parcel "${description}" has been picked up by ${travelerName || 'the courier'}.`,
    type: 'parcel_picked_up',
    action: 'view_tracking'
  },
  in_transit: {
    title: 'Parcel In Transit',
    getBody: (description, travelerName) =>
      `Your parcel "${description}" is now in transit with ${travelerName || 'the courier'}.`,
    type: 'parcel_in_transit',
    action: 'view_tracking'
  },
  arrived: {
    title: 'Parcel Arrived',
    getBody: (description, travelerName) =>
      `Your parcel "${description}" has arrived at destination. ${travelerName || 'The courier'} will deliver it soon.`,
    type: 'parcel_arrived',
    action: 'view_tracking'
  },
  awaiting_confirmation: {
    title: 'Parcel Delivered - Please Confirm',
    getBody: (description, travelerName, receiverName, receiverPhone) =>
      `Your parcel "${description}" has been marked as delivered by ${travelerName || 'the courier'}. Please contact ${receiverName}${receiverPhone ? ` (${receiverPhone})` : ''} to verify delivery before releasing payment.`,
    type: 'delivery_confirmation_required',
    action: 'confirm_delivery'
  },
  delivered: {
    title: 'Delivery Confirmed',
    getBody: (description) =>
      `Your parcel "${description}" delivery has been confirmed. Payment will be released to the courier.`,
    type: 'delivery_confirmed',
    action: 'view_details'
  }
};

/**
 * Trigger: onParcelStatusUpdate
 *
 * Fires when a parcel document is updated in Firestore.
 * When the status changes, sends a push notification to the sender
 * informing them of the delivery progress.
 *
 * Status Flow: created -> paid -> picked_up -> in_transit -> arrived -> awaiting_confirmation -> delivered
 */
const onParcelStatusUpdate = onDocumentUpdated(
  {
    document: 'parcels/{parcelId}',
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TRIGGER_TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
  },
  async (event) => {
    const executionId = `parcel-status-trigger-${Date.now()}`;

    try {
      logger.startFunction('onParcelStatusUpdate', executionId);

      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const parcelId = event.params.parcelId;

      const beforeStatus = beforeData.status;
      const afterStatus = afterData.status;

      // Check if status changed
      if (beforeStatus === afterStatus) {
        logger.info('Status unchanged, skipping trigger', executionId);
        return;
      }

      logger.info(`Parcel ${parcelId} status changed: ${beforeStatus} -> ${afterStatus}`, executionId);

      // Get notification config for this status
      const notificationConfig = STATUS_NOTIFICATIONS[afterStatus];
      if (!notificationConfig) {
        logger.info(`No notification configured for status: ${afterStatus}`, executionId);
        return;
      }

      // Get sender information from nested sender object
      // Parcel structure: { sender: { userId, name, phoneNumber, address, email } }
      const senderId = afterData.sender?.userId;
      if (!senderId) {
        logger.warning(`No sender.userId found for parcel ${parcelId}`, executionId);
        return;
      }

      // Special handling for awaiting_confirmation: set timestamp
      if (afterStatus === 'awaiting_confirmation') {
        await dbHelper.updateDocument('parcels', parcelId, {
          awaitingConfirmationAt: dbHelper.getServerTimestamp()
        }, executionId);
        logger.info(`Set awaitingConfirmationAt timestamp for parcel ${parcelId}`, executionId);
      }

      // Get parcel details for notification
      const parcelDescription = afterData.description || `Parcel #${parcelId.substring(0, 8)}`;
      const receiverName = afterData.receiver?.name || 'the receiver';
      const receiverPhone = afterData.receiver?.phoneNumber || '';
      
      // Get traveler name
      let travelerName = 'the courier';
      const travelerId = afterData.travelerId;
      if (travelerId) {
        const travelerDoc = await dbHelper.getDocument('users', travelerId, executionId);
        if (travelerDoc) {
          travelerName = travelerDoc.displayName || travelerDoc.name || 'the courier';
        }
      }

      // Build notification content
      const notificationTitle = notificationConfig.title;
      const notificationBody = notificationConfig.getBody(
        parcelDescription,
        travelerName,
        receiverName,
        receiverPhone
      );

      const notificationData = {
        type: notificationConfig.type,
        parcelId: parcelId,
        action: notificationConfig.action,
        status: afterStatus,
        travelerId: travelerId || ''
      };

      // Send notification to sender
      const result = await notificationService.sendNotificationToUser(
        senderId,
        notificationTitle,
        notificationBody,
        notificationData,
        executionId
      );

      if (result.success) {
        logger.success(`Notification sent to sender ${senderId} for parcel ${parcelId} (${afterStatus})`, executionId);
      } else {
        logger.warning(`Failed to send notification to sender ${senderId}: ${result.reason || result.error}`, executionId);
      }

      // Log this event for audit purposes
      await dbHelper.addDocument('parcel_events', {
        parcelId: parcelId,
        eventType: `${afterStatus}_notification_sent`,
        senderId: senderId,
        travelerId: travelerId || null,
        previousStatus: beforeStatus,
        newStatus: afterStatus,
        notificationResult: result,
        timestamp: dbHelper.getServerTimestamp()
      }, executionId);

      logger.success(`Trigger completed for parcel ${parcelId} (${afterStatus})`, executionId);

    } catch (error) {
      logger.error('Error in onParcelStatusUpdate trigger', executionId, error);
      throw error;
    }
  }
);

/**
 * Trigger: onParcelAwaitingConfirmation (Legacy - kept for backwards compatibility)
 *
 * This trigger is now handled by onParcelStatusUpdate.
 * Keeping this export to avoid breaking existing deployments.
 * Can be removed after verifying onParcelStatusUpdate works correctly.
 */
const onParcelAwaitingConfirmation = onParcelStatusUpdate;

module.exports = {
  onParcelAwaitingConfirmation,
  onParcelStatusUpdate
};
