import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/neo_mirai_theme.dart';
import '../utils/responsive.dart';

class UpdateDialog extends StatelessWidget {
  final String version;
  final String changelog;
  final bool isMandatory;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.changelog,
    required this.isMandatory,
    required this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(Responsive.cardPadding(24)),
          decoration: BoxDecoration(
            color: NeoMiraiColors.rice,
            borderRadius: BorderRadius.circular(Responsive.radius(24)),
            border: Border.all(
              color: NeoMiraiColors.gold.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: NeoMiraiColors.gold.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Update Icon
              Container(
                padding: EdgeInsets.all(Responsive.radius(16)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      NeoMiraiColors.goldBright,
                      NeoMiraiColors.gold,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NeoMiraiColors.gold.withValues(alpha: 0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  size: Responsive.iconSize(36),
                  color: NeoMiraiColors.rice,
                ),
              ),

              SizedBox(height: Responsive.spacing(20)),

              // Title
              Text(
                'Update Tersedia!',
                style: TextStyle(
                  fontSize: Responsive.fontSize(20),
                  fontWeight: FontWeight.bold,
                  color: NeoMiraiColors.ink,
                ),
              ),

              SizedBox(height: Responsive.spacing(8)),

              // Version Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.spacing(16),
                  vertical: Responsive.spacing(6),
                ),
                decoration: BoxDecoration(
                  gradient: NeoMiraiTheme.nightGradient,
                  borderRadius: BorderRadius.circular(Responsive.radius(20)),
                ),
                child: Text(
                  'v$version',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(12),
                    fontWeight: FontWeight.w600,
                    color: NeoMiraiColors.gold,
                  ),
                ),
              ),

              SizedBox(height: Responsive.spacing(16)),

              // Changelog
              if (changelog.isNotEmpty)
                Container(
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
                        changelog,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(13),
                          color: NeoMiraiColors.ink,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: Responsive.spacing(24)),

              // Buttons
              Row(
                children: [
                  if (!isMandatory && onLater != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onLater,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: Responsive.spacing(14),
                          ),
                          side: BorderSide(
                            color: NeoMiraiColors.ash,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.radius(12)),
                          ),
                        ),
                        child: Text(
                          'Nanti',
                          style: TextStyle(
                            color: NeoMiraiColors.ash,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.spacing(12)),
                  ],
                  Expanded(
                    flex: isMandatory ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: onUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NeoMiraiColors.gold,
                        foregroundColor: NeoMiraiColors.ink,
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.spacing(14),
                        ),
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
                            Icons.download_rounded,
                            size: Responsive.iconSize(18),
                          ),
                          SizedBox(width: Responsive.spacing(8)),
                          Text(
                            'Update Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (isMandatory)
                Padding(
                  padding: EdgeInsets.only(top: Responsive.spacing(12)),
                  child: Text(
                    'Update wajib untuk melanjutkan aplikasi',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(10),
                      color: NeoMiraiColors.inkSoft,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show update dialog
Future<void> showUpdateDialog({
  required BuildContext context,
  required String version,
  required String downloadUrl,
  String changelog = '',
  bool isMandatory = false,
  VoidCallback? onLater,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: !isMandatory,
    builder: (context) => UpdateDialog(
      version: version,
      changelog: changelog,
      isMandatory: isMandatory,
      onUpdate: () {
        Navigator.pop(context);
        // Copy URL to clipboard and show message
        Clipboard.setData(ClipboardData(text: downloadUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: NeoMiraiColors.rice),
                SizedBox(width: Responsive.spacing(12)),
                Expanded(
                  child: Text(
                    'Link download sudah dicopy. Buka browser dan paste untuk download.',
                    style: TextStyle(color: NeoMiraiColors.rice),
                  ),
                ),
              ],
            ),
            backgroundColor: NeoMiraiColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      onLater: onLater,
    ),
  );
}
