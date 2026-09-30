import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_patcher/flutter_patcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_version.dart';

/// Service untuk hot code push menggunakan flutter_patcher
/// Update kode Dart tanpa perlu reinstall APK
///
/// Versioning: Hybrid approach
/// - appVersionCode (integer): dari app_version.dart, tidak bisa diubah oleh patch
/// - patchCount (integer): counter patch, disimpan di SharedPreferences
///
/// Format version: major.version.patchCount
/// Contoh:
/// - APK 2.0.0 (appVersionCode=0, patchCount=0) → "2.0.0.0"
/// - APK 2.0.0 + 2 patches (patchCount=2) → "2.0.0.2"
/// - APK 2.0.1 (appVersionCode=1, patchCount=0) → "2.0.1.0"
class PatchService {
  static PatchService? _instance;
  static PatchService get instance => _instance ??= PatchService._();

  PatchService._();

  // SharedPreferences keys
  static const String _keyPatchCount = 'patch_count';
  static const String _keyAppVersionCodeAtPatch = 'app_version_code_at_patch';
  static const String _keyPatchPending = 'patch_pending';

  bool _isInitialized = false;
  int _patchCount = 0;
  bool _patchPending = false;

  /// Base URL API - sesuai dengan backend Laravel
  static const String _baseUrl = 'https://kemenagtanahdatar.id/api';

  /// Endpoint untuk cek patch/update
  static const String _patchCheckUrl = '$_baseUrl/patch/check';

  /// Initialize flutter_patcher
  Future<void> initialize() async {
    await _loadState();

    if (_isInitialized) return;

    try {
      await FlutterPatcher.init();
      _isInitialized = true;
      debugPrint('[PatchService] Initialized');

      // Promote pending patch if loaded
      await _promotePendingIfLoaded();
    } catch (e) {
      debugPrint('[PatchService] Failed to initialize: $e');
    }
  }

  /// Load state dari SharedPreferences
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _patchCount = prefs.getInt(_keyPatchCount) ?? 0;
      _patchPending = prefs.getBool(_keyPatchPending) ?? false;

      debugPrint('[PatchService] Loaded: patchCount=$_patchCount pending=$_patchPending');

