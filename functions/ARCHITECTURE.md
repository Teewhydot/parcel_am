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
