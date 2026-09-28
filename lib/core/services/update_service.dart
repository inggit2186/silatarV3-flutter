import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppVersion {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String changelog;
  final bool isMandatory;

  AppVersion({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.changelog,
    required this.isMandatory,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      downloadUrl: json['download_url'] ?? '',
      changelog: json['changelog'] ?? '',
      isMandatory: json['is_mandatory'] ?? false,
    );
  }
}

class UpdateService {
  static const String _baseUrl = 'https://kemenagtanahdatar.id/api';
  static const String _versionUrl = '$_baseUrl/app-version';

  /// Get current app version from pubspec.yaml
  static String getCurrentVersion() {
    return '1.0.0'; // Update ini saat release baru
  }

  static int getCurrentVersionCode() {
    return 1; // Update ini saat release baru
  }

  /// Check for app updates
  static Future<UpdateResult> checkForUpdate() async {
    try {
      // Load version info dari API
      final response = await http.get(
        Uri.parse(_versionUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = AppVersion.fromJson(data);

        final currentCode = getCurrentVersionCode();

        // Compare version code
        if (latestVersion.versionCode > currentCode) {
          return UpdateResult(
            hasUpdate: true,
            latestVersion: latestVersion,
          );
        }
      }

      return UpdateResult(hasUpdate: false);
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return UpdateResult(hasUpdate: false);
    }
  }

  /// Load version from local JSON (fallback jika API tidak tersedia)
  static Future<AppVersion?> loadLocalVersion() async {
    try {
      // Untuk demo, load dari assets
      // Untuk production, load dari API atau SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getString('cached_version');

      if (cachedVersion != null) {
        return AppVersion.fromJson(jsonDecode(cachedVersion));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache version info
  static Future<void> cacheVersion(AppVersion version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_version', jsonEncode({
      'version': version.version,
      'version_code': version.versionCode,
      'download_url': version.downloadUrl,
      'changelog': version.changelog,
      'is_mandatory': version.isMandatory,
    }));
  }
}

class UpdateResult {
  final bool hasUpdate;
  final AppVersion? latestVersion;

  UpdateResult({
    required this.hasUpdate,
    this.latestVersion,
  });
}
