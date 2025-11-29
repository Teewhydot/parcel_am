// ========================================================================
// Parcel_am App Firebase Functions - Modular Services
// ========================================================================

// Load environment variables from .env file (root directory for local development)
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

// Firebase Functions
const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');

// External Dependencies
const axios = require('axios');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();
db.settings({
  ignoreUndefinedProperties: true
});

// Import Utilities and Constants
const {
  ENVIRONMENT,
  CONTACT_INFO,
  TRANSACTION_TYPES,
  FUNCTIONS_CONFIG
} = require('./utils/constants');
const { logger } = require('./utils/logger');
const { RequestValidators, DatabaseValidators } = require('./utils/validation');
const { dbHelper } = require('./utils/database');

// Import Services
const { emailService } = require('./services/email-service');
const { paymentService } = require('./services/payment-service');
const { FlutterwaveService } = require('./services/flutterwave-service');
const { notificationService } = require('./services/notification-service');
const { statisticsService } = require('./services/statistics-service');
const { inventoryService } = require('./services/inventory-service');

// Legacy constants for backward compatibility
const PAYSTACK_SECRET_KEY = ENVIRONMENT.PAYSTACK_SECRET_KEY;
const PROJECT_ID = ENVIRONMENT.PROJECT_ID;
const gmailPassword = ENVIRONMENT.GMAIL_PASSWORD;


// Log startup information
console.log('='.repeat(50));
console.log('ParcelAm App Firebase Functions - Modular Version');
console.log('='.repeat(50));
console.log(`Using project ID: ${PROJECT_ID}`);
console.log(`Paystack API Key Status: ${PAYSTACK_SECRET_KEY ? 'Configured (' + PAYSTACK_SECRET_KEY.substring(0, 7) + '...)' : 'NOT CONFIGURED!'}`);
if (!PAYSTACK_SECRET_KEY) {
  console.error('⚠️  WARNING: PAYSTACK_SECRET_KEY is not set! Payment functions will fail.');
  console.error('   Please set the environment variable or Firebase config: paystack.secret_key');
}



// ========================================================================
// Paystack Transaction Creation Function (Food Orders)
// ========================================================================
exports.createPaystackTransaction = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `create-${Date.now()}`;

      try {
        logger.startFunction('createTransaction', executionId);
        logger.info(`Request body received`, executionId, { bodyKeys: Object.keys(req.body) });

        // Validate and sanitize request for food orders
        const validatedData = RequestValidators.validateTransactionRequest(req.body);
        logger.info(`Request validation successful`, executionId, {
          hasOrderId: !!validatedData.orderId,
          hasUserId: !!validatedData.userId,
          hasEmail: !!validatedData.email,
          amount: validatedData.amount
        });
        const { orderId, amount, userId, email, metadata, userName } = validatedData;

        // Extract and structure the food order details from metadata
        logger.info(`Structuring funding details`, executionId, { orderId, transactionType: 'funding' });
        const fundingDetails = {
          orderId: orderId,
          transactionType: 'funding',
          total: metadata.total || amount,
          // Include all other metadata
          ...metadata
        };
        logger.info(`Funding details structured`, executionId, { fundingDetailsKeys: Object.keys(fundingDetails) });

        // Initialize payment with Paystack
        logger.info(`Initializing Paystack transaction`, executionId, { email, amount, userId });
        const paymentResult = await paymentService.initializeTransaction(
          email,
          amount,
          { userId, fundingDetails, userName },
          executionId
        );
        logger.info(`Paystack initialization completed`, executionId, { success: paymentResult.success });

        if (!paymentResult.success) {
          logger.error('Payment initialization failed', executionId, null, paymentResult);
          return res.status(500).json({
            error: 'Failed to initialize payment',
            details: paymentResult.error
          });
        }

        // Determine transaction type and generate reference
        const transactionType = fundingDetails.transactionType || "funding";
        logger.info(`Transaction type determined: ${transactionType}`, executionId);

        const reference = paymentService.generatePrefixedReference(transactionType, paymentResult.reference);
        logger.info(`Prefixed reference generated: ${reference}`, executionId, {
          originalReference: paymentResult.reference
        });

        const currentTimestamp = new Date().toISOString();

        logger.transaction('CREATE', reference, executionId, {
          transactionType,
          amount,
          email
        });

        // Create service record using database helper
        logger.info(`Creating service record in database`, executionId, { reference, userId });
        await dbHelper.createServiceRecord(
          userId,
          userName,
          email,
          reference,
          transactionType,
          fundingDetails,
          amount,
          currentTimestamp,
          executionId
        );
        logger.success(`Service record created successfully in database`, executionId);
        logger.success(`Transaction created successfully: ${reference}`, executionId);

        res.status(200).json({
          success: true,
          reference: reference,
          authorization_url: paymentResult.authorizationUrl,
          access_code: paymentResult.accessCode
        });

      } catch (error) {
        logger.critical('Transaction creation failed', executionId, error);
        res.status(500).json({
          error: 'Internal server error',
          message: error.message
        });
      }
    });
  }
);

