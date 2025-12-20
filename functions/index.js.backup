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

// Initialize Firebase Admin (lazy initialization to speed up container startup)
let adminInitialized = false;
let db;

function initializeFirebase() {
  if (!adminInitialized) {
    admin.initializeApp();
    db = admin.firestore();
    db.settings({
      ignoreUndefinedProperties: true
    });
    adminInitialized = true;
    console.log('✅ Firebase Admin initialized');
  }
  return db;
}

// Initialize immediately for backward compatibility
db = initializeFirebase();

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

// Import Handlers
const { initiateWithdrawal: initiateWithdrawalHandler } = require('./handlers/withdrawal-handler');
const { processTransferWebhook } = require('./handlers/webhook-transfer-handler');

// Legacy constants for backward compatibility
const PAYSTACK_SECRET_KEY = ENVIRONMENT.PAYSTACK_SECRET_KEY;
const PROJECT_ID = ENVIRONMENT.PROJECT_ID;
const gmailPassword = ENVIRONMENT.GMAIL_PASSWORD;


// Log startup information
console.log('='.repeat(50));
console.log('ParcelAm App Firebase Functions - Modular Version');
console.log('='.repeat(50));
console.log(`Using project ID: ${PROJECT_ID}`);
console.log(`Paystack API Key Status: ${PAYSTACK_SECRET_KEY ? 'Configured (...' + PAYSTACK_SECRET_KEY.slice(-5) + ')' : 'NOT CONFIGURED!'}`);
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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `create-${Date.now()}`;

      try {
        console.log('====================================');
        console.log('🔵 CREATE TRANSACTION STARTED', executionId);
        console.log('Request body keys:', Object.keys(req.body));

        logger.startFunction('createTransaction', executionId);
        logger.info(`Request body received`, executionId, { bodyKeys: Object.keys(req.body) });

        // Validate and sanitize request
        const validatedData = RequestValidators.validateTransactionRequest(req.body);
        console.log('✅ Request validation successful');
        console.log('  - User ID:', validatedData.userId);
        console.log('  - Email:', validatedData.email);
        console.log('  - Amount:', validatedData.amount);
        console.log('  - Order ID:', validatedData.orderId);

        logger.info(`Request validation successful`, executionId, {
          hasOrderId: !!validatedData.orderId,
          hasUserId: !!validatedData.userId,
          hasEmail: !!validatedData.email,
          amount: validatedData.amount
        });
        const { orderId, amount, userId, email, metadata, userName } = validatedData;

      
        console.log('📦 Structuring funding details...');

        logger.info(`Structuring funding details`, executionId, { orderId, transactionType: 'funding' });
        const fundingDetails = {
          orderId: orderId,
          transactionType: 'funding',
          total: metadata.total || amount,
          // Include all other metadata
          ...metadata
        };
        console.log('✅ Funding details structured:', Object.keys(fundingDetails).join(', '));

        logger.info(`Funding details structured`, executionId, { fundingDetailsKeys: Object.keys(fundingDetails) });

        // Initialize payment with Paystack
        console.log('💳 Initializing Paystack payment...');
        console.log('  - Email:', email);
        console.log('  - Amount:', amount);

        logger.info(`Initializing Paystack transaction`, executionId, { email, amount, userId });
        const paymentResult = await paymentService.initializeTransaction(
          email,
          amount,
          { userId, fundingDetails, userName },
          executionId
        );
        console.log('Paystack response:', paymentResult.success ? '✅ SUCCESS' : '❌ FAILED');
        if (!paymentResult.success) {
          console.error('Paystack initialization error:', paymentResult.error);
        }

        logger.info(`Paystack initialization completed`, executionId, { success: paymentResult.success });

        if (!paymentResult.success) {
          console.error('❌ PAYMENT INITIALIZATION FAILED');
          console.error('Error details:', paymentResult.error);
          console.error('Full response:', JSON.stringify(paymentResult, null, 2));

          logger.error('Payment initialization failed', executionId, null, paymentResult);
          return res.status(500).json({
            error: 'Failed to initialize payment',
            details: paymentResult.error
          });
        }

        // Determine transaction type and generate reference
        const transactionType = fundingDetails.transactionType || "funding";
        console.log('📝 Transaction type:', transactionType);

        logger.info(`Transaction type determined: ${transactionType}`, executionId);

        const reference = paymentService.generatePrefixedReference(transactionType, paymentResult.reference);
        console.log('🔖 Reference generated:', reference);
        console.log('  - Original:', paymentResult.reference);
        console.log('  - Prefixed:', reference);

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
        console.log('💾 Saving to database...');
        console.log('  - Collection: based on transaction type');
        console.log('  - Reference:', reference);

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
        console.log('✅ Database record created successfully');

        logger.success(`Service record created successfully in database`, executionId);
        logger.success(`Transaction created successfully: ${reference}`, executionId);

        console.log('🎉 TRANSACTION CREATED SUCCESSFULLY');
        console.log('  - Reference:', reference);
        console.log('  - Authorization URL:', paymentResult.authorizationUrl);
        console.log('====================================');

        res.status(200).json({
          success: true,
          reference: reference,
          authorization_url: paymentResult.authorizationUrl,
          access_code: paymentResult.accessCode
        });

      } catch (error) {
        console.error('====================================');
        console.error('❌ TRANSACTION CREATION FAILED');
        console.error('Error:', error.message);
        console.error('Stack:', error.stack);
        console.error('====================================');

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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `verify-${Date.now()}`;

      try {
        console.log('====================================');
        console.log('🔍 VERIFY PAYMENT STARTED', executionId);
        console.log('Request reference:', req.body.reference);

        logger.startFunction('verifyPaystackPayment', executionId);
        logger.info(`Verify payment request received`, executionId, {
          hasReference: !!req.body.reference,
          hasOrderId: !!req.body.orderId
        });

        const { reference, orderId } = req.body;
        if (!reference) {
          console.error('❌ Missing reference parameter');
          logger.warning(`Verification failed: missing reference`, executionId);
          return res.status(400).json({
            success: false,
            error: 'Reference is required'
          });
        }

        console.log('📞 Calling Paystack verification API...');
        console.log('  - Reference:', reference);

        logger.info(`Verifying payment with reference: ${reference}`, executionId);
        // Verify payment with Paystack
        const verificationResult = await paymentService.verifyTransaction(reference, executionId);

        console.log('Paystack verification response:', verificationResult.success ? '✅ SUCCESS' : '❌ FAILED');
        console.log('  - Status:', verificationResult.status);
        console.log('  - Amount:', verificationResult.amount);

        logger.info(`Verification API call completed`, executionId, {
          success: verificationResult.success,
          status: verificationResult.status
        });

        if (!verificationResult.success) {
          console.error('❌ VERIFICATION FAILED');
          console.error('Error:', verificationResult.error);
          console.error('Details:', JSON.stringify(verificationResult.details, null, 2));

          logger.error('Payment verification failed', executionId, null, verificationResult);
          return res.status(400).json({
            success: false,
            error: 'Payment verification failed',
            details: verificationResult.error
          });
        }

        console.log('🎉 PAYMENT VERIFIED SUCCESSFULLY');
        console.log('  - Reference:', reference);
        console.log('  - Status:', verificationResult.status);
        console.log('  - Amount:', verificationResult.amount);
        console.log('  - Channel:', verificationResult.channel);
        console.log('====================================');

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
        console.error('====================================');
        console.error('❌ PAYMENT VERIFICATION ERROR');
        console.error('Error:', error.message);
        console.error('Stack:', error.stack);
        console.error('====================================');

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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
  },
  async (req, res) => {
    const executionId = `webhook-${Date.now()}`;

    try {
      console.log('====================================');
      console.log('🔔 PAYSTACK WEBHOOK RECEIVED', executionId);
      console.log('Event type:', req.body.event);
      console.log('Status:', req.body.data?.status);
      console.log('Reference:', req.body.data?.reference);
      console.log('Has signature:', !!req.headers["x-paystack-signature"]);

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
      console.log('🔐 Verifying webhook signature...');

      logger.info(`Verifying webhook signature`, executionId);
      if (!paymentService.verifyWebhookSignature(event, paystackSignature, executionId)) {
        console.error('❌ INVALID WEBHOOK SIGNATURE - Rejecting');
        logger.warning('Invalid webhook signature - rejecting request', executionId);
        return res.status(400).send("Invalid paystack signature");
      }
      console.log('✅ Webhook signature verified');

      logger.info(`Webhook signature verified successfully`, executionId);

      // ========================================================================
      // WEBHOOK DEDUPLICATION: Check if event has already been processed
      // Paystack may retry webhooks, so we track event IDs to prevent duplicates
      // ========================================================================
      const eventId = event.id || `${event.data?.reference}-${event.event}`;
      console.log('🔍 Checking for duplicate webhook event...');
      console.log('  - Event ID:', eventId);

      logger.info(`Checking webhook event deduplication`, executionId, { eventId });

      const processedWebhookRef = db.collection('processed_webhooks').doc(eventId);
      const processedWebhookDoc = await processedWebhookRef.get();

      if (processedWebhookDoc.exists) {
        const processedData = processedWebhookDoc.data();
        console.log('⚠️  DUPLICATE WEBHOOK EVENT DETECTED');
        console.log('  - Event ID:', eventId);
        console.log('  - First Processed:', processedData.processedAt);
        console.log('  - Event Type:', processedData.eventType);

        logger.warning(`Duplicate webhook event ignored`, executionId, {
          eventId,
          eventType: event.event,
          firstProcessedAt: processedData.processedAt,
          reference: event.data?.reference
        });

        // Return 200 OK (webhook already processed successfully)
        return res.status(200).send("Event already processed");
      }

      console.log('✅ Event not yet processed - continuing');
      logger.info(`New webhook event - proceeding with processing`, executionId, { eventId });

      // Process webhook event
      console.log('📦 Processing webhook event data...');

      logger.info(`Processing webhook event data`, executionId);
      const processResult = paymentService.processWebhookEvent(event, executionId);
      if (!processResult.success) {
        console.error('❌ Failed to process webhook - invalid data');
        console.error('Error:', processResult.error);

        logger.error('Failed to process webhook event - invalid data structure', executionId, null, {
          error: processResult.error
        });
        return res.status(400).send("Invalid event data");
      }
      console.log('✅ Webhook event data processed');

      logger.info(`Webhook event processed successfully`, executionId);

      const processedEvent = processResult.processedEvent;

      // Handle different event types
      console.log('🔀 Routing to handler...');
      console.log('  - Event:', event.event);
      console.log('  - Status:', processedEvent.status);

      logger.info(`Routing webhook to handler`, executionId, {
        eventType: event.event,
        processedStatus: processedEvent.status
      });

      if (event.event === "charge.success" && processedEvent.status === "success") {
        console.log('✅ Handling SUCCESSFUL payment');
        console.log('  - Reference:', processedEvent.reference);

        logger.info(`Handling successful payment`, executionId, { reference: processedEvent.reference });
        await handleSuccessfulPayment(processedEvent, executionId);
      } else if (event.event === "charge.failed") {
        console.log('❌ Handling FAILED payment');
        console.log('  - Reference:', processedEvent.reference);

        logger.info(`Handling failed payment`, executionId, { reference: processedEvent.reference });
        await handleFailedPayment(processedEvent, executionId);
      } else if (event.event === "charge.abandoned") {
        console.log('⚠️ Handling ABANDONED payment');
        console.log('  - Reference:', processedEvent.reference);

        logger.info(`Handling abandoned payment`, executionId, { reference: processedEvent.reference });
        await handleAbandonedPayment(processedEvent, executionId);
      } else if (event.event === "transfer.success" || event.event === "transfer.failed" || event.event === "transfer.reversed") {
        console.log('💸 Handling TRANSFER event:', event.event);
        console.log('  - Reference:', event.data?.reference);
        console.log('  - Transfer Code:', event.data?.transfer_code);

        logger.info(`Handling transfer event`, executionId, {
          eventType: event.event,
          reference: event.data?.reference,
          transferCode: event.data?.transfer_code
        });
        await processTransferWebhook(event, executionId);
      } else {
        console.log('ℹ️ Unhandled event type:', event.event);

        logger.info(`Unhandled webhook event type`, executionId, {
          eventType: event.event,
          status: processedEvent.status
        });
      }

      // ========================================================================
      // STORE PROCESSED EVENT ID: Track this event to prevent future duplicates
      // TTL: Auto-delete after 7 days (Paystack retries for 72 hours max)
      // ========================================================================
      console.log('💾 Recording processed webhook event...');
      logger.info(`Storing processed webhook event ID`, executionId, { eventId });

      try {
        await processedWebhookRef.set({
          eventId: eventId,
          eventType: event.event,
          reference: event.data?.reference,
          status: event.data?.status,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          executionId: executionId,
          // TTL: Will be auto-deleted after 7 days (604800 seconds)
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        });

        console.log('✅ Webhook event recorded');
        logger.info(`Webhook event ID stored successfully`, executionId, { eventId });
      } catch (storageError) {
        // Don't fail the webhook if storage fails - just log it
        console.error('⚠️  Failed to store webhook event ID (non-critical):', storageError.message);
        logger.warning(`Failed to store webhook event ID`, executionId, storageError, { eventId });
      }

      console.log('🎉 WEBHOOK PROCESSED SUCCESSFULLY');
      console.log('====================================');

      logger.success('Webhook processed successfully', executionId);
      res.status(200).send("Webhook received successfully");

    } catch (error) {
      console.error('====================================');
      console.error('❌ WEBHOOK PROCESSING ERROR');
      console.error('Error:', error.message);
      console.error('Stack:', error.stack);
      console.error('====================================');

      logger.critical('Webhook processing failed', executionId, error);
      res.status(200).send("Webhook received with error");
    }
  }
);

