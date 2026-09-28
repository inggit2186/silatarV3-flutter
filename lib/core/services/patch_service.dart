import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_patcher/flutter_patcher.dart';
import 'package:http/http.dart' as http;

/// Service untuk hot code push menggunakan flutter_patcher
/// Update kode Dart tanpa perlu reinstall APK
///
/// Requirements:
/// - Android only
/// - minSdk: 24
/// - compileSdk: 36
/// - NDK: 27.0.12077973+
class PatchService {
  static PatchService? _instance;
  static PatchService get instance => _instance ??= PatchService._();

  PatchService._();

  bool _isInitialized = false;

  /// Base URL API - sesuai dengan backend Laravel
  static const String _baseUrl = 'https://kemenagtanahdatar.id/api';

  /// Endpoint untuk cek patch/update
  static const String _patchCheckUrl = '$_baseUrl/patch/check';

  /// Base version code dari APK (increment setiap release APK baru)
  /// Ini adalah version_code di database, BUKAN version string
  static const int _baseVersionCode = 1;

  /// Current app version string
  static const String _appVersion = '2.0.0';

  /// Initialize flutter_patcher
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await FlutterPatcher.init();
      _isInitialized = true;
      debugPrint('[PatchService] Initialized');
      debugPrint('[PatchService] Current version: ${FlutterPatcher.currentVersion}');
    } catch (e) {
      debugPrint('[PatchService] Failed to initialize: $e');
    }
  }

  /// Check dan apply patch jika tersedia
  Future<PatchResult> checkAndApplyPatch({
    required String patchVersion,
    required String patchMd5,
    required String patchUrl,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final patchInfo = PatchInfo(
        version: patchVersion,
        patchUrl: patchUrl,
        md5: patchMd5,
        targetVersionCode: _baseVersionCode,
      );

      final result = await FlutterPatcher.applyPatch(patchInfo);

      if (result.ok) {
        debugPrint('[PatchService] Patch applied: $patchVersion');
        return PatchResult(
          success: true,
          message: 'Patch berhasil diapply. Restart app untuk melihat perubahan.',
          needsRestart: true,
        );
      } else {
        debugPrint('[PatchService] Patch failed: ${result.message}');
        return PatchResult(
          success: false,
          message: result.message ?? 'Patch gagal diapply',
        );
      }
    } catch (e) {
      debugPrint('[PatchService] Error: $e');
      return PatchResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Rollback ke versi base APK
  Future<PatchResult> rollback() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await FlutterPatcher.rollback();
      debugPrint('[PatchService] Rollback successful');
      return PatchResult(
        success: true,
        message: 'Rollback berhasil. Restart app untuk melihat perubahan.',
        needsRestart: true,
      );
    } catch (e) {
      debugPrint('[PatchService] Rollback error: $e');
      return PatchResult(
        success: false,
        message: 'Rollback gagal: $e',
      );
    }
  }

  /// Get current patch version
  Future<String?> get currentVersion => FlutterPatcher.currentVersion;

  /// Check apakah ada patch aktif
  bool hasActivePatch = false;

  /// Get status info
  Map<String, dynamic> get status => {
        'initialized': _isInitialized,
        'serverUrl': _baseUrl,
        'baseVersionCode': _baseVersionCode,
        'appVersion': _appVersion,
      };

  /// Check for available patch from server
  /// Returns AppPatchInfo if update available, null otherwise
  Future<AppPatchInfo?> checkForPatch() async {
    try {
      final response = await http.get(
        Uri.parse('$_patchCheckUrl?version=$_appVersion&version_code=$_baseVersionCode'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['hasUpdate'] == true || data['needUpdate'] == true) {
          return AppPatchInfo.fromCheckUpdateResponse(data);
        }
      }

      return null;
    } catch (e) {
      debugPrint('[PatchService] Error checking for patch: $e');
      return null;
    }
  }

  /// Check and apply patch automatically
  Future<PatchResult> checkAndApply() async {
    final patchInfo = await checkForPatch();

    if (patchInfo == null) {
      return PatchResult(
        success: true,
        message: 'Tidak ada patch tersedia.',
      );
    }

    return checkAndApplyPatch(
      patchVersion: patchInfo.version,
      patchMd5: patchInfo.md5,
      patchUrl: patchInfo.downloadUrl,
    );
  }
}

/// Result dari patch operation
class PatchResult {
  final bool success;
  final String message;
  final bool needsRestart;

  PatchResult({
    required this.success,
    required this.message,
    this.needsRestart = false,
  });
}

/// Patch info untuk apply patch
/// Diparse dari API response
class AppPatchInfo {
  final String version;
  final String md5;
  final String downloadUrl;
  final int versionCode;
  final int fileSize;
  final String changelog;
  final bool isMandatory;

  AppPatchInfo({
    required this.version,
    required this.md5,
    required this.downloadUrl,
    this.versionCode = 0,
    this.fileSize = 0,
    this.changelog = '',
    this.isMandatory = false,
  });

  factory AppPatchInfo.fromJson(Map<String, dynamic> json) {
    return AppPatchInfo(
      version: json['latestVersion'] ?? json['version'] ?? '',
      md5: json['md5'] ?? '',
      downloadUrl: json['downloadUrl'] ?? json['patchUrl'] ?? json['download_url'] ?? '',
      versionCode: json['version_code'] ?? 0,
      fileSize: json['fileSize'] ?? 0,
      changelog: json['changelog'] ?? '',
      isMandatory: json['isMandatory'] ?? json['is_mandatory'] ?? false,
    );
  }

  /// Parse dari API check update response
  factory AppPatchInfo.fromCheckUpdateResponse(Map<String, dynamic> json) {
    return AppPatchInfo(
      version: json['latestVersion'] ?? '',
      md5: json['md5'] ?? '',
      downloadUrl: json['downloadUrl'] ?? json['patchUrl'] ?? '',
      versionCode: json['version_code'] ?? 0,
      fileSize: json['fileSize'] ?? 0,
      changelog: json['changelog'] ?? '',
      isMandatory: json['isMandatory'] ?? json['is_mandatory'] ?? false,
    );
  }
}
