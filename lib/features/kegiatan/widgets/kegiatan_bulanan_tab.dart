import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/neo_mirai_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/providers/kegiatan_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/kegiatan_model.dart';
import '../../../core/services/kegiatan_service.dart';
import '../widgets/pdf_preview_page.dart';

/// Tab untuk menampilkan rekap kegiatan bulanan
class KegiatanBulananTab extends StatefulWidget {
  const KegiatanBulananTab({super.key});

  @override
  State<KegiatanBulananTab> createState() => _KegiatanBulananTabState();
}

class _KegiatanBulananTabState extends State<KegiatanBulananTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<KegiatanProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingState();
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        final rekap = provider.rekap;
        if (rekap == null || provider.dailyGroups.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.spacing(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRekapHeader(provider.formattedMonth),
              SizedBox(height: Responsive.spacing(16)),
              _buildStatsSection(rekap),
              SizedBox(height: Responsive.spacing(16)),
              _buildDownloadPdfButton(provider.selectedMonth),
              SizedBox(height: Responsive.spacing(24)),
              _buildRecentActivity(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRekapHeader(String month) {
    return Row(
      children: [
        Icon(
          Icons.assessment_rounded,
          color: const Color(0xFFEF6C00),
          size: Responsive.iconSize(24),
        ),
        SizedBox(width: Responsive.spacing(8)),
        Text(
          'Rekap $month',
          style: TextStyle(
            fontSize: Responsive.fontSize(18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(KegiatanRekap rekap) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(14)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.check_circle_rounded,
            label: 'Total Kegiatan',
            value: '${rekap.totalEntries}',
            color: const Color(0xFF2E7D32),
          ),
          Divider(height: Responsive.spacing(24)),
          _buildStatRow(
            icon: Icons.calendar_today_rounded,
            label: 'Hari Terisi',
            value: '${rekap.totalDays} hari',
            color: const Color(0xFFEF6C00),
          ),
          Divider(height: Responsive.spacing(24)),
          _buildStatRow(
            icon: Icons.inventory_rounded,
            label: 'Total Volume',
            value: '${rekap.totalVolume}',
            color: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadPdfButton(String month) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _downloadPdf(month),
        icon: Icon(
          Icons.picture_as_pdf_rounded,
          size: Responsive.iconSize(20),
        ),
        label: Text(
          'Download PDF',
          style: TextStyle(
            fontSize: Responsive.fontSize(14),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(String month) async {
    final ctx = context;
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);
    final navigator = Navigator.of(ctx);
    final userProvider = ctx.read<UserProvider>();
    final user = userProvider.user;

    // Check if user has special dept_id (998/999)
    final specialDeptIds = [998, 999];
    final deptId = user?.dept?.id;
    final isSpecialDept = deptId != null && specialDeptIds.contains(deptId);

    if (isSpecialDept) {
      // Show dialog to input supervisor name and NIP
      final result = await _showSupervisorInputDialog(ctx);
      if (result == null) {
        // User cancelled
        return;
      }
      // Show loading and generate PDF with supervisor info
      _generatePdfWithLoading(ctx, month, scaffoldMessenger, navigator,
          signatureName: result['name'],
          signatureNip: result['nip']);
    } else {
      // Show loading and generate PDF without supervisor info
      _generatePdfWithLoading(ctx, month, scaffoldMessenger, navigator);
    }
  }

  Future<Map<String, String>?> _showSupervisorInputDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final nipController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add_rounded, color: const Color(0xFFEF6C00)),
            SizedBox(width: Responsive.spacing(8)),
            Text(
              'Input Atasan',
              style: TextStyle(fontSize: Responsive.fontSize(16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan data atasan untuk penandatanganan PDF:',
                style: TextStyle(
                  fontSize: Responsive.fontSize(12),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: Responsive.spacing(16)),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Atasan *',
                  hintText: 'Contoh: Drs. H. Ahmad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                  ),
                ),
              ),
              SizedBox(height: Responsive.spacing(12)),
              TextField(
                controller: nipController,
                decoration: InputDecoration(
                  labelText: 'NIP *',
                  hintText: 'Contoh: 196501011990031004',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || nipController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Nama dan NIP harus diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                'name': nameController.text,
                'nip': nipController.text,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6C00),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdfWithLoading(
    BuildContext ctx,
    String month,
    ScaffoldMessengerState scaffoldMessenger,
    NavigatorState navigator, {
    String? signatureName,
    String? signatureNip,
  }) async {
    // Show loading
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: EdgeInsets.all(Responsive.spacing(24)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.radius(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFD32F2F)),
              SizedBox(height: Responsive.spacing(16)),
              Text(
                'Generating PDF...',
                style: TextStyle(
                  fontSize: Responsive.fontSize(13),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await KegiatanService.instance.downloadPdf(
        month: month,
        signatureName: signatureName,
        signatureNip: signatureNip,
      );

      // Close loading dialog
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (response.success && response.data != null) {
        // Navigate to PDF preview
        navigator.push(
          MaterialPageRoute(
            builder: (_) => PdfPreviewPage(
              pdfBytes: response.data!,
              title: 'Laporan CKH - $month',
              filename: 'Laporan_CKH_$month.pdf',
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Gagal generate PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (navigator.canPop()) {
        navigator.pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.spacing(10)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Responsive.radius(10)),
          ),
          child: Icon(
            icon,
            color: color,
            size: Responsive.iconSize(24),
          ),
        ),
        SizedBox(width: Responsive.spacing(16)),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSize(14),
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.fontSize(18),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(KegiatanProvider provider) {
    final recentGroups = provider.dailyGroups.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivitas Terakhir',
          style: TextStyle(
            fontSize: Responsive.fontSize(16),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: Responsive.spacing(12)),
        ...recentGroups.map((group) => _buildActivityCard(group)),
      ],
    );
  }

  Widget _buildActivityCard(KegiatanHarian group) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.spacing(8)),
      padding: EdgeInsets.all(Responsive.spacing(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_rounded,
            color: const Color(0xFFEF6C00),
            size: Responsive.iconSize(20),
          ),
          SizedBox(width: Responsive.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.label,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.spacing(2)),
                Text(
                  '${group.items.length} kegiatan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(11),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(8),
              vertical: Responsive.spacing(4),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(6)),
            ),
            child: Text(
              '${group.volume} vol',
              style: TextStyle(
                fontSize: Responsive.fontSize(11),
                color: const Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFFEF6C00),
          ),
          SizedBox(height: Responsive.spacing(16)),
          Text(
            'Memuat rekap...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.fontSize(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: Responsive.iconSize(48),
                color: Colors.red,
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: Responsive.fontSize(15),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assessment_rounded,
                size: Responsive.iconSize(48),
                color: const Color(0xFFEF6C00),
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text(
              'Belum Ada Data',
              style: TextStyle(
                fontSize: Responsive.fontSize(15),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              'Mulai tambahkan kegiatan untuk melihat rekap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
