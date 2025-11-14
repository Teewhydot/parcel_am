# Firestore Best Practices

## Collection & Document Structure
- Use subcollections for nested data instead of deeply nested maps
- Keep document size under 1MB (Firestore hard limit)
- Use flat, denormalized data structures for read-heavy operations
- Design for your query patterns - structure data how you'll retrieve it
- Use collection group queries when you need to query across subcollections
- Name collections as plural nouns (users, posts, comments)
- Use meaningful, readable document IDs when possible (e.g., userId, not random)

## Queries
- Always add indexes for compound queries (Firestore will prompt you)
- Use where() clauses efficiently - order matters for composite indexes
- Limit query results with limit() - don't fetch more than you need
- Use startAfter() and limit() for pagination, not skip()
- Avoid inequality filters on multiple fields - Firestore supports only one per query
- Use array-contains or array-contains-any for array membership queries
- Query for specific fields with where() rather than fetching full documents and filtering client-side
- Use orderBy() explicitly even if where() implies ordering

## Real-time Listeners
- Use snapshots() for real-time data, get() for one-time reads
- Unsubscribe from listeners when widget is disposed (cancel StreamSubscription)
- Be mindful of read costs - every snapshot triggers a read for each document
- Use where() to minimize documents in real-time listeners
- Consider using get() for data that doesn't need real-time updates
- Implement offline persistence for better UX: persistenceEnabled: true
- Handle snapshot errors in StreamBuilder's error handling

## Writes & Transactions
- Use batch writes when updating multiple documents (up to 500 operations per batch)
- Use transactions for atomic reads and writes that depend on each other
- Set merge: true when updating documents to avoid overwriting existing fields
- Use FieldValue.serverTimestamp() for consistent timestamps across clients
- Use FieldValue.increment() for atomic counter updates
- Use FieldValue.arrayUnion() and arrayRemove() for atomic array operations
- Batch writes are faster and cheaper than individual writes

## Security
- **Never trust client-side validation** - always enforce with Security Rules
- Write Security Rules that validate data structure, types, and business logic
- Use request.auth.uid to ensure users can only access their own data
- Validate field types and required fields in Security Rules
- Use get() in Security Rules to check related documents (sparingly - it counts as a read)
- Test Security Rules with Firestore emulator and Rules Unit Testing
- Lock down default rules - deny all, then explicitly allow what's needed

## Indexing
- Create composite indexes for all compound queries
- Firestore auto-creates single-field indexes
- Monitor index creation in Firebase console
- Delete unused indexes to save storage costs
- Use collection group indexes for querying across subcollections
- Exemptions: exclude fields from indexing if never queried (e.g., large text blobs)

## Data Modeling
- Denormalize for read performance - duplicate data across collections if needed
- Use references (DocumentReference) for large or rarely accessed related data
- Store aggregated data (counts, sums) rather than computing on read
- Use Cloud Functions to maintain denormalized data consistency
- Design for scalability - avoid hotspots (documents written more than once per second)
- Use sharding for high-write documents (e.g., distributed counters)

## Performance & Cost Optimization
- Fetch only needed data - use select() to get specific fields (not available in FlutterFire yet)
- Use local cache when possible - offline persistence reduces reads
- Implement pagination with startAfter() to avoid loading large datasets at once
- Monitor usage in Firebase console - track read/write/delete operations
- Use Cloud Functions for heavy operations instead of client-side processing
- Avoid listening to entire collections - always filter with where()
- Cache frequently accessed, rarely changing data in app (SharedPreferences, local state)

## Offline Support
- Enable offline persistence: persistenceEnabled: true in FirebaseFirestore settings
- Handle connectivity changes gracefully - show offline indicators
- Queue writes with pendingWrites metadata tracking
- Use snapshot metadata to detect if data is from cache: snapshot.metadata.isFromCache
- Understand that listeners receive local writes immediately, then server confirmation
- Test offline scenarios thoroughly

## Error Handling
- Wrap Firestore operations in try-catch blocks
- Handle specific FirestoreException codes (permission-denied, not-found, unavailable)
- Provide user-friendly error messages, not raw exception text
- Implement retry logic with exponential backoff for transient errors
- Log errors for debugging but don't expose sensitive information
- Handle network errors separately from data validation errors

## Testing
- Use Firebase Emulator Suite for local development and testing
- Write unit tests for data models and repository layer
- Test Security Rules with @firebase/rules-unit-testing
- Mock Firestore in widget tests using fake_cloud_firestore
- Test offline scenarios with emulator disconnect
- Test pagination, real-time updates, and error conditions