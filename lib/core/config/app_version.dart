/// App Version Configuration
/// Update this file for every new release
class AppVersion {
  /// Display version (shown in app)
  /// Set by build.bat when building new APK
  static const String version = '2.0.1';

  /// App version code (integer for PATCH matching)
  /// RESET per version (e.g., 2.0.0 → 2.0.1 resets to 1)
  /// flutter_patcher CANNOT change this (compiled to libapp.so)
  /// Used to match patches with the same base APK version
  static const int appVersionCode = 1;

  /// Build number (GLOBAL counter, never resets)
  /// Used for APK update detection - increment every build
  /// Backend checks: build_number > user's build_number
  static const int buildNumber = 3;

  /// Full version string: major.version.patchCount
  /// Example: "2.0.0" (no patch), "2.0.0.1" (1 patch), "2.0.1.0" (new APK)
  static String get full {
    // Will be computed dynamically with patchCount
    return '$version.0';
  }
}
























