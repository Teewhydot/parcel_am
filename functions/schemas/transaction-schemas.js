// ========================================================================
// Transaction Request Schemas
// ========================================================================

const { Validators, DataCleaners, ValidationError } = require('../utils/validation');

/**
 * Schema for creating a new Paystack transaction
 */
const createTransactionSchema = {
  validate(body) {
    const { orderId, amount, email, userId, metadata = {} } = body;

    // Validate required fields
    Validators.isNotEmpty(orderId, 'orderId');
    Validators.isValidAmount(amount, 'amount');
    Validators.isEmail(email, 'email');
    Validators.isNotEmpty(userId, 'userId');

    return {
      orderId: DataCleaners.sanitizeString(orderId),
      amount: Number(amount),
      email: DataCleaners.sanitizeEmail(email),
      userId: DataCleaners.sanitizeString(userId),
      metadata: DataCleaners.cleanTransactionMetadata(metadata),
      userName: metadata.userName || 'Customer'
    };
  }
};

/**
 * Schema for verifying a Paystack payment
 */
const verifyPaymentSchema = {
  validate(body) {
    const { reference } = body;

    if (!reference || reference.trim() === '') {
      throw new ValidationError('Reference is required', 'reference');
    }

    return {
      reference: DataCleaners.sanitizeString(reference)
    };
  }
};

/**
 * Schema for getting transaction status
 */
const transactionStatusSchema = {
  validate(body) {
    const { reference } = body;

    if (!reference || reference.trim() === '') {
      throw new ValidationError('Reference is required', 'reference');
    }

    return {
      reference: DataCleaners.sanitizeString(reference)
    };
  }
};

module.exports = {
  createTransactionSchema,
  verifyPaymentSchema,
  transactionStatusSchema
};
