// ========================================================================
// Chat Triggers - Firestore Document Triggers for Chat Notifications
// ========================================================================

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const { FUNCTIONS_CONFIG } = require('../utils/constants');
const { logger } = require('../utils/logger');
const { dbHelper } = require('../utils/database');
const { notificationService } = require('../services/notification-service');

/**
 * Helper function to update notificationSent flag in a message within a page
 * @param {string} chatId - The chat ID
 * @param {string} messageId - The message ID to mark as sent
 * @param {string} executionId - Execution ID for logging
 */
async function markMessageNotificationSent(chatId, messageId, executionId) {
  if (!messageId) {
    logger.warning('No messageId provided, cannot mark notificationSent', executionId);
    return;
  }

  try {
    const db = admin.firestore();
    const pagesRef = db.collection('chats').doc(chatId).collection('pages');
    const pagesSnapshot = await pagesRef.get();

    for (const pageDoc of pagesSnapshot.docs) {
      const pageData = pageDoc.data();
      const messages = pageData.messages || [];
      
      const messageIndex = messages.findIndex(m => m.id === messageId);
      if (messageIndex !== -1) {
        // Found the message, update it
        const updatedMessages = messages.map(m => {
          if (m.id === messageId) {
            return { ...m, notificationSent: true };
          }
          return m;
        });

        await pageDoc.ref.update({
          messages: updatedMessages,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        logger.info(`Marked message ${messageId} as notificationSent in page ${pageDoc.id}`, executionId);
        return;
      }
    }

    logger.warning(`Message ${messageId} not found in any page for chat ${chatId}`, executionId);
  } catch (error) {
    logger.error(`Failed to mark message ${messageId} notificationSent: ${error.message}`, executionId);
  }
}

/**
 * Trigger: onChatMessageNotification
 *
 * Fires when a chat document is updated in Firestore.
 * When the pendingNotification field is added or updated:
 * - Sends push notification to all participants except the sender
 * - Marks the message as notificationSent in the page
 * - Clears the pendingNotification field after sending
 *
 * Expected pendingNotification structure:
 * {
 *   senderId: string,
 *   senderName: string,
 *   messagePreview: string,
 *   chatId: string,
 *   messageId: string,
 *   timestamp: Timestamp,
 *   type: string (e.g., 'text', 'image')
 * }
 *
 * Note: Messages are now stored in paged structure under chats/{chatId}/pages/{pageId}
 * but the notification trigger still fires from pendingNotification on the chat doc.
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

      const { senderId, senderName, messagePreview, type, messageId } = afterNotification;

      if (!senderId || !messagePreview) {
        logger.warning('Missing required notification data', executionId);
        // Clear invalid notification
        await dbHelper.updateDocument('chats', chatId, {
          pendingNotification: null
        }, executionId);
        return;
      }

      if (!messageId) {
        logger.warning('Missing messageId in notification data', executionId);
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
        messageId: messageId || '', // Include messageId for notification tracking
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

      // Mark the message as notificationSent in the page
      if (successCount > 0 && messageId) {
        await markMessageNotificationSent(chatId, messageId, executionId);
      }

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

/**
 * Trigger: onChatPageUpdated
 *
 * DISABLED - This trigger was causing duplicate notifications.
 * The primary notification path is onChatMessageNotification which
 * watches pendingNotification on the chat document.
 *
 * This backup trigger is kept for reference but not exported.
 * It could be re-enabled if the pendingNotification approach fails.
 *
 * Fires when a message page document is updated (messages appended).
 * This is an alternative/backup notification path that watches the
 * paged message structure directly.
 *
 * Message page structure:
 * chats/{chatId}/pages/{pageId}
 * {
 *   chatId: string,
 *   pageNumber: int,
 *   messages: [MessageModel, ...],
 *   messageCount: int,
 *   bytesUsed: int,
 *   hasOlderPages: bool,
 *   createdAt: Timestamp,
 *   updatedAt: Timestamp
 * }
 *
 * This trigger can be used to:
 * - Send notifications for messages that missed the pendingNotification path
 * - Track message analytics
 * - Trigger read receipts or delivery confirmations
 */
/*
const onChatPageUpdated = onDocumentUpdated(
  {
    document: 'chats/{chatId}/pages/{pageId}',
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TRIGGER_TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
  },
  async (event) => {
    const executionId = `chat-page-trigger-${Date.now()}`;

    try {
      logger.startFunction('onChatPageUpdated', executionId);

      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      const { chatId, pageId } = event.params;

      const beforeMessages = beforeData.messages || [];
      const afterMessages = afterData.messages || [];

      // Find new messages (appended since last update)
      const newMessagesCount = afterMessages.length - beforeMessages.length;

      if (newMessagesCount <= 0) {
        logger.info('No new messages detected (update was edit/delete), skipping', executionId);
        return;
      }

      // Get the new messages (they are appended at the end)
      const newMessages = afterMessages.slice(-newMessagesCount);

      logger.info(
        `Detected ${newMessagesCount} new message(s) in chat ${chatId}, page ${pageId}`,
        executionId
      );

      // Process each new message for notifications that weren't sent yet
      for (const message of newMessages) {
        if (message.notificationSent) {
          logger.info(`Message ${message.id} notification already sent, skipping`, executionId);
          continue;
        }

        // Get the chat document for participant info
        const chatResult = await dbHelper.getDocument('chats', chatId, executionId);
        if (!chatResult || !chatResult.data) {
          logger.warning(`Chat ${chatId} not found`, executionId);
          continue;
        }

        const chatData = chatResult.data;
        const participantIds = chatData.participantIds || [];
        const recipientIds = participantIds.filter(id => id !== message.senderId);

        if (recipientIds.length === 0) {
          logger.info('No recipients for message', executionId);
          continue;
        }

        // Prepare notification
        const notificationTitle = message.senderName || 'New Message';
        const messagePreview = message.content?.length > 100
          ? message.content.substring(0, 97) + '...'
          : message.content || '';

        const notificationData = {
          type: 'chat_message',
          chatId: chatId,
          messageId: message.id || '',
          senderId: message.senderId,
          senderName: message.senderName || '',
          action: 'open_chat'
        };

        // Send notifications
        const results = await Promise.allSettled(
          recipientIds.map(recipientId =>
            notificationService.sendNotificationToUser(
              recipientId,
              notificationTitle,
              messagePreview,
              notificationData,
              `${executionId}-${recipientId}`
            )
          )
        );

        const successCount = results.filter(
          r => r.status === 'fulfilled' && r.value && r.value.success
        ).length;

        logger.info(
          `Page trigger: sent ${successCount}/${recipientIds.length} notifications for message ${message.id}`,
          executionId
        );

        // Mark notification as sent using the helper function
        if (successCount > 0 && message.id) {
          await markMessageNotificationSent(chatId, message.id, executionId);
        }
      }

      logger.success(`Page trigger completed for chat ${chatId}, page ${pageId}`, executionId);

    } catch (error) {
      logger.error('Error in onChatPageUpdated trigger', executionId, error);
      throw error;
    }
  }
);
*/

module.exports = {
  onChatMessageNotification,
  // onChatPageUpdated - DISABLED to prevent duplicate notifications
};
