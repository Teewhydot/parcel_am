// ========================================================================
// Wallet Service - Wallet Balance Operations
// ========================================================================

const admin = require('firebase-admin');
const { logger } = require('../../utils/logger');

/**
 * WalletService handles all wallet-related operations
 * including balance updates within atomic transactions
 */
class WalletService {
  constructor() {
    this.db = admin.firestore();
  }

  /**
   * Updates wallet balance within an existing Firestore transaction
   * @param {FirebaseFirestore.Transaction} transaction - The Firestore transaction
   * @param {string} userId - User ID
   * @param {number} amount - Amount to add to wallet
   * @param {string} executionId - Execution ID for logging
   * @returns {Promise<Object>} Result of wallet update
   */
  async updateBalanceInTransaction(transaction, userId, amount, executionId) {
    if (!userId) {
      logger.warning('Cannot update wallet: missing userId', executionId);
      return { success: false, reason: 'missing_user_id' };
    }

    const walletRef = this.db.collection('wallets').doc(userId);

    console.log('  💰 Updating wallet balance...');
    console.log('    - User ID:', userId);
    console.log('    - Amount to add: ₦', amount);

    logger.info('Wallet update queued', executionId, { userId, amount });

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

      return {
        success: true,
        action: 'increment',
        previousBalance: currentWallet.availableBalance,
        newBalance: newAvailableBalance
      };
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

      return {
        success: true,
        action: 'create',
        previousBalance: 0,
        newBalance: amount
      };
    }
  }

  /**
   * Gets wallet balance for a user
   * @param {string} userId - User ID
   * @param {string} executionId - Execution ID for logging
   * @returns {Promise<Object>} Wallet data
   */
  async getBalance(userId, executionId) {
    try {
      const walletRef = this.db.collection('wallets').doc(userId);
      const walletSnapshot = await walletRef.get();

      if (!walletSnapshot.exists) {
        return {
          success: true,
          exists: false,
          availableBalance: 0,
          heldBalance: 0,
          totalBalance: 0
        };
      }

      const walletData = walletSnapshot.data();
      return {
        success: true,
        exists: true,
        availableBalance: walletData.availableBalance || 0,
        heldBalance: walletData.heldBalance || 0,
        totalBalance: walletData.totalBalance || 0
      };
    } catch (error) {
      logger.error('Failed to get wallet balance', executionId, error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Deducts amount from wallet (for withdrawals)
   * @param {FirebaseFirestore.Transaction} transaction - The Firestore transaction
   * @param {string} userId - User ID
   * @param {number} amount - Amount to deduct
   * @param {string} executionId - Execution ID for logging
   * @returns {Promise<Object>} Result of deduction
   */
  async deductBalanceInTransaction(transaction, userId, amount, executionId) {
    if (!userId) {
      logger.warning('Cannot deduct from wallet: missing userId', executionId);
      return { success: false, reason: 'missing_user_id' };
    }

    const walletRef = this.db.collection('wallets').doc(userId);
    const walletSnapshot = await transaction.get(walletRef);

    if (!walletSnapshot.exists) {
      logger.error('Wallet not found for deduction', executionId, null, { userId });
      return { success: false, reason: 'wallet_not_found' };
    }

    const currentWallet = walletSnapshot.data();
    const currentBalance = currentWallet.availableBalance || 0;

    if (currentBalance < amount) {
      logger.error('Insufficient balance', executionId, null, {
        userId,
        currentBalance,
        requestedAmount: amount
      });
      return { success: false, reason: 'insufficient_balance' };
    }

    const newAvailableBalance = currentBalance - amount;
    const newTotalBalance = newAvailableBalance + (currentWallet.heldBalance || 0);

    transaction.update(walletRef, {
      availableBalance: newAvailableBalance,
      totalBalance: newTotalBalance,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    logger.info(`Wallet deduction queued: ${currentBalance} - ${amount} = ${newAvailableBalance}`, executionId);

    return {
      success: true,
      previousBalance: currentBalance,
      newBalance: newAvailableBalance
    };
  }
}

// Export singleton instance
const walletService = new WalletService();

module.exports = {
  walletService,
  WalletService
};
