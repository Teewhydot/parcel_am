# AI Development Guide - Parcel AM

This guide ensures Flutter code follows project conventions and minimizes technical debt.

## Architecture

**Pattern**: Clean Architecture with BLoC/Cubit for state management
- **Layers**: `presentation/` → `domain/` → `data/`
- **Features**: Organized under `lib/features/[feature_name]/`
- **Core**: Shared utilities under `lib/core/`

**File Structure**:
```
lib/
├── core/
│   ├── bloc/          # Base BLoC classes
│   ├── widgets/       # Custom reusable widgets
│   ├── theme/         # Design system (colors, radius, fonts)
│   ├── helpers/       # Utility helpers
│   ├── services/      # Core services (navigation, auth, etc.)
│   └── utils/         # Utility functions
└── features/
    └── [feature_name]/
        ├── data/
        ├── domain/
        └── presentation/
            ├── bloc/
            ├── screens/
            └── widgets/
```

## State Management

**BLoC/Cubit**: Use `flutter_bloc` for state management
- **Base States**: Extend from `lib/core/bloc/base/base_state.dart`
  - `LoadingState<T>`
  - `LoadedState<T>`
  - `ErrorState<T>`
  - `AsyncErrorState<T>`
- **Pattern**: Use `BlocConsumer` or `BlocBuilder` for listening to state
- **Access**: `context.read<XCubit>()` for actions, `context.watch<XBloc>()` for streams

## Design System

### Colors (`lib/core/theme/app_colors.dart`)
**CRITICAL**: NEVER use hardcoded colors. Always use `AppColors` constants.

```dart
// ✅ CORRECT
color: AppColors.primary
backgroundColor: AppColors.surface

// ❌ WRONG
color: Color(0xFF1B8B5C)
color: Colors.green
```

**Available Colors**:
- Primary: `AppColors.primary`, `AppColors.primaryLight`, `AppColors.primaryDark`
- Semantic: `AppColors.success`, `AppColors.error`, `AppColors.warning`, `AppColors.info`
- Surface: `AppColors.background`, `AppColors.surface`, `AppColors.surfaceVariant`
- Text: `AppColors.onSurface`, `AppColors.onSurfaceVariant`, `AppColors.onBackground`
- Borders: `AppColors.outline`, `AppColors.outlineVariant`

### Spacing (`lib/core/widgets/app_spacing.dart`)
**CRITICAL**: NEVER use hardcoded spacing values. Use `AppSpacing` and `SpacingSize`.

```dart
// ✅ CORRECT
AppSpacing.verticalSpacing(SpacingSize.lg)
AppSpacing.horizontalSpacing(SpacingSize.md)
padding: AppSpacing.paddingLG

// ❌ WRONG
SizedBox(height: 16)
padding: EdgeInsets.all(20)
```

**Available Sizes**: `xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `xxxl`, `huge`, `massive`

### Border Radius (`lib/core/theme/app_radius.dart`)
**CRITICAL**: NEVER use hardcoded border radius. Use `AppRadius` constants.

```dart
// ✅ CORRECT
borderRadius: AppRadius.md
borderRadius: AppRadius.button

// ❌ WRONG
borderRadius: BorderRadius.circular(12)
```

**Available Radius**: `xs`, `sm`, `md`, `lg`, `xl`, `xxl`, `pill`
**Semantic**: `AppRadius.button`, `AppRadius.card`, `AppRadius.dialog`, `AppRadius.input`, `AppRadius.bottomSheet`

### Typography (`lib/core/widgets/app_text.dart`)
**CRITICAL**: NEVER use raw `Text()` widgets. Always use `AppText` or its variants.

```dart
// ✅ CORRECT
AppText.titleLarge('Title')
AppText.bodyMedium('Body text', color: AppColors.onSurface)
AppText.labelSmall('Label', fontWeight: FontWeight.w600)

// ❌ WRONG
Text('Title', style: TextStyle(fontSize: 22))
```

**Variants**: `displayLarge`, `headlineLarge`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`

## Custom Widgets

### Buttons (`lib/core/widgets/app_button.dart`)
**CRITICAL**: Always use `AppButton` variants. NEVER use raw Material buttons.

```dart
// ✅ CORRECT
AppButton.primary(
  onPressed: () {},
  child: AppText.bodyMedium('Submit', color: AppColors.white),
)
AppButton.outline(onPressed: () {}, child: AppText.bodyMedium('Cancel'))
AppButton.text(onPressed: () {}, child: AppText.labelMedium('Skip'))

// ❌ WRONG
ElevatedButton(onPressed: () {}, child: Text('Submit'))
```

**Variants**: `primary`, `secondary`, `outline`, `text`, `ghost`, `danger`
**Properties**: `fullWidth`, `loading`, `requiresKyc`, `leadingIcon`, `trailingIcon`

### Inputs (`lib/core/widgets/app_input.dart`)
Use `AppInput` for text fields (see `lib/core/widgets/app_input.dart`)

