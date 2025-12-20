// ========================================================================
// Transaction Endpoints
// ========================================================================

const { createEndpoint } = require('../core/endpoint-factory');
const { paymentService } = require('../services/payment-service');
const { dbHelper } = require('../utils/database');
const { logger } = require('../utils/logger');
const {
  createTransactionSchema,
  verifyPaymentSchema,
  transactionStatusSchema
} = require('../schemas');

/**
 * Create Paystack Transaction
 * Initializes a payment transaction and returns authorization URL
 */
const createPaystackTransaction = createEndpoint({
  name: 'createPaystackTransaction',
  secrets: ['PAYSTACK_SECRET_KEY'],
  schema: createTransactionSchema
}, async (data, ctx) => {
  const { executionId } = ctx;
  const { orderId, amount, userId, email, metadata, userName } = data;

  console.log('📦 Structuring funding details...');
  logger.info('Structuring funding details', executionId, { orderId, transactionType: 'funding' });

  const fundingDetails = {
    orderId: orderId,
    transactionType: 'funding',
    total: metadata.total || amount,
    ...metadata
  };

  console.log('✅ Funding details structured:', Object.keys(fundingDetails).join(', '));
  logger.info('Funding details structured', executionId, { fundingDetailsKeys: Object.keys(fundingDetails) });

  // Initialize payment with Paystack
  console.log('💳 Initializing Paystack payment...');
  logger.info('Initializing Paystack transaction', executionId, { email, amount, userId });

  const paymentResult = await paymentService.initializeTransaction(
    email,
    amount,
    { userId, fundingDetails, userName },
    executionId
  );

  logger.info('Paystack initialization completed', executionId, { success: paymentResult.success });

  if (!paymentResult.success) {
    logger.error('Payment initialization failed', executionId, null, paymentResult);
    throw {
      statusCode: 500,
      message: 'Failed to initialize payment',
      details: paymentResult.error
    };
  }

  // Generate prefixed reference
  const transactionType = fundingDetails.transactionType || 'funding';
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

  // Create service record
  console.log('💾 Saving to database...');
  logger.info('Creating service record in database', executionId, { reference, userId });

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

  logger.success(`Transaction created successfully: ${reference}`, executionId);

  console.log('🎉 TRANSACTION CREATED SUCCESSFULLY');

  return {
    success: true,
    reference: reference,
    authorization_url: paymentResult.authorizationUrl,
    access_code: paymentResult.accessCode
  };
});

/**
 * Verify Paystack Payment
 * Verifies a payment transaction status with Paystack
 */
const verifyPaystackPayment = createEndpoint({
  name: 'verifyPaystackPayment',
  secrets: ['PAYSTACK_SECRET_KEY'],
  schema: verifyPaymentSchema
}, async (data, ctx) => {
  const { executionId } = ctx;
  const { reference } = data;

  console.log('📞 Calling Paystack verification API...');
  logger.info(`Verifying payment with reference: ${reference}`, executionId);

  const verificationResult = await paymentService.verifyTransaction(reference, executionId);

  logger.info('Verification API call completed', executionId, {
    success: verificationResult.success,
    status: verificationResult.status
  });

  if (!verificationResult.success) {
    logger.error('Payment verification failed', executionId, null, verificationResult);
    throw {
      statusCode: 400,
      message: 'Payment verification failed',
      details: verificationResult.error
    };
  }

  logger.success(`Payment verified successfully: ${reference}`, executionId);

  return {
    success: true,
    status: verificationResult.status,
    amount: verificationResult.amount,
    reference: reference,
    paidAt: verificationResult.paidAt,
    channel: verificationResult.channel
  };
});

/**
 * Get Transaction Status
 * Retrieves the current status of a transaction
 */
const getTransactionStatus = createEndpoint({
  name: 'getTransactionStatus',
  secrets: ['PAYSTACK_SECRET_KEY'],
  timeout: 60,
  schema: transactionStatusSchema
}, async (data, ctx) => {
  const { executionId } = ctx;
  // For GET requests, data comes from query params
  const reference = data.reference || ctx.req.query.reference;

  if (!reference) {
    throw {
      statusCode: 400,
      message: 'Reference is required'
    };
  }

  logger.info(`Checking status for reference: ${reference}`, executionId);

  const verificationResult = await paymentService.verifyTransaction(reference, executionId);

  logger.info('Status check API call completed', executionId, {
    success: verificationResult.success,
    status: verificationResult.status
  });

  if (!verificationResult.success) {
    throw {
      statusCode: 400,
      message: 'Failed to get transaction status',
      details: verificationResult.error
    };
  }

  logger.success(`Transaction status retrieved: ${reference}`, executionId);

  return {
    success: true,
    status: verificationResult.status,
    amount: verificationResult.amount,
    reference: reference,
    paidAt: verificationResult.paidAt
  };
});

module.exports = {
  createPaystackTransaction,
  verifyPaystackPayment,
  getTransactionStatus
};
