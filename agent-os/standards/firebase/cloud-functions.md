# Cloud Functions Best Practices

## Function Types
- Use HTTPS Callable Functions for client-triggered operations (better than HTTP functions)
- Use Background Triggers for automated tasks (onCreate, onUpdate, onDelete, scheduled)
- Use HTTP Functions only when you need direct REST API access or webhooks
- Use Scheduled Functions (Pub/Sub cron) for periodic tasks
- Prefer 2nd generation Cloud Functions for better performance and pricing

## Callable Functions
- Use callable functions instead of HTTP functions when calling from Flutter
- Callable functions automatically handle auth context (context.auth available)
- Return data directly - Cloud Functions handles serialization/deserialization
- Validate all input parameters on the server side
- Throw HttpsError with appropriate error codes for client error handling
- Use TypeScript for better type safety in function implementation
- Keep functions focused - one function per operation

## Background Triggers
- Use onDocumentCreated, onDocumentUpdated for Firestore triggers
- Use onCreate, onDelete for Storage triggers
- Use onUserCreated, onUserDeleted for Auth triggers
- Be aware that triggers are eventually consistent, not immediate
- Implement idempotency - functions may be called multiple times for same event
- Use event.id to deduplicate if necessary
- Avoid long-running operations - functions have timeout limits (9 minutes max)

## Security
- Always validate input - never trust client data
- Check authentication: if (!context.auth) throw HttpsError('unauthenticated', ...)
- Verify user permissions before performing operations
- Use Firebase Admin SDK with service account for elevated privileges
- Never expose API keys or secrets in function code - use Secret Manager
- Sanitize user input to prevent injection attacks
- Rate limit expensive operations using Firestore or memory cache

## Error Handling
- Use HttpsError for callable functions with proper error codes
- Log errors with functions.logger for debugging in Cloud Logging
- Return user-friendly error messages, not stack traces
- Implement try-catch blocks for all operations
- Handle specific error types (FirestoreError, AuthError, etc.)
- Set up error reporting with Firebase Crashlytics or Cloud Error Reporting
- Don't swallow errors - always log or rethrow

## Performance
- Minimize cold start time - avoid heavy imports and initialization
- Use lightweight dependencies - fewer npm packages, smaller bundle size
- Reuse Firebase Admin SDK instances - initialize once outside function handler
- Use connection pooling for external API calls
- Set appropriate memory allocation (default 256MB, can go up to 8GB)
- Set appropriate timeout based on function needs (default 60s, max 9m)
- Use 2nd gen functions for better concurrency and performance
- Cache frequently used data in global scope or memory

## Data Operations
- Use batched writes for multiple Firestore updates (up to 500 operations)
- Use transactions for atomic operations that need consistency
- Avoid reading and writing to same document in tight loop (contention)
- Use FieldValue.increment() for counters instead of read-modify-write
- Denormalize data to reduce function execution time
- Process large datasets in chunks, not all at once
- Use Firestore queries efficiently - don't fetch entire collections

## Callable Function Patterns
```typescript
export const exampleFunction = functions.https.onCall(async (data, context) => {
  // 1. Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  // 2. Validate input
  if (!data.requiredField) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required field');
  }

  // 3. Check authorization
  const userId = context.auth.uid;
  // Verify user has permission...

  // 4. Perform operation
  try {
    const result = await performOperation(data);
    return { success: true, data: result };
  } catch (error) {
    functions.logger.error('Operation failed', error);
    throw new functions.https.HttpsError('internal', 'Operation failed');
  }
});
```

## Deployment
- Use separate functions for different environments (dev, staging, prod)
- Test functions locally with Firebase Emulator Suite before deploying
- Deploy functions one at a time initially to catch errors early
- Use --only functions:functionName to deploy specific functions
- Set environment variables with firebase functions:config:set
- Use .env files with dotenv for local development
- Version your functions code in git with meaningful commits
- Monitor function execution in Firebase Console > Functions dashboard

## Costs & Optimization
- Monitor invocations and execution time in Firebase Console
- Set reasonable memory allocation - don't over-provision
- Set appropriate timeouts - shorter timeouts reduce costs
- Use scheduled functions during off-peak hours when possible
- Batch operations to reduce number of invocations
- Cache results to avoid redundant computations
- Use Cloud Scheduler for precise timing control
- Monitor costs and set budget alerts

## Testing
- Test functions locally with Firebase Emulator Suite
- Write unit tests for function logic using Jest or Mocha
- Mock Firebase Admin SDK in tests
- Test callable functions with curl or Postman
- Test background triggers by creating/updating documents in emulator
- Integration test with test Firestore and Auth instances
- Test error cases and edge conditions

## Debugging & Monitoring
- Use functions.logger for structured logging (info, warn, error)
- View logs in Firebase Console > Functions > Logs
- Use Cloud Logging for advanced log querying and analysis
- Set up alerts for function errors or performance degradation
- Use Cloud Trace for latency analysis
- Monitor function metrics: invocations, execution time, errors
- Implement custom metrics with Cloud Monitoring if needed

## Scheduled Functions
- Use Pub/Sub scheduled functions for cron jobs
- Use standard cron syntax: '0 0 * * *' for daily at midnight
- Consider timezone when scheduling (functions run in UTC by default)
- Implement proper error handling - scheduled functions retry on failure
- Keep scheduled functions idempotent
- Use Firestore to track last execution and prevent duplicate work
- Monitor scheduled function execution in Cloud Scheduler