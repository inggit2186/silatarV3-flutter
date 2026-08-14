import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import 'acara_detail_page.dart';

class AcaraListPage extends StatefulWidget {
  const AcaraListPage({super.key});

  @override
  State<AcaraListPage> createState() => _AcaraListPageState();
}

class _AcaraListPageState extends State<AcaraListPage> {
  List<Map<String, dynamic>> _acaraList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAcara();
  }

  Future<void> _loadAcara() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getAcaraList();

      if (response.success && response.data != null) {
        setState(() {
          _acaraList = List<Map<String, dynamic>>.from(response.data!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Gagal memuat data acara';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: NeoMiraiTheme.paperGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildAcaraList(),
              ),
            ],
          ),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice,
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.arrow_back_rounded, size: Responsive.iconSize(20), color: NeoMiraiColors.ink),
            ),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Container(
            padding: EdgeInsets.all(Responsive.radius(12)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.event_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acara Kankemenag', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Daftar kegiatan kantor', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcaraList() {
    if (_acaraList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAcara,
      child: ListView.builder(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        itemCount: _acaraList.length,
        itemBuilder: (context, index) => _buildAcaraCard(_acaraList[index], index),
      ),
    );
  }

  Widget _buildAcaraCard(Map<String, dynamic> acara, int index) {
    final judul = acara['judul'] ?? '-';
    final tanggal = acara['tanggal'] ?? '-';
    final jamMulai = acara['jam_mulai'] ?? '-';
    final jamSelesai = acara['jam_selesei'] ?? '-';
    final lokasi = acara['lokasi'] ?? '-';
    final deskripsi = acara['deskripsi'] ?? '-';
    final statusKehadiran = acara['status_kehadiran'];
    final sudahPresensi = acara['sudah_presensi'] ?? false;

    Color statusColor;
    String statusLabel;

    if (sudahPresensi) {
      if (statusKehadiran == 'hadir') {
        statusColor = NeoMiraiColors.success;
        statusLabel = 'Hadir';
      } else {
        statusColor = NeoMiraiColors.error;
        statusLabel = 'Tidak Hadir';
      }
    } else {
      statusColor = NeoMiraiColors.warning;
      statusLabel = 'Belum Presensi';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AcaraDetailPage(acaraId: acara['id']),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.spacing(12)),
        padding: EdgeInsets.all(Responsive.spacing(16)),
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(16)),
          border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.ink.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(10), vertical: Responsive.spacing(4)),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: statusColor)),
                ),
                SizedBox(width: Responsive.spacing(8)),
                Expanded(
                  child: Text(judul, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
                ),
              ],
            ),
            SizedBox(height: Responsive.spacing(12)),
            _buildInfoRow(Icons.calendar_today_rounded, 'Tanggal', tanggal),
            SizedBox(height: Responsive.spacing(6)),
            _buildInfoRow(Icons.access_time_rounded, 'Waktu', '$jamMulai - $jamSelesai'),
            SizedBox(height: Responsive.spacing(6)),
            _buildInfoRow(Icons.location_on_rounded, 'Lokasi', lokasi),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: Responsive.iconSize(14), color: NeoMiraiColors.ash),
        SizedBox(width: Responsive.spacing(8)),
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.ash)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.ink)),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NeoMiraiColors.gold),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat data acara...', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.error),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Gagal Memuat', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(6)),
            Text(_errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(24)),
            ElevatedButton.icon(
              onPressed: _loadAcara,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoMiraiColors.gold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(20), vertical: Responsive.spacing(12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
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
        padding: EdgeInsets.all(Responsive.cardPadding(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.gold),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Tidak Ada Acara', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(6)),
            Text('Tidak ada acara yang tersedia saat ini', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
