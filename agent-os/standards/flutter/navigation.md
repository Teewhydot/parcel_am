# Navigation & Routing Best Practices

## Navigator 2.0 & Declarative Routing
- Use GoRouter or similar declarative routing package for complex navigation
- Define routes in a centralized location (e.g., lib/config/routes.dart or lib/router/app_router.dart)
- Use named routes instead of directly instantiating widgets
- Prefer GoRouter over Navigator 1.0 for new projects - better deep linking and state management
- Use declarative routing for web apps - enables proper URL management and browser back button

## GoRouter Configuration (Recommended)
- Define all routes in a single GoRouter instance at app startup
- Use path parameters for dynamic routes: '/user/:userId'
- Use query parameters for optional filters: '/products?category=shoes'
- Implement redirects for authentication flows (login required, redirect after login)
- Use nested routes for tab navigation or master-detail layouts
- Define error/404 routes for unmatched paths
- Use GoRouter's built-in support for deep links and web URLs

## Route Definitions
- Use meaningful, descriptive route names (e.g., '/profile' not '/p')
- Follow REST-like conventions: '/users/:userId/posts/:postId'
- Keep route parameters type-safe using path parameters
- Define route constants: static const String profileRoute = '/profile'
- Group related routes logically (e.g., all auth routes start with '/auth')
- Document route parameters and expected query params

## Navigation Actions
- Use context.go() for navigation that replaces current route
- Use context.push() for navigation that adds to stack
- Use context.pop() to go back programmatically
- Pass data through route parameters or state, not via globals
- Await navigation results when needed: final result = await context.push('/edit')
- Use context.pushReplacement() for flows where back shouldn't work (e.g., after login)

## Navigator 1.0 (Legacy/Simple Apps)
- Use Navigator.pushNamed() with named routes defined in MaterialApp
- Define onGenerateRoute for centralized route handling and parameter passing
- Use RouteSettings to pass arguments: Navigator.pushNamed(context, '/user', arguments: userId)
- Extract arguments in target widget: final args = ModalRoute.of(context)!.settings.arguments
- Use Navigator.pop() with return values for result-based navigation
- Avoid Navigator.push() with widget instances - use named routes

## Deep Linking
- Configure deep links in AndroidManifest.xml and Info.plist
- Use GoRouter's deep link support for automatic handling
- Test deep links on physical devices - emulators can be unreliable
- Handle deep link parameters validation - don't assume data is valid
- Implement universal links (iOS) and App Links (Android) for production
- Redirect to appropriate screens based on authentication state

## Bottom Navigation & Tabs
- Use separate Navigator for each tab to maintain independent navigation stacks
- Preserve tab state when switching between tabs
- Use IndexedStack to keep all tab contents mounted (if performance allows)
- Implement back button behavior that navigates within current tab first
- Use GoRouter's ShellRoute for tab navigation with preserved state

## Authentication & Guards
- Implement route guards to protect authenticated routes
- Redirect to login when accessing protected routes while unauthenticated
- Redirect to intended route after successful login
- Use GoRouter's redirect property for centralized auth logic
- Handle token expiration and automatic logout/redirect
- Clear navigation stack after logout: context.go('/login')

## Modal & Dialog Navigation
- Use showDialog() for alerts, confirmations, and simple forms
- Use showModalBottomSheet() for action sheets and mobile-friendly selections
- Use showCupertinoDialog() and showCupertinoModalPopup() for iOS-style modals
- Always return results from modals: Navigator.pop(context, result)
- Use barrierDismissible: false for required actions
- Handle back button on Android to dismiss modals appropriately

## Navigation State Management
- Keep navigation logic separate from business logic
- Use state management to trigger navigation (e.g., BlocListener for navigation after success)
- Don't navigate from BLoCs/Cubits - emit states and let UI handle navigation
- Store navigation state when needed (e.g., remember last viewed tab)
- Avoid passing BuildContext to business logic layers

## Web & Desktop Considerations
- Support browser back/forward buttons with proper routing
- Use meaningful URLs that can be bookmarked and shared
- Implement proper page titles using GoRouter's pageBuilder
- Handle browser refresh gracefully - deep links should restore state
- Support keyboard shortcuts for common navigation actions

## Testing
- Test navigation flows in integration tests, not just unit tests
- Mock GoRouter in widget tests for isolated component testing
- Test deep link handling and parameter parsing
- Verify back button behavior across different navigation scenarios
- Test authentication redirects and guards