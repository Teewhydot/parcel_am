// ========================================================================
// Withdrawal Endpoints
// ========================================================================

const admin = require('firebase-admin');
const { createEndpoint } = require('../core/endpoint-factory');
const { logger } = require('../utils/logger');
const { initiateWithdrawal: initiateWithdrawalHandler } = require('../handlers/withdrawal-handler');
const { initiateWithdrawalSchema } = require('../schemas');

/**
 * Initiate Withdrawal
 * Initiates a withdrawal transfer via Paystack
 */
const initiateWithdrawal = createEndpoint({
  name: 'initiateWithdrawal',
  secrets: ['PAYSTACK_SECRET_KEY'],
  timeout: 60,
  requiresAuth: true,
  schema: initiateWithdrawalSchema
}, async (data, ctx) => {
  const { executionId, auth } = ctx;
  const { userId, amount, recipientCode, withdrawalReference, bankAccountId } = data;

  console.log('💸 Processing withdrawal...');
  console.log('  - User ID:', userId);
  console.log('  - Amount:', amount);
  console.log('  - Recipient Code:', recipientCode);
  console.log('  - Withdrawal Reference:', withdrawalReference);
  console.log('  - Bank Account ID:', bankAccountId);

  logger.info('Initiating withdrawal', executionId, {
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
    throw {
      statusCode: 404,
      message: 'Bank account not found'
    };
  }

  const bankAccountDetails = bankAccountDoc.data();

  // Create context object for the handler
  const context = {
    auth: {
      uid: auth.uid,
      token: auth.token
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

  return {
    success: true,
    ...result
  };
});

module.exports = {
  initiateWithdrawal
};
