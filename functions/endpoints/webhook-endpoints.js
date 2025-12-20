// ========================================================================
// Webhook Endpoints
// ========================================================================

const admin = require('firebase-admin');
const { createWebhookEndpoint } = require('../core/endpoint-factory');
const { paymentService } = require('../services/payment-service');
const { webhookRouter } = require('../webhooks');
const { logger } = require('../utils/logger');

/**
 * Paystack Webhook
 * Handles all Paystack webhook events (payments and transfers)
 */
const paystackWebhook = createWebhookEndpoint({
  name: 'paystackWebhook',
  secrets: ['PAYSTACK_SECRET_KEY']
}, async (rawEvent, ctx) => {
  const { executionId, headers } = ctx;
  const db = admin.firestore();

  console.log('====================================');
  console.log('🔔 PAYSTACK WEBHOOK RECEIVED', executionId);
  console.log('Event type:', rawEvent.event);
  console.log('Status:', rawEvent.data?.status);
  console.log('Reference:', rawEvent.data?.reference);
  console.log('Has signature:', !!headers['x-paystack-signature']);

  logger.info('Received Paystack webhook', executionId, {
    event: rawEvent.event,
    status: rawEvent.data?.status,
    reference: rawEvent.data?.reference,
    hasSignature: !!headers['x-paystack-signature']
  });

  // Verify webhook signature
  console.log('🔐 Verifying webhook signature...');
  logger.info('Verifying webhook signature', executionId);

  const paystackSignature = headers['x-paystack-signature'];
  if (!paymentService.verifyWebhookSignature(rawEvent, paystackSignature, executionId)) {
    console.error('❌ INVALID WEBHOOK SIGNATURE - Rejecting');
    logger.warning('Invalid webhook signature - rejecting request', executionId);
    throw {
      statusCode: 400,
      message: 'Invalid paystack signature'
    };
  }
  console.log('✅ Webhook signature verified');
  logger.info('Webhook signature verified successfully', executionId);

  // ========================================================================
  // WEBHOOK DEDUPLICATION: Check if event has already been processed
  // ========================================================================
  const eventId = rawEvent.id || `${rawEvent.data?.reference}-${rawEvent.event}`;
  console.log('🔍 Checking for duplicate webhook event...');
  console.log('  - Event ID:', eventId);

  logger.info('Checking webhook event deduplication', executionId, { eventId });

  const processedWebhookRef = db.collection('processed_webhooks').doc(eventId);
  const processedWebhookDoc = await processedWebhookRef.get();

  if (processedWebhookDoc.exists) {
    const processedData = processedWebhookDoc.data();
    console.log('⚠️  DUPLICATE WEBHOOK EVENT DETECTED');
    console.log('  - Event ID:', eventId);
    console.log('  - First Processed:', processedData.processedAt);

    logger.warning('Duplicate webhook event ignored', executionId, {
      eventId,
      eventType: rawEvent.event,
      firstProcessedAt: processedData.processedAt,
      reference: rawEvent.data?.reference
    });

    return { message: 'Event already processed' };
  }

  console.log('✅ Event not yet processed - continuing');
  logger.info('New webhook event - proceeding with processing', executionId, { eventId });

  // Process webhook event data
  console.log('📦 Processing webhook event data...');
  logger.info('Processing webhook event data', executionId);

  const processResult = paymentService.processWebhookEvent(rawEvent, executionId);
  if (!processResult.success) {
    console.error('❌ Failed to process webhook - invalid data');
    logger.error('Failed to process webhook event - invalid data structure', executionId, null, {
      error: processResult.error
    });
    throw {
      statusCode: 400,
      message: 'Invalid event data'
    };
  }
  console.log('✅ Webhook event data processed');
  logger.info('Webhook event processed successfully', executionId);

  const processedEvent = processResult.processedEvent;

  // Route to appropriate handler
  console.log('🔀 Routing to handler...');
  console.log('  - Event:', rawEvent.event);
  console.log('  - Status:', processedEvent.status);

  logger.info('Routing webhook to handler', executionId, {
    eventType: rawEvent.event,
    processedStatus: processedEvent.status
  });

  // For charge events, use processed event; for transfer events, use raw event
  const eventData = rawEvent.event.startsWith('transfer.')
    ? rawEvent
    : processedEvent;

  // Only route charge.success if status is success
  if (rawEvent.event === 'charge.success' && processedEvent.status !== 'success') {
    logger.info('Skipping charge.success - status is not success', executionId, {
      status: processedEvent.status
    });
  } else {
    await webhookRouter.route(rawEvent.event, eventData, executionId);
  }

  // ========================================================================
  // STORE PROCESSED EVENT ID: Track this event to prevent future duplicates
  // ========================================================================
  console.log('💾 Recording processed webhook event...');
  logger.info('Storing processed webhook event ID', executionId, { eventId });

  try {
    await processedWebhookRef.set({
      eventId: eventId,
      eventType: rawEvent.event,
      reference: rawEvent.data?.reference,
      status: rawEvent.data?.status,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      executionId: executionId,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    });

    console.log('✅ Webhook event recorded');
    logger.info('Webhook event ID stored successfully', executionId, { eventId });
  } catch (storageError) {
    console.error('⚠️  Failed to store webhook event ID (non-critical):', storageError.message);
    logger.warning('Failed to store webhook event ID', executionId, storageError, { eventId });
  }

  console.log('🎉 WEBHOOK PROCESSED SUCCESSFULLY');
  console.log('====================================');

  logger.success('Webhook processed successfully', executionId);

  return { message: 'Webhook received successfully' };
});

module.exports = {
  paystackWebhook
};
