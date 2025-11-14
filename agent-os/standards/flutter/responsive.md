# Responsive & Adaptive Design Best Practices

## Screen Size & Breakpoints
- Design for multiple screen sizes from the start (phones, tablets, foldables, desktop)
- Use LayoutBuilder to get parent constraints and build responsive layouts
- Define breakpoint constants (e.g., mobile: <600, tablet: 600-900, desktop: >900)
- Use MediaQuery.of(context).size to get device dimensions
- Consider using packages like responsive_builder or flutter_screenutil for complex apps
- Test on physical devices with different screen sizes, not just emulators

## Responsive Techniques
- Use flexible widgets: Flexible, Expanded, Spacer for proportional layouts
- Prefer relative sizing over fixed pixel values (e.g., MediaQuery width percentages)
- Use FractionallySizedBox for percentage-based dimensions
- Use AspectRatio to maintain proportions across different screens
- Implement responsive grids with GridView.builder and dynamic crossAxisCount
- Use Wrap instead of Row/Column when content might overflow on smaller screens

## Orientation Handling
- Handle both portrait and landscape orientations
- Use OrientationBuilder to detect and react to orientation changes
- Consider different layouts for portrait vs landscape (e.g., list vs grid)
- Lock orientation only when absolutely necessary (e.g., games, specific features)
- Test all screens in both orientations

## Adaptive Layouts
- Use different layouts for phones, tablets, and desktop (e.g., single pane vs master-detail)
- Show/hide navigation elements based on screen size (e.g., BottomNavigationBar vs NavigationRail)
- Adjust column counts in grids based on available width
- Use SafeArea to respect device notches, status bars, and system UI
- Implement responsive padding/margins that scale with screen size

## Text & Font Scaling
- Use relative font sizes based on TextTheme, not hardcoded values
- Support system text scaling via MediaQuery.of(context).textScaleFactor
- Test with large text accessibility settings (Settings > Accessibility > Larger Text)
- Use FittedBox carefully - it can make text too small or too large
- Set maximum text scale factor if needed: MediaQuery(data: data.copyWith(textScaleFactor: min(data.textScaleFactor, 1.5)))

## Touch Targets
- Ensure minimum touch target size of 48x48 logical pixels for interactive elements
- Use SizedBox or Padding to expand touch areas if visual element is smaller
- Increase spacing between tappable elements on smaller screens
- Consider thumb zones for one-handed use on mobile devices

## Images & Assets
- Provide multiple resolution assets (1x, 2x, 3x) for different pixel densities
- Use AssetImage with proper resolution suffixes
- Implement responsive images that scale based on screen size
- Use FadeInImage or cached_network_image for network images with placeholders
- Lazy load images in lists with ListView.builder

## Desktop & Web Considerations
- Implement keyboard shortcuts and mouse hover states for desktop
- Support window resizing gracefully - test with very small and very large windows
- Use Scrollbar widgets for desktop/web (they're hidden on mobile)
- Consider multi-window support on desktop platforms
- Implement proper focus management for keyboard navigation