import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_patcher/flutter_patcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_version.dart';

/// Service untuk hot code push menggunakan flutter_patcher
/// Update kode Dart tanpa perlu reinstall APK
///
/// Versioning: Hybrid approach
/// - appVersionCode (integer): dari app_version.dart, di-reset per versi
/// - buildNumber (integer): dari app_version.dart, selalu increment (global)
/// - patchCount (integer): counter patch, disimpan di SharedPreferences + flutter_patcher
///
/// APK Upgrade Detection: Gunakan flutter_patcher directory + metadata file
/// Karena SharedPreferences bisa di-reset saat APK upgrade, kita simpan state
/// di flutter_patcher directory yang PERSIST saat APK upgrade.
/// Patch matching: Gunakan version + appVersionCode + patchCount
class PatchService {
  static PatchService? _instance;
  static PatchService get instance => _instance ??= PatchService._();

  PatchService._();

  // SharedPreferences keys
  static const String _keyPatchCount = 'patch_count';
  static const String _keyBuildNumberAtPatch = 'build_number_at_patch'; // Simpan buildNumber saat patch di-apply
  static const String _keyPatchPending = 'patch_pending';
  static const String _keyStoredAppVersion = 'stored_app_version'; // Track versi app yang menyimpan data

  // Flutter patcher metadata file name (stored in flutter_patcher directory - PERSISTS on APK upgrade!)
  static const String _metaFileName = 'patch_metadata.json';

  bool _isInitialized = false;
  int _patchCount = 0;
  bool _patchPending = false;

  /// Base URL API - sesuai dengan backend Laravel
  static const String _baseUrl = 'https://kemenagtanahdatar.id/api';

  /// Endpoint untuk cek patch/update
  static const String _patchCheckUrl = '$_baseUrl/patch/check';

