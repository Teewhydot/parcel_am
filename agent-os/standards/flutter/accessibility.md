# Accessibility Best Practices

## Semantic Widgets & Labels
- Use Semantics widget to provide accessibility information for custom widgets
- Always provide semantics labels for images, icons, and decorative elements
- Use semanticsLabel parameter on Image, Icon widgets instead of relying on tooltips
- Add Semantics(button: true) for custom interactive widgets
- Use MergeSemantics to combine child semantics into a single node
- Use ExcludeSemantics to hide decorative elements from screen readers

## Screen Reader Support
- Test with TalkBack (Android) and VoiceOver (iOS) screen readers regularly
- Provide meaningful labels that describe the purpose, not just the visual appearance
- Use proper reading order - screen readers traverse the widget tree in order
- Avoid redundant labels (e.g., "icon" or "button" - these are added automatically)
- Use Semantics(header: true) for section headers
- Provide state information (e.g., Semantics(checked: true) for toggles)

## Focus & Navigation
- Implement proper focus order for keyboard navigation
- Use FocusNode and Focus widgets to manage focus programmatically
- Support tab navigation on web and desktop platforms
- Ensure focus indicators are visible (don't remove default focus styles without replacement)
- Use autofocus: true on the first input field in forms
- Trap focus in modal dialogs until dismissed

## Touch Targets & Interactions
- Minimum touch target size of 48x48 logical pixels for all interactive elements
- Use Material/InkWell for proper ripple effects that indicate interactivity
- Provide visual feedback for all interactive elements (press states, hover)
- Use Tooltip widgets to provide context for icon-only buttons
- Avoid gestures that require fine motor skills or multiple simultaneous touches
- Support both tap and long-press where appropriate

## Color & Contrast
- Maintain minimum contrast ratio of 4.5:1 for normal text, 3:1 for large text
- Never rely on color alone to convey information (use icons, labels, patterns)
- Test UI with color blindness simulators
- Support system color inversion and high contrast modes
- Ensure focus indicators have sufficient contrast with background
- Test dark mode for proper contrast as well

## Text & Readability
- Support system text scaling - test with large text sizes (up to 2.0x)
- Use semantic text widgets (e.g., Text vs RichText) for proper text rendering
- Set minFontSize or maxLines with ellipsis to handle extreme text scaling
- Avoid text in images - use actual Text widgets for scalability
- Use sufficient line height (1.5x font size) for readability
- Avoid justified text alignment - use left alignment for LTR languages

## Forms & Input
- Provide clear, descriptive labels for all form inputs
- Use TextField.decoration.labelText and hintText properly
- Show validation errors with semantically labeled Text below inputs
- Use autofillHints for better autofill support
- Group related inputs with Semantics(container: true)
- Announce form submission success/failure to screen readers using announcements

## Media & Content
- Provide captions and transcripts for video/audio content
- Use ExcludeSemantics for decorative animations that don't convey information
- Reduce motion for users with prefers-reduced-motion enabled
- Provide alternative text for charts, graphs, and complex images
- Use SemanticsService.announce() for important dynamic content changes

## Testing & Validation
- Run flutter analyze with accessibility lints enabled
- Test with screen readers on both iOS and Android
- Use Accessibility Scanner (Android) and Accessibility Inspector (iOS)
- Test with system font scaling at various levels
- Verify keyboard navigation works throughout the app
- Include accessibility requirements in acceptance criteria