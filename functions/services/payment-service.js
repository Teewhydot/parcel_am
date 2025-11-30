// ========================================================================
// Payment Service - Paystack Integration and Transaction Management
// ========================================================================

const axios = require('axios');
const crypto = require('crypto');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const { ENVIRONMENT, PAYSTACK, TRANSACTION_PREFIX_MAP } = require('../utils/constants');
const { logger } = require('../utils/logger');
const { ReferenceUtils } = require('../utils/validation');

class PaymentService {
  constructor() {
    this.apiKey = ENVIRONMENT.PAYSTACK_SECRET_KEY;
    this.baseUrl = PAYSTACK.API_BASE_URL;

    // Log API key status (without exposing the actual key)
    if (!this.apiKey) {
      logger.error('CRITICAL: Paystack API key is not configured!', 'payment-service-init', null, {
        hasApiKey: false,
        apiKeyType: typeof this.apiKey,
        envVarExists: !!process.env.PAYSTACK_SECRET_KEY
      });
    } else {
      logger.info('Paystack service initialized', 'payment-service-init', {
        hasApiKey: true,
        apiKeyLength: this.apiKey.length,
        apiKeySuffix: '...' + this.apiKey.slice(-5),
        baseUrl: this.baseUrl
      });
    }
  }

  // ========================================================================
  // Transaction Initialization
  // ========================================================================

