// ========================================================================
// Notification Request Schemas
// ========================================================================

const { Validators, DataCleaners, ValidationError } = require('../utils/validation');

/**
 * Schema for sending email
 */
const sendEmailSchema = {
  validate(body) {
    const { to, subject, text, html } = body;

    Validators.isEmail(to, 'to');
    Validators.isNotEmpty(subject, 'subject');

    if (!text && !html) {
      throw new ValidationError('Either text or html content is required', 'content');
    }

    return {
      to: DataCleaners.sanitizeEmail(to),
      subject: DataCleaners.sanitizeString(subject),
      text: text ? DataCleaners.sanitizeString(text) : null,
      html: html || null
    };
  }
};

/**
 * Schema for sending FCM notification
 */
const sendFCMNotificationSchema = {
  validate(body) {
    const { userId, title, body: notificationBody, data = {} } = body;

    Validators.isNotEmpty(userId, 'userId');
    Validators.isNotEmpty(title, 'title');
    Validators.isNotEmpty(notificationBody, 'body');

    return {
      userId: DataCleaners.sanitizeString(userId),
      title: DataCleaners.sanitizeString(title),
      body: DataCleaners.sanitizeString(notificationBody),
      data: DataCleaners.cleanTransactionMetadata(data)
    };
  }
};

/**
 * Schema for checking FCM config (no validation needed)
 */
const checkFCMConfigSchema = {
  validate() {
    return {};
  }
};

module.exports = {
  sendEmailSchema,
  sendFCMNotificationSchema,
  checkFCMConfigSchema
};
