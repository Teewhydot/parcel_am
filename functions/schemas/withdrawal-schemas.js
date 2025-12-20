// ========================================================================
// Withdrawal Request Schemas
// ========================================================================

const { Validators, DataCleaners, ValidationError } = require('../utils/validation');

// Withdrawal limits
const MIN_WITHDRAWAL_AMOUNT = 100;
const MAX_WITHDRAWAL_AMOUNT = 500000;

/**
 * Schema for initiating a withdrawal
 */
const initiateWithdrawalSchema = {
  validate(body) {
    const { userId, amount, recipientCode, withdrawalReference, bankAccountId } = body;

    // Validate required fields
    if (!userId || userId.trim() === '') {
      throw new ValidationError('User ID is required', 'userId');
    }

    if (!amount || isNaN(Number(amount))) {
      throw new ValidationError('Valid amount is required', 'amount');
    }

    const numAmount = Number(amount);
    if (numAmount < MIN_WITHDRAWAL_AMOUNT) {
      throw new ValidationError(
        `Minimum withdrawal amount is NGN ${MIN_WITHDRAWAL_AMOUNT}`,
        'amount'
      );
    }

    if (numAmount > MAX_WITHDRAWAL_AMOUNT) {
      throw new ValidationError(
        `Maximum withdrawal amount is NGN ${MAX_WITHDRAWAL_AMOUNT}`,
        'amount'
      );
    }

    if (!recipientCode || recipientCode.trim() === '') {
      throw new ValidationError('Recipient code is required', 'recipientCode');
    }

    if (!withdrawalReference || withdrawalReference.trim() === '') {
      throw new ValidationError('Withdrawal reference is required', 'withdrawalReference');
    }

    if (!bankAccountId || bankAccountId.trim() === '') {
      throw new ValidationError('Bank account ID is required', 'bankAccountId');
    }

    return {
      userId: DataCleaners.sanitizeString(userId),
      amount: numAmount,
      recipientCode: DataCleaners.sanitizeString(recipientCode),
      withdrawalReference: DataCleaners.sanitizeString(withdrawalReference),
      bankAccountId: DataCleaners.sanitizeString(bankAccountId)
    };
  }
};

module.exports = {
  initiateWithdrawalSchema,
  MIN_WITHDRAWAL_AMOUNT,
  MAX_WITHDRAWAL_AMOUNT
};
