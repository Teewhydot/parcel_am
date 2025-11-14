# Theming & Design System Best Practices

## Theme Setup
- Define a single ThemeData instance at the app level in MaterialApp for consistent styling
- Keep theme definitions in a dedicated file (e.g., lib/theme/app_theme.dart or lib/config/theme.dart)
- Use Material Design 3 (useMaterial3: true) for modern, adaptive designs
- Create separate ThemeData instances for light and dark modes
- Use ColorScheme.fromSeed() or ColorScheme.fromSwatch() for harmonious color palettes
- Never hardcode colors, fonts, or spacing values directly in widgets

## Accessing Theme Data
- Access theme via Theme.of(context) rather than hardcoding values in widgets
- Cache Theme.of(context) in build method if used multiple times: final theme = Theme.of(context)
- Use context.theme extension if available for cleaner syntax
- Use MediaQuery.of(context).platformBrightness to detect system theme preference
- Listen to system theme changes by using MediaQuery and rebuilding MaterialApp

## Color Management
- Use ColorScheme for all color management instead of arbitrary color values
- Define semantic colors (primary, secondary, error, surface, background) in ColorScheme
- Use ColorScheme properties: primary, onPrimary, secondary, surface, error, etc.
- Define custom theme extensions (ThemeExtension) for app-specific colors not in ColorScheme
- Avoid Color(0xFF...) literals in widgets - always reference theme colors
- Test color contrast ratios for accessibility (4.5:1 minimum for normal text)

## Typography
- Use TextTheme for consistent typography across the app
- Access text styles via Theme.of(context).textTheme.bodyLarge, .headlineMedium, etc.
- Define custom text styles as extensions on TextTheme for reusability
- Use relative font sizes (TextStyle.fontSize with scale factor) for accessibility
- Never hardcode TextStyle() in widgets - always derive from theme

## Dark Mode
- Implement dark mode support using ThemeMode.system by default
- Provide user toggle between ThemeMode.light, .dark, and .system
- Use separate ColorScheme.dark() or ColorScheme.fromSeed(brightness: Brightness.dark)
- Test all screens in both light and dark modes during development
- Use Theme.of(context).brightness to conditionally adjust non-themed elements
- Avoid pure black (#000000) in dark mode - use dark gray for better OLED performance

## Platform Adaptation
- Consider Cupertino widgets for iOS-specific designs when platform consistency is important
- Use platform-adaptive widgets (e.g., showDialog vs showCupertinoDialog) when appropriate
- Detect platform with Theme.of(context).platform or Platform.isIOS/Platform.isAndroid
- Use adaptive constructors (Text.rich, Icon.adaptive) when available
- Test on both iOS and Android to ensure proper platform look and feel

## Spacing & Layout
- Define spacing constants in a centralized file (e.g., lib/config/spacing.dart)
- Use consistent spacing scale (4, 8, 12, 16, 24, 32, 40, 48) based on 4px/8px grid
- Avoid magic numbers for padding, margins, or sizing
- Use SizedBox.shrink() for empty space instead of Container()
- Use const SizedBox(height: 16) for vertical spacing, const SizedBox(width: 16) for horizontal

## Theme Overrides
- Use Theme widget to override theme for specific widget subtrees when needed
- Use ThemeData.copyWith() sparingly - only for localized overrides
- Avoid creating new ThemeData() instances in build methods - define them as static constants
- Use Material, Card, Surface for proper elevation and color based on theme