// Helper function for successful payments
async function handleSuccessfulPayment(processedEvent, executionId) {
  console.log('💰 === HANDLE SUCCESSFUL PAYMENT ===');
  console.log('Reference:', processedEvent.reference);
  console.log('Amount:', processedEvent.amount);
  console.log('User ID:', processedEvent.userId);

  logger.info(`handleSuccessfulPayment started`, executionId, {
    reference: processedEvent.reference,
    amount: processedEvent.amount,
    userId: processedEvent.userId
  });

  const { reference, amount, paidAt, userId, userName, bookingDetails } = processedEvent;

  // Find document and update status
  console.log('🔍 Finding document in database...');

  logger.info(`Finding document with prefix`, executionId, { reference });
  const { actualReference, transactionType, orderDetails, userEmail } = await dbHelper.findDocumentWithPrefix(reference, executionId);

  console.log('✅ Document found:');
  console.log('  - Actual Reference:', actualReference);
  console.log('  - Transaction Type:', transactionType);
  console.log('  - Has Order Details:', !!orderDetails);

  logger.info(`Document found`, executionId, {
    actualReference,
    transactionType,
    hasOrderDetails: !!orderDetails
  });

  // Update transaction status - default to food_order if transactionType not found
  const config = TRANSACTION_TYPES[transactionType] || TRANSACTION_TYPES['funding'];

  if (!config) {
    logger.error(`No configuration found for transaction type: ${transactionType}`, executionId);
    return;
  }

  // ========================================================================
  // IDEMPOTENCY CHECK: Verify transaction hasn't already been processed
  // ========================================================================
  console.log('🔍 Checking transaction status for idempotency...');
  logger.info(`Checking current transaction status`, executionId, {
    collection: config.collectionName,
    reference: actualReference
  });

  const { doc: existingDoc, data: existingData } = await dbHelper.getDocument(
    config.collectionName,
    actualReference,
    executionId
  );

  if (existingData && existingData.status === 'confirmed') {
    console.log('⚠️  DUPLICATE WEBHOOK DETECTED - Transaction already confirmed');
    console.log('  - Reference:', actualReference);
    console.log('  - Current Status:', existingData.status);
    console.log('  - Verified At:', existingData.verified_at);

    logger.warning(`Duplicate webhook ignored - transaction already confirmed`, executionId, {
      reference: actualReference,
      currentStatus: existingData.status,
      verifiedAt: existingData.verified_at,
      amount: existingData.amount
    });

    // Return early - this webhook has already been processed (idempotent behavior)
    return;
  }

  console.log('✅ Transaction not yet confirmed - proceeding with processing');
  logger.info(`Transaction status: ${existingData?.status || 'not found'} - safe to process`, executionId);
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

  // ========================================================================
  // ATOMIC TRANSACTION: Update transaction status and wallet balance
  // All operations succeed or all fail - no partial updates
  // ========================================================================
  console.log('💾 Starting atomic transaction...');
  logger.info(`Starting atomic Firestore transaction`, executionId, {
    collection: config.collectionName,
    reference: actualReference,
    transactionType,
    hasUserId: !!userId
  });

  try {
    await db.runTransaction(async (transaction) => {
      // Get document references
      const transactionDocRef = db.collection(config.collectionName).doc(actualReference);
      const walletRef = userId ? db.collection('wallets').doc(userId) : null;

      console.log('  📄 Step 1: Updating transaction status to CONFIRMED...');

      // Update transaction status
      transaction.update(transactionDocRef, updateData);

      logger.info(`Transaction document update queued`, executionId, {
        reference: actualReference,
        status: 'confirmed'
      });

      // Update wallet balance if this is a funding transaction
      if (transactionType === 'funding' && userId && walletRef) {
        console.log('  💰 Step 2: Updating wallet balance...');
        console.log('    - User ID:', userId);
        console.log('    - Amount to add: ₦', amount);

        logger.info(`Wallet update queued`, executionId, { userId, amount });

        // Read wallet within transaction
        const walletSnapshot = await transaction.get(walletRef);

        if (walletSnapshot.exists) {
          // Wallet exists - increment balance
          const currentWallet = walletSnapshot.data();
          const newAvailableBalance = (currentWallet.availableBalance || 0) + amount;
          const newTotalBalance = newAvailableBalance + (currentWallet.heldBalance || 0);

          transaction.update(walletRef, {
            availableBalance: newAvailableBalance,
            totalBalance: newTotalBalance,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
          });

          console.log('    ✅ Wallet balance increment queued');
          logger.info(`Wallet increment queued: ${currentWallet.availableBalance} + ${amount} = ${newAvailableBalance}`, executionId);
        } else {
          // Wallet doesn't exist - create new wallet
          console.log('    ⚠️  Wallet not found, creating new wallet...');

          transaction.set(walletRef, {
            id: userId,
            userId: userId,
            availableBalance: amount,
            heldBalance: 0.0,
            totalBalance: amount,
            currency: 'NGN',
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
          });

          console.log('    ✅ Wallet creation queued');
          logger.info(`Wallet creation queued with initial balance: ₦${amount}`, executionId);
        }
      } else if (transactionType === 'funding' && !userId) {
        console.log('  ⚠️  Skipping wallet update: missing user ID');
        logger.warning(`Cannot update wallet: missing userId`, executionId);
      } else {
        console.log('  ⏭️  Skipping wallet update (not a funding transaction)');
        logger.info(`Skipping wallet update for ${transactionType}`, executionId);
      }

      console.log('  🔄 Committing atomic transaction...');
    });

    console.log('✅ Atomic transaction committed successfully');
    logger.success(`Transaction and wallet updated atomically`, executionId, {
      reference: actualReference,
      amount,
      userId: userId || 'N/A'
    });

  } catch (error) {
    console.error('❌ Atomic transaction FAILED - all changes rolled back');
    console.error('  Error:', error.message);

    logger.error(`Atomic transaction failed - rollback complete`, executionId, error, {
      reference: actualReference,
      transactionType,
      userId: userId || 'N/A',
      amount
    });

    // Re-throw to prevent notification from being sent if transaction failed
    throw error;
  }

//  // Clear user cart after successful food order payment
//  if (transactionType === 'food_order' && userId) {
//    try {
//      console.log('🛒 Clearing user cart...');
//      console.log('  - User ID:', userId);
//
//      logger.info(`Clearing user cart`, executionId, { userId, transactionType });
//      const clearResult = await dbHelper.clearUserCart(userId, executionId);
//
//      console.log('Cart clearing result:', clearResult.success ? '✅ SUCCESS' : '❌ FAILED');
//      console.log('  - Items cleared:', clearResult.itemCount || 0);
//
//      logger.info(`Cart clearing result for user ${userId}: ${clearResult.success ? 'success' : 'failed'} - ${clearResult.itemCount || 0} items`, executionId);
//    } catch (error) {
//      console.error('❌ Failed to clear cart:', error.message);
//      logger.error(`Failed to clear cart for user: ${userId}`, executionId, error);
//    }
//  } else {
//    console.log('⏭️  Skipping cart clearing (not a food order or no user ID)');
//    logger.info(`Skipping cart clearing`, executionId, {
//      transactionType,
//      hasUserId: !!userId,
//      reason: transactionType !== 'food_order' ? 'not a food order' : 'no userId'
//    });
//  }

  // Send success notification
  logger.info(`Generating notification data`, executionId, { transactionType });
  const notificationData = notificationService.generateNotificationData(
    transactionType, orderDetails, actualReference, amount, true
  );
  logger.info(`Notification data generated`, executionId);

  if (userId && config) {
    console.log('🔔 Sending notification to user...');
    console.log('  - User ID:', userId);
    console.log('  - Title:', config.notificationTitle.success);

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
    console.log('✅ Notification sent successfully');

    logger.info(`Notification sent successfully`, executionId);
  } else {
    console.log('⚠️ Notification not sent (missing user ID or config)');
    logger.warning(`Notification not sent`, executionId, {
      hasUserId: !!userId,
      hasConfig: !!config
    });
  }

  console.log('🎉 SUCCESSFUL PAYMENT HANDLED COMPLETELY');
  console.log('=== END HANDLE SUCCESSFUL PAYMENT ===');

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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
  },
  async (context) => {
    const executionId = `verify-${Date.now()}`;

    try {
      logger.startFunction('verifyPendingTransactions', executionId);

      // Get pending transactions from the last 24 hours
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

      const pendingFundingOrders = await dbHelper.queryDocuments('funding_orders',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '>=', value: oneDayAgo.toISOString() }
        ],
        null, 50, executionId
      );

      const pendingWithdrawals = await dbHelper.queryDocuments('withdrawals',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '>=', value: oneDayAgo.toISOString() }
        ],
        null, 50, executionId
      );

      const allPending = [...pendingFundingOrders, ...pendingWithdrawals];

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
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES
  },
  async (context) => {
    const executionId = `cleanup-${Date.now()}`;

    try {
      logger.startFunction('cleanupOldPendingTransactions', executionId);

      // Clean up transactions older than 7 days
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      const oldPendingFundingOrders = await dbHelper.queryDocuments('funding_orders',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '<', value: sevenDaysAgo.toISOString() }
        ],
        null, 100, executionId
      );

      const oldPendingWithdrawals = await dbHelper.queryDocuments('withdrawals',
        [
          { field: 'status', operator: '==', value: 'pending' },
          { field: 'time_created', operator: '<', value: sevenDaysAgo.toISOString() }
        ],
        null, 100, executionId
      );

      const allOldPending = [...oldPendingFundingOrders, ...oldPendingWithdrawals];

      logger.info(`Found ${allOldPending.length} old pending transactions to cleanup`, executionId);

      const batch = dbHelper.createBatch();
      let cleanedCount = 0;

      for (const transaction of allOldPending) {
        const collection = transaction.id.startsWith('F-') ? 'funding_orders' : 'withdrawals';
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

// ========================================================================
// Bank Account Resolution Function (Paystack)
// ========================================================================
exports.resolveBankAccount = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `resolve-bank-${Date.now()}`;

      try {
        console.log('====================================');
        console.log('🏦 RESOLVE BANK ACCOUNT STARTED', executionId);

        logger.startFunction('resolveBankAccount', executionId);

        const { accountNumber, bankCode } = req.body;

        // Validate required fields
        if (!accountNumber || !bankCode) {
          console.log('❌ Missing required fields');
          return res.status(400).json({
            success: false,
            error: 'Account number and bank code are required'
          });
        }

        console.log('  - Account Number:', accountNumber);
        console.log('  - Bank Code:', bankCode);

        logger.info(`Resolving bank account`, executionId, { accountNumber, bankCode });

        // Call Paystack Resolve Account API
        const paystackUrl = `https://api.paystack.co/bank/resolve?account_number=${accountNumber}&bank_code=${bankCode}`;

        const response = await axios.get(paystackUrl, {
          headers: {
            'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
            'Content-Type': 'application/json'
          }
        });

        if (response.data.status === true) {
          const accountName = response.data.data.account_name;
          console.log('✅ Account resolved successfully:', accountName);

          logger.success(`Bank account resolved: ${accountName}`, executionId);

          return res.status(200).json({
            success: true,
            accountName: accountName,
            accountNumber: accountNumber,
            bankCode: bankCode
          });
        } else {
          console.log('❌ Paystack returned error:', response.data.message);

          logger.error('Paystack resolve failed', executionId, null, response.data);

          return res.status(400).json({
            success: false,
            error: response.data.message || 'Could not resolve account'
          });
        }

      } catch (error) {
        console.error('====================================');
        console.error('❌ RESOLVE BANK ACCOUNT FAILED');
        console.error('Error:', error.message);

        // Handle Paystack-specific errors
        if (error.response) {
          const paystackError = error.response.data;
          console.error('Paystack Error:', paystackError);

          logger.error('Paystack API error', executionId, error, paystackError);

          return res.status(error.response.status).json({
            success: false,
            error: paystackError.message || 'Account verification failed'
          });
        }

        logger.critical('Resolve bank account failed', executionId, error);

        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    });
  }
);