// ========================================================================
// Paystack Payment Verification Function
// ========================================================================
exports.verifyPaystackPayment = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `verify-${Date.now()}`;

      try {
        logger.startFunction('verifyPaystackPayment', executionId);
        logger.info(`Verify payment request received`, executionId, {
          hasReference: !!req.body.reference,
          hasOrderId: !!req.body.orderId
        });

        const { reference, orderId } = req.body;
        if (!reference) {
          logger.warning(`Verification failed: missing reference`, executionId);
          return res.status(400).json({
            success: false,
            error: 'Reference is required'
          });
        }

        logger.info(`Verifying payment with reference: ${reference}`, executionId);
        // Verify payment with Paystack
        const verificationResult = await paymentService.verifyTransaction(reference, executionId);
        logger.info(`Verification API call completed`, executionId, {
          success: verificationResult.success,
          status: verificationResult.status
        });

        if (!verificationResult.success) {
          logger.error('Payment verification failed', executionId, null, verificationResult);
          return res.status(400).json({
            success: false,
            error: 'Payment verification failed',
            details: verificationResult.error
          });
        }

        logger.success(`Payment verified successfully: ${reference}`, executionId);

        res.status(200).json({
          success: true,
          status: verificationResult.status,
          amount: verificationResult.amount,
          reference: reference,
          paidAt: verificationResult.paidAt,
          channel: verificationResult.channel
        });

      } catch (error) {
        logger.critical('Payment verification failed', executionId, error);
        res.status(500).json({
          success: false,
          error: 'Internal server error',
          message: error.message
        });
      }
    });
  }
);

// ========================================================================
// Transaction Status Function
// ========================================================================
exports.getTransactionStatus = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `status-${Date.now()}`;

      try {
        logger.startFunction('getTransactionStatus', executionId);
        logger.info(`Status check request received`, executionId, {
          queryParams: Object.keys(req.query)
        });

        const { reference } = req.query;
        if (!reference) {
          logger.warning(`Status check failed: missing reference`, executionId);
          return res.status(400).json({
            success: false,
            error: 'Reference is required'
          });
        }

        logger.info(`Checking status for reference: ${reference}`, executionId);
        // Get transaction status from Paystack
        const verificationResult = await paymentService.verifyTransaction(reference, executionId);
        logger.info(`Status check API call completed`, executionId, {
          success: verificationResult.success,
          status: verificationResult.status
        });

        if (!verificationResult.success) {
          return res.status(400).json({
            success: false,
            error: 'Failed to get transaction status',
            details: verificationResult.error
          });
        }

        logger.success(`Transaction status retrieved: ${reference}`, executionId);

        res.status(200).json({
          success: true,
          status: verificationResult.status,
          amount: verificationResult.amount,
          reference: reference,
          paidAt: verificationResult.paidAt
        });

      } catch (error) {
        logger.critical('Failed to get transaction status', executionId, error);
        res.status(500).json({
          success: false,
          error: 'Internal server error',
          message: error.message
        });
      }
    });
  }
);

