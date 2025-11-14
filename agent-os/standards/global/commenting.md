## Code Commenting Best Practices

## Self-Documenting Code (Priority)
- Write code that explains itself through clear structure and naming
- Use descriptive variable names: userEmail not e, isLoading not flag
- Use descriptive function names: fetchUserProfile() not getData()
- Break complex logic into well-named functions
- Use meaningful class and widget names
- Prefer refactoring over commenting - if you need to explain it, maybe simplify it

## Dart Documentation Comments
- Use /// (triple slash) for public API documentation
- Document public classes, methods, and properties
- Use /// format for documentation that appears in IDE tooltips
- Document parameters, return values, and exceptions:
  ```dart
  /// Fetches user profile from Firestore.
  ///
  /// Returns [UserModel] if found, null if user doesn't exist.
  /// Throws [FirebaseException] if network error occurs.
  Future<UserModel?> fetchUserProfile(String userId) async { ... }
  ```
- Use [ClassName] and [methodName] to create links in doc comments
- Document complex widgets with usage examples

## When to Comment
- Explain WHY, not WHAT - code shows what, comments explain why
- Document non-obvious business logic or algorithms
- Explain workarounds for bugs or limitations
- Document regex patterns: // Matches email format: user@domain.com
- Explain complex Firebase Security Rules
- Document API contracts and expected data formats
- Warn about performance considerations or side effects

## When NOT to Comment
- Don't comment obvious code: // Set loading to true
- Don't comment changes or fixes: // Fixed bug on 2024-01-15
- Don't leave TODOs without issue tracking: // TODO: fix this (create GitHub issue instead)
- Don't keep commented-out code - delete it (use git history if needed)
- Don't use comments to disable code - remove it or use feature flags
- Don't write novel-length comments - refactor instead

## Comments Should Be Evergreen
- Write comments that will be relevant long-term
- Update comments when code changes - stale comments are worse than none
- Remove outdated comments immediately
- Avoid referring to specific dates, versions, or people
- Focus on timeless information about the code's purpose

## Flutter/Dart Specific
- Document widget parameters with ///
- Explain why a widget can't be const if it looks like it should be
- Document platform-specific behavior
- Explain unusual State management decisions
- Document performance optimizations (why RepaintBoundary is needed)
- Comment complex layouts or animations

## Code Organization Comments
- Use section comments to organize large files:
  ```dart
  // ========== Public Methods ==========

  // ========== Private Helpers ==========
  ```
- Use comments to mark regions in IDE (// region / // endregion)
- Group related code with brief section headers
- Keep section comments minimal and structural