      // Cek apakah APK sudah di-upgrade sejak patch terakhir di-apply
      await _checkApkUpgrade();
    } catch (e) {
      debugPrint('[PatchService] Failed to load state: $e');
    }
  }

  /// Cek apakah APK sudah di-upgrade sejak patch terakhir
  /// Jika appVersionCode di SharedPreferences != appVersionCode saat ini,
  /// berarti APK sudah di-upgrade dan patch state harus di-reset
  Future<void> _checkApkUpgrade() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAppVersionCode = prefs.getInt(_keyAppVersionCodeAtPatch);
      final currentAppVersionCode = AppVersion.appVersionCode;

      debugPrint('[PatchService] ===== APK UPGRADE CHECK =====');
      debugPrint('[PatchService] storedAppVersionCode: $storedAppVersionCode');
      debugPrint('[PatchService] currentAppVersionCode: $currentAppVersionCode');

      if (storedAppVersionCode != null && storedAppVersionCode != currentAppVersionCode) {
        // APK berbeda dengan saat patch di-apply — reset state
        debugPrint('[PatchService] APK upgraded! Clearing patch state...');

        await FlutterPatcher.rollback();
        await prefs.remove(_keyPatchCount);
        await prefs.remove(_keyPatchPending);
        await prefs.remove(_keyAppVersionCodeAtPatch);

        _patchCount = 0;
        _patchPending = false;

        debugPrint('[PatchService] Patch state cleared');
      } else {
        debugPrint('[PatchService] No APK upgrade detected');
      }
      debugPrint('[PatchService] ===== END CHECK =====');
    } catch (e) {
      debugPrint('[PatchService] _checkApkUpgrade failed: $e');
    }
  }

  /// Promote pending patch ke applied setelah restart
  Future<void> _promotePendingIfLoaded() async {
    if (!_patchPending) return;

    try {
      final installedVersion = await FlutterPatcher.currentVersion;
      if (installedVersion != null && installedVersion.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyPatchPending, false);
        _patchPending = false;
        debugPrint('[PatchService] Pending patch promoted to applied');
      }
    } catch (e) {
      debugPrint('[PatchService] _promotePendingIfLoaded failed: $e');
    }
  }

  /// Get full version string: major.version.patchCount
  String getFullVersion() {
    return '${AppVersion.version}.$_patchCount';
  }

  /// Get version info untuk display
  Future<({String version, int patchCount})> getVersionInfo() async {
    await _loadState();
    return (version: getFullVersion(), patchCount: _patchCount);
  }

  /// Get current version info (for display in UI)
  /// Returns: version string with patch count (e.g., "2.0.0.0") and appVersionCode
  Future<({String version, int versionCode})> getCurrentVersionInfo() async {
    await _loadState();
    return (version: getFullVersion(), versionCode: AppVersion.appVersionCode);
  }

  /// Get patchCount untuk dikirim ke server
  int get patchCount => _patchCount;

  /// Get current appVersionCode (sync getter)
  /// Returns AppVersion.appVersionCode
  int get currentVersionCode => AppVersion.appVersionCode;

  /// Get current version string (sync getter)
  /// Returns full version with patch count
  String get currentVersion => getFullVersion();

  /// Check dan apply patch
  Future<PatchResult> checkAndApplyPatch({
    required String patchVersion,
    required String patchMd5,
    required String patchUrl,
    required int patchVersionCode,
  }) async {
    await _loadState();

    if (!_isInitialized) {
      await initialize();
    }

    try {
      // targetVersionCode harus = appVersionCode dari APK saat ini
      final patchInfo = PatchInfo(
        version: patchVersion,
        patchUrl: patchUrl,
        md5: patchMd5,
        targetVersionCode: AppVersion.appVersionCode,
      );

      final result = await FlutterPatcher.applyPatch(patchInfo);

      if (result.ok) {
        debugPrint('[PatchService] Patch applied: $patchVersion');

        // Simpan state
        final prefs = await SharedPreferences.getInstance();

        // Simpan appVersionCode saat patch ini di-apply
        await prefs.setInt(_keyAppVersionCodeAtPatch, AppVersion.appVersionCode);

        // Increment patchCount
        _patchCount++;
        await prefs.setInt(_keyPatchCount, _patchCount);

        // Set pending (akan di-promote setelah restart)
        _patchPending = true;
        await prefs.setBool(_keyPatchPending, true);

        debugPrint('[PatchService] Patch count: $_patchCount');

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

      // Reset patch count
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPatchCount);
      await prefs.remove(_keyPatchPending);
      await prefs.remove(_keyAppVersionCodeAtPatch);

      _patchCount = 0;
      _patchPending = false;

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

  /// Check for available patch from server
  Future<AppPatchInfo?> checkForPatch() async {
    try {
      await _loadState();
      final version = getFullVersion();
      final patchCountToSend = _patchPending ? _patchCount - 1 : _patchCount;

      final response = await http.get(
        Uri.parse('$_patchCheckUrl?version=$version&patch_count=$patchCountToSend&app_version_code=${AppVersion.appVersionCode}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['hasUpdate'] == true || json['needUpdate'] == true) {
          return AppPatchInfo.fromCheckUpdateResponse(json);
        }
      }

      return null;
    } catch (e) {
      debugPrint('[PatchService] Error checking for patch: $e');
      return null;
    }
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

/// Patch info dari API response
class AppPatchInfo {
  final String version;
  final String md5;
  final String downloadUrl;
  final int versionCode;
  final int patchCount;
  final int fileSize;
  final String changelog;
  final bool isMandatory;

  AppPatchInfo({
    required this.version,
    required this.md5,
    required this.downloadUrl,
    this.versionCode = 0,
    this.patchCount = 0,
    this.fileSize = 0,
    this.changelog = '',
    this.isMandatory = false,
  });

  factory AppPatchInfo.fromCheckUpdateResponse(Map<String, dynamic> json) {
    return AppPatchInfo(
      version: json['latestVersion'] ?? '',
      md5: json['md5'] ?? '',
      downloadUrl: json['downloadUrl'] ?? json['patchUrl'] ?? '',
      versionCode: json['version_code'] ?? 0,
      patchCount: json['patch_count'] ?? 0,
      fileSize: json['fileSize'] ?? 0,
      changelog: json['changelog'] ?? '',
      isMandatory: json['isMandatory'] ?? json['is_mandatory'] ?? false,
    );
  }
}