// ========================================================================
// Paystack Webhook Handler (Refactored)
// ========================================================================
exports.paystackWebhook = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (req, res) => {
    const executionId = `webhook-${Date.now()}`;

    try {
      logger.startFunction('paystackWebhook', executionId);

      const event = req.body;
      const paystackSignature = req.headers["x-paystack-signature"];

      logger.info(`Received Paystack webhook`, executionId, {
        event: event.event,
        status: event.data?.status,
        reference: event.data?.reference,
        hasSignature: !!paystackSignature
      });

      // Verify webhook signature
      logger.info(`Verifying webhook signature`, executionId);
      if (!paymentService.verifyWebhookSignature(event, paystackSignature, executionId)) {
        logger.warning('Invalid webhook signature - rejecting request', executionId);
        return res.status(400).send("Invalid paystack signature");
      }
      logger.info(`Webhook signature verified successfully`, executionId);

      // Process webhook event
      logger.info(`Processing webhook event data`, executionId);
      const processResult = paymentService.processWebhookEvent(event, executionId);
      if (!processResult.success) {
        logger.error('Failed to process webhook event - invalid data structure', executionId, null, {
          error: processResult.error
        });
        return res.status(400).send("Invalid event data");
      }
      logger.info(`Webhook event processed successfully`, executionId);

      const processedEvent = processResult.processedEvent;

      // Handle different event types
      logger.info(`Routing webhook to handler`, executionId, {
        eventType: event.event,
        processedStatus: processedEvent.status
      });

      if (event.event === "charge.success" && processedEvent.status === "success") {
        logger.info(`Handling successful payment`, executionId, { reference: processedEvent.reference });
        await handleSuccessfulPayment(processedEvent, executionId);
      } else if (event.event === "charge.failed") {
        logger.info(`Handling failed payment`, executionId, { reference: processedEvent.reference });
        await handleFailedPayment(processedEvent, executionId);
      } else if (event.event === "charge.abandoned") {
        logger.info(`Handling abandoned payment`, executionId, { reference: processedEvent.reference });
        await handleAbandonedPayment(processedEvent, executionId);
      } else {
        logger.info(`Unhandled webhook event type`, executionId, {
          eventType: event.event,
          status: processedEvent.status
        });
      }

      logger.success('Webhook processed successfully', executionId);
      res.status(200).send("Webhook received successfully");

    } catch (error) {
      logger.critical('Webhook processing failed', executionId, error);
      res.status(200).send("Webhook received with error");
    }
  }
);

// Helper function for successful payments
async function handleSuccessfulPayment(processedEvent, executionId) {
  logger.info(`handleSuccessfulPayment started`, executionId, {
    reference: processedEvent.reference,
    amount: processedEvent.amount,
    userId: processedEvent.userId
  });

  const { reference, amount, paidAt, userId, userName, bookingDetails } = processedEvent;

  // Find document and update status
  logger.info(`Finding document with prefix`, executionId, { reference });
  const { actualReference, transactionType, orderDetails, userEmail } = await dbHelper.findDocumentWithPrefix(reference, executionId);
  logger.info(`Document found`, executionId, {
    actualReference,
    transactionType,
    hasOrderDetails: !!orderDetails
  });

  // Update transaction status - default to food_order if transactionType not found
  const config = TRANSACTION_TYPES[transactionType] || TRANSACTION_TYPES['food_order'];

  if (!config) {
    logger.error(`No configuration found for transaction type: ${transactionType}`, executionId);
    return;
  }
  logger.info(`Transaction type config found`, executionId, {
    transactionType,
    collectionName: config.collectionName
  });

  const updateData = {
    status: 'confirmed',
    time_created: paidAt,
    amount: amount,
    verified_at: dbHelper.getServerTimestamp()
  };

  if (config.transactionType === 'service') {
    updateData.updatedAt = paidAt;
    logger.info(`Added updatedAt field for service transaction`, executionId);
  }

  logger.info(`Updating document in database`, executionId, {
    collection: config.collectionName,
    reference: actualReference,
    status: 'confirmed'
  });
  await dbHelper.updateDocument(config.collectionName, actualReference, updateData, executionId);
  logger.info(`Document updated successfully`, executionId);

  // Clear user cart after successful food order payment
  if (transactionType === 'food_order' && userId) {
    try {
      logger.info(`Clearing user cart`, executionId, { userId, transactionType });
      const clearResult = await dbHelper.clearUserCart(userId, executionId);
      logger.info(`Cart clearing result for user ${userId}: ${clearResult.success ? 'success' : 'failed'} - ${clearResult.itemCount || 0} items`, executionId);
    } catch (error) {
      logger.error(`Failed to clear cart for user: ${userId}`, executionId, error);
    }
  } else {
    logger.info(`Skipping cart clearing`, executionId, {
      transactionType,
      hasUserId: !!userId,
      reason: transactionType !== 'food_order' ? 'not a food order' : 'no userId'
    });
  }

  // Send success notification
  logger.info(`Generating notification data`, executionId, { transactionType });
  const notificationData = notificationService.generateNotificationData(
    transactionType, orderDetails, actualReference, amount, true
  );
  logger.info(`Notification data generated`, executionId);

  if (userId && config) {
    logger.info(`Sending notification to user`, executionId, {
      userId,
      title: config.notificationTitle.success
    });
    await notificationService.sendNotificationToUser(
      userId,
      config.notificationTitle.success,
      `Your ${transactionType.replace('_', ' ')} payment of ₦${amount.toLocaleString()} has been confirmed!`,
      notificationData,
      executionId
    );
    logger.info(`Notification sent successfully`, executionId);
  } else {
    logger.warning(`Notification not sent`, executionId, {
      hasUserId: !!userId,
      hasConfig: !!config
    });
  }

  logger.success(`handleSuccessfulPayment completed`, executionId);
}