// ========================================================================
// Create Transfer Recipient Function (Paystack)
// ========================================================================
exports.createTransferRecipient = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `create-recipient-${Date.now()}`;

      try {
        console.log('====================================');
        console.log('👤 CREATE TRANSFER RECIPIENT STARTED', executionId);

        logger.startFunction('createTransferRecipient', executionId);

        const { accountNumber, accountName, bankCode } = req.body;

        // Validate required fields
        if (!accountNumber || !accountName || !bankCode) {
          console.log('❌ Missing required fields');
          return res.status(400).json({
            success: false,
            error: 'Account number, account name, and bank code are required'
          });
        }

        console.log('  - Account Number:', accountNumber);
        console.log('  - Account Name:', accountName);
        console.log('  - Bank Code:', bankCode);

        logger.info(`Creating transfer recipient`, executionId, { accountNumber, accountName, bankCode });

        // Call Paystack Create Transfer Recipient API
        const response = await axios.post(
          'https://api.paystack.co/transferrecipient',
          {
            type: 'nuban',
            name: accountName,
            account_number: accountNumber,
            bank_code: bankCode,
            currency: 'NGN'
          },
          {
            headers: {
              'Authorization': `Bearer ${PAYSTACK_SECRET_KEY}`,
              'Content-Type': 'application/json'
            }
          }
        );

        if (response.data.status === true) {
          const recipientCode = response.data.data.recipient_code;
          console.log('✅ Transfer recipient created:', recipientCode);

          logger.success(`Transfer recipient created: ${recipientCode}`, executionId);

          return res.status(200).json({
            success: true,
            recipientCode: recipientCode
          });
        } else {
          console.log('❌ Paystack returned error:', response.data.message);

          logger.error('Paystack create recipient failed', executionId, null, response.data);

          return res.status(400).json({
            success: false,
            error: response.data.message || 'Could not create transfer recipient'
          });
        }

      } catch (error) {
        console.error('====================================');
        console.error('❌ CREATE TRANSFER RECIPIENT FAILED');
        console.error('Error:', error.message);

        // Handle Paystack-specific errors
        if (error.response) {
          const paystackError = error.response.data;
          console.error('Paystack Error:', paystackError);

          logger.error('Paystack API error', executionId, error, paystackError);

          return res.status(error.response.status).json({
            success: false,
            error: paystackError.message || 'Failed to create transfer recipient'
          });
        }

        logger.critical('Create transfer recipient failed', executionId, error);

        res.status(500).json({
          success: false,
          error: 'Internal server error'
        });
      }
    });
  }
);

