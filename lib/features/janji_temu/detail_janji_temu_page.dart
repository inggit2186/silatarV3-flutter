import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../core/models/janji_temu_model.dart';

class DetailJanjiTemuPage extends StatefulWidget {
  final int appointmentId;

  const DetailJanjiTemuPage({super.key, required this.appointmentId});

  @override
  State<DetailJanjiTemuPage> createState() => _DetailJanjiTemuPageState();
}

class _DetailJanjiTemuPageState extends State<DetailJanjiTemuPage> {
  JanjiTemu? _appointment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getJanjiTemuDetail(widget.appointmentId);
      if (response.success && response.data != null) {
        setState(() {
          _appointment = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Gagal memuat detail janji temu';
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
                Text('Detail Janji Temu', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('#${_appointment?.id ?? '-'}', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_appointment == null) return _buildEmptyState();

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          SizedBox(height: Responsive.spacing(16)),
          _buildInfoCard(),
          SizedBox(height: Responsive.spacing(16)),
          _buildTargetCard(),
          SizedBox(height: Responsive.spacing(16)),
          _buildKeteranganCard(),
          if (_appointment!.komen != null && _appointment!.komen!.isNotEmpty) ...[
            SizedBox(height: Responsive.spacing(16)),
            _buildKomenCard(),
          ],
          if (_appointment!.canCancel == true) ...[
            SizedBox(height: Responsive.spacing(24)),
            _buildCancelButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor(_appointment!.status);
    final statusLabel = _appointment!.statusLabel ?? '-';

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
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(16)),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(_appointment!.status), size: Responsive.iconSize(40), color: statusColor),
          ),
          SizedBox(height: Responsive.spacing(12)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(16), vertical: Responsive.spacing(6)),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(20)),
            ),
            child: Text(statusLabel, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: statusColor)),
          ),
          if (_appointment!.staffPenangan != null) ...[
            SizedBox(height: Responsive.spacing(10)),
            Text('Ditangani oleh: ${_appointment!.staffPenangan}', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInfoCard() {
    return _buildCard(
      title: 'Informasi Janji Temu',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildInfoRow('ID', '#${_appointment!.id}'),
          _buildInfoRow('Waktu', _appointment!.waktuFormatted),
          _buildInfoRow('Tipe', _appointment!.tipe == 'asn' ? 'Ke Pegawai' : 'Ke Seksi'),
          _buildInfoRow('Dibuat', _formatDate(_appointment!.createdAt)),
        ],
      ),
    );
  }

  Widget _buildTargetCard() {
    // Helper to safely convert value to String
    String safeToString(dynamic value) {
      if (value == null) return '-';
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return _buildCard(
      title: 'Tujuan Pertemuan',
      icon: Icons.person_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_appointment!.targetNama ?? '-', style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          if (_appointment!.targetDetail != null) ...[
            SizedBox(height: Responsive.spacing(10)),
            if (_appointment!.tipe == 'asn') ...[
              _buildInfoRow('NIP', safeToString(_appointment!.targetDetail!['nip'])),
              _buildInfoRow('Jabatan', safeToString(_appointment!.targetDetail!['jabatan'])),
            ] else ...[
              _buildInfoRow('Unit Kerja', safeToString(_appointment!.targetDetail!['nama'])),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildKeteranganCard() {
    return _buildCard(
      title: 'Keperluan / Alasan',
      icon: Icons.description_rounded,
      child: Text(_appointment!.tujuan ?? '-', style: TextStyle(fontSize: Responsive.fontSize(13), color: NeoMiraiColors.ink, height: 1.5)),
    );
  }

  Widget _buildKomenCard() {
    return _buildCard(
      title: 'Keterangan / Komentar',
      icon: Icons.chat_bubble_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${_appointment!.komen}"', style: TextStyle(fontSize: Responsive.fontSize(13), fontStyle: FontStyle.italic, color: NeoMiraiColors.ink, height: 1.5)),
          if (_appointment!.staffPenangan != null) ...[
            SizedBox(height: Responsive.spacing(8)),
            Text('— ${_appointment!.staffPenangan}', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.ash)),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.radius(8)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                ),
                child: Icon(icon, size: Responsive.iconSize(18), color: NeoMiraiColors.gold),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Text(title, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            ],
          ),
          SizedBox(height: Responsive.spacing(16)),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.ash)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showCancelDialog(),
        icon: const Icon(Icons.cancel_rounded, size: 20),
        label: const Text('Batalkan Janji Temu'),
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoMiraiColors.error,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: Responsive.spacing(16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
        ),
      ),
    );
  }

  void _showCancelDialog() {
    final TextEditingController alasanController = TextEditingController(text: 'Dibatalkan oleh pengguna');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: NeoMiraiColors.error, size: 24),
            SizedBox(width: Responsive.spacing(8)),
            Text('Batalkan Janji Temu?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin membatalkan janji temu ini?'),
            SizedBox(height: Responsive.spacing(16)),
            TextField(
              controller: alasanController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alasan (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.radius(8))),
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
              Navigator.pop(context);
              await _cancelAppointment(alasanController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(8))),
            ),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(String alasan) async {
    try {
      final response = await ApiService.instance.cancelJanjiTemu(widget.appointmentId, alasan: alasan);
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Janji temu berhasil dibatalkan'),
              backgroundColor: NeoMiraiColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
          _loadDetail();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal membatalkan janji temu'),
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
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    return switch (status) {
      'APPOINTMENT' => NeoMiraiColors.warning,
      'PENDING' => NeoMiraiColors.info,
      'APPROVED' => NeoMiraiColors.success,
      'REJECTED' => NeoMiraiColors.error,
      'CANCELLED' => NeoMiraiColors.ash,
      _ => NeoMiraiColors.ash,
    };
  }

  IconData _getStatusIcon(String? status) {
    return switch (status) {
      'APPOINTMENT' => Icons.schedule_rounded,
      'PENDING' => Icons.pending_rounded,
      'APPROVED' => Icons.check_circle_rounded,
      'REJECTED' => Icons.cancel_rounded,
      'CANCELLED' => Icons.event_busy_rounded,
      _ => Icons.help_outline_rounded,
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NeoMiraiColors.gold),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat detail janji temu...', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
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
              onPressed: _loadDetail,
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
                color: NeoMiraiColors.ash.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.ash),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Data Tidak Ditemukan', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          ],
        ),
      ),
    );
  }
}
