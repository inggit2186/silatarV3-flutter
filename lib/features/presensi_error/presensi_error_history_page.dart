import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';

class PresensiErrorHistoryPage extends StatefulWidget {
  const PresensiErrorHistoryPage({super.key});

  @override
  State<PresensiErrorHistoryPage> createState() => _PresensiErrorHistoryPageState();
}

class _PresensiErrorHistoryPageState extends State<PresensiErrorHistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDownloading = false;
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getPresensiErrorHistory();

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        if (data is List) {
          setState(() {
            _history = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        } else {
          setState(() {
            _history = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Gagal memuat data';
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

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'SISTEM_ERROR':
        return 'Sistem Error';
      case 'TUGAS_LUAR':
        return 'Tugas Luar';
      case 'LUPA_PRESNSI_PUSAKA':
        return 'Lupa Presensi';
      default:
        return status ?? '-';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'SISTEM_ERROR':
        return NeoMiraiColors.error;
      case 'TUGAS_LUAR':
        return NeoMiraiColors.warning;
      case 'LUPA_PRESNSI_PUSAKA':
        return Colors.purple;
      default:
        return NeoMiraiColors.inkSoft;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'SISTEM_ERROR':
        return Icons.computer_rounded;
      case 'TUGAS_LUAR':
        return Icons.directions_run_rounded;
      case 'LUPA_PRESNSI_PUSAKA':
        return Icons.schedule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _downloadSurat(String id) async {
    setState(() {
      _isDownloading = true;
      _downloadingId = id;
    });

    try {
      final baseUrl = 'https://kemenagtanahdatar.id';
      final url = Uri.parse('$baseUrl/presensi-error/cetak/$id');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Tidak bisa membuka link')),
                ],
              ),
              backgroundColor: NeoMiraiColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal download: $e')),
              ],
            ),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadingId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: NeoMiraiColors.paperSoft,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _history.isEmpty
                        ? _buildEmptyState()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: Responsive.cardPadding(16),
        right: Responsive.cardPadding(16),
        top: Responsive.spacing(MediaQuery.of(context).padding.top + 12),
        bottom: Responsive.spacing(12),
      ),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        boxShadow: [
          BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.paperSoft,
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
              ),
              child: Icon(Icons.arrow_back_rounded, size: Responsive.iconSize(22), color: NeoMiraiColors.ink),
            ),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Container(
            padding: EdgeInsets.all(Responsive.radius(10)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.history_rounded, size: Responsive.iconSize(22), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Presensi Error', style: TextStyle(fontSize: Responsive.fontSize(17), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                Text('Daftar pengajuan yang telah dibuat', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: NeoMiraiColors.gold,
      child: ListView.builder(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _buildHistoryCard(item, index);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, int index) {
    final status = item['status'] as String?;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusLabel = _getStatusLabel(status);

    String tanggal = '-';
    if (item['tanggal'] != null) {
      try {
        final date = DateTime.parse(item['tanggal'].toString());
        tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
      } catch (e) {
        tanggal = item['tanggal'].toString();
      }
    }

    final mAbsen = item['m_absen'] as String?;
    final pAbsen = item['p_absen'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.spacing(12)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(14)),
        boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(Responsive.spacing(14)),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(14))),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.radius(8)),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  ),
                  child: Icon(statusIcon, size: Responsive.iconSize(20), color: statusColor),
                ),
                SizedBox(width: Responsive.spacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusLabel, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w700, color: statusColor)),
                      SizedBox(height: Responsive.spacing(2)),
                      Text(tanggal, style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(10), vertical: Responsive.spacing(4)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: NeoMiraiColors.success),
                      SizedBox(width: Responsive.spacing(4)),
                      Text('Berhasil', style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: NeoMiraiColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: EdgeInsets.all(Responsive.spacing(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waktu
                Row(
                  children: [
                    if (mAbsen != null) ...[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(Responsive.spacing(10)),
                          decoration: BoxDecoration(
                            color: NeoMiraiColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Responsive.radius(8)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, size: Responsive.iconSize(16), color: NeoMiraiColors.success),
                              SizedBox(width: Responsive.spacing(8)),
                              Text('Masuk: $mAbsen', style: TextStyle(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w500, color: NeoMiraiColors.success)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (mAbsen != null && pAbsen != null) SizedBox(width: Responsive.spacing(8)),
                    if (pAbsen != null)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(Responsive.spacing(10)),
                          decoration: BoxDecoration(
                            color: NeoMiraiColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Responsive.radius(8)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: Responsive.iconSize(16), color: NeoMiraiColors.info),
                              SizedBox(width: Responsive.spacing(8)),
                              Text('Pulang: $pAbsen', style: TextStyle(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w500, color: NeoMiraiColors.info)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Keterangan
                if (item['keterangan'] != null && (item['keterangan'] as String).isNotEmpty) ...[
                  SizedBox(height: Responsive.spacing(10)),
                  Container(
                    padding: EdgeInsets.all(Responsive.spacing(10)),
                    decoration: BoxDecoration(
                      color: NeoMiraiColors.ash.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(Responsive.radius(8)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notes_rounded, size: Responsive.iconSize(14), color: NeoMiraiColors.ash),
                        SizedBox(width: Responsive.spacing(8)),
                        Expanded(
                          child: Text(
                            item['keterangan'].toString(),
                            style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Tombol Download
                SizedBox(height: Responsive.spacing(14)),
                GestureDetector(
                  onTap: _isDownloading ? null : () => _downloadSurat(item['id'].toString()),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: Responsive.spacing(12)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [NeoMiraiColors.gold, NeoMiraiColors.gold.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(Responsive.radius(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isDownloading && _downloadingId == item['id'].toString())
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          Icon(Icons.download_rounded, size: Responsive.iconSize(18), color: Colors.white),
                        SizedBox(width: Responsive.spacing(8)),
                        Text('Download Surat Keterangan', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index), duration: 200.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: NeoMiraiColors.gold),
          ),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat data...', style: TextStyle(fontSize: Responsive.fontSize(13), color: NeoMiraiColors.inkSoft)),
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
            SizedBox(height: Responsive.spacing(20)),
            Text('Gagal Memuat', style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(8)),
            Text(_errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(24)),
            GestureDetector(
              onTap: _loadHistory,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(24), vertical: Responsive.spacing(12)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold,
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: Responsive.iconSize(18), color: Colors.white),
                    SizedBox(width: Responsive.spacing(8)),
                    Text('Coba Lagi', style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
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
              padding: EdgeInsets.all(Responsive.radius(24)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, size: Responsive.iconSize(56), color: NeoMiraiColors.gold),
            ),
            SizedBox(height: Responsive.spacing(20)),
            Text('Belum Ada Data', style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(8)),
            Text('Riwayat presensi error yang telah\ndiajukan akan muncul di sini', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
