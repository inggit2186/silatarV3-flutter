import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Phase of APK update process
enum ApkUpdatePhase {
  downloading,
  verifying,
  readyToInstall,
  launching,
  launched,
}

/// Service for downloading and installing full APK updates
/// Used when native code or plugins need to be updated
class ApkUpdateService {
  static ApkUpdateService? _instance;
  static ApkUpdateService get instance => _instance ??= ApkUpdateService._();

  ApkUpdateService._();

  final Dio _dio = Dio();

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

    return true;
  }

  Future<int> _getAndroidVersion() async {
    try {
      return 29;
    } catch (e) {
      return 29;
    }
  }

  /// Download APK update
  /// Returns ApkDownloadResult with file path on success
  Future<ApkDownloadResult> downloadApk({
    required String downloadUrl,
    required String version,
    required String md5,
    String? fileName,
    Function(double progress, String statusText)? onProgress,
  }) async {
    try {
      debugPrint('[ApkUpdate] Starting download: $downloadUrl');

      // 1. Request permissions
      final hasInstallPermission = await requestInstallPermission();
      if (!hasInstallPermission) {
        debugPrint('[ApkUpdate] Install permission denied');
        return ApkDownloadResult(
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

      // 4. Download APK with progress
      debugPrint('[ApkUpdate] Downloading to: $filePath');

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress?.call(progress, 'Mengunduh update... ${(progress * 100).toStringAsFixed(0)}%');
            debugPrint('[ApkUpdate] Progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 15),
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      debugPrint('[ApkUpdate] Download complete, file size: ${await file.length()} bytes');
      onProgress?.call(1.0, 'Memverifikasi file...');

      // 5. Verify file exists
      if (!await file.exists()) {
        return ApkDownloadResult(
          success: false,
          error: 'File download gagal',
          errorCode: 'FILE_NOT_FOUND',
        );
      }

      // 6. Verify MD5
      if (md5.isNotEmpty) {
        onProgress?.call(1.0, 'Memverifikasi MD5...');
        final downloadedMd5 = await _calculateMd5(file);
        if (downloadedMd5.toLowerCase() != md5.toLowerCase()) {
          debugPrint('[ApkUpdate] MD5 mismatch: expected $md5, got $downloadedMd5');
          await file.delete();
          return ApkDownloadResult(
            success: false,
            error: 'File verification gagal (MD5 tidak cocok)',
            errorCode: 'MD5_MISMATCH',
          );
        }
        debugPrint('[ApkUpdate] MD5 verified: $downloadedMd5');
      }

      // Download complete, ready to install
      return ApkDownloadResult(
        success: true,
        filePath: filePath,
        message: 'Download selesai. Silakan klik "Install Update" untuk melanjutkan.',
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

      return ApkDownloadResult(
        success: false,
        error: errorMsg,
        errorCode: 'DOWNLOAD_ERROR',
      );
    } catch (e, stackTrace) {
      debugPrint('[ApkUpdate] Error: $e');
      debugPrint('[ApkUpdate] StackTrace: $stackTrace');
      return ApkDownloadResult(
        success: false,
        error: 'Terjadi kesalahan: $e',
        errorCode: 'UNKNOWN',
      );
    }
  }

  /// Install downloaded APK
  /// Call this after downloadApk returns success
  Future<ApkInstallResult> installApk({
    required String filePath,
    Function(double progress, String statusText)? onProgress,
  }) async {
    try {
      debugPrint('[ApkUpdate] Opening installer: $filePath');

      onProgress?.call(0, 'Membuka installer...');

      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('[ApkUpdate] OpenFile result: ${result.type.name} - ${result.message}');

      // OpenFile returns "done" or "opened" when it successfully launches the installer
      // This does NOT mean installation is complete, just that the installer was opened
      final isLaunched = result.type.name == 'done' ||
          result.type.name == 'opened' ||
          result.message.toLowerCase().contains('done') ||
          result.message.toLowerCase().contains('opened');

      if (isLaunched) {
        return ApkInstallResult(
          success: true,
          message: 'Installer berhasil dibuka. Mohon selesaikan installasi di layar berikutnya, lalu restart aplikasi.',
        );
      }

      // Handle specific errors
      if (result.message.contains('permission') ||
          result.type.name == 'no_permission_to_open_file') {
        return ApkInstallResult(
          success: false,
          error: 'Izin install ditolak. Silakan aktifkan di Settings.',
          errorCode: 'PERMISSION_DENIED',
        );
      }

      if (result.type.name == 'activity_not_found') {
        return ApkInstallResult(
          success: false,
          error: 'Installer APK tidak ditemukan. Coba restart aplikasi.',
          errorCode: 'ACTIVITY_NOT_FOUND',
        );
      }

      return ApkInstallResult(
        success: false,
        error: 'Gagal membuka installer: ${result.message}',
        errorCode: 'INSTALL_FAILED',
      );
    } catch (e, stackTrace) {
      debugPrint('[ApkUpdate] Install error: $e');
      debugPrint('[ApkUpdate] StackTrace: $stackTrace');
      return ApkInstallResult(
        success: false,
        error: 'Terjadi kesalahan saat membuka installer: $e',
        errorCode: 'UNKNOWN',
      );
    }
  }

  /// Combined download and install in one call
  /// Returns success when download is complete and installer is launched
  Future<ApkUpdateResult> downloadAndInstall({
    required String downloadUrl,
    required String version,
    required String md5,
    String? fileName,
    Function(double progress, String statusText)? onProgress,
  }) async {
    // Step 1: Download
    onProgress?.call(0, 'Memulai download...');

    final downloadResult = await downloadApk(
      downloadUrl: downloadUrl,
      version: version,
      md5: md5,
      fileName: fileName,
      onProgress: onProgress,
    );

    if (!downloadResult.success) {
      return ApkUpdateResult(
        success: false,
        error: downloadResult.error,
        errorCode: downloadResult.errorCode,
      );
    }

    // Download complete, now we need user to confirm install
    // Return special status indicating download is done and we need user action
    return ApkUpdateResult(
      success: true,
      downloadComplete: true,
      filePath: downloadResult.filePath,
      needsUserConfirmation: true,
      message: downloadResult.message,
    );
  }

  /// Calculate MD5 hash of file
  Future<String> _calculateMd5(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('[ApkUpdate] MD5 calculation error: $e');
      return '';
    }
  }
}

/// Result from APK download operation
class ApkDownloadResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final String? filePath;
  final String? message;

  ApkDownloadResult({
    required this.success,
    this.error,
    this.errorCode,
    this.filePath,
    this.message,
  });
}

/// Result from APK install operation
class ApkInstallResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final String? message;

  ApkInstallResult({
    required this.success,
    this.error,
    this.errorCode,
    this.message,
  });
}

/// Result from complete APK update operation
class ApkUpdateResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final String? filePath;
  final String? message;
  final bool downloadComplete;
  final bool needsUserConfirmation;

  ApkUpdateResult({
    required this.success,
    this.error,
    this.errorCode,
    this.filePath,
    this.message,
    this.downloadComplete = false,
    this.needsUserConfirmation = false,
  });
}
