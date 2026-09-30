/// App Version Configuration
/// Update this file for every new release
class AppVersion {
  /// Display version (shown in app)
  /// Set by build.bat when building new APK
  static const String version = '2.0.0';

  /// App version code (integer for logic/DB/comparison)
  /// INCREMENT this when building new APK release
  /// flutter_patcher CANNOT change this (compiled to libapp.so)
  /// Set by build.bat when building new APK
  static const int appVersionCode = 1;

  /// Build number (same as appVersionCode)
  static const int buildNumber = 1;

  /// Full version string: major.version.patchCount
  /// Example: "2.0.0" (no patch), "2.0.0.1" (1 patch), "2.0.1.0" (new APK)
  static String get full {
    // Will be computed dynamically with patchCount
    return '$version.0';
  }
}


















