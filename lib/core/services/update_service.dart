import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_version.dart';
import 'apk_update_service.dart';
import 'patch_service.dart';
import 'api_config.dart';

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

  // API Configuration - use same base URL as ApiConfig
  static String get _baseUrl => ApiConfig.baseUrl;
  static String get _checkUrl => '$_baseUrl/patch/check';

  /// Get current version string from AppVersion config
  static String get currentVersion => AppVersion.version;

  /// Get base version code from AppVersion config
  /// Returns APK's native versionCode (tidak berubah setelah patch).
  static int get baseVersionCode => AppVersion.appVersionCode;

  /// Async getter for the version code currently being run oleh user.
  /// Mengembalikan applied_version_code (yang sudah termasuk patch), BUKAN
  /// base APK version. Ini adalah nilai yang harus dikirim ke server agar
  /// server tidak menawarkan patch yang sama berulang kali.
  static Future<int> getCurrentVersionCode() async {
    return PatchService.instance.currentVersionCode;
  }

  /// Check for updates from server
  /// Returns UpdateInfo if update available, null otherwise
  Future<UpdateInfo?> checkForUpdate({
    String? customVersion,
    int? customVersionCode,
  }) async {
    try {
      // Base version (tanpa patchCount) untuk patch matching di backend
      // patchCount dikirim terpisah untuk filtering
      final baseVersion = customVersion ?? AppVersion.version;
      final versionCode = customVersionCode ?? PatchService.instance.currentVersionCode;
      final patchCount = PatchService.instance.patchCount;
      final buildNumber = PatchService.instance.buildNumber;

      debugPrint('[UpdateService] ==================================');
      debugPrint('[UpdateService] Checking for updates...');
      debugPrint('[UpdateService] Current: v$baseVersion ($versionCode), patchCount=$patchCount, buildNumber=$buildNumber');
      debugPrint('[UpdateService] API URL: $_checkUrl');
      debugPrint('[UpdateService] ==================================');

      final response = await _dio.get(
        _checkUrl,
        queryParameters: {
          'version': baseVersion,
          'patch_count': patchCount,
          'app_version_code': versionCode,
          'build_number': buildNumber,
        },
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      debugPrint('[UpdateService] Response status: ${response.statusCode}');
      debugPrint('[UpdateService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['hasUpdate'] == true || data['needUpdate'] == true) {
          final info = UpdateInfo.fromJson(data);
          debugPrint('[UpdateService] ✅ Update available: ${info.version} (${info.updateType})');
          debugPrint('[UpdateService]    Download URL: ${info.downloadUrl}');
          debugPrint('[UpdateService]    Size: ${info.displaySize}');
          return info;
        }

        debugPrint('[UpdateService] No update available');
        return null;
      }

      return null;
    } on DioException catch (e) {
      debugPrint('[UpdateService] ❌ Network error: ${e.message}');
      debugPrint('[UpdateService]    Type: ${e.type}');
      debugPrint('[UpdateService]    Response: ${e.response}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[UpdateService] ❌ Error: $e');
      debugPrint('[UpdateService]    StackTrace: $stackTrace');
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

  /// Download and install APK update directly
  /// Use this for APK updates with progress callback
  Future<UpdateResult> downloadAndInstall({
    required String downloadUrl,
    required String version,
    required String md5,
    Function(double progress, String statusText)? onProgress,
  }) async {
    final result = await ApkUpdateService.instance.downloadAndInstall(
      downloadUrl: downloadUrl,
      version: version,
      md5: md5,
      onProgress: onProgress,
    );

    if (result.success) {
      if (result.needsUserConfirmation) {
        return UpdateResult(
          success: true,
          message: result.message ?? 'Download selesai',
          needsUserConfirmation: true,
          filePath: result.filePath,
          updateType: UpdateType.apk,
        );
      }
      return UpdateResult(
        success: true,
        message: result.message ?? 'Installer dibuka',
        needsInstallDialog: true,
        updateType: UpdateType.apk,
      );
    }
    return UpdateResult(
      success: false,
      message: result.error ?? 'Gagal download',
      errorCode: result.errorCode,
      updateType: UpdateType.apk,
    );
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
        patchVersionCode: info.versionCode,
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
  /// Returns progress updates via callback
  Future<UpdateResult> _applyApkUpdate(
    UpdateInfo info, {
    Function(double progress, String statusText)? onProgress,
  }) async {
    try {
      final result = await ApkUpdateService.instance.downloadAndInstall(
        downloadUrl: info.downloadUrl,
        version: info.version,
        md5: info.md5,
        onProgress: onProgress,
      );

      if (result.success) {
        if (result.needsUserConfirmation) {
          // Download complete, waiting for user to confirm install
          return UpdateResult(
            success: true,
            message: result.message ?? 'Download selesai. Silakan klik Install Update.',
            needsUserConfirmation: true,
            filePath: result.filePath,
            updateType: UpdateType.apk,
          );
        }
        // Installer launched
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

  /// Install APK (call after download completes)
  Future<UpdateResult> installApk(
    String filePath, {
    Function(double progress, String statusText)? onProgress,
  }) async {
    try {
      final result = await ApkUpdateService.instance.installApk(
        filePath: filePath,
        onProgress: onProgress,
      );

      if (result.success) {
        return UpdateResult(
          success: true,
          message: result.message ?? 'Installer berhasil dibuka.',
          needsRestart: true,
          updateType: UpdateType.apk,
        );
      } else {
        return UpdateResult(
          success: false,
          message: result.error ?? 'Gagal membuka installer',
          errorCode: result.errorCode ?? 'INSTALL_FAILED',
          updateType: UpdateType.apk,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Install error: $e');
      return UpdateResult(
        success: false,
        message: 'Gagal membuka installer: $e',
        errorCode: 'INSTALL_ERROR',
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
      return PatchService.instance.currentVersion;
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
  final int buildNumber;
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
    this.buildNumber = 0,
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
      // Use ApiConfig baseUrl for relative URLs
      downloadUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}$downloadUrl';
    }

    return UpdateInfo(
      updateType: type,
      version: json['latestVersion'] ?? json['version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      buildNumber: json['build_number'] ?? json['version_code'] ?? 0,
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
  final bool needsUserConfirmation;
  final String? filePath;
  final String? errorCode;

  UpdateResult({
    required this.success,
    required this.message,
    this.updateType,
    this.needsRestart = false,
    this.needsInstallDialog = false,
    this.needsUserConfirmation = false,
    this.filePath,
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
