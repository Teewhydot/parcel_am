// ========================================================================
// Notification Service - Withdrawal Notification Methods Extension
// ========================================================================
// Add these methods to the NotificationService class before the closing brace

/**
 * Send withdrawal success notification
 */
async sendWithdrawalSuccessNotification(params, executionId = 'withdrawal-success-notif') {
  try {
    const { userId, amount, bankAccountName, bankName, reference, expectedArrivalTime } = params;

    const title = '✅ Withdrawal Successful';
    const body = `Your withdrawal of NGN ${amount.toLocaleString()} to ${bankName} is processing`;

    const data = {
      type: 'withdrawal_success',
      reference,
      amount: amount.toString(),
      bankAccountName,
      bankName,
      expectedArrivalTime,
      action: 'view_withdrawal_status'
    };

    logger.info('Sending withdrawal success notification', executionId, {
      userId,
      amount,
      reference
    });

    return await this.sendNotificationToUser(userId, title, body, data, executionId);
  } catch (error) {
    logger.error('Failed to send withdrawal success notification', executionId, error);
    throw error;
  }
}

/**
 * Send withdrawal failed notification
 */
async sendWithdrawalFailedNotification(params, executionId = 'withdrawal-failed-notif') {
  try {
    const { userId, amount, bankAccountName, reference, reason } = params;

    const title = '❌ Withdrawal Failed';
    const body = `Your withdrawal of NGN ${amount.toLocaleString()} failed. Funds have been returned to your wallet.`;

    const data = {
      type: 'withdrawal_failed',
      reference,
      amount: amount.toString(),
      bankAccountName,
      failureReason: reason,
      action: 'view_withdrawal_status'
    };

    logger.info('Sending withdrawal failed notification', executionId, {
      userId,
      amount,
      reference,
      reason
    });

    return await this.sendNotificationToUser(userId, title, body, data, executionId);
  } catch (error) {
    logger.error('Failed to send withdrawal failed notification', executionId, error);
    throw error;
  }
}

/**
 * Send withdrawal reversed notification
 */
async sendWithdrawalReversedNotification(params, executionId = 'withdrawal-reversed-notif') {
  try {
    const { userId, amount, bankAccountName, reference, reason, reversalTransactionId } = params;

    const title = '🔄 Withdrawal Reversed';
    const body = `Your withdrawal of NGN ${amount.toLocaleString()} was reversed. Funds have been returned to your wallet.`;

    const data = {
      type: 'withdrawal_reversed',
      reference,
      amount: amount.toString(),
      bankAccountName,
      reversalReason: reason,
      reversalTransactionId,
      action: 'view_wallet'
    };

    logger.info('Sending withdrawal reversed notification', executionId, {
      userId,
      amount,
      reference,
      reason
    });

    return await this.sendNotificationToUser(userId, title, body, data, executionId);
  } catch (error) {
    logger.error('Failed to send withdrawal reversed notification', executionId, error);
    throw error;
  }
}

// ========================================================================
// INSTRUCTIONS FOR INTEGRATION
// ========================================================================
//
// 1. Open /functions/services/notification-service.js
//
// 2. Find the line that says "async getUnreadNotificationCount(userId, executionId = 'unread-count') {"
//    (Around line 606)
//
// 3. Add the three methods above BEFORE that method (around line 605)
//
// 4. The methods should be added inside the NotificationService class but before
//    getUnreadNotificationCount
//
// Example placement:
//
// class NotificationService {
//   ... existing methods ...
//
//   async testConnection(executionId = 'fcm-test') {
//     ... existing code ...
//   }
//
//   // ADD THE THREE METHODS HERE (sendWithdrawalSuccessNotification, etc.)
//
//   async getUnreadNotificationCount(userId, executionId = 'unread-count') {
//     ... existing code ...
//   }
//
//   ... remaining methods ...
// }
//
// ========================================================================

module.exports = {
  // These methods should be added to the NotificationService class
  // This file is for reference only
};
