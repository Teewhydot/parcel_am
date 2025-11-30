# Wallet Withdrawal User Guide

## Overview
This guide explains how to withdraw funds from your ParcelAM wallet to your Nigerian bank account.

## Prerequisites
- Active ParcelAM account with KYC verification completed
- Available balance in your wallet
- Valid Nigerian bank account

## Table of Contents
1. [Adding a Bank Account](#adding-a-bank-account)
2. [Withdrawing Funds](#withdrawing-funds)
3. [Understanding Withdrawal Status](#understanding-withdrawal-status)
4. [Transaction History](#transaction-history)
5. [Troubleshooting](#troubleshooting)

---

## Adding a Bank Account

### Step-by-Step Instructions

1. **Navigate to Bank Accounts**
   - Open the ParcelAM app
   - Go to your wallet
   - Tap on "Manage Bank Accounts" or the bank icon

2. **Add New Account**
   - Tap the "Add Bank Account" button
   - Select your bank from the dropdown list
   - Use the search bar to quickly find your bank

3. **Enter Account Details**
   - Enter your 10-digit account number
   - Tap "Verify Account"

4. **Confirm Account**
   - The app will display the account name registered with your bank
   - **Important:** Verify that the name matches your account
   - Tap "Save Account" to confirm

5. **Account Saved**
   - Your account is now saved and ready for withdrawals
   - You can save up to 5 bank accounts

### Important Notes
- Account verification uses Paystack's secure API
- Only accounts that pass verification can be saved
- The account name must match your bank records
- You can delete saved accounts at any time

---

## Withdrawing Funds

### Withdrawal Requirements
- **Minimum Amount:** NGN 100
- **Maximum Amount:** NGN 500,000 per transaction
- **Hourly Limit:** Maximum 5 withdrawal requests per hour
- **Available Balance:** You must have sufficient available balance

### Step-by-Step Instructions

1. **Initiate Withdrawal**
   - Open your wallet
   - Tap the "Withdraw" button
   - Ensure you have internet connection

2. **Enter Amount**
   - Enter the amount you wish to withdraw
   - The app will validate:
     - Minimum amount (NGN 100)
     - Maximum amount (NGN 500,000)
     - Available balance
   - View any applicable fees (if configured)

3. **Select Bank Account**
   - Choose from your saved bank accounts
   - If you don't have a saved account, you'll be prompted to add one

4. **Review and Confirm**
   - Review withdrawal summary:
     - Amount
     - Destination bank account
     - Any fees
     - Total deduction
   - Tap "Confirm Withdrawal"

5. **Authenticate**
   - Enter your PIN or use biometric authentication
   - This ensures only you can authorize withdrawals

6. **Processing**
   - Your funds are held during processing
   - You'll see a processing indicator
   - A unique reference ID is generated

7. **Track Status**
   - You'll be redirected to the withdrawal status screen
   - Real-time updates show your withdrawal progress

### What Happens During Processing

1. **Initiated:** Your withdrawal request is created
2. **Processing:** Funds are being transferred via Paystack
3. **Success:** Transfer completed successfully
4. **Failed:** Transfer failed, funds returned to your wallet
5. **Reversed:** Transfer was reversed by the bank, funds returned

### Expected Processing Time
- Most withdrawals complete within 5-15 minutes
- Bank processing may take up to 24 hours
- You'll receive push notifications for status changes

---

## Understanding Withdrawal Status

### Status Badges

#### Pending (Yellow)
- Your withdrawal is queued for processing
- Funds are held in your wallet
- No action required

#### Processing (Blue)
- Paystack is transferring your funds
- Expected completion within minutes
- Monitor for status updates

#### Success (Green)
- Transfer completed successfully
- Funds sent to your bank account
- Bank may take additional time to credit your account
- **Expected arrival:** Within 24 hours

#### Failed (Red)
- Transfer could not be completed
- Funds automatically returned to your available balance
- View failure reason for details
- You can retry the withdrawal

#### Reversed (Gray)
- Bank reversed the transfer
- Funds automatically returned to your available balance
- View reversal reason for details
- Contact support if you have questions

### Timeline View
The withdrawal detail screen shows a timeline:
1. **Initiated:** When you submitted the withdrawal
2. **Processing:** When Paystack started the transfer
3. **Completed/Failed/Reversed:** Final outcome

---

## Transaction History

### Viewing Withdrawal Transactions

1. **Access Transaction History**
   - Open your wallet
   - Scroll to "Recent Transactions"
   - Use filters to show only withdrawals

2. **Filter Options**
   - All transactions
   - Withdrawals only
   - Deposits only
   - Payments only

3. **Search Transactions**
   - Search by reference ID
   - Search by bank account name
   - Search by amount

### Transaction Details

Tap any withdrawal transaction to view:
- Amount withdrawn
- Destination bank account
- Status
- Reference ID (tap to copy)
- Timestamps (created, updated, processed)
- Transfer code (if available)
- Failure or reversal reason (if applicable)

### Retry Failed Withdrawal

If a withdrawal fails:
1. Open the transaction details
2. Tap "Retry Withdrawal"
3. Amount and bank account are pre-filled
4. A new reference ID is generated
5. Follow the standard withdrawal flow

---

## Troubleshooting

### Common Issues and Solutions

#### "Insufficient Balance"
**Cause:** Your available balance is less than the withdrawal amount
**Solution:**
- Check your available balance (excludes held/pending funds)
- Reduce the withdrawal amount
- Wait for pending transactions to complete

#### "Account Verification Failed"
**Cause:** The account number or bank code is incorrect
**Solution:**
- Double-check your account number
- Ensure you selected the correct bank
- Verify with your bank that the account is active
- Some account types may not support online transfers

#### "Rate Limit Exceeded"
**Cause:** You've made 5 withdrawal requests in the last hour
**Solution:**
- Wait for the rate limit to reset (1 hour from first request)
- This security measure protects your account

#### "No Internet Connection"
**Cause:** Your device is offline
**Solution:**
- Check your internet connection
- Try again when connected
- Withdrawal operations require internet connectivity

#### "Withdrawal Failed" - After Processing
**Cause:** Various reasons including:
- Insufficient funds in Paystack account (contact support)
- Invalid recipient account
- Bank declined the transfer
**Solution:**
- Check the failure reason in transaction details
- Ensure your bank account is active
- Contact support if the issue persists
- Funds are automatically returned to your wallet

#### "Withdrawal Reversed"
**Cause:** Bank returned the funds after initial acceptance
**Reasons may include:**
- Account closed or frozen
- Account details mismatch
- Bank's internal security checks
**Solution:**
- Check reversal reason in transaction details
- Verify your account with your bank
- Try a different bank account
- Contact support for assistance

### Getting Help

If you encounter issues not covered here:

1. **In-App Support**
   - Tap the support icon in the app
   - Include your withdrawal reference ID
   - Describe the issue in detail

2. **Contact Information**
   - Email: support@parcelam.com
   - Include:
     - Your user ID
     - Withdrawal reference ID
     - Description of the issue
     - Screenshots (if helpful)

3. **Response Time**
   - Support typically responds within 24 hours
   - Urgent issues are prioritized

---

## Security Best Practices

### Protect Your Account
1. **Never share your PIN** with anyone
2. **Enable biometric authentication** for faster, secure withdrawals
3. **Verify account names** before saving bank accounts
4. **Keep your app updated** to the latest version
5. **Use secure internet connections** for withdrawals

### What ParcelAM Does to Protect You
- **Encryption:** All bank details are encrypted at rest
- **Authentication:** PIN or biometric required for withdrawals
- **Rate Limiting:** Prevents rapid, unauthorized withdrawal attempts
- **Real-time Monitoring:** Suspicious patterns are detected and flagged
- **Audit Logs:** All withdrawal attempts are logged with device info
- **Secure API:** Paystack's certified payment infrastructure

---

## Withdrawal Statistics

### In Your Wallet
View helpful withdrawal statistics:
- **Total Withdrawn This Month:** Sum of successful withdrawals
- **Pending Withdrawals:** Count of withdrawals being processed
- **Failed Withdrawals (Last 30 Days):** Count of failed attempts

These stats help you track your withdrawal activity.

---

## Frequently Asked Questions

### How long does a withdrawal take?
- Processing: 5-15 minutes (Paystack transfer)
- Bank crediting: Up to 24 hours (varies by bank)
- Total: Usually complete within a few hours

### Are there fees for withdrawals?
- Check the withdrawal confirmation screen
- Fees (if any) are displayed before you confirm
- Standard Paystack transfer fees may apply

### What if I entered the wrong bank account?
- Withdrawals cannot be cancelled once initiated
- Ensure you verify the account name during setup
- Only withdraw to accounts you own

### Can I withdraw to someone else's account?
- No, for security reasons
- Account name verification helps prevent errors
- Only use your own verified accounts

### What happens to failed withdrawal funds?
- Automatically returned to your available balance
- Usually within minutes of failure
- You can retry immediately

### Why was my withdrawal reversed?
- Banks may reverse for various reasons
- Check the reversal reason in transaction details
- Funds are automatically returned to your wallet
- Contact support if you need clarification

### How do I delete a saved bank account?
1. Go to "Manage Bank Accounts"
2. Find the account to delete
3. Swipe left or tap the menu icon
4. Tap "Delete"
5. Confirm deletion

### Can I save accounts from any Nigerian bank?
- Yes, all Nigerian banks supported by Paystack
- The app fetches the updated bank list daily
- Accounts must pass verification to be saved

---

## Summary

Withdrawing from your ParcelAM wallet is designed to be:
- **Fast:** Most withdrawals complete in minutes
- **Secure:** Multiple layers of protection
- **Simple:** Easy 6-step process
- **Transparent:** Real-time status updates
- **Reliable:** Automatic refunds for failed transactions

For the best experience:
- Add and verify your bank accounts in advance
- Ensure stable internet connection
- Monitor withdrawal status
- Keep the app updated

If you encounter any issues, our support team is here to help!
