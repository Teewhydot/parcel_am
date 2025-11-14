## Validation Best Practices

## Server-Side Validation (Firebase Security Rules)
- **NEVER trust client-side validation** - always enforce with Firebase Security Rules
- Validate data structure, types, and business logic in Firestore Security Rules
- Use request.resource.data to access incoming data in Security Rules
- Validate required fields: request.resource.data.keys().hasAll(['field1', 'field2'])
- Validate field types: request.resource.data.fieldName is string
- Validate string lengths: request.resource.data.name.size() <= 100
- Validate number ranges: request.resource.data.age >= 0 && request.resource.data.age <= 150
- Test Security Rules with Firebase Emulator and Rules Unit Testing

## Client-Side Validation (Flutter)
- Use client-side validation for immediate user feedback, not security
- Validate form inputs with TextFormField validator parameter
- Show field-specific error messages below inputs
- Disable submit button until form is valid
- Use RegExp for format validation (email, phone, etc.)
- Use packages like form_validator or validators for common validations
- Validate before attempting Firebase operations to provide better UX

## Form Validation in Flutter
- Use GlobalKey<FormState> to access form validation state
- Call formKey.currentState!.validate() before submitting
- Return null from validator for valid input, error string for invalid
- Validate on submit, optionally on text change with autovalidateMode
- Show loading state during validation/submission
- Handle validation errors from Firebase (permission denied, etc.)

## Input Sanitization
- Sanitize user input to prevent injection attacks
- Trim whitespace from strings: text.trim()
- Remove special characters if not needed
- Validate URLs before opening: Uri.tryParse(url)
- Escape HTML entities if displaying user content in web view
- Never execute user input as code

## Type Validation
- Use Dart's type system - avoid dynamic when possible
- Validate types in fromJson methods when deserializing
- Check for null with null-aware operators: ??, ?.
- Use is operator to check types at runtime
- Handle type mismatches gracefully with try-catch

## Business Rule Validation
- Validate business rules in both Flutter app and Security Rules
- Check user permissions before allowing actions
- Validate relationships (e.g., user owns the document they're modifying)
- Verify data consistency (e.g., dates, quantities, balances)
- Return user-friendly error messages when validation fails

## Email & Phone Validation
- Use RegExp for email validation: RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
- Use phone number packages for international phone validation
- Validate format before attempting to save
- Consider using Firebase Auth's email verification instead of manual validation
- Show format hints to users (e.g., "email@example.com")

## Password Validation
- Enforce minimum length (8+ characters)
- Optionally require uppercase, lowercase, numbers, special characters
- Show password strength indicator
- Validate on text change for real-time feedback
- Use Firebase Auth's built-in password validation
- Don't send passwords to Firestore - Firebase Auth handles this

## Error Messages
- Provide clear, specific error messages: "Email is required" not "Invalid input"
- Explain how to fix the error: "Password must be at least 8 characters"
- Show errors near the relevant field, not just at top of form
- Use consistent error styling across the app
- Translate error messages for internationalized apps

## Fail Early
- Validate input as soon as possible
- Don't wait for submit to show obvious errors
- Return early from functions if validation fails
- Use assert() for development-time validation
- Throw exceptions for truly exceptional cases

## Consistent Validation
- Apply same validation rules in client, Security Rules, and Cloud Functions
- Use shared constants for validation rules (max lengths, regex patterns)
- Document validation requirements in code comments
- Test validation thoroughly - valid inputs, invalid inputs, edge cases
