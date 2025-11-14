## Coding Style Best Practices

## Dart Naming Conventions
- **Classes, enums, typedefs, extensions**: UpperCamelCase (e.g., UserModel, AuthState, PaymentStatus)
- **Libraries, packages, directories, files**: lowercase_with_underscores (e.g., user_repository.dart, auth_bloc.dart)
- **Variables, functions, parameters**: lowerCamelCase (e.g., userName, fetchUserData, isLoading)
- **Constants**: lowerCamelCase (e.g., maxRetryCount, defaultTimeout) - NOT UPPER_SNAKE_CASE
- **Private members**: prefix with underscore (e.g., _privateMethod, _internalState)
- **Import prefixes**: lowercase_with_underscores (e.g., import 'package:foo/foo.dart' as foo_bar)

## Automated Formatting
- Use dart format (formerly dartfmt) for consistent code formatting
- Run dart format . before committing code
- Configure IDE to format on save (VSCode: "editor.formatOnSave": true)
- Use flutter analyze to check for code issues and style violations
- Set up pre-commit hooks to enforce formatting automatically
- Follow the official Dart Style Guide: https://dart.dev/guides/language/effective-dart/style

## Meaningful Names
- Choose descriptive names that reveal intent: getUserById not getUser, isEmailValid not check
- Avoid abbreviations except common ones (id, url, json, http, ui, db)
- Use full words: authentication not auth, repository not repo (unless established convention)
- Boolean variables should be questions: isLoading, hasError, canSubmit
- Functions should be verbs: fetchData, validateEmail, updateUserProfile
- Classes should be nouns: UserRepository, AuthenticationBloc, PaymentService

## Small, Focused Functions
- Keep functions small - ideally under 20 lines, max 50 lines
- One function should do one thing - Single Responsibility Principle
- Extract complex logic into separate helper functions
- Use meaningful function names that describe what they do
- Avoid functions with too many parameters (max 3-4) - use objects/classes instead
- Keep widget build methods small - extract into separate widgets or builder methods

## Code Organization
- Use consistent indentation - 2 spaces (Dart standard)
- Configure editor to use spaces, not tabs
- Group related code together with blank lines for readability
- Order class members: fields → constructors → methods (public then private)
- Order imports: dart libraries → Flutter libraries → package imports → relative imports
- Remove unused imports immediately (flutter analyze will warn)

## Remove Dead Code
- Delete unused code, never comment it out
- Remove commented-out code blocks
- Delete unused imports, variables, functions, and classes
- Clean up debug print statements before committing
- Use version control (git) for code history - don't keep old code "just in case"
- Run flutter analyze to find dead code warnings

## DRY Principle (Don't Repeat Yourself)
- Extract common logic into reusable functions or classes
- Create utility classes for shared functionality
- Use mixins for shared behavior across unrelated classes
- Create custom widgets for reusable UI components
- Use constants for repeated values (colors, strings, dimensions, etc.)
- Avoid copy-pasting code - refactor instead

## Abtract core widgets that can be reused throughout the app
- Eg AppText,AppButton,AppScaffold,Gesture detector and other commonly/frequently used widgets. NO HARDCODING OF FLUTTER WIDGETS.
- Those commonly used widgets should be abstracted so that they can be used anywhere in the project 

## Dart-Specific Best Practices
- Use final for variables that won't be reassigned
- Use const for compile-time constants (massive performance benefit)
- Prefer ?? and ??= for null-aware operations
- Use cascade notation (..) when calling multiple methods on same object
- Use collection if and for in list/map literals for cleaner code
- Avoid using dynamic - use proper types or Object?
- Use late keyword for non-nullable fields initialized after construction
- Prefer is over as for type checking before casting

## Flutter-Specific Best Practices
- Always use StatelessWidget or StatefulWidget classes, never functions that return widgets
- Mark all widget properties as final
- Use const constructors whenever possible for performance
- Avoid unnecessary setState() calls - be specific about what changed
- Dispose controllers, listeners, and subscriptions in dispose() method
- Use async/await instead of raw Futures and .then() chaining

## Backward Compatibility
- Unless specifically instructed otherwise, assume you do not need to handle backward compatibility
- Write code for the current project state, not hypothetical future scenarios
- Refactor freely without maintaining old APIs
