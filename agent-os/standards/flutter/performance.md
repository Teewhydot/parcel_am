# Performance & Optimization Best Practices

## Const Optimization (CRITICAL)
- **Use const constructors everywhere possible** - eliminates unnecessary widget rebuilds
- Mark all widgets as const if their properties are compile-time constants
- Use const with collections: const [1, 2, 3], const {'key': 'value'}
- Prefer const SizedBox() over SizedBox() for fixed-size boxes
- Use const EdgeInsets.all(8) instead of EdgeInsets.all(8)
- Flutter DevTools shows widgets that could be const - enable const diagnostics

## Build Method Optimization
- Keep build methods pure - no side effects, no async calls, no heavy computation
- Extract complex widget subtrees into separate StatelessWidget classes (not functions!)
- Avoid creating new objects in build methods (callbacks, lists, etc.) - create them once
- Cache computed values outside build method if they don't change
- Use ListView.builder, GridView.builder for long lists - never ListView(children: [...thousands...])
- Pass callbacks as widget properties, don't create new closures in build method

## Widget Rebuilds
- Use const to prevent entire widget subtrees from rebuilding
- Split widgets into smaller pieces to localize rebuilds
- Use ValueListenableBuilder or StreamBuilder for granular reactive updates
- Use RepaintBoundary to isolate expensive widgets from parent rebuilds
- Check Flutter DevTools for unnecessary rebuilds (enable "Track widget rebuilds")
- Never call setState() in build methods or during layout phase

## State Management Performance
- Use BlocSelector or Selector (Provider) to rebuild only when specific state changes
- Implement proper equality for state classes using Equatable or override ==
- Avoid emitting duplicate states - compare before emitting
- Don't subscribe to streams in build methods - use StreamBuilder or BlocBuilder
- Dispose streams, controllers, and listeners to prevent memory leaks

## List Performance
- Always use ListView.builder or GridView.builder for dynamic/large lists
- Use itemExtent or prototypeItem when all list items have same size
- Implement proper keys for list items (key: ValueKey(item.id))
- Use AutomaticKeepAliveClientMixin for tabs/pages that should stay alive
- Avoid shrinkWrap: true in nested scrollables - use SliverList instead
- Use CachedNetworkImage or similar for network images in lists

## Image Optimization
- Provide appropriate resolution images (1x, 2x, 3x) for different pixel densities
- Compress images before including in app - use tools like TinyPNG
- Use cacheWidth and cacheHeight parameters to load downscaled images
- Implement lazy loading for images outside viewport
- Use cached_network_image package for network images with caching
- Preload critical images with precacheImage() in initState
- Use Image.network with loadingBuilder for progressive loading
- Consider using WebP or compressed formats over PNG/JPEG

## Animation Performance
- Use AnimatedContainer, AnimatedOpacity instead of manual animation for simple cases
- Avoid animating expensive operations (layout, painting large areas)
- Use const widgets for animated content that doesn't change
- Apply Opacity carefully - it's expensive; prefer AnimatedOpacity
- Use Transform widgets for animations - they use GPU compositing
- Use RepaintBoundary around animated widgets to isolate repaints
- Avoid animating many widgets simultaneously - stagger if possible
- Target 60fps (16ms per frame) on mobile, 120fps on devices that support it

## Memory Management
- Dispose all controllers (TextEditingController, AnimationController) in dispose()
- Cancel stream subscriptions and close StreamControllers in dispose()
- Remove listeners in dispose() if added in initState()
- Avoid memory leaks from closures capturing large objects or context
- Use WeakReference for caches that can be garbage collected
- Profile memory usage with Flutter DevTools memory profiler
- Avoid keeping large objects in memory unnecessarily

## App Size Optimization
- Use --split-debug-info and --obfuscate flags for release builds
- Enable code shrinking and resource shrinking in Android build.gradle
- Remove unused dependencies from pubspec.yaml
- Use deferred loading for large, rarely used features (import 'package' deferred as lib)
- Optimize and compress assets (images, fonts, etc.)
- Analyze app size with flutter build apk --analyze-size
- Consider using vector graphics (SVG) instead of raster images where appropriate

## Network Performance
- Use http package with keep-alive connections for multiple requests
- Implement request caching for static or slowly-changing data
- Use pagination for large data sets - don't load everything at once
- Implement retry logic with exponential backoff for failed requests
- Compress API responses (gzip) at server level
- Use Isolates for heavy JSON parsing (large responses > 100KB)
- Debounce or throttle API calls triggered by user input (e.g., search)

## Computation & Heavy Operations
- Move heavy computations to Isolates to avoid blocking UI thread
- Use compute() function for one-off background computations
- Parse large JSON responses in separate isolate
- Avoid synchronous file I/O on main thread
- Use async/await properly - don't block with .then() chains unnecessarily
- Profile CPU usage with Flutter DevTools performance view

## Rendering Optimization
- Use RepaintBoundary to isolate complex widgets that don't need frequent repaints
- Avoid ClipPath, ClipRRect on large areas - they're expensive
- Use CustomPainter for complex custom drawing instead of multiple widgets
- Enable multithreading for Skia (flutter run --enable-software-rendering on supported devices)
- Avoid transparency/opacity on large widget trees - expensive for GPU
- Use ColorFilter for tinting images instead of loading multiple colored versions

## Profiling & Debugging
- Use Flutter DevTools Performance view to identify jank and bottlenecks
- Enable performance overlay: flutter run --profile --enable-performance-overlay
- Profile in Release mode, not Debug - debug mode has performance overhead
- Use Timeline events to trace custom operations
- Check for memory leaks with DevTools Memory view
- Use flutter analyze to catch performance anti-patterns
- Set debugPrintScheduleBuildForStacks = true to track build causes

## Startup Performance
- Minimize work in main() function
- Defer non-critical initializations until after first frame
- Use WidgetsBinding.instance.addPostFrameCallback for post-startup work
- Implement splash screen properly to hide startup time
- Reduce initial bundle size with deferred loading
- Cache frequently used data locally to reduce initial API calls

## Release Build Configuration
- Always build in release mode for production: flutter build apk --release
- Enable obfuscation: --obfuscate --split-debug-info=build/symbols
- Use --tree-shake-icons to remove unused Material/Cupertino icons
- Set shrinkResources true in Android build.gradle
- Optimize Proguard rules for Android
- Test release builds thoroughly - behavior differs from debug builds