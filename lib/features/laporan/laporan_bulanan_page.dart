import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/models/ckh_bulanan_model.dart';
import '../../core/services/kegiatan_service.dart';
import '../kegiatan/widgets/pdf_preview_page.dart';

/// Halaman Laporan CKH Bulanan
class LaporanBulananPage extends StatefulWidget {
  const LaporanBulananPage({super.key});

  @override
  State<LaporanBulananPage> createState() => _LaporanBulananPageState();
}

class _LaporanBulananPageState extends State<LaporanBulananPage> {
  late String _selectedYear;
  List<CkhBulanan> _reports = [];
  CkhBulananStats _stats = CkhBulananStats();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year.toString();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await KegiatanService.instance.getBulanan(year: _selectedYear);

      if (response.success && response.data != null) {
        final reportsData = response.data!['reports'] as List? ?? [];
        _reports = reportsData.map((r) => CkhBulanan.fromJson(r)).toList();
        _stats = CkhBulananStats.fromJson(response.data!['stats'] ?? {});
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onYearChanged(String year) {
    setState(() {
      _selectedYear = year;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildYearSelector(),
            _buildStatsSection(),
            Expanded(
              child: _buildReportsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.spacing(10)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              boxShadow: [
                BoxShadow(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.assessment_rounded,
              size: Responsive.iconSize(22),
              color: Colors.white,
            ),
          ),
          SizedBox(width: Responsive.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Laporan CKH Bulanan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(16),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                  ),
                ),
                SizedBox(height: Responsive.spacing(2)),
                Text(
                  'Rekap laporan kinerja bulanan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(10),
                    color: NeoMiraiColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(6),
      ),
      child: GestureDetector(
        onTap: () => _showYearPicker(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(14),
            vertical: Responsive.spacing(10),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            boxShadow: [
              BoxShadow(
                color: NeoMiraiColors.ink.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: const Color(0xFF1565C0),
                size: Responsive.iconSize(18),
              ),
              SizedBox(width: Responsive.spacing(10)),
              Expanded(
                child: Text(
                  'Tahun $_selectedYear',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: Responsive.iconSize(20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(8),
      ),
      child: Row(
        children: [
          _buildStatCard(
            '${_stats.total}',
            'Total',
            Icons.assessment_rounded,
            const Color(0xFF1565C0),
          ),
          SizedBox(width: Responsive.spacing(8)),
          _buildStatCard(
            '${_stats.disetujui}',
            'Disetujui',
            Icons.check_circle_rounded,
            const Color(0xFF2E7D32),
          ),
          SizedBox(width: Responsive.spacing(8)),
          _buildStatCard(
            '${_stats.dikirim}',
            'Dikirim',
            Icons.send_rounded,
            const Color(0xFFF57C00),
          ),
          SizedBox(width: Responsive.spacing(8)),
          _buildStatCard(
            '${_stats.ditolak}',
            'Ditolak',
            Icons.cancel_rounded,
            const Color(0xFFD32F2F),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(6),
          vertical: Responsive.spacing(8),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: Responsive.iconSize(16)),
            SizedBox(height: Responsive.spacing(4)),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.fontSize(14),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(9),
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_reports.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(12)),
      child: Column(
        children: [
          _buildTableHeader(),
          ..._reports.asMap().entries.map((entry) =>
            _buildReportRow(entry.key + 1, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(12),
        vertical: Responsive.spacing(10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.radius(12)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              'No',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Bulan',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'File',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(int index, CkhBulanan report) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(12),
        vertical: Responsive.spacing(10),
      ),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(10),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  report.bulan,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(11),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: _buildStatusChip(report),
              ),
              Expanded(
                flex: 2,
                child: _buildFileChip(report),
              ),
            ],
          ),
          // Keterangan under status
          if (report.alasan != null && report.alasan!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: Responsive.spacing(42),
                top: Responsive.spacing(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: Responsive.iconSize(12),
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: Responsive.spacing(4)),
                  Expanded(
                    child: Text(
                      report.alasan!,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(10),
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileChip(CkhBulanan report) {
    if (!report.hasPdf) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(6),
          vertical: Responsive.spacing(2),
        ),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Responsive.radius(6)),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Text(
          '-',
          style: TextStyle(
            fontSize: Responsive.fontSize(10),
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return InkWell(
      onTap: () => _viewPdf(report),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(6),
          vertical: Responsive.spacing(2),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Responsive.radius(6)),
          border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: Responsive.iconSize(12),
              color: const Color(0xFF1565C0),
            ),
            SizedBox(width: Responsive.spacing(4)),
            Text(
              'PDF',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CkhBulanan report) {
    Color color;
    switch (report.statusColor) {
      case 'emerald':
        color = const Color(0xFF2E7D32);
        break;
      case 'amber':
        color = const Color(0xFFF57C00);
        break;
      case 'rose':
        color = const Color(0xFFD32F2F);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(6),
        vertical: Responsive.spacing(2),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(6)),
      ),
      child: Text(
        report.statusLabel,
        style: TextStyle(
          fontSize: Responsive.fontSize(9),
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: const Color(0xFF1565C0)),
          SizedBox(height: Responsive.spacing(16)),
          Text(
            'Memuat data...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Responsive.fontSize(13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
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
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assessment_rounded,
                size: Responsive.iconSize(48),
                color: const Color(0xFF1565C0),
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text(
              'Belum Ada Laporan',
              style: TextStyle(
                fontSize: Responsive.fontSize(15),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              'Tidak ada data laporan kinerja pada tahun $_selectedYear',
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

  Future<void> _showYearPicker() async {
    final currentYear = int.parse(_selectedYear);
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => _YearPickerDialog(initialYear: currentYear),
    );

    if (picked != null) {
      _onYearChanged(picked.toString());
    }
  }

  Future<void> _viewPdf(CkhBulanan report) async {
    if (report.pdfUrl == null) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
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
                const CircularProgressIndicator(color: Color(0xFF1565C0)),
                SizedBox(height: Responsive.spacing(16)),
                Text(
                  'Memuat PDF...',
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
    }

    try {
      // Fetch PDF from URL
      final response = await http.get(Uri.parse(report.pdfUrl!));

      // Close loading
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        // Navigate to PDF preview
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfPreviewPage(
                pdfBytes: response.bodyBytes,
                title: 'CKH ${report.bulan}',
                filename: report.filename ?? 'ckh_${report.bulanRaw}.pdf',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog untuk memilih tahun
class _YearPickerDialog extends StatefulWidget {
  final int initialYear;

  const _YearPickerDialog({required this.initialYear});

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
      ),
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Tahun',
              style: TextStyle(
                fontSize: Responsive.fontSize(16),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear--;
                    });
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: const Color(0xFF1565C0),
                ),
                Text(
                  '$_selectedYear',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(24),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedYear++;
                    });
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
            SizedBox(height: Responsive.spacing(16)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                SizedBox(width: Responsive.spacing(12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedYear),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                    ),
                    child: const Text('Pilih'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