### Other Custom Widgets
- `AppCard` - Card containers
- `AppScaffold` - Scaffold wrapper
- `AppContainer` - Custom containers
- `AppIcon` - Icon wrappers

## Dependency Injection

**Package**: `get_it` (via `injection_container.dart`)
- Access via `sl<ServiceName>()`
- Example: `sl<NavigationService>().goBack()`

## Navigation

**Service**: `NavigationService` (`lib/core/services/navigation_service/`)
- Use `sl<NavigationService>()` for navigation
- DO NOT use `Navigator.of(context)` for app navigation (use it for dialogs/modals only)

## Modal Bottom Sheets

**Pattern**: Create StatelessWidget classes for bottom sheet content
**File Location**: Place in `lib/features/[feature]/presentation/widgets/`

```dart
// ✅ CORRECT Pattern (from status_update_action_sheet.dart)
class _MyConfirmationSheet extends StatelessWidget {
  final VoidCallback onConfirm;

  const _MyConfirmationSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.topXxl, // Use semantic constant
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20), // OK for modal padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Content...
            ],
          ),
        ),
      ),
    );
  }
}

// Show method
void _showConfirmation() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Transparent for custom decoration
    builder: (context) => _MyConfirmationSheet(onConfirm: _handleConfirm),
  );
}
```

## Key Packages

- **State Management**: `flutter_bloc`, `provider`
- **DI**: `get_it`
- **Functional**: `dartz` (Either<Failure, Success>)
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- **UI**: `flutter_screenutil` (responsive sizing)
- **Navigation**: Custom `NavigationService`

## Best Practices

### Widget Classes vs Functions
**CRITICAL**: ALWAYS use widget classes, NEVER widget functions

```dart
// ✅ CORRECT
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

// ❌ WRONG
Widget myWidget() => Container();
```

### Const Constructors
Use `const` where possible for performance

```dart
// ✅ CORRECT
const AppText.bodyMedium('Static text')
const Icon(Icons.check)

// Only omit const when values are dynamic
AppText.bodyMedium(dynamicValue)
```

### Async Operations & Context
Always check `mounted` after async operations before using `context`

```dart
// ✅ CORRECT
await someAsyncOperation();
if (!mounted) return;
context.showSnackbar(message: 'Done');

// ❌ WRONG
await someAsyncOperation();
context.showSnackbar(message: 'Done'); // Context may be invalid
```

### Resource Disposal
Always dispose controllers/subscriptions in `dispose()`

```dart
@override
void dispose() {
  _controller.dispose();
  _subscription?.cancel();
  super.dispose();
}
```

### Lists
Use `.builder` for dynamic/long lists

```dart
// ✅ CORRECT
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ❌ WRONG (for long/dynamic lists)
ListView(children: items.map((item) => ItemWidget(item)).toList())
```

## File Naming

- **Screens**: `[name]_screen.dart` (e.g., `request_details_screen.dart`)
- **Widgets**: `[name]_widget.dart` or descriptive name (e.g., `status_update_action_sheet.dart`)
- **BLoCs**: `[name]_bloc.dart`, `[name]_cubit.dart`
- **Entities**: `[name]_entity.dart`
- **Use snake_case** for all file names

## Anti-Patterns to Avoid

❌ Hardcoded colors, spacing, or radius values
❌ Raw `Text()`, `ElevatedButton()`, `TextField()` widgets
❌ Widget functions instead of widget classes
❌ Using `Navigator.push/pop` directly for app navigation (use `NavigationService`)
❌ Not checking `mounted` after async operations
❌ Missing `const` on static widgets
❌ Not disposing controllers/subscriptions
❌ `ListView(children: [])` for long lists (use `.builder`)

## Quick Reference Checklist

Before committing code, verify:
- [ ] No hardcoded colors (use `AppColors`)
- [ ] No hardcoded spacing (use `AppSpacing`)
- [ ] No hardcoded radius (use `AppRadius`)
- [ ] Using `AppText` instead of `Text`
- [ ] Using `AppButton` instead of Material buttons
- [ ] Widget classes, not functions
- [ ] `const` constructors where possible
- [ ] `mounted` check after async operations
- [ ] Controllers/subscriptions disposed
- [ ] `.builder` for dynamic lists
- [ ] Proper error handling with `Either<Failure, T>`
- [ ] Following established modal bottom sheet pattern

## Example: Correct Modal Bottom Sheet

See `lib/features/parcel_am_core/presentation/widgets/status_update_action_sheet.dart` for reference implementation showing:
- Private StatelessWidget class for sheet content
- Proper use of design system (AppColors, AppRadius, AppSpacing, AppText)
- SafeArea wrapping
- Drag handle pattern
- Proper button usage (AppButton variants)

## Additional Resources

- **Custom Widgets**: `lib/core/widgets/`
- **Theme System**: `lib/core/theme/`
- **Base BLoC**: `lib/core/bloc/base/`
- **Navigation**: `lib/core/services/navigation_service/`
