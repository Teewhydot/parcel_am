// ========================================================================
// Withdrawal Handler - Initiate Withdrawal and Process Transfer Events
// ========================================================================

const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const { logger } = require('../utils/logger');
const { paymentService } = require('../services/payment-service');
const { dbHelper } = require('../utils/database');

// Constants
const MIN_WITHDRAWAL_AMOUNT = 100; // NGN 100
const MAX_WITHDRAWAL_AMOUNT = 500000; // NGN 500,000
const MAX_WITHDRAWAL_REQUESTS_PER_HOUR = 5;
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour

/**
 * Check rate limiting for withdrawal requests
 * Maximum 5 requests per hour per user
 */
async function checkRateLimit(userId, executionId) {
  try {
    const now = Date.now();
    const windowStart = now - RATE_LIMIT_WINDOW_MS;

    const rateLimitRef = admin.firestore()
      .collection('withdrawal_rate_limits')
      .doc(userId);

    const rateLimitDoc = await rateLimitRef.get();

    if (!rateLimitDoc.exists) {
      // First withdrawal request
      await rateLimitRef.set({
        userId,
        attempts: [{
          timestamp: now,
          success: false // Will be updated after successful withdrawal
        }],
        lastAttempt: now,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return { allowed: true, attemptsInWindow: 1 };
    }

    const data = rateLimitDoc.data();
    const recentAttempts = (data.attempts || [])
      .filter(attempt => attempt.timestamp > windowStart);

    if (recentAttempts.length >= MAX_WITHDRAWAL_REQUESTS_PER_HOUR) {
      const oldestAttempt = recentAttempts[0];
      const retryAfterMs = (oldestAttempt.timestamp + RATE_LIMIT_WINDOW_MS) - now;
      const retryAfterMinutes = Math.ceil(retryAfterMs / (60 * 1000));

      logger.warning('Rate limit exceeded for withdrawal', executionId, {
        userId,
        attemptsInWindow: recentAttempts.length,
        maxAllowed: MAX_WITHDRAWAL_REQUESTS_PER_HOUR,
        retryAfterMinutes
      });

      return {
        allowed: false,
        attemptsInWindow: recentAttempts.length,
        retryAfterMinutes
      };
    }

    // Add current attempt
    await rateLimitRef.update({
      attempts: admin.firestore.FieldValue.arrayUnion({
        timestamp: now,
        success: false
      }),
      lastAttempt: now
    });

    return { allowed: true, attemptsInWindow: recentAttempts.length + 1 };
  } catch (error) {
    logger.error('Error checking rate limit', executionId, error);
    // On error, allow the request (fail open)
    return { allowed: true, attemptsInWindow: 0 };
  }
}

/**
 * Check for duplicate withdrawal order by reference
 * Implements idempotency
 */
async function checkDuplicateWithdrawal(reference, executionId) {
  try {
    const existingOrder = await admin.firestore()
      .collection('withdrawal_orders')
      .doc(reference)
      .get();

    if (existingOrder.exists) {
      logger.info('Duplicate withdrawal detected', executionId, {
        reference,
        status: existingOrder.data().status
      });
      return existingOrder.data();
    }

    return null;
  } catch (error) {
    logger.error('Error checking duplicate withdrawal', executionId, error);
    return null;
  }
}

/**
 * Hold balance atomically using Firestore transaction
 */
async function holdBalanceForWithdrawal(userId, amount, reference, executionId) {
  try {
    const db = admin.firestore();
    const walletRef = db.collection('wallets').doc(userId);

    const result = await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw new Error('Wallet not found');
      }

      const wallet = walletDoc.data();
      const availableBalance = wallet.availableBalance || 0;
      const heldBalance = wallet.heldBalance || 0;

      if (availableBalance < amount) {
        throw new Error(`Insufficient balance. Available: NGN ${availableBalance}, Required: NGN ${amount}`);
      }

      const newAvailableBalance = availableBalance - amount;
      const newHeldBalance = heldBalance + amount;

      transaction.update(walletRef, {
        availableBalance: newAvailableBalance,
        heldBalance: newHeldBalance,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        previousAvailable: availableBalance,
        newAvailableBalance,
        newHeldBalance,
        totalBalance: wallet.totalBalance
      };
    });

    logger.success('Balance held successfully', executionId, {
      userId,
      amount,
      reference,
      ...result
    });

    return { success: true, ...result };
  } catch (error) {
    logger.error('Failed to hold balance', executionId, error, {
      userId,
      amount,
      reference
    });
    throw error;
  }
}

