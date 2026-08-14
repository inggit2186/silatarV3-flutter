import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import 'acara_presensi_page.dart';

class AcaraDetailPage extends StatefulWidget {
  final int acaraId;

  const AcaraDetailPage({super.key, required this.acaraId});

  @override
  State<AcaraDetailPage> createState() => _AcaraDetailPageState();
}

class _AcaraDetailPageState extends State<AcaraDetailPage> {
  Map<String, dynamic>? _acara;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAcaraDetail();
  }

  Future<void> _loadAcaraDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getAcaraList();
      // We need to get the detail from the list or make a separate call
      if (response.success && response.data != null) {
        final acaraList = List<Map<String, dynamic>>.from(response.data!);
        final acara = acaraList.firstWhere(
          (a) => a['id'] == widget.acaraId,
          orElse: () => {},
        );

        if (acara.isNotEmpty) {
          setState(() {
            _acara = acara;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Acara tidak ditemukan';
            _isLoading = false;
          });
        }
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

  void _showHadirDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: NeoMiraiColors.success, size: 24),
            SizedBox(width: Responsive.spacing(8)),
            const Expanded(child: Text('Konfirmasi Kehadiran')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anda akan mengkonfirmasi kehadiran pada acara ini.'),
            SizedBox(height: Responsive.spacing(12)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(12)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(8)),
                border: Border.all(color: NeoMiraiColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: NeoMiraiColors.success),
                  SizedBox(width: Responsive.spacing(8)),
                  Expanded(
                    child: Text(
                      'Lokasi Anda akan dicatat sebagai bukti kehadiran.',
                      style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: NeoMiraiColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AcaraPresensiPage(
                    acaraId: widget.acaraId,
                    judul: _acara?['judul'] ?? '-',
                    acaraLatitude: _acara?['latitude']?.toDouble(),
                    acaraLongitude: _acara?['longitude']?.toDouble(),
                    acaraRadius: _acara?['radius'],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hadir'),
          ),
        ],
      ),
    );
  }

  void _showTidakHadirDialog() {
    final TextEditingController keteranganController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
        title: Row(
          children: [
            Icon(Icons.cancel_rounded, color: NeoMiraiColors.error, size: 24),
            SizedBox(width: Responsive.spacing(8)),
            const Expanded(child: Text('Tidak Hadir')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anda akan mengirimkan keterangan tidak hadir.'),
            SizedBox(height: Responsive.spacing(12)),
            TextField(
              controller: keteranganController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan tidak hadir...',
                hintStyle: TextStyle(color: NeoMiraiColors.ash),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  borderSide: BorderSide(color: NeoMiraiColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  borderSide: BorderSide(color: NeoMiraiColors.gold, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: NeoMiraiColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (keteranganController.text.isNotEmpty) {
                Navigator.pop(context);
                await _submitTidakHadir(keteranganController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTidakHadir(String keterangan) async {
    try {
      final response = await ApiService.instance.submitTidakHadir(
        widget.acaraId,
        keterangan: keterangan,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Keterangan berhasil dikirim'),
              backgroundColor: NeoMiraiColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
          _loadAcaraDetail();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal mengirim keterangan'),
              backgroundColor: NeoMiraiColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
          ),
        );
      }
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
                        : _buildContent(),
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
            child: Icon(Icons.event_note_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail Acara', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text(_acara?['judul'] ?? '-', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_acara == null) return _buildEmptyState();

    final judul = _acara!['judul'] ?? '-';
    final tanggal = _acara!['tanggal'] ?? '-';
    final jamMulai = _acara!['jam_mulai'] ?? '-';
    final jamSelesai = _acara!['jam_selesei'] ?? '-';
    final lokasi = _acara!['lokasi'] ?? '-';
    final deskripsi = _acara!['deskripsi'] ?? '-';
    final filename = _acara!['filename'];
    final statusKehadiran = _acara!['status_kehadiran'];
    final sudahPresensi = _acara!['sudah_presensi'] ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Photo
          if (filename != null && filename.toString().isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: Responsive.spacing(16)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.radius(16)),
                boxShadow: [
                  BoxShadow(
                    color: NeoMiraiColors.ink.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.radius(16)),
                child: Image.network(
                  'http://127.0.0.1:8000/storage/acara/$filename',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: NeoMiraiColors.paperSoft,
                    child: Center(
                      child: Icon(Icons.image_not_supported_rounded, size: 48, color: NeoMiraiColors.ash),
                    ),
                  ),
                ),
              ),
            ),

          // Acara Info Card
          _buildInfoCard(judul, tanggal, jamMulai, jamSelesai, lokasi, deskripsi),

          SizedBox(height: Responsive.spacing(20)),

          // Status Kehadiran
          if (sudahPresensi)
            _buildStatusCard(statusKehadiran, _acara!['keterangan_kehadiran'])
          else
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String judul, String tanggal, String jamMulai, String jamSelesai, String lokasi, String deskripsi) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(20)),
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
          // Title
          Text(judul, style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(16)),

          _buildInfoRow(Icons.calendar_today_rounded, 'Tanggal', tanggal),
          SizedBox(height: Responsive.spacing(8)),
          _buildInfoRow(Icons.access_time_rounded, 'Waktu', '$jamMulai - $jamSelesai'),
          SizedBox(height: Responsive.spacing(8)),
          _buildInfoRow(Icons.location_on_rounded, 'Lokasi', lokasi),

          if (deskripsi.isNotEmpty) ...[
            SizedBox(height: Responsive.spacing(12)),
            Divider(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
            SizedBox(height: Responsive.spacing(8)),
            Text('Deskripsi', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ash)),
            SizedBox(height: Responsive.spacing(4)),
            Text(deskripsi, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.ink)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
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

  Widget _buildStatusCard(String? status, String? keterangan) {
    final isHadir = status == 'hadir';
    final statusColor = isHadir ? NeoMiraiColors.success : NeoMiraiColors.error;
    final statusLabel = isHadir ? 'Hadir' : 'Tidak Hadir';
    final icon = isHadir ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(20)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(16)),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: statusColor),
          ),
          SizedBox(height: Responsive.spacing(12)),
          Text(statusLabel, style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: statusColor)),
          if (keterangan != null && keterangan.isNotEmpty) ...[
            SizedBox(height: Responsive.spacing(8)),
            Text(keterangan, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(20)),
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
          Text('Kehadiran', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(16)),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showHadirDialog,
                  icon: Icon(Icons.check_rounded, size: 20),
                  label: Text('Hadir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoMiraiColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
                  ),
                ),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showTidakHadirDialog,
                  icon: Icon(Icons.close_rounded, size: 20),
                  label: Text('Tidak Hadir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoMiraiColors.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NeoMiraiColors.gold),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat detail acara...', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
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
              onPressed: _loadAcaraDetail,
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
            Text('Acara Tidak Ditemukan', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          ],
        ),
      ),
    );
  }
}
