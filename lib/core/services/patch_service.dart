import 'package:flutter/foundation.dart';
import 'package:flutter_patcher/flutter_patcher.dart';

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

  /// Patch server URL - ganti dengan URL server Anda
  /// Contoh: https://kemenagtanahdatar.id/patches/
  static const String _patchServerUrl = 'https://kemenagtanahdatar.id/patches/';

  /// Current version dari base APK
  static const int _baseVersionCode = 1; // Update setiap release APK baru

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

  /// Get current patch version (Future)
  Future<String?> get currentVersion => FlutterPatcher.currentVersion;

  /// Check apakah ada patch aktif
  bool hasActivePatch = false;

  /// Get status info
  Map<String, dynamic> get status => {
        'initialized': _isInitialized,
        'serverUrl': _patchServerUrl,
        'baseVersionCode': _baseVersionCode,
      };
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

  AppPatchInfo({
    required this.version,
    required this.md5,
    required this.downloadUrl,
  });

  factory AppPatchInfo.fromJson(Map<String, dynamic> json) {
    return AppPatchInfo(
      version: json['version'] ?? '',
      md5: json['md5'] ?? '',
      downloadUrl: json['download_url'] ?? '',
    );
  }
}
