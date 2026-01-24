// ========================================================================
// Chat Triggers - RTDB Triggers for Chat Notifications
// ========================================================================
// Migrated from Firestore to RTDB for lower latency (~50ms vs 2-4s)
// ========================================================================

const { onValueCreated } = require('firebase-functions/v2/database');
const admin = require('firebase-admin');
const { FUNCTIONS_CONFIG, RTDB_CONFIG } = require('../utils/constants');
const { logger } = require('../utils/logger');
const { notificationService } = require('../services/notification-service');

// RTDB Database URL from centralized config
const DATABASE_URL = RTDB_CONFIG.DATABASE_URL;

/**
 * Get RTDB reference
 */
function getRtdb() {
  return admin.database(admin.app(), DATABASE_URL);
}

/**
 * Atomically claim notification to prevent duplicates.
 * Uses RTDB transaction to ensure only one function instance sends the notification.
 *
 * @param {string} chatId - The chat ID
 * @param {string} messageId - The message ID
 * @returns {Promise<boolean>} - True if this instance claimed the notification
 */
async function tryClaimNotification(chatId, messageId) {
  const db = getRtdb();
  const ref = db.ref(`messages/${chatId}/${messageId}/notificationSent`);

  try {
    const result = await ref.transaction((currentValue) => {
      if (currentValue === true) {
        // Already claimed by another instance
        return; // Abort transaction
      }
      return true; // Claim the notification
    });

    return result.committed;
  } catch (error) {
    logger.error(`tryClaimNotification failed: ${error.message}`, 'claim-notif');
    return false;
  }
}

/**
 * Get chat metadata from RTDB
 * @param {string} chatId - The chat ID
 * @returns {Promise<Object|null>} - Chat data or null
 */
async function getChatMetadata(chatId) {
  const db = getRtdb();
  const snapshot = await db.ref(`chats/${chatId}`).once('value');
  return snapshot.exists() ? snapshot.val() : null;
}

/**
 * Trigger: onChatMessageCreated
 *
 * Fires when a new message is created in RTDB at /messages/{chatId}/{messageId}.
 * - Atomically claims the notification to prevent duplicates
 * - Sends push notification to all participants except the sender
 * - Marks the message as notificationSent
 *
 * RTDB Message structure at /messages/{chatId}/{messageId}:
 * {
 *   id: string,
 *   chatId: string,
 *   senderId: string,
 *   senderName: string,
 *   senderAvatar: string | null,
 *   content: string,
 *   type: "text" | "image" | "video" | "document",
 *   status: "sending" | "sent" | "delivered" | "read" | "failed",
 *   timestamp: number (ServerValue.timestamp),
 *   mediaUrl: string | null,
 *   thumbnailUrl: string | null,
 *   fileName: string | null,
 *   fileSize: number | null,
 *   replyToMessageId: string | null,
 *   isDeleted: boolean,
 *   notificationSent: boolean,
 *   readBy: { [userId]: number }
 * }
 */
const onChatMessageCreated = onValueCreated(
  {
    ref: '/messages/{chatId}/{messageId}',
    instance: DATABASE_URL,
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TRIGGER_TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
  },
  async (event) => {
    const executionId = `rtdb-chat-notify-${Date.now()}`;

    try {
      logger.startFunction('onChatMessageCreated', executionId);

      const { chatId, messageId } = event.params;
      const messageData = event.data.val();

      if (!messageData) {
        logger.warning('Message data is null, skipping', executionId);
        return;
      }

      const { senderId, senderName, content, type, isDeleted, notificationSent } = messageData;

      // Skip if message is deleted
      if (isDeleted) {
        logger.info('Message is deleted, skipping notification', executionId);
        return;
      }

      // Skip if notification was already sent (shouldn't happen on create, but safety check)
      if (notificationSent === true) {
        logger.info('Notification already sent, skipping', executionId);
        return;
      }

      // Skip if sender info is missing
      if (!senderId || !content) {
        logger.warning('Missing senderId or content, skipping', executionId);
        return;
      }

      logger.info(`Processing message: chatId=${chatId}, messageId=${messageId}, sender=${senderName}`, executionId);

      // Atomically claim the notification to prevent duplicates
      const claimed = await tryClaimNotification(chatId, messageId);
      if (!claimed) {
        logger.info('Notification already claimed by another instance, skipping', executionId);
        return;
      }

      logger.info('Notification claimed successfully', executionId);

      // Get chat metadata for participant list
      const chatData = await getChatMetadata(chatId);
      if (!chatData) {
        logger.warning(`Chat ${chatId} not found in RTDB`, executionId);
        return;
      }

      const participantIds = chatData.participantIds || [];
      const recipientIds = participantIds.filter(id => id !== senderId);

      if (recipientIds.length === 0) {
        logger.info('No recipients to notify', executionId);
        return;
      }

      // Prepare notification content
      const notificationTitle = senderName || 'New Message';

      // Customize message preview based on type
      let messagePreview;
      switch (type) {
        case 'image':
          messagePreview = '📷 Image';
          break;
        case 'video':
          messagePreview = '🎬 Video';
          break;
        case 'document':
          messagePreview = '📄 Document';
          break;
        default:
          messagePreview = content.length > 100
            ? content.substring(0, 97) + '...'
            : content;
      }

      const notificationData = {
        type: 'chat_message',
        chatId: chatId,
        messageId: messageId,
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
            messagePreview,
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

      logger.success(`RTDB chat notification trigger completed for message ${messageId}`, executionId);

    } catch (error) {
      logger.error('Error in onChatMessageCreated trigger', executionId, error);
      throw error;
    }
  }
);

// ========================================================================
// Legacy Firestore Triggers (Deprecated - kept for reference)
// ========================================================================
// The following Firestore triggers have been replaced by RTDB triggers.
// They are kept here commented out for reference during migration.
// Once RTDB migration is confirmed working, these can be removed.
// ========================================================================

/*
// OLD: Firestore-based trigger (DEPRECATED)
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

const onChatMessageNotification_DEPRECATED = onDocumentUpdated(
  {
    document: 'chats/{chatId}',
    region: FUNCTIONS_CONFIG.REGION,
    ...
  },
  async (event) => {
    // Old Firestore logic using pendingNotification field
    // Replaced by RTDB onValueCreated trigger
  }
);
*/

module.exports = {
  onChatMessageCreated,
  // Legacy exports for backward compatibility during migration
  // These are now no-ops or can be removed after confirming RTDB works
  onChatMessageNotification: onChatMessageCreated, // Alias for existing index.js references
};