// Helper function for failed payments
async function handleFailedPayment(processedEvent, executionId) {
  logger.info(`handleFailedPayment started`, executionId, {
    reference: processedEvent.reference,
    amount: processedEvent.amount
  });

  const { reference, amount, paidAt } = processedEvent;

  logger.info(`Finding document with prefix`, executionId, { reference });
  const { actualReference, transactionType } = await dbHelper.findDocumentWithPrefix(reference, executionId);
  logger.info(`Document found`, executionId, { actualReference, transactionType });

  const config = TRANSACTION_TYPES[transactionType] || TRANSACTION_TYPES['food_order'];

  if (!config) {
    logger.error(`No configuration found for transaction type: ${transactionType}`, executionId);
    return;
  }
  logger.info(`Transaction type config found`, executionId, {
    transactionType,
    collectionName: config.collectionName
  });

  const updateData = {
    status: 'failed',
    time_created: paidAt,
    amount: amount,
  };

  logger.info(`Updating document to failed status`, executionId, {
    collection: config.collectionName,
    reference: actualReference
  });
  await dbHelper.updateDocument(config.collectionName, actualReference, updateData, executionId);
  logger.info(`Payment failed for ${reference}`, executionId);
  logger.success(`handleFailedPayment completed`, executionId);
}

// Helper function for abandoned payments
async function handleAbandonedPayment(processedEvent, executionId) {
  logger.info(`handleAbandonedPayment started`, executionId, {
    reference: processedEvent.reference,
    amount: processedEvent.amount
  });

  const { reference, amount, paidAt } = processedEvent;

  logger.info(`Finding document with prefix`, executionId, { reference });
  const { actualReference, transactionType } = await dbHelper.findDocumentWithPrefix(reference, executionId);
  logger.info(`Document found`, executionId, { actualReference, transactionType });

  const config = TRANSACTION_TYPES[transactionType] || TRANSACTION_TYPES['food_order'];

  if (!config) {
    logger.error(`No configuration found for transaction type: ${transactionType}`, executionId);
    return;
  }
  logger.info(`Transaction type config found`, executionId, {
    transactionType,
    collectionName: config.collectionName
  });

  const updateData = {
    status: 'abandoned',
    time_created: paidAt,
    amount: amount,
  };

  logger.info(`Updating document to abandoned status`, executionId, {
    collection: config.collectionName,
    reference: actualReference
  });
  await dbHelper.updateDocument(config.collectionName, actualReference, updateData, executionId);
  logger.info(`Payment abandoned for ${reference}`, executionId);
  logger.success(`handleAbandonedPayment completed`, executionId);
}

// ========================================================================
// Email Service Function
// ========================================================================
exports.sendEmail = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `email-${Date.now()}`;

      try {
        const validatedData = RequestValidators.validateEmailRequest(req.body);
        const { to, subject, text } = validatedData;

        const success = await emailService.sendEmail(to, subject, text, null, [], executionId);

        if (success) {
          res.status(200).send('Email sent successfully');
        } else {
          res.status(500).send('Error sending email');
        }
      } catch (error) {
        logger.error('Email sending failed', executionId, error);
        res.status(500).send('Error sending email');
      }
    });
  }
);

// ========================================================================
// FCM Configuration Check
// ========================================================================
exports.checkFCMConfig = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `fcm-check-${Date.now()}`;

      try {
        const config = {
          projectId: PROJECT_ID,
          envProjectId: process.env.GOOGLE_CLOUD_PROJECT,
          gcloudProjectId: process.env.GCLOUD_PROJECT,
          adminProjectId: admin.instanceId().app.options.projectId,
        };

        const connectionTest = await notificationService.testFCMConnection(executionId);

        res.status(200).json({
          success: true,
          config: config,
          connectionTest: connectionTest,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        logger.error('FCM config check failed', executionId, error);
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });
  }
);