// ========================================================================
// Initiate Withdrawal Function (Paystack Transfer)
// ========================================================================
exports.initiateWithdrawal = onRequest(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: FUNCTIONS_CONFIG.MEMORY,
    cpu: FUNCTIONS_CONFIG.CPU,
    minInstances: FUNCTIONS_CONFIG.MIN_INSTANCES,
    maxInstances: FUNCTIONS_CONFIG.MAX_INSTANCES,
    secrets: ['PAYSTACK_SECRET_KEY']
  },
  async (req, res) => {
    cors(req, res, async () => {
      const executionId = `withdrawal-${Date.now()}`;

      try {
        console.log('====================================');
        console.log('💸 INITIATE WITHDRAWAL STARTED', executionId);

        logger.startFunction('initiateWithdrawal', executionId);

        // Verify Firebase ID token from Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          console.log('❌ Missing or invalid Authorization header');
          return res.status(401).json({
            success: false,
            error: 'Authorization header is required'
          });
        }

        const idToken = authHeader.split('Bearer ')[1];
        let decodedToken;

        try {
          decodedToken = await admin.auth().verifyIdToken(idToken);
        } catch (authError) {
          console.log('❌ Invalid ID token:', authError.message);
          return res.status(401).json({
            success: false,
            error: 'Invalid or expired token'
          });
        }

        const { userId, amount, recipientCode, withdrawalReference, bankAccountId } = req.body;

        // Validate required fields
        if (!userId || !amount || !recipientCode || !withdrawalReference || !bankAccountId) {
          console.log('❌ Missing required fields');
          return res.status(400).json({
            success: false,
            error: 'userId, amount, recipientCode, withdrawalReference, and bankAccountId are required'
          });
        }

        console.log('  - User ID:', userId);
        console.log('  - Amount:', amount);
        console.log('  - Recipient Code:', recipientCode);
        console.log('  - Withdrawal Reference:', withdrawalReference);
        console.log('  - Bank Account ID:', bankAccountId);

        logger.info(`Initiating withdrawal`, executionId, {
          userId,
          amount,
          recipientCode,
          withdrawalReference
        });

        // Get bank account details from user's subcollection
        const bankAccountDoc = await admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('user_bank_accounts')
          .doc(bankAccountId)
          .get();

        if (!bankAccountDoc.exists) {
          console.log('❌ Bank account not found:', bankAccountId, 'for user:', userId);
          return res.status(404).json({
            success: false,
            error: 'Bank account not found'
          });
        }

        const bankAccountDetails = bankAccountDoc.data();

        // Create context object for the handler
        const context = {
          auth: {
            uid: decodedToken.uid,
            token: decodedToken
          }
        };

        // Call the withdrawal handler
        const result = await initiateWithdrawalHandler({
          userId,
          amount,
          recipientCode,
          withdrawalReference,
          bankAccountId,
          bankAccountDetails: {
            id: bankAccountId,
            bankName: bankAccountDetails.bankName,
            bankCode: bankAccountDetails.bankCode,
            accountNumber: bankAccountDetails.accountNumber,
            accountName: bankAccountDetails.accountName
          }
        }, context, executionId);

        console.log('✅ Withdrawal initiated successfully:', withdrawalReference);
        logger.success(`Withdrawal initiated: ${withdrawalReference}`, executionId);

        return res.status(200).json({
          success: true,
          ...result
        });

      } catch (error) {
        console.error('====================================');
        console.error('❌ INITIATE WITHDRAWAL FAILED');
        console.error('Error:', error.message);

        logger.error('Initiate withdrawal failed', executionId, error);

        return res.status(500).json({
          success: false,
          error: error.message || 'Failed to initiate withdrawal'
        });
      }
    });
  }
);

console.log('✅ ParcelAm  App Firebase Functions initialized successfully');
console.log('📦 All services loaded and ready');
