// ========================================================================
// Constants and Configuration
// ========================================================================

// Environment variables configuration (Firebase Functions v2)
const ENVIRONMENT = {
  GMAIL_PASSWORD: process.env.PASSWORD,
  PAYSTACK_SECRET_KEY: process.env.PAYSTACK_SECRET_KEY,
  PROJECT_ID: process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT,

};

// Contact information configuration (can be updated remotely)
const CONTACT_INFO = {
  SUPPORT_EMAIL: process.env.SUPPORT_EMAIL || 'support@fooddelivery.com',
  SUPPORT_PHONE: process.env.SUPPORT_PHONE || '+234 XXX XXX XXXX',
  BUSINESS_LOCATION: process.env.BUSINESS_LOCATION || 'Lagos, Nigeria'
};

// Transaction reference prefix mapping
const TRANSACTION_PREFIX_MAP = {
  'funding': 'F-',
  'withdrawal': 'W-',
};

// Transaction type configuration for food delivery system
const TRANSACTION_TYPES = {
  funding: {
    collectionName: 'funding_orders',
    transactionType: 'funding',
    serviceType: 'funding',
    emailSubject: {
      creation: 'Funding Created',
      success: 'Funding Confirmed'
    },
    notificationTitle: {
      creation: 'Funding Created',
      success: 'Funding Confirmed! 🍽️'
    },
    emoji: '🍽️'
  },
  withdrawal: {
    collectionName: 'withdrawals',
    transactionType: 'withdrawal',
    serviceType: 'withdrawal',
    emailSubject: {
      creation: 'Withdrawal Created',
      success: 'Withdrawal Confirmed'
    },
    notificationTitle: {
      creation: 'Withdrawal Created',
      success: 'Withdrawal Confirmed! ⭐'
    },
    emoji: '⭐'
  },
};

// Google API scopes for FCM
const GOOGLE_SCOPES = [
  'https://www.googleapis.com/auth/firebase.messaging'
];

// Paystack API configuration
const PAYSTACK = {
  API_BASE_URL: 'https://api.paystack.co',
  ENDPOINTS: {
    INITIALIZE_TRANSACTION: '/transaction/initialize',
    VERIFY_TRANSACTION: '/transaction/verify'
  }
};

// Firebase Functions configuration
const FUNCTIONS_CONFIG = {
  REGION: 'us-central1',
  TIMEOUT_SECONDS: 560,
  MEMORY: '256MB'
};
// Email styling constants
const EMAIL_STYLES = {
  HEADER_COLOR: '#1a365d',
  LOGO_URL: '',
  BUSINESS_NAME: 'Food Delivery App',
  BUSINESS_TAGLINE: 'Fresh Food, Fast Delivery'
};

// Admin notification types mapping
const NOTIFICATION_TYPE_MAP = {
  'funding': 'Funding',
  'withdrawal': 'Withdrawal'
};

module.exports = {
  ENVIRONMENT,
  CONTACT_INFO,
  TRANSACTION_PREFIX_MAP,
  TRANSACTION_TYPES,
  GOOGLE_SCOPES,
  PAYSTACK,
  FLUTTERWAVE,
  FLUTTERWAVE_ENVIRONMENT,
  FUNCTIONS_CONFIG,
  EMAIL_STYLES,
  NOTIFICATION_TYPE_MAP,
  ADMIN_NOTIFICATION_TITLES,
  TARGET_ROLES
};