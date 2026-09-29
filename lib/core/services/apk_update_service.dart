import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for downloading and installing full APK updates
/// Used when native code or plugins need to be updated
class ApkUpdateService {
  static ApkUpdateService? _instance;
  static ApkUpdateService get instance => _instance ??= ApkUpdateService._();

  ApkUpdateService._();

  final Dio _dio = Dio();

  /// Download progress callback
  Function(int received, int total)? onProgress;

  /// Check if device can install unknown apps
  Future<bool> canInstallUnknownApps() async {
    if (!Platform.isAndroid) return false;
    return await Permission.requestInstallPackages.status.isGranted;
  }

  /// Request install permission (Android 8.0+)
  Future<bool> requestInstallPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.requestInstallPackages.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.requestInstallPackages.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Need to open app settings
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Request storage permission for older Android versions
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await _getAndroidVersion();
    if (androidInfo >= 29) {
      // Android 10+ doesn't need storage permission for app-specific dirs
      return true;
    }

    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return true; // Continue anyway on newer Android
  }

  /// Get Android SDK version
  Future<int> _getAndroidVersion() async {
    try {
      // This is a simplified check - in production use device_info_plus
      return 29; // Default to Android 10+ assumption
    } catch (e) {
      return 29;
    }
  }

  /// Download and install APK update
  /// Returns true if successful, false otherwise
  Future<ApkUpdateResult> downloadAndInstall({
    required String downloadUrl,
    required String version,
    required String md5,
    String? fileName,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      debugPrint('[ApkUpdate] Starting download: $downloadUrl');

      // 1. Request permissions
      final hasInstallPermission = await requestInstallPermission();
      if (!hasInstallPermission) {
        debugPrint('[ApkUpdate] Install permission denied');
        return ApkUpdateResult(
          success: false,
          error: 'Izin install diperlukan. Silakan aktifkan di Settings > Apps > SILATAR > Install unknown apps',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      await requestStoragePermission();

      // 2. Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final apkFileName = fileName ?? 'silatar_update_$version.apk';
      final filePath = '${tempDir.path}/$apkFileName';
      final file = File(filePath);

      // 3. Delete old file if exists
      if (await file.exists()) {
        await file.delete();
      }

      // 4. Download APK
      debugPrint('[ApkUpdate] Downloading to: $filePath');

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          this.onProgress?.call(received, total);
          onProgress?.call(received, total);
          debugPrint('[ApkUpdate] Progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 15),
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      debugPrint('[ApkUpdate] Download complete, file size: ${await file.length()} bytes');

      // 5. Verify file exists
      if (!await file.exists()) {
        return ApkUpdateResult(
          success: false,
          error: 'File download gagal',
          errorCode: 'FILE_NOT_FOUND',
        );
      }

      // 6. Verify MD5 (if provided)
      if (md5.isNotEmpty) {
        final downloadedMd5 = await _calculateMd5(file);
        if (downloadedMd5.toLowerCase() != md5.toLowerCase()) {
          debugPrint('[ApkUpdate] MD5 mismatch: expected $md5, got $downloadedMd5');
          await file.delete();
          return ApkUpdateResult(
            success: false,
            error: 'File verification gagal (MD5 tidak cocok)',
            errorCode: 'MD5_MISMATCH',
          );
        }
        debugPrint('[ApkUpdate] MD5 verified: $downloadedMd5');
      }

      // 7. Open system installer
      debugPrint('[ApkUpdate] Opening installer...');

      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('[ApkUpdate] OpenFile result: ${result.message}');

      // Check if opened successfully
      // ResultType values: done, opened, error, no_permission_to_open_file, activity_not_found
      final isSuccess = result.message.toLowerCase().contains('done') ||
          result.type.name == 'done' ||
          result.type.name == 'opened';

      if (isSuccess) {
        return ApkUpdateResult(
          success: true,
          filePath: filePath,
          message: 'Update berhasil diunduh. Layar install akan muncul.',
        );
      }

      // Handle specific errors
      if (result.message.contains('permission')) {
        return ApkUpdateResult(
          success: false,
          error: 'Izin install ditolak. Silakan aktifkan di Settings.',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      return ApkUpdateResult(
        success: false,
        error: 'Gagal membuka installer: ${result.message}',
        errorCode: 'INSTALL_FAILED',
      );
    } on DioException catch (e) {
      debugPrint('[ApkUpdate] DioError: ${e.message}');
      String errorMsg = 'Gagal mengunduh update';

      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Koneksi timeout. Coba lagi.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Tidak ada koneksi internet.';
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'File update tidak ditemukan.';
      }

      return ApkUpdateResult(
        success: false,
        error: errorMsg,
        errorCode: 'DOWNLOAD_ERROR',
      );
    } catch (e, stackTrace) {
      debugPrint('[ApkUpdate] Error: $e');
      debugPrint('[ApkUpdate] StackTrace: $stackTrace');
      return ApkUpdateResult(
        success: false,
        error: 'Terjadi kesalahan: $e',
        errorCode: 'UNKNOWN',
      );
    }
  }

  /// Calculate MD5 hash of file
  Future<String> _calculateMd5(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // Use crypto package for proper MD5
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('[ApkUpdate] MD5 calculation error: $e');
      return '';
    }
  }

  /// Open app settings for permission management
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

/// Result from APK update operation
class ApkUpdateResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final String? filePath;
  final String? message;

  ApkUpdateResult({
    required this.success,
    this.error,
    this.errorCode,
    this.filePath,
    this.message,
  });

  @override
  String toString() {
    if (success) {
      return 'ApkUpdateResult: SUCCESS - $message';
    }
    return 'ApkUpdateResult: FAILED - $error (code: $errorCode)';
  }
}
