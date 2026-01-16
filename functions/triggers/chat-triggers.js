// ========================================================================
// Chat Triggers - Firestore Document Triggers for Chat Notifications
// ========================================================================

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { FUNCTIONS_CONFIG } = require('../utils/constants');
const { logger } = require('../utils/logger');
const { dbHelper } = require('../utils/database');
const { notificationService } = require('../services/notification-service');

/**
 * Trigger: onChatMessageNotification
 *
 * Fires when a chat document is updated in Firestore.
 * When the pendingNotification field is added or updated:
 * - Sends push notification to all participants except the sender
 * - Clears the pendingNotification field after sending
 *
 * Expected pendingNotification structure:
 * {
 *   senderId: string,
 *   senderName: string,
 *   messagePreview: string,
 *   chatId: string,
 *   timestamp: Timestamp,
 *   type: string (e.g., 'text', 'image')
 * }
 */
const onChatMessageNotification = onDocumentUpdated(
  {
    document: 'chats/{chatId}',
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TRIGGER_TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
  },
  async (event) => {
    const executionId = `chat-notify-trigger-${Date.now()}`;

    try {
      logger.startFunction('onChatMessageNotification', executionId);

      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const chatId = event.params.chatId;

      // Check if pendingNotification was added or updated
      const beforeNotification = beforeData.pendingNotification;
      const afterNotification = afterData.pendingNotification;

      // Skip if no pending notification in after data
      if (!afterNotification) {
        logger.info('No pending notification, skipping', executionId);
        return;
      }

      // Check if it's a new notification (different timestamp or didn't exist before)
      const beforeTimestamp = beforeNotification?.timestamp?.toMillis?.();
      const afterTimestamp = afterNotification?.timestamp?.toMillis?.();

      if (beforeTimestamp && beforeTimestamp === afterTimestamp) {
        logger.info('Same notification timestamp, skipping', executionId);
        return;
      }

      const { senderId, senderName, messagePreview, type } = afterNotification;

      if (!senderId || !messagePreview) {
        logger.warning('Missing required notification data', executionId);
        // Clear invalid notification
        await dbHelper.updateDocument('chats', chatId, {
          pendingNotification: null
        }, executionId);
        return;
      }

      logger.info(`Processing chat notification from ${senderName} in chat ${chatId}`, executionId);

      // Get all participants except sender
      const participantIds = afterData.participantIds || [];
      const recipientIds = participantIds.filter(id => id !== senderId);

      if (recipientIds.length === 0) {
        logger.info('No recipients to notify', executionId);
        await dbHelper.updateDocument('chats', chatId, {
          pendingNotification: null
        }, executionId);
        return;
      }

      // Prepare notification content
      const notificationTitle = senderName || 'New Message';
      const notificationBody = messagePreview.length > 100
        ? messagePreview.substring(0, 97) + '...'
        : messagePreview;

      const notificationData = {
        type: 'chat_message',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName || '',
        action: 'open_chat'
      };

      // Send notifications to each recipient
      const results = await Promise.allSettled(
        recipientIds.map(recipientId =>
          notificationService.sendNotificationToUser(
            recipientId,
            notificationTitle,
            notificationBody,
            notificationData,
            `${executionId}-${recipientId}`
          )
        )
      );

      // Count successes and failures
      const successCount = results.filter(
        r => r.status === 'fulfilled' && r.value && r.value.success
      ).length;

      const failedCount = recipientIds.length - successCount;

      logger.info(
        `Sent ${successCount}/${recipientIds.length} chat notifications (${failedCount} failed)`,
        executionId
      );

      // Clear the pendingNotification field
      await dbHelper.updateDocument('chats', chatId, {
        pendingNotification: null
      }, executionId);

      logger.success(`Chat notification trigger completed for chat ${chatId}`, executionId);

    } catch (error) {
      logger.error('Error in onChatMessageNotification trigger', executionId, error);

      // Attempt to clear pendingNotification even on error to prevent infinite retries
      try {
        const chatId = event.params.chatId;
        await dbHelper.updateDocument('chats', chatId, {
          pendingNotification: null
        }, executionId);
      } catch (clearError) {
        logger.error('Failed to clear pendingNotification after error', executionId, clearError);
      }

      throw error;
    }
  }
);

module.exports = {
  onChatMessageNotification
};
