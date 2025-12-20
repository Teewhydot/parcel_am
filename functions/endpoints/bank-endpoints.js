// ========================================================================
// Bank Endpoints
// ========================================================================

const axios = require('axios');
const { createEndpoint } = require('../core/endpoint-factory');
const { ENVIRONMENT } = require('../utils/constants');
const { logger } = require('../utils/logger');
const {
  resolveBankAccountSchema,
  createTransferRecipientSchema
} = require('../schemas');

/**
 * Resolve Bank Account
 * Verifies a bank account number with Paystack and returns account name
 */
const resolveBankAccount = createEndpoint({
  name: 'resolveBankAccount',
  secrets: ['PAYSTACK_SECRET_KEY'],
  timeout: 60,
  schema: resolveBankAccountSchema
}, async (data, ctx) => {
  const { executionId } = ctx;
  const { accountNumber, bankCode } = data;

  console.log('🏦 Resolving bank account...');
  console.log('  - Account Number:', accountNumber);
  console.log('  - Bank Code:', bankCode);

  logger.info('Resolving bank account', executionId, { accountNumber, bankCode });

  const paystackUrl = `https://api.paystack.co/bank/resolve?account_number=${accountNumber}&bank_code=${bankCode}`;

  try {
    const response = await axios.get(paystackUrl, {
      headers: {
        'Authorization': `Bearer ${ENVIRONMENT.PAYSTACK_SECRET_KEY}`,
        'Content-Type': 'application/json'
      }
    });

    if (response.data.status === true) {
      const accountName = response.data.data.account_name;
      console.log('✅ Account resolved successfully:', accountName);
      logger.success(`Bank account resolved: ${accountName}`, executionId);

      return {
        success: true,
        accountName: accountName,
        accountNumber: accountNumber,
        bankCode: bankCode
      };
    } else {
      console.log('❌ Paystack returned error:', response.data.message);
      logger.error('Paystack resolve failed', executionId, null, response.data);

      throw {
        statusCode: 400,
        message: response.data.message || 'Could not resolve account'
      };
    }
  } catch (error) {
    if (error.response) {
      const paystackError = error.response.data;
      logger.error('Paystack API error', executionId, error, paystackError);

      throw {
        statusCode: error.response.status,
        message: paystackError.message || 'Account verification failed'
      };
    }
    throw error;
  }
});

/**
 * Create Transfer Recipient
 * Creates a Paystack transfer recipient for withdrawals
 */
const createTransferRecipient = createEndpoint({
  name: 'createTransferRecipient',
  secrets: ['PAYSTACK_SECRET_KEY'],
  timeout: 60,
  schema: createTransferRecipientSchema
}, async (data, ctx) => {
  const { executionId } = ctx;
  const { accountNumber, accountName, bankCode } = data;

  console.log('👤 Creating transfer recipient...');
  console.log('  - Account Number:', accountNumber);
  console.log('  - Account Name:', accountName);
  console.log('  - Bank Code:', bankCode);

  logger.info('Creating transfer recipient', executionId, { accountNumber, accountName, bankCode });

  try {
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
          'Authorization': `Bearer ${ENVIRONMENT.PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (response.data.status === true) {
      const recipientCode = response.data.data.recipient_code;
      console.log('✅ Transfer recipient created:', recipientCode);
      logger.success(`Transfer recipient created: ${recipientCode}`, executionId);

      return {
        success: true,
        recipientCode: recipientCode
      };
    } else {
      console.log('❌ Paystack returned error:', response.data.message);
      logger.error('Paystack create recipient failed', executionId, null, response.data);

      throw {
        statusCode: 400,
        message: response.data.message || 'Could not create transfer recipient'
      };
    }
  } catch (error) {
    if (error.response) {
      const paystackError = error.response.data;
      logger.error('Paystack API error', executionId, error, paystackError);

      throw {
        statusCode: error.response.status,
        message: paystackError.message || 'Failed to create transfer recipient'
      };
    }
    throw error;
  }
});

module.exports = {
  resolveBankAccount,
  createTransferRecipient
};
