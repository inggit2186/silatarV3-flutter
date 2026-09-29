import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/update_service.dart';
import '../theme/neo_mirai_theme.dart';
import '../utils/responsive.dart';

/// Unified Update Dialog for both Patch and APK updates
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final Function(UpdateResult) onUpdate;
  final VoidCallback? onLater;
  final VoidCallback? onRestart;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.onUpdate,
    this.onLater,
    this.onRestart,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateDialogStatus _status = UpdateDialogStatus.idle;
  double _progress = 0;
  String _statusText = 'Menunggu...';
  UpdateResult? _result;

  bool get _isPatch => widget.info.isPatch;
  bool get _isMandatory => widget.info.isMandatory;

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
      case UpdateDialogStatus.success:
        title = 'Update Berhasil!';
        break;
      case UpdateDialogStatus.error:
        title = 'Update Gagal';
        break;
      case UpdateDialogStatus.install:
        title = 'Siap di Install';
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
        color: (isPatch ? NeoMiraiColors.gold : NeoMiraiColors.gold)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        border: Border.all(
          color: (isPatch ? NeoMiraiColors.gold : NeoMiraiColors.gold)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPatch ? Icons.bolt_rounded : Icons.android_rounded,
            size: 14,
            color: isPatch ? NeoMiraiColors.gold : NeoMiraiColors.gold,
          ),
          SizedBox(width: 4),
          Text(
            isPatch ? 'Patch' : 'Full APK',
            style: TextStyle(
              fontSize: Responsive.fontSize(10),
              fontWeight: FontWeight.w600,
              color: isPatch ? NeoMiraiColors.gold : NeoMiraiColors.gold,
            ),
          ),
        ],
      ),
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
        // Size indicator
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
              SizedBox(width: 8),
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
        // Changelog
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
                SizedBox(width: 8),
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
                SizedBox(width: 12),
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
                  SizedBox(width: 8),
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
            SizedBox(width: 12),
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

    // Progress view
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: NeoMiraiColors.line.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(NeoMiraiColors.gold),
            minHeight: 10,
          ),
        ),
        SizedBox(height: Responsive.spacing(12)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _statusText,
              style: TextStyle(
                fontSize: Responsive.fontSize(13),
                color: NeoMiraiColors.inkSoft,
              ),
            ),
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
      case UpdateDialogStatus.success:
        return _buildSuccessActions();
      case UpdateDialogStatus.error:
        return _buildErrorActions();
      case UpdateDialogStatus.install:
        return _buildInstallActions();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdleActions() {
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
              children: [
                Icon(
                  _isPatch ? Icons.bolt_rounded : Icons.download_rounded,
                  size: Responsive.iconSize(18),
                ),
                SizedBox(width: Responsive.spacing(8)),
                Text(
                  _isPatch ? 'Update Sekarang' : 'Download Update',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          if (widget.onRestart != null) {
            widget.onRestart!();
          }
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

  Widget _buildInstallActions() {
    return SizedBox(
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
            Icon(Icons.open_in_new_rounded),
            SizedBox(width: 8),
            Text('Buka Installer', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _startUpdate() async {
    setState(() {
      _status = widget.info.isPatch
          ? UpdateDialogStatus.applying
          : UpdateDialogStatus.downloading;
      _statusText = widget.info.isPatch
          ? 'Menerapkan patch...'
          : 'Mengunduh update...';
      _progress = 0;
    });

    try {
      final result = await widget.onUpdate(UpdateResult(
        success: false,
        message: '',
        updateType: widget.info.updateType,
      ));

      _result = result;

      if (result.success) {
        setState(() {
          _status = UpdateDialogStatus.success;
        });

        // Auto restart after success for patch updates
        if (widget.info.isPatch) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context);
            widget.onRestart?.call();
          }
        }
      } else {
        setState(() {
          _status = UpdateDialogStatus.error;
        });
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

  /// Update progress from external source (e.g., download progress)
  void updateProgress(double progress, String text) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _statusText = text;
      });
    }
  }
}

enum UpdateDialogStatus {
  idle,
  downloading,
  applying,
  success,
  error,
  install,
}

/// Helper function to show unified update dialog
Future<void> showUpdateDialog({
  required BuildContext context,
  required UpdateInfo info,
  required Function(UpdateResult) onUpdate,
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
      onLater: onLater,
      onRestart: onRestart,
    ),
  );
}
