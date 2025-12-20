// ========================================================================
// Notification Endpoints
// ========================================================================

const admin = require('firebase-admin');
const { createEndpoint } = require('../core/endpoint-factory');
const { emailService } = require('../services/email-service');
const { notificationService } = require('../services/notification-service');
const { ENVIRONMENT } = require('../utils/constants');
const { logger } = require('../utils/logger');
const {
  sendEmailSchema,
  sendFCMNotificationSchema,
  checkFCMConfigSchema
} = require('../schemas');

/**
 * Send Email
 * Sends an email using the email service
 */
const sendEmail = createEndpoint({
  name: 'sendEmail',
  timeout: 60,
  schema: sendEmailSchema
}, async (data, ctx) => {
  const { executionId } = ctx;
  const { to, subject, text } = data;

  const success = await emailService.sendEmail(to, subject, text, null, [], executionId);

  if (success) {
    return { success: true, message: 'Email sent successfully' };
  } else {
    throw {
      statusCode: 500,
      message: 'Error sending email'
    };
  }
});

/**
 * Check FCM Config
 * Checks Firebase Cloud Messaging configuration
 */
const checkFCMConfig = createEndpoint({
  name: 'checkFCMConfig',
  timeout: 60,
  schema: checkFCMConfigSchema
}, async (data, ctx) => {
  const { executionId } = ctx;

  const config = {
    projectId: ENVIRONMENT.PROJECT_ID,
    envProjectId: process.env.GOOGLE_CLOUD_PROJECT,
    gcloudProjectId: process.env.GCLOUD_PROJECT,
    adminProjectId: admin.instanceId().app.options.projectId,
  };

  const connectionTest = await notificationService.testFCMConnection(executionId);

  return {
    success: true,
    config: config,
    connectionTest: connectionTest,
    timestamp: new Date().toISOString()
  };
});

/**
 * Send FCM Notification
 * Sends a push notification via Firebase Cloud Messaging
 */
const sendFCMNotification = createEndpoint({
  name: 'sendFCMNotification',
  timeout: 60,
  schema: sendFCMNotificationSchema
}, async (data, ctx) => {
  const { executionId } = ctx;
  const { userId, title, body, data: notificationData } = data;

  const result = await notificationService.sendNotificationToUser(
    userId,
    title,
    body,
    notificationData,
    executionId
  );

  if (result.success) {
    return {
      success: true,
      messageId: result.messageId
    };
  } else {
    throw {
      statusCode: 400,
      message: result.reason || result.error
    };
  }
});

module.exports = {
  sendEmail,
  checkFCMConfig,
  sendFCMNotification
};
