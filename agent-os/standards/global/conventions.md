## General Development Conventions

## Flutter Project Structure
- Follow standard Flutter project structure:
  - lib/ - All Dart source code
  - lib/main.dart - App entry point
  - lib/screens/ or lib/features/ - UI screens/features
  - lib/widgets/ - Reusable custom widgets
  - lib/models/ - Data models
  - lib/services/ - Business logic services
  - lib/repositories/ - Data access layer
  - lib/bloc/ or lib/cubits/ - State management
  - lib/utils/ or lib/helpers/ - Utility functions
  - lib/config/ or lib/constants/ - App configuration and constants
  - assets/ - Images, fonts, and other static files
  - test/ - Unit and widget tests
  - integration_test/ - Integration tests

## File Naming
- Use lowercase_with_underscores for all Dart files: user_repository.dart, login_screen.dart
- Name files after their primary class: UserRepository class → user_repository.dart
- Suffix files with type indicator: _screen, _widget, _model, _bloc, _cubit, _repository, _service
- Keep related files together in feature folders when using feature-first structure

## Documentation
- Maintain up-to-date README.md with:
  - Project description and purpose
  - Setup instructions (Flutter version, dependencies)
  - How to run: flutter pub get, flutter run
  - Environment configuration (Firebase setup, API keys)
  - Architecture overview (state management, folder structure)
  - Contribution guidelines
- Document complex functions and classes with /// doc comments
- Keep pubspec.yaml clean and organized with comments for dependency groups

## Version Control (Git)
- Write clear, descriptive commit messages: "Add user authentication with Firebase Auth"
- Use conventional commits format if team prefers: feat:, fix:, docs:, refactor:, test:
- Create feature branches: feature/user-authentication, bugfix/login-validation
- Keep commits focused - one feature or fix per commit
- Always pull before pushing to avoid conflicts
- Never commit generated files (*.g.dart, *.freezed.dart) unless required
- Review changes before committing: git diff

## Environment Configuration
- Store environment-specific config in separate files (not in code)
- Use --dart-define for build-time configuration: flutter run --dart-define=ENV=prod
- Never commit secrets, API keys, or credentials to version control
- Use .env files for local development (add to .gitignore)
- Document required environment variables in README
- Use Firebase options from google-services.json and GoogleService-Info.plist

## Dependency Management (pubspec.yaml)
- Keep dependencies minimal - only add what you actually use
- Use latest stable versions, not dev versions for production
- Pin major versions to avoid breaking changes: package: ^2.0.0
- Organize dependencies logically with comments:
  ```yaml
  # State Management
  flutter_bloc: ^8.1.0

  # Firebase
  firebase_core: ^2.0.0
  cloud_firestore: ^4.0.0
  ```
- Run flutter pub outdated regularly to check for updates
- Document why major/unusual dependencies are used
- Remove unused dependencies immediately

## Code Review
- All code must be reviewed before merging to main branch
- Review for: functionality, code style, test coverage, performance
- Provide constructive feedback with explanations
- Request changes when necessary, approve when ready
- Test the code locally when reviewing major changes
- Check for proper error handling and edge cases

## Testing Requirements
- Write unit tests for business logic (BLoCs, repositories, services)
- Write widget tests for custom widgets and screens
- Test critical user flows with integration tests
- Aim for reasonable coverage on core functionality
- Run flutter test before committing
- Mock dependencies in tests for isolated testing
- Test error cases, not just happy paths

## Feature Flags & Incomplete Features
- Use feature flags (Firebase Remote Config, launch_darkly) for incomplete features
- Don't merge incomplete features that break the app
- Hide UI for features in development behind flags
- Test both enabled and disabled states of feature flags
- Document feature flag status in code comments

## Build & Release
- Test release builds before deploying: flutter build apk --release
- Use proper version numbering in pubspec.yaml: version: 1.2.3+4 (semantic version + build number)
- Increment version number for each release
- Tag releases in git: git tag v1.2.3
- Maintain CHANGELOG.md with release notes
- Build separate APKs/IPAs for different environments (dev, staging, prod)

## Assets Management
- Organize assets in folders: assets/images/, assets/fonts/, assets/icons/
- Declare assets in pubspec.yaml:
  ```yaml
  assets:
    - assets/images/
    - assets/icons/
  ```
- Use meaningful asset names: logo.png, user_placeholder.jpg
- Provide 1x, 2x, 3x versions for images in appropriate folders
- Compress images before adding to project
- Use SVGs for icons when possible (flutter_svg package)

## Platform-Specific Configuration
- Keep android/ and ios/ folders in version control
- Update AndroidManifest.xml for required permissions
- Update Info.plist for iOS permissions with usage descriptions
- Configure app name, package identifier, and icons properly
- Don't modify native code unless absolutely necessary
- Document any native code changes in README
