# ParcelAm Firebase Functions - Lego Brick Architecture

This document explains the modular architecture of the Firebase Cloud Functions and how to extend functionality.

## Table of Contents

- [Overview](#overview)
- [Folder Structure](#folder-structure)
- [Adding New Endpoints](#adding-new-endpoints)
- [Adding Webhook Handlers](#adding-webhook-handlers)
- [Adding Scheduled Tasks](#adding-scheduled-tasks)
- [Adding Validation Schemas](#adding-validation-schemas)
- [Extending the Domain Layer](#extending-the-domain-layer)
- [Error Handling](#error-handling)
- [Authentication](#authentication)

---

## Overview

The architecture follows a "Lego Brick" pattern where:

- **index.js** is a pure assembly file (~75 lines) that imports and exports functions
- **Business logic** is extracted into reusable domain services
- **Endpoints** are thin wrappers using a factory pattern
- **Middleware** provides cross-cutting concerns (auth, logging, error handling)

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Single Responsibility** | Each file has one purpose |
| **Testability** | Domain logic is isolated and testable |
| **Consistency** | All endpoints behave the same way |
| **Reusability** | Core framework works for any endpoint |
| **Maintainability** | Easy to find and modify code |

---

## Folder Structure

```
functions/
├── index.js                    # Assembly layer - imports and exports
├── core/                       # Framework layer
│   ├── endpoint-factory.js     # Creates HTTP endpoints
│   ├── scheduled-task-factory.js
│   ├── response-builder.js
│   └── middleware/
│       ├── auth-middleware.js
│       ├── cors-handler.js
│       ├── error-handler.js
│       └── request-logger.js
├── endpoints/                  # Thin endpoint definitions
│   ├── transaction-endpoints.js
│   ├── bank-endpoints.js
│   └── index.js               # Barrel export
├── scheduled/                  # Scheduled tasks
│   ├── pending-transactions.js
│   └── index.js
├── webhooks/                   # Webhook routing
│   ├── webhook-router.js
│   └── handlers/
├── domain/                     # Business logic
│   ├── payment/
│   └── wallet/
├── schemas/                    # Request validation
├── services/                   # External service integrations
├── handlers/                   # Legacy handlers
└── utils/                      # Utilities
```

---

## Adding New Endpoints

### Step 1: Create a Validation Schema (Optional)

Create a schema in `schemas/` if input validation is needed:

```javascript
// schemas/my-feature-schemas.js
const { Validators, DataCleaners, ValidationError } = require('../utils/validation');

const myFeatureSchema = {
  validate(body) {
    const { userId, data } = body;

    Validators.isNotEmpty(userId, 'userId');

    return {
      userId: DataCleaners.sanitizeString(userId),
      data: data || {}
    };
  }
};

module.exports = { myFeatureSchema };
```

Add to the barrel export:

```javascript
// schemas/index.js
const { myFeatureSchema } = require('./my-feature-schemas');
module.exports = { ..., myFeatureSchema };
```

### Step 2: Create the Endpoint

Create endpoint in `endpoints/`:

```javascript
// endpoints/my-feature-endpoints.js
const { createEndpoint } = require('../core/endpoint-factory');
const { myFeatureSchema } = require('../schemas');
const { logger } = require('../utils/logger');

const myFeature = createEndpoint({
  name: 'myFeature',           // Used for logging
  secrets: ['MY_SECRET'],       // Optional: secrets to inject
  timeout: 60,                  // Optional: timeout in seconds
  requiresAuth: true,           // Optional: require Firebase ID token
  schema: myFeatureSchema       // Optional: validation schema
}, async (data, ctx) => {
  const { executionId, auth } = ctx;

  // auth.uid is available when requiresAuth: true
  logger.info('Processing request', executionId, { userId: data.userId });

  // Your business logic here
  const result = await doSomething(data);

  // Return object becomes the JSON response
  return {
    success: true,
    result: result
  };
});

module.exports = { myFeature };
```

### Step 3: Export from Barrel

```javascript
// endpoints/index.js
const { myFeature } = require('./my-feature-endpoints');
module.exports = { ..., myFeature };
```

### Step 4: Register in index.js

```javascript
// index.js
const { ..., myFeature } = require('./endpoints');

exports.myFeature = myFeature;
```

### Endpoint Factory Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | required | Endpoint name for logging |
| `secrets` | string[] | `[]` | Secret names to inject |
| `timeout` | number | 300 | Timeout in seconds |
| `memory` | string | '256MiB' | Memory allocation |
| `requiresAuth` | boolean | `false` | Verify Firebase ID token |
| `schema` | object | `null` | Validation schema with `validate(data)` |
| `middleware` | Function[] | `[]` | Additional middleware |

### Context Object

The handler receives `(data, ctx)` where `ctx` contains:

```javascript
{
  executionId: string,    // Unique ID for logging
  req: Request,           // Express request object
  res: Response,          // Express response object
  auth?: {                // Only when requiresAuth: true
    uid: string,
    token: DecodedIdToken
  }
}
```

---

## Adding Webhook Handlers

### Step 1: Create the Handler

```javascript
// webhooks/handlers/my-event-handlers.js
const { logger } = require('../../utils/logger');

async function handleMyEvent(eventData, executionId) {
  console.log('Processing my event...');
  logger.info('Handling my event', executionId, {
    reference: eventData.reference
  });

  // Your business logic here
  await processEvent(eventData);
}

module.exports = { handleMyEvent };
```

### Step 2: Register with Router

```javascript
// webhooks/index.js
const { handleMyEvent } = require('./handlers/my-event-handlers');

webhookRouter
  .register('my.event.type', handleMyEvent);
```

### Webhook Router API

```javascript
// Register a single handler
webhookRouter.register('event.type', handlerFunction);

// Register multiple handlers
webhookRouter.registerAll({
  'event.type1': handler1,
  'event.type2': handler2
});

// Check if handler exists
webhookRouter.hasHandler('event.type');

// Route an event (called automatically by webhook endpoint)
await webhookRouter.route('event.type', eventData, executionId);
```

---

## Adding Scheduled Tasks

### Step 1: Create the Task

```javascript
// scheduled/my-task.js
const { createScheduledTask } = require('../core/scheduled-task-factory');
const { logger } = require('../utils/logger');

const myScheduledTask = createScheduledTask({
  name: 'myScheduledTask',
  schedule: 'every 1 hours',    // or cron: '0 * * * *'
  secrets: ['MY_SECRET'],        // Optional
  timezone: 'Africa/Lagos'       // Optional, default: UTC
}, async (context, executionId) => {
  logger.info('Running scheduled task', executionId);

  // Your task logic here
  await performTask();

  logger.success('Task completed', executionId);
});

module.exports = { myScheduledTask };
```

### Step 2: Export and Register

```javascript
// scheduled/index.js
const { myScheduledTask } = require('./my-task');
module.exports = { ..., myScheduledTask };

// index.js
const { ..., myScheduledTask } = require('./scheduled');
exports.myScheduledTask = myScheduledTask;
```

### Schedule Expressions

| Expression | Description |
|------------|-------------|
| `every 5 minutes` | Every 5 minutes |
| `every 1 hours` | Every hour |
| `every 24 hours` | Once daily |
| `every monday 09:00` | Weekly on Monday at 9 AM |
| `0 0 * * *` | Cron: daily at midnight |
| `0 */2 * * *` | Cron: every 2 hours |

---

## Adding Validation Schemas

Schemas validate and sanitize request data:

```javascript
// schemas/my-schemas.js
const { Validators, DataCleaners, ValidationError } = require('../utils/validation');

const mySchema = {
  validate(body) {
    const { email, amount, items } = body;

    // Required field validation
    Validators.isEmail(email, 'email');
    Validators.isValidAmount(amount, 'amount');

    // Custom validation
    if (!items || items.length === 0) {
      throw new ValidationError('At least one item is required', 'items');
    }

    // Return sanitized data
    return {
      email: DataCleaners.sanitizeEmail(email),
      amount: Number(amount),
      items: items.map(item => DataCleaners.sanitizeString(item))
    };
  }
};

module.exports = { mySchema };
```

### Available Validators

| Validator | Description |
|-----------|-------------|
| `Validators.isNotEmpty(value, fieldName)` | Check non-empty string |
| `Validators.isEmail(value, fieldName)` | Validate email format |
| `Validators.isValidAmount(value, fieldName)` | Validate positive number |

### Available Cleaners

| Cleaner | Description |
|---------|-------------|
| `DataCleaners.sanitizeString(value)` | Trim and clean string |
| `DataCleaners.sanitizeEmail(value)` | Normalize email |
| `DataCleaners.cleanTransactionMetadata(obj)` | Clean metadata object |

---

## Extending the Domain Layer

Domain services contain business logic separate from HTTP concerns.

### Creating a New Domain Service

```javascript
// domain/my-feature/my-service.js
const admin = require('firebase-admin');
const { logger } = require('../../utils/logger');

class MyService {
  constructor() {
    this.db = admin.firestore();
  }

  async doSomething(data, executionId) {
    logger.info('Doing something', executionId, { data });

    // Business logic here
    const result = await this.db.collection('items').add(data);

    return { id: result.id };
  }
}

const myService = new MyService();

module.exports = { myService, MyService };
```

### Barrel Export

```javascript
// domain/my-feature/index.js
const { myService } = require('./my-service');
module.exports = { myService };

// domain/index.js
const { myService } = require('./my-feature');
module.exports = { ..., myService };
```

---

## Error Handling

### Throwing Errors in Handlers

```javascript
// Throw an error object with statusCode
throw {
  statusCode: 400,
  message: 'Invalid request',
  details: 'Amount must be positive'
};

// Or use custom error classes
const { NotFoundError, ValidationError } = require('../core/middleware/error-handler');

throw new NotFoundError('User not found');
throw new ValidationError('Invalid email format', 'email');
```

### Error Classes

| Class | Status Code | Use Case |
|-------|-------------|----------|
| `ValidationError` | 400 | Input validation failures |
| `AuthenticationError` | 401 | Missing or invalid token |
| `AuthorizationError` | 403 | Permission denied |
| `NotFoundError` | 404 | Resource not found |
| `RateLimitError` | 429 | Rate limit exceeded |

---

## Authentication

### Requiring Authentication

```javascript
const myEndpoint = createEndpoint({
  name: 'myEndpoint',
  requiresAuth: true  // Requires Firebase ID token
}, async (data, ctx) => {
  // ctx.auth is available
  const userId = ctx.auth.uid;
  const email = ctx.auth.token.email;

  // Verify user matches request
  if (data.userId !== userId) {
    throw { statusCode: 403, message: 'Access denied' };
  }

  // Continue processing...
});
```

### Client-Side Token

Clients must send the Firebase ID token in the Authorization header:

```javascript
// Flutter/Dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();

final response = await http.post(
  Uri.parse('https://your-function-url'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(data),
);
```

---

## Real World Example: Escrow Acceptance Flow

This section demonstrates a complete real-world implementation of a function triggered when a user marks an escrow as accepted. The function:

1. Credits the receiver's **pending balance** with the escrow amount
2. Debits the sender's **main balance** and credits their **pending balance**

### Step 1: Create the Domain Service

```javascript
// domain/escrow/escrow-balance-service.js
const admin = require('firebase-admin');
const { logger } = require('../../utils/logger');

class EscrowBalanceService {
  constructor() {
    this.db = admin.firestore();
  }

  /**
   * Process balance transfers when escrow is accepted.
   * - Debits sender's main balance
   * - Credits sender's pending balance (funds in transit)
   * - Credits receiver's pending balance (awaiting delivery confirmation)
   */
  async processEscrowAcceptance(escrowData, executionId) {
    const { escrowId, senderId, receiverId, amount, currency } = escrowData;

    logger.info('Processing escrow acceptance', executionId, {
      escrowId,
      senderId,
      receiverId,
      amount,
      currency
    });

    const senderWalletRef = this.db.collection('wallets').doc(senderId);
    const receiverWalletRef = this.db.collection('wallets').doc(receiverId);
    const escrowRef = this.db.collection('escrows').doc(escrowId);

    try {
      await this.db.runTransaction(async (transaction) => {
        // Get current wallet states
        const [senderWallet, receiverWallet] = await Promise.all([
          transaction.get(senderWalletRef),
          transaction.get(receiverWalletRef)
        ]);

        if (!senderWallet.exists) {
          throw new Error(`Sender wallet not found: ${senderId}`);
        }
        if (!receiverWallet.exists) {
          throw new Error(`Receiver wallet not found: ${receiverId}`);
        }

        const senderData = senderWallet.data();
        const receiverData = receiverWallet.data();

        // Validate sender has sufficient main balance
        const senderMainBalance = senderData.mainBalance || 0;
        if (senderMainBalance < amount) {
          throw new Error(
            `Insufficient balance. Required: ${amount}, Available: ${senderMainBalance}`
          );
        }

        // Calculate new balances
        const newSenderMainBalance = senderMainBalance - amount;
        const newSenderPendingBalance = (senderData.pendingBalance || 0) + amount;
        const newReceiverPendingBalance = (receiverData.pendingBalance || 0) + amount;

        // Update sender wallet: debit main, credit pending
        transaction.update(senderWalletRef, {
          mainBalance: newSenderMainBalance,
          pendingBalance: newSenderPendingBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Update receiver wallet: credit pending balance
        transaction.update(receiverWalletRef, {
          pendingBalance: newReceiverPendingBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Update escrow status
        transaction.update(escrowRef, {
          status: 'accepted',
          acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
          balanceProcessed: true
        });

        // Create transaction records for audit trail
        const timestamp = admin.firestore.FieldValue.serverTimestamp();

        // Sender transaction record
        transaction.set(this.db.collection('transactions').doc(), {
          type: 'escrow_hold',
          userId: senderId,
          escrowId,
          amount: -amount,
          balanceType: 'main',
          description: `Escrow hold for parcel to ${receiverId}`,
          currency,
          createdAt: timestamp
        });

        // Sender pending credit record
        transaction.set(this.db.collection('transactions').doc(), {
          type: 'escrow_pending',
          userId: senderId,
          escrowId,
          amount: amount,
          balanceType: 'pending',
          description: `Pending escrow for parcel delivery`,
          currency,
          createdAt: timestamp
        });

        // Receiver pending credit record
        transaction.set(this.db.collection('transactions').doc(), {
          type: 'escrow_pending_received',
          userId: receiverId,
          escrowId,
          amount: amount,
          balanceType: 'pending',
          description: `Pending payment for incoming parcel`,
          currency,
          createdAt: timestamp
        });
      });

      logger.success('Escrow acceptance processed', executionId, {
        escrowId,
        amount,
        senderId,
        receiverId
      });

      return { success: true, escrowId };
    } catch (error) {
      logger.error('Failed to process escrow acceptance', executionId, error, {
        escrowId
      });
      throw error;
    }
  }
}

const escrowBalanceService = new EscrowBalanceService();

module.exports = { escrowBalanceService, EscrowBalanceService };
```

### Step 2: Create the Barrel Export

```javascript
// domain/escrow/index.js
const { escrowBalanceService } = require('./escrow-balance-service');

module.exports = { escrowBalanceService };
```

```javascript
// domain/index.js
const { escrowBalanceService } = require('./escrow');
// ... other exports

module.exports = {
  // ... existing exports
  escrowBalanceService
};
```

### Step 3: Create the Firestore Trigger

```javascript
// triggers/escrow-triggers.js
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { escrowBalanceService } = require('../domain');
const { logger } = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

/**
 * Triggered when an escrow document is updated.
 * Processes balance transfers when status changes to 'accepted'.
 */
const onEscrowAccepted = onDocumentUpdated(
  {
    document: 'escrows/{escrowId}',
    region: 'us-central1'
  },
  async (event) => {
    const executionId = uuidv4();
    const escrowId = event.params.escrowId;

    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Only process if status changed to 'accepted'
    if (beforeData.status === afterData.status) {
      return null; // No status change
    }

    if (afterData.status !== 'accepted') {
      return null; // Not an acceptance event
    }

    // Prevent double-processing
    if (afterData.balanceProcessed) {
      logger.info('Escrow already processed, skipping', executionId, { escrowId });
      return null;
    }

    logger.info('Escrow acceptance detected', executionId, {
      escrowId,
      previousStatus: beforeData.status,
      newStatus: afterData.status
    });

    try {
      await escrowBalanceService.processEscrowAcceptance({
        escrowId,
        senderId: afterData.senderId,
        receiverId: afterData.receiverId,
        amount: afterData.amount,
        currency: afterData.currency || 'NGN'
      }, executionId);

      return { success: true };
    } catch (error) {
      logger.error('Failed to process escrow acceptance', executionId, error, {
        escrowId
      });
      throw error; // Re-throw to trigger Cloud Functions retry
    }
  }
);

module.exports = { onEscrowAccepted };
```

### Step 4: Create the Barrel Export for Triggers

```javascript
// triggers/index.js
const { onEscrowAccepted } = require('./escrow-triggers');

module.exports = { onEscrowAccepted };
```

### Step 5: Register in index.js

```javascript
// index.js
const { onEscrowAccepted } = require('./triggers');

// ... other exports

exports.onEscrowAccepted = onEscrowAccepted;
```

### Data Model Reference

**Escrow Document (`escrows/{escrowId}`)**
```javascript
{
  senderId: 'user_abc123',           // User sending the parcel
  receiverId: 'user_xyz789',         // User receiving the parcel
  amount: 5000,                       // Escrow amount in smallest unit
  currency: 'NGN',
  status: 'pending' | 'accepted' | 'completed' | 'cancelled',
  balanceProcessed: false,            // Prevents double-processing
  createdAt: Timestamp,
  acceptedAt: Timestamp | null
}
```

**Wallet Document (`wallets/{userId}`)**
```javascript
{
  userId: 'user_abc123',
  mainBalance: 50000,                 // Available balance
  pendingBalance: 5000,               // Funds in escrow/transit
  updatedAt: Timestamp
}
```

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ESCROW ACCEPTANCE FLOW                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. User marks escrow as "accepted" in app                          │
│     └──> Firestore update: escrows/{id}.status = 'accepted'         │
│                                                                     │
│  2. Cloud Function triggered (onEscrowAccepted)                     │
│     └──> Detects status change from 'pending' to 'accepted'         │
│                                                                     │
│  3. Atomic Transaction Executes:                                    │
│     ┌─────────────────────────────────────────────────────────────┐ │
│     │ SENDER WALLET                                               │ │
│     │   mainBalance:    50,000 → 45,000  (debit 5,000)           │ │
│     │   pendingBalance:  0     → 5,000   (credit 5,000)          │ │
│     ├─────────────────────────────────────────────────────────────┤ │
│     │ RECEIVER WALLET                                             │ │
│     │   pendingBalance:  0     → 5,000   (credit 5,000)          │ │
│     ├─────────────────────────────────────────────────────────────┤ │
│     │ ESCROW DOCUMENT                                             │ │
│     │   status:          'accepted'                               │ │
│     │   balanceProcessed: true                                    │ │
│     └─────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  4. Transaction records created for audit trail                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Firestore Trigger** | Automatic execution when escrow status changes - no API call needed |
| **Atomic Transaction** | All balance updates succeed or fail together - no partial states |
| **balanceProcessed Flag** | Prevents double-processing if function retries |
| **Separate Pending Balances** | Clear distinction between available and in-transit funds |
| **Audit Trail** | Transaction records for compliance and dispute resolution |
| **Idempotency** | Safe to retry without causing duplicate balance changes |

### Testing the Flow

```javascript
// Test: Simulate escrow acceptance
const admin = require('firebase-admin');

async function testEscrowAcceptance() {
  const db = admin.firestore();

  // Create test escrow
  const escrowRef = await db.collection('escrows').add({
    senderId: 'test_sender',
    receiverId: 'test_receiver',
    amount: 5000,
    currency: 'NGN',
    status: 'pending',
    balanceProcessed: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Update to accepted - this triggers the function
  await escrowRef.update({ status: 'accepted' });

  console.log('Escrow acceptance triggered for:', escrowRef.id);
}
```

---

## Quick Reference

### Adding a New Feature Checklist

1. [ ] Create validation schema in `schemas/`
2. [ ] Add schema to `schemas/index.js`
3. [ ] Create endpoint in `endpoints/`
4. [ ] Add endpoint to `endpoints/index.js`
5. [ ] Export from `index.js`
6. [ ] Deploy: `firebase deploy --only functions:functionName`

### Common Patterns

```javascript
// Endpoint with auth and validation
const myEndpoint = createEndpoint({
  name: 'myEndpoint',
  requiresAuth: true,
  schema: mySchema,
  secrets: ['API_KEY']
}, async (data, ctx) => {
  return { success: true, data };
});

// Scheduled task
const myTask = createScheduledTask({
  name: 'myTask',
  schedule: 'every 1 hours'
}, async (context, executionId) => {
  // Task logic
});

// Webhook handler registration
webhookRouter.register('event.type', async (data, executionId) => {
  // Handler logic
});
```

---

## Deployment

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:createPaystackTransaction

# Deploy multiple functions
firebase deploy --only functions:createPaystackTransaction,functions:verifyPaystackPayment
```

---

## Troubleshooting

### Common Issues

1. **Module not found**: Ensure barrel exports include your new module
2. **Auth errors**: Check `requiresAuth` is set and client sends token
3. **Validation errors**: Check schema is correctly assigned to endpoint
4. **Webhook not processing**: Verify handler is registered with router

### Debugging

```javascript
// Use logger for structured logging
const { logger } = require('./utils/logger');

logger.info('Message', executionId, { key: value });
logger.error('Error', executionId, error, { context });
logger.success('Success', executionId);
```

---

*Last updated: December 2024*
