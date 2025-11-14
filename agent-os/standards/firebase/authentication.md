# Firebase Authentication Best Practices

## Authentication Setup
- Enable only the sign-in methods you actually need in Firebase Console
- Configure OAuth providers properly with correct redirect URIs
- Set up email templates for verification, password reset, etc.
- Use Firebase App Check to protect against abuse
- Configure authorized domains for production deployment
- Never store authentication tokens or passwords in app code

## Sign-In Methods
- Use email/password for simple authentication needs
- Implement Google Sign-In for frictionless authentication on Android/iOS
- Support Apple Sign-In for iOS apps (required by Apple for social login)
- Use phone authentication for regions where it's preferred
- Consider anonymous authentication for try-before-signup flows
- Link multiple authentication methods to same account when appropriate
- Use FirebaseAuth.instance.authStateChanges() to listen for auth state

## User Management
- Create user profile documents in Firestore after successful registration
- Use user UID as document ID in users collection for easy lookup
- Don't store sensitive data in user profiles without encryption
- Implement user deletion properly - clean up all user data
- Use displayName and photoURL in FirebaseAuth for basic profile info
- Update user profile with updateDisplayName() and updatePhotoURL()
- Verify email addresses before allowing full access with sendEmailVerification()

## Security Rules Integration
- Use request.auth.uid in Security Rules to restrict data access
- Check if user is authenticated: request.auth != null
- Verify email: request.auth.token.email_verified == true
- Use custom claims for role-based access control (set via Admin SDK or Cloud Functions)
- Never trust client-side authentication state - always verify with Security Rules
- Implement proper authorization checks in Firestore Security Rules

## Token Management
- Tokens automatically refresh - don't manually handle refresh
- Use getIdToken() to get current token for API calls
- Listen to idTokenChanges() stream for token refresh events
- Tokens expire after 1 hour - Firebase handles refresh automatically
- Don't store tokens in SharedPreferences or local storage
- Use currentUser to check authentication state, not stored tokens

## Password Management
- Enforce strong password requirements on client side
- Use sendPasswordResetEmail() for password recovery
- Validate password reset codes before allowing password change
- Require recent authentication for sensitive operations with reauthenticateWithCredential()
- Use updatePassword() only after recent authentication
- Implement rate limiting for password reset to prevent abuse

## Email Verification
- Send verification email immediately after registration
- Block access to sensitive features until email is verified
- Check currentUser.emailVerified before allowing access
- Resend verification email option if user didn't receive it
- Redirect after email verification link is clicked
- Handle verification errors gracefully (expired link, already verified)

## Multi-Factor Authentication (MFA)
- Enable MFA for high-security applications
- Use phone number as second factor
- Prompt for MFA setup after initial registration
- Allow users to enable/disable MFA in settings
- Store MFA status in user profile for UX purposes
- Handle MFA enrollment and verification errors properly

## Account Linking
- Allow users to link multiple sign-in methods (email + Google, etc.)
- Use linkWithCredential() to link authentication methods
- Handle account already exists error when linking
- Provide UI for users to view and manage linked accounts
- Unlink methods with unlink() when requested by user

## Session Management
- Sign out users with signOut() when they explicitly request it
- Don't automatically sign users out unless required for security
- Persist authentication state across app restarts (Firebase does this automatically)
- Handle concurrent sessions appropriately
- Implement inactivity timeout for sensitive applications
- Clear local data on sign out if needed

## Error Handling
- Handle FirebaseAuthException with specific error codes
- Provide user-friendly error messages for common errors (wrong password, user not found, etc.)
- Don't expose technical error details to users
- Log authentication errors for debugging
- Implement retry logic for network-related errors
- Handle edge cases: weak password, email already in use, invalid email

## Authorization & Permissions
- Use custom claims for role-based access control (admin, moderator, etc.)
- Set custom claims using Admin SDK in Cloud Functions, never on client
- Access custom claims: user.getIdTokenResult().claims['role']
- Check custom claims in Security Rules: request.auth.token.role == 'admin'
- Refresh token after updating custom claims to see changes
- Document roles and permissions clearly

## Testing
- Use Firebase Emulator for local auth testing
- Test all sign-in methods (email, Google, Apple, phone, anonymous)
- Test error scenarios (wrong password, network failure, etc.)
- Test email verification flow end-to-end
- Test password reset flow
- Mock FirebaseAuth in unit tests with mockito or fake implementations
- Test Security Rules with authenticated and unauthenticated users

## Privacy & Compliance
- Implement data export for GDPR compliance
- Allow users to delete their accounts
- Provide clear privacy policy about data usage
- Handle PII (Personally Identifiable Information) carefully
- Implement proper data retention policies
- Log authentication events for audit purposes
- Comply with regional regulations (GDPR, CCPA, etc.)

## Performance
- Cache currentUser reference - don't call it repeatedly
- Use authStateChanges() stream instead of polling for auth state
- Avoid unnecessary token refreshes
- Implement proper loading states during auth operations
- Handle authentication UI transitions smoothly
- Prefetch user profile data after authentication

## Sign-In Flow Best Practices
- Show loading indicator during sign-in
- Redirect to home screen after successful authentication
- Persist authentication state across app restarts
- Implement proper error handling with user feedback
- Provide "forgot password" and "resend verification" options
- Implement social sign-in buttons with proper branding guidelines
- Handle authentication in BLoC/Cubit, not directly in widgets
- Navigate based on auth state changes, not manually after sign-in call