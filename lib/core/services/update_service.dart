import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_patcher/flutter_patcher.dart';
import 'apk_update_service.dart';
import 'patch_service.dart';

/// Enum untuk tipe update
enum UpdateType {
  patch, // Hot code push (Dart only)
  apk, // Full APK update (native + Dart)
  none, // No update available
}

/// Unified Update Service
/// Handles both flutter_patcher and APK updates
class UpdateService {
  static UpdateService? _instance;
  static UpdateService get instance => _instance ??= UpdateService._();

  UpdateService._();

  final Dio _dio = Dio();

  // API Configuration
  static const String _baseUrl = 'https://kemenagtanahdatar.id/api';
  static const String _checkUrl = '$_baseUrl/patch/check';

  // Current app version (should match pubspec.yaml)
  static const int _currentVersionCode = 1;
  static const String _currentVersion = '2.0.0';

  /// Get current version info
  static int get currentVersionCode => _currentVersionCode;
  static String get currentVersion => _currentVersion;

  /// Check for updates from server
  /// Returns UpdateInfo if update available, null otherwise
  Future<UpdateInfo?> checkForUpdate({
    String? customVersion,
    int? customVersionCode,
  }) async {
    try {
      final version = customVersion ?? _currentVersion;
      final versionCode = customVersionCode ?? _currentVersionCode;

      debugPrint('[UpdateService] Checking for updates...');
      debugPrint('[UpdateService] Current: v$version ($versionCode)');

      final response = await _dio.get(
        _checkUrl,
        queryParameters: {
          'version': version,
          'version_code': versionCode,
        },
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['hasUpdate'] == true || data['needUpdate'] == true) {
          final info = UpdateInfo.fromJson(data);
          debugPrint('[UpdateService] Update available: ${info.version} (${info.updateType})');
          return info;
        }

        debugPrint('[UpdateService] No update available');
        return null;
      }

      return null;
    } on DioException catch (e) {
      debugPrint('[UpdateService] Network error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
      return null;
    }
  }

  /// Apply update based on its type
  /// Returns UpdateResult indicating success/failure
  Future<UpdateResult> applyUpdate(UpdateInfo info) async {
    debugPrint('[UpdateService] Applying update: ${info.version} (${info.updateType})');

    switch (info.updateType) {
      case UpdateType.patch:
        return await _applyPatchUpdate(info);
      case UpdateType.apk:
        return await _applyApkUpdate(info);
      case UpdateType.none:
        return UpdateResult(
          success: true,
          message: 'Tidak ada update',
        );
    }
  }