/**
 * Release held balance (on failure or reversal)
 */
async function releaseHeldBalance(userId, amount, reference, executionId) {
  try {
    const db = admin.firestore();
    const walletRef = db.collection('wallets').doc(userId);

    const result = await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw new Error('Wallet not found');
      }

      const wallet = walletDoc.data();
      const availableBalance = wallet.availableBalance || 0;
      const heldBalance = wallet.heldBalance || 0;

      if (heldBalance < amount) {
        logger.warning('Insufficient held balance to release', executionId, {
          required: amount,
          available: heldBalance
        });
      }

      const newAvailableBalance = availableBalance + amount;
      const newHeldBalance = Math.max(0, heldBalance - amount);

      transaction.update(walletRef, {
        availableBalance: newAvailableBalance,
        heldBalance: newHeldBalance,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        newAvailableBalance,
        newHeldBalance
      };
    });

    logger.success('Balance released successfully', executionId, {
      userId,
      amount,
      reference,
      ...result
    });

    return { success: true, ...result };
  } catch (error) {
    logger.error('Failed to release balance', executionId, error);
    throw error;
  }
}

/**
 * Deduct held balance (on successful transfer)
 */
async function deductHeldBalance(userId, amount, reference, executionId) {
  try {
    const db = admin.firestore();
    const walletRef = db.collection('wallets').doc(userId);

    const result = await db.runTransaction(async (transaction) => {
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw new Error('Wallet not found');
      }

      const wallet = walletDoc.data();
      const heldBalance = wallet.heldBalance || 0;
      const totalBalance = wallet.totalBalance || 0;

      if (heldBalance < amount) {
        throw new Error(`Insufficient held balance. Held: NGN ${heldBalance}, Required: NGN ${amount}`);
      }

      const newHeldBalance = heldBalance - amount;
      const newTotalBalance = totalBalance - amount;

      transaction.update(walletRef, {
        heldBalance: newHeldBalance,
        totalBalance: newTotalBalance,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        newHeldBalance,
        newTotalBalance
      };
    });

    logger.success('Held balance deducted successfully', executionId, {
      userId,
      amount,
      reference,
      ...result
    });

    return { success: true, ...result };
  } catch (error) {
    logger.error('Failed to deduct held balance', executionId, error);
    throw error;
  }
}

/**
 * Main handler for initiating withdrawal
 */