  async initializeTransaction(email, amount, metadata, reference = null, executionId = 'payment-init') {
    const initStartTime = Date.now();
    try {
      // Generate unique reference if not provided (Paystack idempotency mechanism)
      const transactionReference = reference || `TXN-${uuidv4()}`;

      console.log('💳 [PAYSTACK] Initializing transaction...');
      console.log('  Email:', email);
      console.log('  Amount (NGN):', amount);
      console.log('  Amount (kobo):', amount * 100);
      console.log('  Reference:', transactionReference);

      // Validate API key before making request
      if (!this.apiKey) {
        console.error('❌ [PAYSTACK] API key not configured!');
        throw new Error('Paystack API key is not configured. Please set PAYSTACK_SECRET_KEY environment variable or Firebase config.');
      }

      console.log('  API Key:', this.apiKey ? '...' + this.apiKey.slice(-5) : 'NOT SET');

      logger.info(`Starting transaction initialization`, executionId, {
        email,
        amount,
        amountInKobo: amount * 100,
        reference: transactionReference,
        referenceProvided: !!reference,
        hasMetadata: !!metadata,
        metadataKeys: metadata ? Object.keys(metadata) : [],
        apiKeyConfigured: !!this.apiKey,
        apiKeySuffix: this.apiKey ? '...' + this.apiKey.slice(-5) : 'NOT SET'
      });

      logger.apiCall('POST', `${this.baseUrl}${PAYSTACK.ENDPOINTS.INITIALIZE_TRANSACTION}`, null, executionId);
      logger.payment('INITIALIZE', 'new-transaction', amount, executionId);

      const requestPayload = {
        email: email,
        amount: amount * 100, // Convert to kobo
        reference: transactionReference, // Unique reference for idempotency
        metadata: metadata
      };

      logger.info(`Sending request to Paystack API`, executionId, {
        url: `${this.baseUrl}${PAYSTACK.ENDPOINTS.INITIALIZE_TRANSACTION}`,
        payloadKeys: Object.keys(requestPayload),
        hasAuthHeader: !!this.apiKey,
        authHeaderSuffix: this.apiKey ? `Bearer ...${this.apiKey.slice(-5)}` : 'MISSING'
      });

      const response = await axios.post(
        `${this.baseUrl}${PAYSTACK.ENDPOINTS.INITIALIZE_TRANSACTION}`,
        requestPayload,
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 30000 // 30 second timeout
        }
      );

      const initEndTime = Date.now();
      const initDuration = initEndTime - initStartTime;

      console.log(`✅ [PAYSTACK] Response received (${initDuration}ms)`);
      console.log('  HTTP Status:', response.status);
      console.log('  Data Status:', response.data.status);

      logger.info(`Paystack API response received`, executionId, {
        status: response.status,
        dataStatus: response.data.status,
        duration: `${initDuration}ms`
      });

      if (response.status === 200 && response.data.status) {
        const paystackReference = response.data.data.reference;
        const authorizationUrl = response.data.data.authorization_url;
        const accessCode = response.data.data.access_code;

        console.log('🎉 [PAYSTACK] Transaction initialized successfully');
        console.log('  Reference:', paystackReference);
        console.log('  Authorization URL:', authorizationUrl?.substring(0, 50) + '...');

        logger.success(`Transaction initialized: ${paystackReference}`, executionId, {
          reference: paystackReference,
          providedReference: transactionReference,
          amount: amount,
          email: email,
          hasAuthUrl: !!authorizationUrl,
          hasAccessCode: !!accessCode,
          duration: `${initDuration}ms`
        });

        return {
          success: true,
          reference: paystackReference,
          providedReference: transactionReference,
          authorizationUrl: authorizationUrl,
          accessCode: accessCode,
          amount: amount
        };
      } else {
        console.error('❌ [PAYSTACK] Unexpected response');
        console.error('  Status:', response.status);
        console.error('  Message:', response.data.message);

        logger.error(`Unexpected Paystack response`, executionId, null, {
          status: response.status,
          dataStatus: response.data.status,
          message: response.data.message
        });
        throw new Error(`Paystack API error: ${response.data.message || 'Unknown error'}`);
      }
    } catch (error) {
      const initEndTime = Date.now();
      const initDuration = initEndTime - initStartTime;

      console.error('====================================');
      console.error('❌ [PAYSTACK] Initialization FAILED');
      console.error('Error:', error.message);
      console.error('Type:', error.name);
      console.error('Duration:', `${initDuration}ms`);
      if (error.response) {
        console.error('Response Status:', error.response.status);
        console.error('Response Data:', JSON.stringify(error.response.data, null, 2));
      }
      console.error('====================================');

      logger.error('Failed to initialize transaction', executionId, error, {
        email: email,
        amount: amount,
        duration: `${initDuration}ms`,
        errorType: error.name,
        hasResponse: !!error.response,
        responseStatus: error.response?.status,
        responseData: error.response?.data
      });

      return {
        success: false,
        error: error.message,
        details: error.response?.data || null
      };
    }
  }

  // ========================================================================
  // Transaction Verification
  // ========================================================================

  async verifyTransaction(reference, executionId = 'payment-verify') {
    const verificationStartTime = Date.now();

    try {
      console.log('🔍 [PAYSTACK] Verifying transaction...');
      console.log('  Reference:', reference);

      // Validate API key before making request
      if (!this.apiKey) {
        console.error('❌ [PAYSTACK] API key not configured!');
        throw new Error('Paystack API key is not configured. Please set PAYSTACK_SECRET_KEY environment variable or Firebase config.');
      }

      logger.info(`Starting transaction verification`, executionId, {
        reference,
        apiKeyConfigured: !!this.apiKey
      });
      logger.payment('VERIFY', reference, null, executionId);

      const verificationUrl = `${this.baseUrl}${PAYSTACK.ENDPOINTS.VERIFY_TRANSACTION}/${reference}`;
      logger.apiCall('GET', verificationUrl, null, executionId);
      logger.info(`Sending GET request to Paystack`, executionId, { url: verificationUrl });

      const response = await axios.get(
        verificationUrl,
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 30000
        }
      );

      const verificationEndTime = Date.now();
      const verificationDuration = verificationEndTime - verificationStartTime;

      console.log(`✅ [PAYSTACK] Verification response (${verificationDuration}ms)`);
      console.log('  HTTP Status:', response.status);
      console.log('  Data Status:', response.data.status);

      logger.info(`Paystack API Response received`, executionId, {
        httpStatus: response.status,
        dataStatus: response.data.status,
        hasData: !!response.data.data,
        duration: `${verificationDuration}ms`
      });

      if (response.status === 200 && response.data.status) {
        const transactionData = response.data.data;

        console.log('📊 [PAYSTACK] Transaction data:');
        console.log('  Status:', transactionData.status);
        console.log('  Amount (kobo):', transactionData.amount);
        console.log('  Channel:', transactionData.channel);

        logger.info(`Processing verification response`, executionId, {
          reference: transactionData.reference,
          status: transactionData.status,
          amount: transactionData.amount
        });

        const verificationResult = this.processVerificationResponse(transactionData, executionId);

        console.log('🎉 [PAYSTACK] Transaction verified successfully');

        logger.success(`Transaction verified: ${reference}`, executionId, {
          ...verificationResult,
          duration: `${verificationDuration}ms`
        });
        return {
          success: true,
          ...verificationResult
        };
      } else {
        console.error('❌ [PAYSTACK] Unexpected verification response');
        console.error('  Status:', response.status);
        console.error('  Message:', response.data.message);

        logger.error(`Unexpected verification response`, executionId, null, {
          httpStatus: response.status,
          dataStatus: response.data.status,
          message: response.data.message
        });
        throw new Error(`Verification failed: ${response.data.message || 'Unknown error'}`);
      }
    } catch (error) {
      const verificationEndTime = Date.now();
      const verificationDuration = verificationEndTime - verificationStartTime;

      console.error('====================================');
      console.error('❌ [PAYSTACK] Verification FAILED');
      console.error('Reference:', reference);
      console.error('Error:', error.message);
      console.error('Type:', error.name);
      console.error('Duration:', `${verificationDuration}ms`);
      if (error.response) {
        console.error('Response Status:', error.response.status);
        console.error('Response Message:', error.response.data?.message);
        console.error('Response Data:', JSON.stringify(error.response.data, null, 2));
      }
      console.error('====================================');

      logger.error(`Transaction verification failed after ${verificationDuration}ms`, executionId, error, {
        reference: reference,
        errorType: error.name,
        errorCode: error.code,
        hasResponse: !!error.response,
        responseStatus: error.response?.status,
        responseMessage: error.response?.data?.message,
        responseData: error.response?.data
      });

      return {
        success: false,
        error: error.message,
        details: error.response?.data || null
      };
    }
  }

  processVerificationResponse(transactionData, executionId = 'process-verification') {
    logger.info(`Processing verification response data`, executionId, {
      hasReference: !!transactionData.reference,
      hasStatus: !!transactionData.status,
      hasAmount: !!transactionData.amount,
      hasPaidAt: !!transactionData.paid_at,
      hasMetadata: !!transactionData.metadata
    });

    const {
      reference,
      status,
      amount,
      paid_at,
      created_at,
      channel,
      currency,
      gateway_response,
      metadata
    } = transactionData;

    const convertedAmount = amount / 100; // Convert from kobo

    logger.info(`Converting amount from kobo to naira`, executionId, {
      amountInKobo: amount,
      amountInNaira: convertedAmount
    });

    const processedData = {
      reference: reference,
      status: status,
      amount: convertedAmount,
      amountInKobo: amount,
      paidAt: paid_at || created_at,
      channel: channel,
      currency: currency,
      gatewayResponse: gateway_response,
      metadata: metadata || {},
      timestamp: new Date().toISOString()
    };

    logger.info('Transaction verification details processed', executionId, {
      reference: processedData.reference,
      status: processedData.status,
      amount: `${processedData.currency} ${processedData.amount}`,
      channel: processedData.channel,
      paidAt: processedData.paidAt,
      hasMetadata: Object.keys(processedData.metadata).length > 0
    });

    return processedData;
  }

  // ========================================================================
  // Webhook Verification
  // ========================================================================

  verifyWebhookSignature(requestBody, signature, executionId = 'webhook-verify') {
    try {
      logger.info('Starting webhook signature verification', executionId, {
        hasRequestBody: !!requestBody,
        hasSignature: !!signature,
        requestBodyType: typeof requestBody
      });

      if (!signature) {
        logger.warning('No signature provided in webhook - rejecting', executionId);
        return false;
      }

      logger.info('Computing HMAC hash', executionId, {
        algorithm: 'sha512',
        bodyLength: JSON.stringify(requestBody).length
      });

      const hash = crypto
        .createHmac('sha512', this.apiKey)
        .update(JSON.stringify(requestBody))
        .digest('hex');

      const isValid = hash === signature;

      logger.info('Signature comparison completed', executionId, {
        isValid,
        hashPreview: hash.substring(0, 20) + '...',
        signaturePreview: signature.substring(0, 20) + '...'
      });

      if (isValid) {
        logger.success('Webhook signature verified successfully', executionId);
      } else {
        logger.warning('Invalid webhook signature - possible tampering or incorrect key', executionId, {
          expected: hash.substring(0, 20) + '...',
          received: signature.substring(0, 20) + '...'
        });
      }

      return isValid;
    } catch (error) {
      logger.error('Error verifying webhook signature', executionId, error, {
        errorType: error.name,
        errorMessage: error.message
      });
      return false;
    }
  }

  processWebhookEvent(eventData, executionId = 'webhook-process') {
    try {
      logger.info(`Starting webhook event processing`, executionId, {
        hasEventData: !!eventData,
        eventDataKeys: eventData ? Object.keys(eventData) : []
      });

      const { event, data } = eventData;

      logger.info(`Processing webhook event: ${event}`, executionId, {
        event: event,
        status: data?.status,
        reference: data?.reference,
        hasData: !!data
      });

      if (!data) {
        logger.error('No data found in webhook event', executionId, null, {
          event,
          eventDataKeys: Object.keys(eventData)
        });
        throw new Error('No data found in webhook event');
      }

      logger.info('Extracting event data fields', executionId, {
        hasReference: !!data.reference,
        hasStatus: !!data.status,
        hasAmount: !!data.amount,
        hasPaidAt: !!data.paid_at,
        hasMetadata: !!data.metadata
      });

      const convertedAmount = data.amount ? data.amount / 100 : 0;

      const processedEvent = {
        eventType: event,
        reference: data.reference,
        status: data.status,
        amount: convertedAmount,
        paidAt: data.paid_at,
        metadata: data.metadata || {},
        channel: data.channel,
        currency: data.currency,
        gatewayResponse: data.gateway_response
      };

      logger.info('Event data extracted', executionId, {
        reference: processedEvent.reference,
        status: processedEvent.status,
        amount: `${processedEvent.currency} ${processedEvent.amount}`,
        hasMetadata: Object.keys(processedEvent.metadata).length > 0
      });

      // Extract user information from metadata
      if (processedEvent.metadata) {
        logger.info('Extracting user information from metadata', executionId, {
          metadataKeys: Object.keys(processedEvent.metadata)
        });

        processedEvent.userId = processedEvent.metadata.userId;
        processedEvent.userName = processedEvent.metadata.userName;
        processedEvent.bookingDetails = processedEvent.metadata.bookingDetails || {};

        logger.info('User information extracted', executionId, {
          hasUserId: !!processedEvent.userId,
          hasUserName: !!processedEvent.userName,
          hasBookingDetails: Object.keys(processedEvent.bookingDetails).length > 0
        });
      } else {
        logger.warning('No metadata found in webhook event', executionId);
      }

      logger.success(`Webhook event processed: ${event}`, executionId, {
        reference: processedEvent.reference,
        status: processedEvent.status,
        amount: processedEvent.amount,
        hasUserId: !!processedEvent.userId
      });

      return {
        success: true,
        processedEvent: processedEvent
      };
    } catch (error) {
      logger.error('Failed to process webhook event', executionId, error, {
        errorType: error.name,
        errorMessage: error.message,
        hasEventData: !!eventData
      });
      return {
        success: false,
        error: error.message
      };
    }
  }

  // ========================================================================
  // Reference Management
  // ========================================================================

  generatePrefixedReference(transactionType, paystackReference) {
    return ReferenceUtils.generatePrefixedReference(transactionType, paystackReference);
  }

  extractOriginalReference(prefixedReference) {
    return ReferenceUtils.removePrefixFromReference(prefixedReference);
  }

  getTransactionTypeFromReference(reference) {
    return ReferenceUtils.getTransactionTypeFromReference(reference);
  }

  // ========================================================================
  // Payment Status Management
  // ========================================================================

  isSuccessfulPayment(status) {
    return status === 'success';
  }

  isFailedPayment(status) {
    return status === 'failed';
  }

  isPendingPayment(status) {
    return status === 'pending';
  }

  isAbandonedPayment(status) {
    return status === 'abandoned';
  }

  getPaymentStatusDescription(status) {
    const statusMap = {
      'success': 'Payment completed successfully',
      'failed': 'Payment failed',
      'pending': 'Payment is pending',
      'abandoned': 'Payment was abandoned',
      'ongoing': 'Payment is in progress',
      'reversed': 'Payment has been reversed'
    };

    return statusMap[status] || `Unknown status: ${status}`;
  }

  // ========================================================================
  // Batch Payment Operations
  // ========================================================================

  async verifyMultipleTransactions(references, executionId = 'batch-verify') {
    logger.processing(`Verifying ${references.length} transactions`, executionId);

    const results = [];
    for (const reference of references) {
      try {
        const result = await this.verifyTransaction(reference, `${executionId}-${reference}`);
        results.push(result);
      } catch (error) {
        logger.error(`Failed to verify transaction: ${reference}`, executionId, error);
        results.push({
          success: false,
          reference: reference,
          error: error.message
        });
      }
    }

    const successCount = results.filter(r => r.success).length;
    const failureCount = results.length - successCount;

    logger.info(`Batch verification completed: ${successCount} successful, ${failureCount} failed`, executionId);

    return {
      total: results.length,
      successful: successCount,
      failed: failureCount,
      results: results
    };
  }

  // ========================================================================
  // Error Handling and Retry Logic
  // ========================================================================

  async verifyTransactionWithRetry(reference, maxRetries = 3, executionId = 'payment-verify-retry') {
    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logger.info(`Verification attempt ${attempt}/${maxRetries} for ${reference}`, executionId);

        const result = await this.verifyTransaction(reference, `${executionId}-attempt-${attempt}`);

        if (result.success) {
          logger.success(`Transaction verified on attempt ${attempt}`, executionId);
          return result;
        } else {
          lastError = new Error(result.error || 'Verification failed');
        }
      } catch (error) {
        lastError = error;
        logger.warning(`Verification attempt ${attempt} failed: ${error.message}`, executionId);

        if (attempt < maxRetries) {
          const delay = Math.pow(2, attempt) * 1000; // Exponential backoff
          logger.info(`Retrying in ${delay}ms...`, executionId);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    logger.error(`All verification attempts failed for ${reference}`, executionId, lastError);
    throw lastError;
  }

  // ========================================================================
  // Utility Methods
  // ========================================================================

  formatAmount(amount, currency = 'NGN') {
    return `${currency} ${amount.toLocaleString()}`;
  }

  convertToKobo(nairaAmount) {
    return Math.round(nairaAmount * 100);
  }

  convertFromKobo(koboAmount) {
    return koboAmount / 100;
  }

  async testConnection(executionId = 'payment-test') {
    try {
      logger.info('Testing Paystack connection', executionId);

      // Test with a simple API call (get banks)
      const response = await axios.get(
        `${this.baseUrl}/bank`,
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 10000
        }
      );

      if (response.status === 200) {
        logger.success('Paystack connection test successful', executionId);
        return true;
      } else {
        throw new Error(`Unexpected response: ${response.status}`);
      }
    } catch (error) {
      logger.error('Paystack connection test failed', executionId, error);
      return false;
    }
  }
}

// Create default payment service instance
const paymentService = new PaymentService();

module.exports = {
  PaymentService,
  paymentService
};