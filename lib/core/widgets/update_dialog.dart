import 'package:flutter/material.dart';
import '../services/apk_update_service.dart';
import '../services/patch_service.dart';
import '../services/update_service.dart';
import '../config/app_version.dart';
import '../theme/neo_mirai_theme.dart';
import '../utils/responsive.dart';

/// Unified Update Dialog for both Patch and APK updates
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final Function(UpdateResult) onUpdate;
  /// Callback for APK updates that returns (downloadResult, installerLauncher)
  /// Returns: (result, shouldInstallNow)
  final Future<ApkInstallCallbackResult> Function(
    Function(double progress, String statusText) onProgress,
  )? onApkDownloadWithProgress;
  /// Callback when mandatory APK install is triggered (user clicked Install)
  final VoidCallback? onMandatoryInstallTriggered;
  final VoidCallback? onLater;
  final VoidCallback? onRestart;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.onUpdate,
    this.onApkDownloadWithProgress,
    this.onMandatoryInstallTriggered,
    this.onLater,
    this.onRestart,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

/// Result dari APK download + install callback
class ApkInstallCallbackResult {
  final bool downloadSuccess;
  final String? filePath;
  final String? error;
  final String? message;

  ApkInstallCallbackResult({
    required this.downloadSuccess,
    this.filePath,
    this.error,
    this.message,
  });
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateDialogStatus _status = UpdateDialogStatus.idle;
  double _progress = 0;
  String _statusText = 'Menunggu...';
  UpdateResult? _result;
  String? _downloadedFilePath;
  bool _autoStarted = false; // Track if auto-start was triggered for mandatory patch

  bool get _isPatch => widget.info.isPatch;
  bool get _isMandatory => widget.info.isMandatory;