  /// Apply patch update (flutter_patcher)
  Future<UpdateResult> _applyPatchUpdate(UpdateInfo info) async {
    try {
      // Initialize flutter_patcher
      await PatchService.instance.initialize();

      // Apply the patch
      final result = await PatchService.instance.checkAndApplyPatch(
        patchVersion: info.version,
        patchMd5: info.md5,
        patchUrl: info.downloadUrl,
      );

      if (result.success) {
        return UpdateResult(
          success: true,
          message: result.message,
          needsRestart: true,
          updateType: UpdateType.patch,
        );
      } else {
        return UpdateResult(
          success: false,
          message: result.message,
          errorCode: 'PATCH_FAILED',
          updateType: UpdateType.patch,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Patch error: $e');
      return UpdateResult(
        success: false,
        message: 'Gagal mengaplikasikan patch: $e',
        errorCode: 'PATCH_ERROR',
        updateType: UpdateType.patch,
      );
    }
  }

  /// Apply APK update (full app update)
  Future<UpdateResult> _applyApkUpdate(UpdateInfo info) async {
    try {
      final result = await ApkUpdateService.instance.downloadAndInstall(
        downloadUrl: info.downloadUrl,
        version: info.version,
        md5: info.md5,
      );

      if (result.success) {
        return UpdateResult(
          success: true,
          message: result.message ?? 'Update berhasil diunduh. Layar install akan muncul.',
          needsInstallDialog: true,
          updateType: UpdateType.apk,
        );
      } else {
        return UpdateResult(
          success: false,
          message: result.error ?? 'Gagal mengunduh update',
          errorCode: result.errorCode ?? 'DOWNLOAD_FAILED',
          updateType: UpdateType.apk,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] APK error: $e');
      return UpdateResult(
        success: false,
        message: 'Gagal mengunduh APK: $e',
        errorCode: 'APK_ERROR',
        updateType: UpdateType.apk,
      );
    }
  }

  /// Check and apply update automatically
  /// Returns UpdateResult if applied, null if no update
  Future<UpdateResult?> checkAndApply() async {
    final info = await checkForUpdate();
    if (info == null) return null;
    return await applyUpdate(info);
  }

  /// Rollback to base APK version
  /// Only works for patch updates
  Future<UpdateResult> rollback() async {
    try {
      await PatchService.instance.initialize();
      final result = await PatchService.instance.rollback();

      return UpdateResult(
        success: result.success,
        message: result.message,
        needsRestart: result.needsRestart,
      );
    } catch (e) {
      return UpdateResult(
        success: false,
        message: 'Rollback gagal: $e',
        errorCode: 'ROLLBACK_ERROR',
      );
    }
  }

  /// Get current patch version from flutter_patcher
  Future<String?> getCurrentPatchVersion() async {
    try {
      return await PatchService.instance.currentVersion;
    } catch (e) {
      return null;
    }
  }
}

/// Update information from API response
class UpdateInfo {
  final UpdateType updateType;
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String? patchUrl;
  final String md5;
  final int fileSize;
  final String? sizeHint;
  final String changelog;
  final bool isMandatory;
  final String? minAppVersion;
  final String? maxAppVersion;

  UpdateInfo({
    required this.updateType,
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    this.patchUrl,
    required this.md5,
    this.fileSize = 0,
    this.sizeHint,
    this.changelog = '',
    this.isMandatory = false,
    this.minAppVersion,
    this.maxAppVersion,
  });

  bool get hasUpdate => true; // UpdateInfo only created when update exists
  bool get isPatch => updateType == UpdateType.patch;
  bool get isApk => updateType == UpdateType.apk;

  String get displaySize {
    if (sizeHint != null && sizeHint!.isNotEmpty) {
      return sizeHint!;
    }
    if (fileSize > 0) {
      return _formatFileSize(fileSize);
    }
    return 'Unknown';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    // Determine update type
    UpdateType type = UpdateType.patch;

    // Check explicit type field
    if (json['updateType'] != null) {
      type = json['updateType'] == 'apk' ? UpdateType.apk : UpdateType.patch;
    } else if (json['isApk'] == true) {
      type = UpdateType.apk;
    } else if (json['isPatch'] == true) {
      type = UpdateType.patch;
    }
    // Fallback: if has separate patchUrl, it's a patch
    else if (json['patchUrl'] != null && json['patchUrl'].toString().isNotEmpty) {
      type = UpdateType.patch;
    }
    // Otherwise assume APK
    else {
      type = UpdateType.apk;
    }

    // Get download URL
    String downloadUrl = '';
    if (type == UpdateType.patch && json['patchUrl'] != null) {
      downloadUrl = json['patchUrl'].toString();
    } else if (json['downloadUrl'] != null) {
      downloadUrl = json['downloadUrl'].toString();
    } else if (json['download_url'] != null) {
      downloadUrl = json['download_url'].toString();
    }

    // Handle relative URLs
    if (downloadUrl.startsWith('/')) {
      downloadUrl = 'https://kemenagtanahdatar.id$downloadUrl';
    }

    return UpdateInfo(
      updateType: type,
      version: json['latestVersion'] ?? json['version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      downloadUrl: downloadUrl,
      patchUrl: json['patchUrl']?.toString(),
      md5: json['md5'] ?? '',
      fileSize: json['fileSize'] ?? json['file_size'] ?? 0,
      sizeHint: json['sizeHint']?.toString(),
      changelog: json['changelog'] ?? '',
      isMandatory: json['isMandatory'] ?? json['is_mandatory'] ?? false,
      minAppVersion: json['minAppVersion']?.toString(),
      maxAppVersion: json['maxAppVersion']?.toString(),
    );
  }

  @override
  String toString() {
    return 'UpdateInfo(type: $updateType, version: $version, size: $displaySize, mandatory: $isMandatory)';
  }
}

/// Result from update operation
class UpdateResult {
  final bool success;
  final String message;
  final UpdateType? updateType;
  final bool needsRestart;
  final bool needsInstallDialog;
  final String? errorCode;

  UpdateResult({
    required this.success,
    required this.message,
    this.updateType,
    this.needsRestart = false,
    this.needsInstallDialog = false,
    this.errorCode,
  });

  factory UpdateResult.fromPatchResult(PatchResult result) {
    return UpdateResult(
      success: result.success,
      message: result.message,
      updateType: UpdateType.patch,
      needsRestart: result.needsRestart,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'UpdateResult: SUCCESS - $message';
    }
    return 'UpdateResult: FAILED - $message (code: $errorCode)';
  }
}
