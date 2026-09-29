/// App Version Configuration
/// Update this file for every new release
///
/// Version format: major.minor.patch
/// Build number format: YYYYMMDD or incrementing number
class AppVersion {
  /// Display version (shown in app)
  static const String display = '2.0.1';

  /// Build number (for Play Store / internal tracking)
  static const int buildNumber = 3;

  /// Full version string with build number
  static String get full => '$display ($buildNumber)';

  /// Base version code (must match database for update system)
  /// Increment this for every APK release
  static const int baseVersionCode = 3;
}