  @override
  void initState() {
    super.initState();
    // Auto-start mandatory patch updates immediately
    if (_isPatch && _isMandatory && !_autoStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoStartIfNeeded();
      });
    }
  }

  void _autoStartIfNeeded() {
    // Only auto-start for mandatory patch updates in idle state
    if (_isPatch && _isMandatory && _status == UpdateDialogStatus.idle && !_autoStarted) {
      _autoStarted = true;
      debugPrint('[UpdateDialog] Auto-starting mandatory patch update...');
      _startUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMandatory && _status != UpdateDialogStatus.downloading,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(Responsive.cardPadding(24)),
          decoration: BoxDecoration(
            color: NeoMiraiColors.rice,
            borderRadius: BorderRadius.circular(Responsive.radius(24)),
            border: Border.all(
              color: _getBorderColor().withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getBorderColor().withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              SizedBox(height: Responsive.spacing(16)),
              _buildTitle(),
              SizedBox(height: Responsive.spacing(8)),
              _buildVersionBadge(),
              SizedBox(height: Responsive.spacing(12)),
              _buildInstallStatusWarning(),
              SizedBox(height: Responsive.spacing(16)),
              _buildContent(),
              SizedBox(height: Responsive.spacing(24)),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (_status == UpdateDialogStatus.error) {
      return NeoMiraiColors.error;
    }
    if (_status == UpdateDialogStatus.success) {
      return NeoMiraiColors.success;
    }
    if (_isPatch) {
      return NeoMiraiColors.gold;
    }
    return NeoMiraiColors.gold;
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (_status) {
      case UpdateDialogStatus.downloading:
        icon = Icons.downloading_rounded;
        color = NeoMiraiColors.gold;
        break;
      case UpdateDialogStatus.applying:
        icon = _isPatch ? Icons.bolt_rounded : Icons.settings_rounded;
        color = NeoMiraiColors.gold;
        break;
      case UpdateDialogStatus.readyToInstall:
        icon = Icons.check_circle_rounded;
        color = NeoMiraiColors.success;
        break;
      case UpdateDialogStatus.launching:
        icon = Icons.open_in_new_rounded;
        color = NeoMiraiColors.gold;
        break;
      case UpdateDialogStatus.success:
        icon = Icons.check_circle_rounded;
        color = NeoMiraiColors.success;
        break;
      case UpdateDialogStatus.error:
        icon = Icons.error_rounded;
        color = NeoMiraiColors.error;
        break;
      case UpdateDialogStatus.install:
        icon = Icons.system_update_alt_rounded;
        color = NeoMiraiColors.gold;
        break;
      default:
        icon = _isPatch ? Icons.bolt_rounded : Icons.system_update_alt_rounded;
        color = NeoMiraiColors.gold;
    }

    return Container(
      padding: EdgeInsets.all(Responsive.radius(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(icon, size: Responsive.iconSize(36), color: color),
    );
  }

  Widget _buildTitle() {
    String title;
    switch (_status) {
      case UpdateDialogStatus.downloading:
        title = 'Mengunduh Update...';
        break;
      case UpdateDialogStatus.applying:
        title = _isPatch ? 'Menerapkan Update...' : 'Mempersiapkan Install...';
        break;
      case UpdateDialogStatus.readyToInstall:
        title = 'Download Selesai';
        break;
      case UpdateDialogStatus.launching:
        title = 'Membuka Installer...';
        break;
      case UpdateDialogStatus.success:
        title = 'Update Berhasil!';
        break;
      case UpdateDialogStatus.error:
        title = 'Update Gagal';
        break;
      case UpdateDialogStatus.install:
        title = 'Membuka Installer...';
        break;
      default:
        title = _isPatch ? 'Update Ringan Tersedia!' : 'Update Tersedia!';
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: Responsive.fontSize(20),
        fontWeight: FontWeight.bold,
        color: NeoMiraiColors.ink,
      ),
    );
  }

  Widget _buildVersionBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(12),
            vertical: Responsive.spacing(4),
          ),
          decoration: BoxDecoration(
            color: NeoMiraiColors.ink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Responsive.radius(16)),
          ),
          child: Text(
            'v${widget.info.version}',
            style: TextStyle(
              fontSize: Responsive.fontSize(12),
              fontWeight: FontWeight.w600,
              color: NeoMiraiColors.ink,
            ),
          ),
        ),
        SizedBox(width: Responsive.spacing(8)),
        _buildUpdateTypeChip(),
        if (widget.info.isMandatory) ...[
          SizedBox(width: Responsive.spacing(8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(8),
              vertical: Responsive.spacing(2),
            ),
            decoration: BoxDecoration(
              color: NeoMiraiColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
            child: Text(
              'WAJIB',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.bold,
                color: NeoMiraiColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUpdateTypeChip() {
    final isPatch = widget.info.isPatch;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(8),
        vertical: Responsive.spacing(2),
      ),
      decoration: BoxDecoration(
        color: NeoMiraiColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        border: Border.all(
          color: NeoMiraiColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPatch ? Icons.bolt_rounded : Icons.android_rounded,
            size: 14,
            color: NeoMiraiColors.gold,
          ),
          const SizedBox(width: 4),
          Text(
            isPatch ? 'Patch' : 'Full APK',
            style: TextStyle(
              fontSize: Responsive.fontSize(10),
              fontWeight: FontWeight.w600,
              color: NeoMiraiColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  /// Warning widget untuk APK update — cek apakah APK installer sudah selesai
  Widget _buildInstallStatusWarning() {
    // Hanya untuk APK update (bukan patch)
    if (!widget.info.isApk) return const SizedBox.shrink();

    // Hanya tampilkan warning saat status idle (sebelum download/install)
    if (_status != UpdateDialogStatus.idle) return const SizedBox.shrink();

    return FutureBuilder<({String version, int versionCode})>(
      future: PatchService.instance.getCurrentVersionInfo(),
      builder: (context, snapshot) {
        final currentAppVersionCode = snapshot.data?.versionCode ?? AppVersion.appVersionCode;

        // Jika belum diinstall, tampilkan warning
        if (currentAppVersionCode != widget.info.versionCode) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(12),
              vertical: Responsive.spacing(8),
            ),
            decoration: BoxDecoration(
              color: NeoMiraiColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              border: Border.all(
                color: NeoMiraiColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: NeoMiraiColors.warning,
                ),
                SizedBox(width: Responsive.spacing(8)),
                Expanded(
                  child: Text(
                    'Versi APK installer (${widget.info.versionCode}) berbeda dari app saat ini ($currentAppVersionCode). Selesaikan installasi APK terlebih dahulu.',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(11),
                      color: NeoMiraiColors.warning,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Versi cocok — tidak perlu warning
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent() {
    if (_status == UpdateDialogStatus.idle) {
      return _buildIdleContent();
    }
    return _buildProgressContent();
  }

  Widget _buildIdleContent() {
    return Column(
      children: [
        // Versi update saja
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(12),
            vertical: Responsive.spacing(6),
          ),
          decoration: BoxDecoration(
            color: NeoMiraiColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Responsive.radius(8)),
            border: Border.all(
              color: NeoMiraiColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: NeoMiraiColors.gold,
              ),
              SizedBox(width: Responsive.spacing(6)),
              Text(
                'Update ke: v${widget.info.version}',
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  fontWeight: FontWeight.w700,
                  color: NeoMiraiColors.gold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.spacing(12)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(16),
            vertical: Responsive.spacing(8),
          ),
          decoration: BoxDecoration(
            color: NeoMiraiColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storage_rounded,
                size: 16,
                color: NeoMiraiColors.gold,
              ),
              const SizedBox(width: 8),
              Text(
                widget.info.isPatch
                    ? 'Hanya ${widget.info.displaySize}'
                    : 'Ukuran: ${widget.info.displaySize}',
                style: TextStyle(
                  fontSize: Responsive.fontSize(12),
                  color: NeoMiraiColors.gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.spacing(12)),
        if (widget.info.changelog.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.spacing(16)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.paper.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
              border: Border.all(
                color: NeoMiraiColors.line.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apa yang baru:',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(12),
                    fontWeight: FontWeight.w600,
                    color: NeoMiraiColors.inkSoft,
                  ),
                ),
                SizedBox(height: Responsive.spacing(8)),
                Text(
                  widget.info.changelog,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(13),
                    color: NeoMiraiColors.ink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        if (widget.info.isPatch && !widget.info.isMandatory) ...[
          SizedBox(height: Responsive.spacing(12)),
          Container(
            padding: EdgeInsets.all(Responsive.spacing(12)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 20,
                  color: NeoMiraiColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update ringan, apply instant tanpa install ulang!',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(11),
                      color: NeoMiraiColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressContent() {
    // Download complete state
    if (_status == UpdateDialogStatus.readyToInstall) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.spacing(16)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 32,
                  color: NeoMiraiColors.success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(13),
                      color: NeoMiraiColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(12)),
          Container(
            padding: EdgeInsets.all(Responsive.spacing(12)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.android_rounded,
                  size: 20,
                  color: NeoMiraiColors.gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tekan "Install Update" untuk melanjutkan',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(11),
                      color: NeoMiraiColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Success state
    if (_status == UpdateDialogStatus.success) {
      return Column(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.spacing(16)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 32,
                  color: NeoMiraiColors.success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _result?.message ?? 'Update berhasil diapply!',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(13),
                      color: NeoMiraiColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.info.isPatch) ...[
            SizedBox(height: Responsive.spacing(12)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(12)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: NeoMiraiColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restart aplikasi untuk melihat perubahan',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(11),
                        color: NeoMiraiColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // Error state
    if (_status == UpdateDialogStatus.error) {
      return Container(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        decoration: BoxDecoration(
          color: NeoMiraiColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Responsive.radius(16)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_rounded,
              size: 32,
              color: NeoMiraiColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _result?.message ?? 'Terjadi kesalahan',
                style: TextStyle(
                  fontSize: Responsive.fontSize(13),
                  color: NeoMiraiColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Downloading / Launching state (with progress bar)
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
          child: LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            backgroundColor: NeoMiraiColors.line.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(NeoMiraiColors.gold),
            minHeight: 10,
          ),
        ),
        SizedBox(height: Responsive.spacing(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _statusText,
                style: TextStyle(
                  fontSize: Responsive.fontSize(13),
                  color: NeoMiraiColors.inkSoft,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_progress > 0)
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: Responsive.fontSize(14),
                  fontWeight: FontWeight.bold,
                  color: NeoMiraiColors.gold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    switch (_status) {
      case UpdateDialogStatus.idle:
        return _buildIdleActions();
      case UpdateDialogStatus.readyToInstall:
        return _buildReadyToInstallActions();
      case UpdateDialogStatus.launching:
        return _buildLaunchingActions();
      case UpdateDialogStatus.success:
        return _buildSuccessActions();
      case UpdateDialogStatus.error:
        return _buildErrorActions();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdleActions() {
    // For mandatory patch updates that are auto-starting, show progress instead of buttons
    if (_isPatch && _isMandatory && _autoStarted) {
      return _buildAutoUpdateProgress();
    }

    return Row(
      children: [
        if (!_isMandatory && widget.onLater != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
                side: BorderSide(color: NeoMiraiColors.ash),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                ),
              ),
              child: Text(
                'Nanti',
                style: TextStyle(color: NeoMiraiColors.ash),
              ),
            ),
          ),
          SizedBox(width: Responsive.spacing(12)),
        ],
        Expanded(
          flex: _isMandatory ? 1 : 1,
          child: ElevatedButton(
            onPressed: _startUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.gold,
              foregroundColor: NeoMiraiColors.ink,
              padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
              elevation: 4,
              shadowColor: NeoMiraiColors.gold.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isPatch ? Icons.bolt_rounded : Icons.download_rounded,
                  size: Responsive.iconSize(18),
                ),
                SizedBox(width: Responsive.spacing(8)),
                Flexible(
                  child: Text(
                    _isPatch ? 'Update Sekarang' : 'Download Update',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build progress widget for auto-updating mandatory patches
  Widget _buildAutoUpdateProgress() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.spacing(16)),
          decoration: BoxDecoration(
            color: NeoMiraiColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Responsive.radius(16)),
            border: Border.all(
              color: NeoMiraiColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(NeoMiraiColors.gold),
                ),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Expanded(
                child: Text(
                  'Update wajib sedang diterapkan...',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(13),
                    color: NeoMiraiColors.gold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.spacing(8)),
        Text(
          'Mohon tunggu, janganmatikan aplikasi',
          style: TextStyle(
            fontSize: Responsive.fontSize(11),
            color: NeoMiraiColors.inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildReadyToInstallActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _installApk,
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.success,
              foregroundColor: NeoMiraiColors.rice,
              padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
              elevation: 4,
              shadowColor: NeoMiraiColors.success.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.system_update_alt_rounded),
                SizedBox(width: Responsive.spacing(8)),
                Text(
                  _isMandatory ? 'Wajib Install Update' : 'Install Update',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        // Only show "Nanti" button for non-mandatory updates
        if (!_isMandatory) ...[
          SizedBox(height: Responsive.spacing(8)),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Nanti',
              style: TextStyle(color: NeoMiraiColors.ash),
            ),
          ),
        ],
        // Show warning for mandatory
        if (_isMandatory) ...[
          SizedBox(height: Responsive.spacing(8)),
          Container(
            padding: EdgeInsets.all(Responsive.spacing(12)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, size: 16, color: NeoMiraiColors.error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update ini wajib diinstall. Aplikasi tidak bisa digunakan sebelum update.',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(11),
                      color: NeoMiraiColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLaunchingActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.gold.withValues(alpha: 0.5),
              foregroundColor: NeoMiraiColors.ink,
              padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(NeoMiraiColors.ink),
                  ),
                ),
                SizedBox(width: Responsive.spacing(8)),
                Text(
                  'Membuka Installer...',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Responsive.spacing(8)),
        Text(
          'Selesaikan installasi di layar berikutnya',
          style: TextStyle(
            fontSize: Responsive.fontSize(12),
            color: NeoMiraiColors.inkSoft,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessActions() {
    // For mandatory patch updates, show success info with version and changelog
    if (_isPatch && _isMandatory) {
      return Column(
        children: [
          // Success info card with version and changelog
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Responsive.spacing(16)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
              border: Border.all(
                color: NeoMiraiColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 24,
                      color: NeoMiraiColors.success,
                    ),
                    SizedBox(width: Responsive.spacing(8)),
                    Text(
                      'Update Berhasil',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(16),
                        fontWeight: FontWeight.bold,
                        color: NeoMiraiColors.success,
                      ),
                    ),
                  ],
                ),
                if (widget.info.changelog.isNotEmpty) ...[
                  SizedBox(height: Responsive.spacing(12)),
                  Text(
                    widget.info.changelog,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(13),
                      color: NeoMiraiColors.ink,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(16)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onRestart?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoMiraiColors.success,
                foregroundColor: NeoMiraiColors.rice,
                padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded),
                  SizedBox(width: Responsive.spacing(8)),
                  const Text(
                    'Restart Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Default success actions for non-mandatory updates
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          widget.onRestart?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoMiraiColors.success,
          foregroundColor: NeoMiraiColors.rice,
          padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh_rounded),
            SizedBox(width: Responsive.spacing(8)),
            const Text(
              'Restart Aplikasi',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _startUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.gold,
              foregroundColor: NeoMiraiColors.ink,
              padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded),
                SizedBox(width: 8),
                Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        SizedBox(height: Responsive.spacing(8)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Tutup',
            style: TextStyle(color: NeoMiraiColors.ash),
          ),
        ),
      ],
    );
  }

  /// Update progress display
  void _updateProgress(double progress, String statusText) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _statusText = statusText;
      });
    }
  }

  /// Simulate progress updates for patch updates
  void _simulatePatchProgress() {
    // Simulate progress for better UX
    _updateProgress(0.1, 'Mengunduh patch...');
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _status == UpdateDialogStatus.applying) {
        _updateProgress(0.3, 'Memverifikasi integritas...');
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _status == UpdateDialogStatus.applying) {
        _updateProgress(0.5, 'Menerapkan perubahan...');
      }
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _status == UpdateDialogStatus.applying) {
        _updateProgress(0.7, 'Menyelesaikan instalasi...');
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _status == UpdateDialogStatus.applying) {
        _updateProgress(0.9, 'Menyimpan konfigurasi...');
      }
    });
  }

  Future<void> _startUpdate() async {
    setState(() {
      _status = widget.info.isPatch
          ? UpdateDialogStatus.applying
          : UpdateDialogStatus.downloading;
      _statusText = widget.info.isPatch
          ? 'Menerapkan patch...'
          : 'Memulai download...';
      _progress = 0;
    });

    try {
      // For APK updates with progress callback
      if (!widget.info.isPatch && widget.onApkDownloadWithProgress != null) {
        final result = await widget.onApkDownloadWithProgress!(
          _updateProgress,
        );

        if (result.downloadSuccess && result.filePath != null) {
          // Download complete, store file path and show install button
          setState(() {
            _status = UpdateDialogStatus.readyToInstall;
            _statusText = 'Download selesai!';
            _progress = 1.0;
            _downloadedFilePath = result.filePath;
          });
        } else {
          setState(() {
            _status = UpdateDialogStatus.error;
            _result = UpdateResult(
              success: false,
              message: result.error ?? 'Gagal download update',
            );
          });
        }
      }
      // For patch updates
      else if (widget.info.isPatch) {
        // Start progress simulation for patch update
        _simulatePatchProgress();

        final result = await widget.onUpdate(UpdateResult(
          success: false,
          message: '',
          updateType: widget.info.updateType,
        ));

        _result = result;

        if (result.success) {
          setState(() {
            _status = UpdateDialogStatus.success;
            _progress = 1.0;
            _statusText = 'Update berhasil!';
          });
        } else {
          setState(() {
            _status = UpdateDialogStatus.error;
          });
        }
      }
      // Fallback for APK without progress callback
      else {
        final result = await widget.onUpdate(UpdateResult(
          success: false,
          message: '',
          updateType: widget.info.updateType,
        ));

        _result = result;

        if (result.success) {
          setState(() {
            _status = UpdateDialogStatus.launching;
            _statusText = 'Installer dibuka...';
          });
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _status = UpdateDialogStatus.error;
          });
        }
      }
    } catch (e) {
      debugPrint('[UpdateDialog] Error: $e');
      setState(() {
        _status = UpdateDialogStatus.error;
        _result = UpdateResult(
          success: false,
          message: 'Terjadi kesalahan: $e',
        );
      });
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFilePath == null) {
      setState(() {
        _status = UpdateDialogStatus.error;
        _result = UpdateResult(
          success: false,
          message: 'File tidak ditemukan',
        );
      });
      return;
    }

    setState(() {
      _status = UpdateDialogStatus.launching;
      _statusText = 'Membersihkan data lama...';
    });

    // CRITICAL: Clear flutter_patcher BEFORE APK install
    // This ensures the new APK starts fresh without stale patches
    try {
      await PatchService.instance.prepareForApkUpdate();
      debugPrint('[UpdateDialog] Patch data cleared, opening installer...');
    } catch (e) {
      debugPrint('[UpdateDialog] Failed to clear patch data: $e');
      // Continue anyway - APK install should still work
    }

    // Notify parent that mandatory install was triggered
    if (_isMandatory && widget.onMandatoryInstallTriggered != null) {
      widget.onMandatoryInstallTriggered!();
    }

    try {
      // Call ApkUpdateService to install
      await ApkUpdateService.instance.installApk(
        filePath: _downloadedFilePath!,
        onProgress: (progress, status) {
          _updateProgress(progress, status);
        },
      );

      // For mandatory updates, DO NOT close dialog - user must complete install
      if (!_isMandatory && mounted) {
        Navigator.pop(context);
      }
      // For mandatory, keep dialog open with message
      if (_isMandatory) {
        setState(() {
          _statusText = 'TUNGGU - Selesaikan installasi APK terlebih dahulu';
        });
      }
    } catch (e) {
      debugPrint('[UpdateDialog] Install error: $e');
      setState(() {
        _status = UpdateDialogStatus.error;
        _result = UpdateResult(
          success: false,
          message: 'Gagal membuka installer: $e',
        );
      });
    }
  }
}

enum UpdateDialogStatus {
  idle,
  downloading,
  applying,
  readyToInstall,
  launching,
  success,
  error,
  install,
}

/// Helper function to show unified update dialog
Future<void> showUpdateDialog({
  required BuildContext context,
  required UpdateInfo info,
  required Function(UpdateResult) onUpdate,
  Future<ApkInstallCallbackResult> Function(
    Function(double progress, String statusText) onProgress,
  )? onApkDownloadWithProgress,
  VoidCallback? onMandatoryInstallTriggered,
  VoidCallback? onLater,
  VoidCallback? onRestart,
  bool barrierDismissible = true,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible && !info.isMandatory,
    builder: (context) => UpdateDialog(
      info: info,
      onUpdate: onUpdate,
      onApkDownloadWithProgress: onApkDownloadWithProgress,
      onMandatoryInstallTriggered: onMandatoryInstallTriggered,
      onLater: onLater,
      onRestart: onRestart,
    ),
  );
}
