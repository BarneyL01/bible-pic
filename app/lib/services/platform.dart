// Platform-specific pieces behind one import. `platform_io.dart` (Android,
// desktop) or `platform_web.dart` (browser) is chosen at compile time.
export 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart';