async function initiateWithdrawal(params, context, executionId) {
  const startTime = Date.now();

  try {
    const { userId, amount, recipientCode, withdrawalReference, bankAccountId, bankAccountDetails } = params;

    logger.info('Starting withdrawal initiation', executionId, {
      userId,
      amount,
      recipientCode,
      withdrawalReference,
      bankAccountId
    });

    // 1. Validate authentication
    if (!context.auth || context.auth.uid !== userId) {
      throw new Error('Unauthorized: User ID mismatch');
    }

    // 2. Validate withdrawal amount
    if (!amount || amount < MIN_WITHDRAWAL_AMOUNT) {
      throw new Error(`Minimum withdrawal amount is NGN ${MIN_WITHDRAWAL_AMOUNT}`);
    }

    if (amount > MAX_WITHDRAWAL_AMOUNT) {
      throw new Error(`Maximum withdrawal amount is NGN ${MAX_WITHDRAWAL_AMOUNT}`);
    }

    // 3. Check rate limiting
    const rateLimitCheck = await checkRateLimit(userId, executionId);
    if (!rateLimitCheck.allowed) {
      throw new Error(`Rate limit exceeded. Please try again in ${rateLimitCheck.retryAfterMinutes} minutes.`);
    }

    // 4. Check for duplicate reference (idempotency)
    const existingOrder = await checkDuplicateWithdrawal(withdrawalReference, executionId);
    if (existingOrder) {
      logger.info('Returning existing withdrawal order', executionId, {
        reference: withdrawalReference,
        status: existingOrder.status
      });

      return {
        success: true,
        withdrawalOrder: existingOrder,
        duplicate: true
      };
    }

    // 5. Hold balance atomically
    try {
      await holdBalanceForWithdrawal(userId, amount, withdrawalReference, executionId);
    } catch (error) {
      throw new Error(`Failed to hold balance: ${error.message}`);
    }

    // 6. Create withdrawal order document (status: pending)
    const withdrawalOrder = {
      id: withdrawalReference,
      userId,
      amount,
      bankAccount: bankAccountDetails,
      status: 'pending',
      recipientCode,
      transferCode: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      processedAt: null,
      metadata: {
        bankAccountId,
        initiatedAt: new Date().toISOString(),
        executionId
      },
      failureReason: null,
      reversalReason: null
    };

    await admin.firestore()
      .collection('withdrawal_orders')
      .doc(withdrawalReference)
      .set(withdrawalOrder);

    logger.info('Withdrawal order created', executionId, {
      reference: withdrawalReference,
      status: 'pending'
    });

    // 7. Create pending transaction record
    const transactionRef = admin.firestore().collection('transactions').doc();
    const transaction = {
      walletId: userId,
      userId,
      amount,
      type: 'withdrawal',
      status: 'pending',
      currency: 'NGN',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      description: `Withdrawal to ${bankAccountDetails.bankName}`,
      referenceId: withdrawalReference,
      metadata: {
        bankAccount: bankAccountDetails,
        withdrawalOrderId: withdrawalReference
      },
      idempotencyKey: withdrawalReference
    };

    await transactionRef.set(transaction);

    logger.info('Transaction record created', executionId, {
      transactionId: transactionRef.id,
      reference: withdrawalReference
    });

    // 8. Call Paystack initiateTransfer
    const transferResult = await paymentService.initiateTransfer({
      amount,
      recipientCode,
      reference: withdrawalReference,
      reason: `Wallet withdrawal to ${bankAccountDetails.bankName}`,
      metadata: {
        userId,
        withdrawalOrderId: withdrawalReference,
        bankAccountId
      }
    }, executionId);

    if (!transferResult.success) {
      // Rollback: release held balance
      logger.error('Paystack transfer failed, rolling back', executionId, {
        error: transferResult.error
      });

      await releaseHeldBalance(userId, amount, withdrawalReference, executionId);

      await admin.firestore()
        .collection('withdrawal_orders')
        .doc(withdrawalReference)
        .update({
          status: 'failed',
          failureReason: transferResult.error,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

      await transactionRef.update({
        status: 'failed',
        metadata: admin.firestore.FieldValue.arrayUnion({
          error: transferResult.error,
          timestamp: new Date().toISOString()
        })
      });

      throw new Error(`Transfer initiation failed: ${transferResult.error}`);
    }

    // 9. Update withdrawal order to 'processing' with transferCode
    await admin.firestore()
      .collection('withdrawal_orders')
      .doc(withdrawalReference)
      .update({
        status: 'processing',
        transferCode: transferResult.transferCode,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          ...withdrawalOrder.metadata,
          transferInitiatedAt: new Date().toISOString(),
          paystackStatus: transferResult.status
        }
      });

    logger.success('Withdrawal initiated successfully', executionId, {
      reference: withdrawalReference,
      transferCode: transferResult.transferCode,
      amount,
      duration: `${Date.now() - startTime}ms`
    });

    // Return updated withdrawal order
    const updatedOrder = await admin.firestore()
      .collection('withdrawal_orders')
      .doc(withdrawalReference)
      .get();

    return {
      success: true,
      withdrawalOrder: updatedOrder.data(),
      transferCode: transferResult.transferCode,
      duplicate: false
    };

  } catch (error) {
    logger.error('Withdrawal initiation failed', executionId, error, {
      params,
      duration: `${Date.now() - startTime}ms`
    });

    throw error;
  }
}

module.exports = {
  initiateWithdrawal,
  holdBalanceForWithdrawal,
  releaseHeldBalance,
  deductHeldBalance,
  checkRateLimit,
  checkDuplicateWithdrawal
};
