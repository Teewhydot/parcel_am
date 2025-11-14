# Widget Architecture & Composition Best Practices

## Critical Rules
- **ALWAYS use StatelessWidget or StatefulWidget classes, NEVER use functions that return widgets** - functions break element tree optimization, prevent const usage, and bypass proper lifecycle management
- Use const constructors wherever possible - marks widgets as compile-time constants for maximum performance
- Use final for ALL widget properties to ensure immutability
- Prefer StatelessWidget over StatefulWidget when the widget doesn't manage state

## Widget Structure
- Follow Single Responsibility Principle - each widget should have one clear purpose
- Prefer composition over inheritance - build complex widgets from smaller, focused widgets
- Extract reusable widgets into separate widget classes (not functions) when used multiple times
- Keep build methods small and readable - extract complex UI into separate StatelessWidget classes
- Avoid deeply nested widget trees (more than 3-4 levels) - refactor into smaller widget classes
- Make widgets as dumb as possible - separate presentation from business logic
- Keep stateful logic minimal - lift state up or use state management solutions (BLoC, Riverpod)

## Parameters & Configuration
- Use named parameters with required keyword for mandatory widget properties
- Provide sensible defaults for optional parameters to reduce boilerplate
- Pass data down through constructor parameters, not through global state when possible
- Avoid optional callbacks - make them required or provide a default no-op function

## Keys & Identity
- Use keys (ValueKey, ObjectKey, GlobalKey) when widgets of the same type need to be distinguished in lists
- Use GlobalKey sparingly - only when you need to access state or call methods across the tree
- Use const with ValueKey when the key value is a compile-time constant
- Always provide keys to list items in ListView.builder, especially when items can be reordered

## Context & Builders
- Use Builder widgets when you need a BuildContext that's "inside" a specific widget (e.g., after Scaffold)
- Never store BuildContext in variables - it can become invalid after widget disposal
- Use context parameter from build method - don't reference context from callbacks without checking mounted

## Documentation & Maintenance
- Document public widgets with /// doc comments explaining purpose, usage, and parameters
- Encapsulate internal widget implementation details - expose only necessary APIs
- Name widgets descriptively - widget name should clearly indicate its purpose (e.g., UserProfileCard not Card)
- Keep related widgets in the same file if they're only used together and are small