// ========================================================================
// FCM Notification Function
// ========================================================================
exports.sendFCMNotification = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `fcm-${Date.now()}`;

      try {
        const validatedData = RequestValidators.validateNotificationRequest(req.body);
        const { userId, title, body, data } = validatedData;

        const result = await notificationService.sendNotificationToUser(userId, title, body, data, executionId);

        if (result.success) {
          res.status(200).json({
            success: true,
            messageId: result.messageId
          });
        } else {
          res.status(400).json({
            success: false,
            error: result.reason || result.error
          });
        }
      } catch (error) {
        logger.error('FCM notification failed', executionId, error);
        res.status(500).json({
          success: false,
          error: error.message
        });
      }
    });
  }
);

// ========================================================================
// Scheduled Functions
// ========================================================================

// Verify pending transactions
exports.verifyPendingTransactions = onSchedule(
  {
    schedule: 'every 10 minutes',
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (context) => {
    const executionId = `verify-${Date.now()}`;

    try {
      logger.startFunction('verifyPendingTransactions', executionId);

      // Get pending transactions from the last 24 hours
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

      const pendingFoodOrders = await dbHelper.queryDocuments('food_orders',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '>=', value: oneDayAgo.toISOString() }
        ],
        null, 50, executionId
      );

      const pendingDeliveries = await dbHelper.queryDocuments('delivery_orders',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '>=', value: oneDayAgo.toISOString() }
        ],
        null, 50, executionId
      );

      const allPending = [...pendingFoodOrders, ...pendingDeliveries];

      logger.info(`Found ${allPending.length} pending transactions to verify`, executionId);

      let verifiedCount = 0;
      for (const transaction of allPending) {
        try {
          const originalReference = paymentService.extractOriginalReference(transaction.id);
          const verificationResult = await paymentService.verifyTransaction(originalReference, `${executionId}-${transaction.id}`);

          if (verificationResult.success && verificationResult.status === 'success') {
            await handleSuccessfulPayment({
              reference: originalReference,
              amount: verificationResult.amount,
              paidAt: verificationResult.paidAt,
              userId: transaction.data.userId,
              userName: transaction.data.userName,
              bookingDetails: transaction.data.bookingDetails || {}
            }, `${executionId}-${transaction.id}`);

            verifiedCount++;
          }
        } catch (error) {
          logger.error(`Failed to verify transaction ${transaction.id}`, executionId, error);
        }
      }

      logger.success(`Verification completed: ${verifiedCount}/${allPending.length} transactions verified`, executionId);

    } catch (error) {
      logger.error('Scheduled verification failed', executionId, error);
    }
  }
);

// Cleanup old pending transactions
exports.cleanupOldPendingTransactions = onSchedule(
  {
    schedule: 'every 24 hours',
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: FUNCTIONS_CONFIG.TIMEOUT_SECONDS,
    memory: FUNCTIONS_CONFIG.MEMORY
  },
  async (context) => {
    const executionId = `cleanup-${Date.now()}`;

    try {
      logger.startFunction('cleanupOldPendingTransactions', executionId);

      // Clean up transactions older than 7 days
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      const oldPendingFoodOrders = await dbHelper.queryDocuments('food_orders',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '<', value: sevenDaysAgo.toISOString() }
        ],
        null, 100, executionId
      );

      const oldPendingDeliveries = await dbHelper.queryDocuments('delivery_orders',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '<', value: sevenDaysAgo.toISOString() }
        ],
        null, 100, executionId
      );

      const allOldPending = [...oldPendingFoodOrders, ...oldPendingDeliveries];

      logger.info(`Found ${allOldPending.length} old pending transactions to cleanup`, executionId);

      const batch = dbHelper.createBatch();
      let cleanedCount = 0;

      for (const transaction of allOldPending) {
        const collection = transaction.id.startsWith('F-') ? 'food_orders' : 'delivery_orders';
        dbHelper.batchUpdate(batch, collection, transaction.id, {
          status: 'expired',
          expiredAt: dbHelper.getServerTimestamp()
        });
        cleanedCount++;
      }

      if (cleanedCount > 0) {
        await dbHelper.commitBatch(batch, cleanedCount, executionId);
      }

      logger.success(`Cleanup completed: ${cleanedCount} transactions marked as expired`, executionId);

    } catch (error) {
      logger.error('Scheduled cleanup failed', executionId, error);
    }
  }
);

console.log('✅ ParcelAm  App Firebase Functions initialized successfully');
console.log('📦 All services loaded and ready');
