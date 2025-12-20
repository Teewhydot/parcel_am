// ========================================================================
// Bank Operation Request Schemas
// ========================================================================

const { Validators, DataCleaners, ValidationError } = require('../utils/validation');

/**
 * Schema for resolving bank account details
 */
const resolveBankAccountSchema = {
  validate(body) {
    const { accountNumber, bankCode } = body;

    if (!accountNumber || accountNumber.trim() === '') {
      throw new ValidationError('Account number is required', 'accountNumber');
    }

    if (!bankCode || bankCode.trim() === '') {
      throw new ValidationError('Bank code is required', 'bankCode');
    }

    // Validate account number is 10 digits
    const cleanAccountNumber = accountNumber.trim();
    if (!/^\d{10}$/.test(cleanAccountNumber)) {
      throw new ValidationError('Account number must be 10 digits', 'accountNumber');
    }

    return {
      accountNumber: cleanAccountNumber,
      bankCode: DataCleaners.sanitizeString(bankCode)
    };
  }
};

/**
 * Schema for creating a transfer recipient
 */
const createTransferRecipientSchema = {
  validate(body) {
    const { accountNumber, accountName, bankCode } = body;

    if (!accountNumber || accountNumber.trim() === '') {
      throw new ValidationError('Account number is required', 'accountNumber');
    }

    if (!accountName || accountName.trim() === '') {
      throw new ValidationError('Account name is required', 'accountName');
    }

    if (!bankCode || bankCode.trim() === '') {
      throw new ValidationError('Bank code is required', 'bankCode');
    }

    // Validate account number is 10 digits
    const cleanAccountNumber = accountNumber.trim();
    if (!/^\d{10}$/.test(cleanAccountNumber)) {
      throw new ValidationError('Account number must be 10 digits', 'accountNumber');
    }

    return {
      accountNumber: cleanAccountNumber,
      accountName: DataCleaners.sanitizeString(accountName),
      bankCode: DataCleaners.sanitizeString(bankCode)
    };
  }
};

module.exports = {
  resolveBankAccountSchema,
  createTransferRecipientSchema
};