  /// Initialize flutter_patcher
  /// Note: _checkApkUpgrade is called BEFORE this to determine if cleanup is needed
  Future<void> initialize() async {
    // First, load state and check for APK upgrade BEFORE initializing flutter_patcher
    await _loadState();

    if (_isInitialized) return;

    try {
      // Now initialize flutter_patcher
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
      // CRITICAL: Clean up old flutter_patcher directory first
      await _cleanupOldPatchDirectory();

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

  /// Clean up old flutter_patcher directory from previous APK install
  Future<void> _cleanupOldPatchDirectory() async {
    try {
      final oldDir = await _getOldPatchDirectory();
      if (await oldDir.exists()) {
        debugPrint('[PatchService] Found old flutter_patcher directory - deleting...');
        await oldDir.delete(recursive: true);
        debugPrint('[PatchService] Old flutter_patcher directory deleted');
      }
    } catch (e) {
      debugPrint('[PatchService] Failed to cleanup old directory: $e');
    }
  }

  /// Cek apakah APK sudah di-upgrade sejak patch terakhir
  ///
  /// CRITICAL FIX: SharedPreferences bisa di-reset saat APK upgrade!
  /// Kita gunakan flutter_patcher directory (yang PERSIST) untuk deteksi.
  ///
  /// Approach: Cek metadata di disk (flutter_patcher directory).
  /// Bandingkan stored buildNumber dengan current buildNumber.
  ///
  /// Jika berbeda, berarti APK di-upgrade → hapus flutter_patcher + clear state.
  /// Jika sama atau tidak ada metadata, berarti fresh start atau patch normal.
  Future<void> _checkApkUpgrade() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Read stored values from SharedPreferences
      final storedBuildNumberSp = prefs.getInt(_keyBuildNumberAtPatch);
      final storedPatchCountSp = prefs.getInt(_keyPatchCount);
      final storedPatchPending = prefs.getBool(_keyPatchPending);

      // Read metadata from disk (flutter_patcher directory - PERSISTS on APK upgrade!)
      final diskMeta = await _readMetadataFromDisk();

      final currentBuildNumber = AppVersion.buildNumber;
      final currentAppVersionCode = AppVersion.appVersionCode;
      final currentVersion = AppVersion.version;

      debugPrint('[PatchService] ===== APK UPGRADE CHECK =====');
      debugPrint('[PatchService] Current AppVersionCode: $currentAppVersionCode');
      debugPrint('[PatchService] Current buildNumber: $currentBuildNumber');
      debugPrint('[PatchService] Current version: $currentVersion');
      debugPrint('[PatchService] ----- SharedPreferences -----');
      debugPrint('[PatchService] Stored buildNumberAtPatch: $storedBuildNumberSp');
      debugPrint('[PatchService] Stored patchCount: $storedPatchCountSp');
      debugPrint('[PatchService] Stored patchPending: $storedPatchPending');
      debugPrint('[PatchService] ----- Disk Metadata -----');
      debugPrint('[PatchService] Disk metadata: $diskMeta');

      // CRITICAL: Also read stored app version to detect SharedPreferences migration
      final storedAppVersion = prefs.getString(_keyStoredAppVersion);
      debugPrint('[PatchService] Stored app version (SP): $storedAppVersion');
      debugPrint('[PatchService] Current app version (code): $currentVersion');

      // Check 1: If stored app version differs from current, SharedPreferences was migrated from old APK
      if (storedAppVersion != null && storedAppVersion != currentVersion) {
        debugPrint('[PatchService] -> SharedPreferences was migrated from app version $storedAppVersion!');
        debugPrint('[PatchService] -> Current version is $currentVersion - clearing all patch data');
        await _performCleanup();

        // Save current version to SharedPreferences
        await prefs.setString(_keyStoredAppVersion, currentVersion);
        return;
      }

      // Primary check: Use disk metadata (which persists on APK upgrade)
      if (diskMeta != null) {
        final diskBuildNumber = diskMeta['buildNumber'] as int?;
        final diskPatchCount = diskMeta['patchCount'] as int?;
        final diskVersion = diskMeta['version'] as String?;
        final diskAppVersionCode = diskMeta['appVersionCode'] as int?;

        debugPrint('[PatchService] Disk buildNumber: $diskBuildNumber');
        debugPrint('[PatchService] Disk patchCount: $diskPatchCount');
        debugPrint('[PatchService] Disk version: $diskVersion');
        debugPrint('[PatchService] Disk appVersionCode: $diskAppVersionCode');

        // Check if buildNumber changed (APK was upgraded)
        if (diskBuildNumber != null && diskBuildNumber != currentBuildNumber) {
          debugPrint('[PatchService] -> APK was upgraded from build $diskBuildNumber to $currentBuildNumber!');
          debugPrint('[PatchService] -> Clearing patch state and flutter_patcher directory');
          await _performCleanup();
          return;
        }

        // Check if version changed (e.g., 2.0.0 → 2.0.1)
        if (diskVersion != null && diskVersion != currentVersion) {
          debugPrint('[PatchService] -> Version changed from $diskVersion to $currentVersion!');
          debugPrint('[PatchService] -> Clearing patch state and flutter_patcher directory');
          await _performCleanup();
          return;
        }

        // Same version and buildNumber - patch state is valid
        debugPrint('[PatchService] -> Same build, preserving patches from disk metadata');
        return;
      }

      // No disk metadata - check SharedPreferences as fallback
      debugPrint('[PatchService] ----- Fallback to SharedPreferences -----');

      if (storedBuildNumberSp != null) {
        if (storedBuildNumberSp != currentBuildNumber) {
          debugPrint('[PatchService] -> APK was upgraded (SharedPrefs)!');
          await _performCleanup();
        } else {
          debugPrint('[PatchService] -> Same build, preserving patches');
        }
      }
      // No stored buildNumber - fresh install or SharedPrefs was cleared
      else if (storedPatchCountSp != null && storedPatchCountSp > 0) {
        debugPrint('[PatchService] -> SharedPrefs cleared but had patches (storedPatchCount=$storedPatchCountSp)');
        debugPrint('[PatchService] -> This could mean APK was updated - clearing for safety');
        await _performCleanup();
      }
      else {
        debugPrint('[PatchService] -> Fresh install or no patches ever applied');
        // CRITICAL: If this is a fresh start but flutter_patcher might have internal state,
        // we need to ensure it's rolled back to base APK AND clean SharedPreferences
        debugPrint('[PatchService] -> Ensuring flutter_patcher is at base APK state...');
        try {
          await FlutterPatcher.rollback();
          debugPrint('[PatchService] -> FlutterPatcher rolled back to base APK');
        } catch (e) {
          debugPrint('[PatchService] -> FlutterPatcher rollback skipped (not initialized): $e');
        }

        // FIX: Only clear PATCH-SPECIFIC keys, NOT all SharedPreferences
        // This preserves auth data (token, user_data, remember_me)
        debugPrint('[PatchService] -> Clearing patch state from SharedPreferences...');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyPatchCount);
        await prefs.remove(_keyPatchPending);
        await prefs.remove(_keyBuildNumberAtPatch);
        await prefs.remove(_keyStoredAppVersion);
        debugPrint('[PatchService] -> Patch state cleared, auth data preserved');
      }

      debugPrint('[PatchService] ===== END CHECK =====');
    } catch (e, stack) {
      debugPrint('[PatchService] _checkApkUpgrade failed: $e');
      debugPrint('[PatchService] Stack: $stack');
    }
  }

  /// Perform cleanup of patch state and directory
  Future<void> _performCleanup() async {
    debugPrint('[PatchService] Performing cleanup...');

    // Clear flutter_patcher directory (includes patch files)
    await _clearFlutterPatcherDirectory();

    // Clear metadata file from disk
    await _clearMetadataFromDisk();

    // Clear SharedPreferences state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatchCount);
    await prefs.remove(_keyPatchPending);
    await prefs.remove(_keyBuildNumberAtPatch);
    await prefs.remove(_keyStoredAppVersion);

    _patchCount = 0;
    _patchPending = false;

    debugPrint('[PatchService] Cleanup complete');
  }

  /// Clear flutter_patcher directory to prevent old patches being loaded
  /// Android migrates this directory during APK update, so we must clear it
  Future<void> _clearFlutterPatcherDirectory() async {
    try {
      debugPrint('[PatchService] _clearFlutterPatcherDirectory: Starting...');

      // Get the app's internal storage directory
      final appDir = await getApplicationDocumentsDirectory();
      debugPrint('[PatchService] appDir path: ${appDir.path}');

      // flutter_patcher stores patches in a subdirectory
      final patchDir = Directory('${appDir.path}/flutter_patcher');
      debugPrint('[PatchService] patchDir path: ${patchDir.path}');

      final exists = await patchDir.exists();
      debugPrint('[PatchService] patchDir exists: $exists');

      if (exists) {
        debugPrint('[PatchService] Deleting flutter_patcher directory...');
        await patchDir.delete(recursive: true);
        debugPrint('[PatchService] Successfully deleted flutter_patcher directory');
      } else {
        debugPrint('[PatchService] No flutter_patcher directory to delete');
      }
    } catch (e, stack) {
      debugPrint('[PatchService] Failed to clear flutter_patcher directory: $e');
      debugPrint('[PatchService] Stack: $stack');
    }
  }

  /// Get flutter_patcher directory path
  Future<Directory> _getPatchDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/flutter_patcher');
  }

  /// Get old/stale flutter_patcher directory path (for migration cleanup)
  Future<Directory> _getOldPatchDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/flutter_patcher_old');
  }

  /// Get metadata file path in flutter_patcher directory
  Future<File> _getMetaFile() async {
    final patchDir = await _getPatchDirectory();
    return File('${patchDir.path}/$_metaFileName');
  }

  /// Patch metadata structure (stored as JSON in flutter_patcher directory)
  /// This PERSISTS even when SharedPreferences is cleared during APK upgrade!
  Future<Map<String, dynamic>?> _readMetadataFromDisk() async {
    try {
      final metaFile = await _getMetaFile();
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[PatchService] Failed to read metadata from disk: $e');
    }
    return null;
  }

  /// Write metadata to flutter_patcher directory
  /// This persists across APK upgrades (unlike SharedPreferences)
  Future<void> _writeMetadataToDisk({
    required int buildNumber,
    required int patchCount,
    required String version,
    required int appVersionCode,
  }) async {
    try {
      final patchDir = await _getPatchDirectory();

      // Ensure directory exists
      if (!await patchDir.exists()) {
        await patchDir.create(recursive: true);
      }

      final metaFile = await _getMetaFile();
      final metadata = {
        'buildNumber': buildNumber,
        'patchCount': patchCount,
        'version': version,
        'appVersionCode': appVersionCode,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await metaFile.writeAsString(jsonEncode(metadata));
      debugPrint('[PatchService] Metadata saved to disk: buildNumber=$buildNumber, patchCount=$patchCount');
    } catch (e) {
      debugPrint('[PatchService] Failed to write metadata to disk: $e');
    }
  }

  /// Clear metadata file from flutter_patcher directory
  Future<void> _clearMetadataFromDisk() async {
    try {
      final metaFile = await _getMetaFile();
      if (await metaFile.exists()) {
        await metaFile.delete();
        debugPrint('[PatchService] Metadata file deleted from disk');
      }
    } catch (e) {
      debugPrint('[PatchService] Failed to clear metadata from disk: $e');
    }
  }

  /// PUBLIC METHOD: Prepare for APK update
  /// Call this BEFORE installing a new APK to clear all patch data.
  /// This ensures the new APK starts fresh without stale patches.
  ///
  /// Usage: Call this when user clicks "Install Update" on APK update dialog
  Future<void> prepareForApkUpdate() async {
    debugPrint('[PatchService] ===== PREPARE FOR APK UPDATE =====');
    debugPrint('[PatchService] Clearing all patch data before APK install...');

    // CRITICAL: First rollback flutter_patcher to reset internal state
    try {
      debugPrint('[PatchService] Rolling back flutter_patcher first...');
      await FlutterPatcher.rollback();
      debugPrint('[PatchService] FlutterPatcher rollback complete');
    } catch (e) {
      debugPrint('[PatchService] FlutterPatcher rollback failed (may not be initialized): $e');
    }

    // Rename flutter_patcher directory to _old (instead of delete)
    // This will be cleaned up on next app start
    try {
      final patchDir = await _getPatchDirectory();
      final oldDir = await _getOldPatchDirectory();

      if (await patchDir.exists()) {
        debugPrint('[PatchService] Renaming flutter_patcher to flutter_patcher_old...');
        // Delete old backup if exists
        if (await oldDir.exists()) {
          await oldDir.delete(recursive: true);
        }
        // Rename current to old
        await patchDir.rename(oldDir.path);
        debugPrint('[PatchService] Successfully renamed flutter_patcher to flutter_patcher_old');
      }
    } catch (e) {
      debugPrint('[PatchService] Failed to rename flutter_patcher directory: $e');
      // Fallback to delete
      await _clearFlutterPatcherDirectory();
    }

    // Clear metadata file from disk
    await _clearMetadataFromDisk();

    // Clear SharedPreferences state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatchCount);
    await prefs.remove(_keyPatchPending);
    await prefs.remove(_keyBuildNumberAtPatch);
    await prefs.remove(_keyStoredAppVersion);

    _patchCount = 0;
    _patchPending = false;

    debugPrint('[PatchService] All patch data cleared - APK update ready');
    debugPrint('[PatchService] ===== END PREPARE =====');
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

  /// Get current buildNumber (sync getter)
  /// Returns AppVersion.buildNumber - used for APK update detection
  int get buildNumber => AppVersion.buildNumber;

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

        // Simpan buildNumber saat patch ini di-apply (untuk deteksi APK upgrade)
        await prefs.setInt(_keyBuildNumberAtPatch, AppVersion.buildNumber);

        // Increment patchCount
        _patchCount++;
        await prefs.setInt(_keyPatchCount, _patchCount);

        // Set pending (akan di-promote setelah restart)
        _patchPending = true;
        await prefs.setBool(_keyPatchPending, true);

        // CRITICAL: Save current app version to detect SharedPreferences migration
        await prefs.setString(_keyStoredAppVersion, AppVersion.version);

        // CRITICAL: Also save to disk metadata (PERSISTS on APK upgrade!)
        await _writeMetadataToDisk(
          buildNumber: AppVersion.buildNumber,
          patchCount: _patchCount,
          version: AppVersion.version,
          appVersionCode: AppVersion.appVersionCode,
        );

        debugPrint('[PatchService] Patch count: $_patchCount, buildNumber: ${AppVersion.buildNumber}');

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
      await prefs.remove(_keyBuildNumberAtPatch);
      await prefs.remove(_keyStoredAppVersion);

      // Also clear disk metadata
      await _clearMetadataFromDisk();

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
      // Base version tanpa patchCount untuk backend matching
      final version = AppVersion.version;
      final patchCountToSend = _patchPending ? _patchCount - 1 : _patchCount;

      final response = await http.get(
        Uri.parse('$_patchCheckUrl?version=$version&patch_count=$patchCountToSend&app_version_code=${AppVersion.appVersionCode}&build_number=${AppVersion.buildNumber}'),
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
