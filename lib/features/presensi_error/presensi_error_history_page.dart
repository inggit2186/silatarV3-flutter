import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<void> _downloadSurat(int id) async {
    try {
      final url = ApiService.instance.getPresensiErrorSuratUrl(id);
      final token = ApiService.instance.token;

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Silakan login ulang'),
              backgroundColor: NeoMiraiColors.error,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Mengunduh surat...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        // Save file using path_provider
        final blob = response.data;
        final dir = await _getDownloadDirectory();
        final fileName = 'Surat_Keterangan_Presensi_Error_$id.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(blob);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Surat tersimpan: $fileName')),
                ],
              ),
              backgroundColor: NeoMiraiColors.success,
              action: SnackBarAction(
                label: 'Buka',
                textColor: Colors.white,
                onPressed: () {
                  // Open file - can add file opener later
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengunduh: ${response.statusMessage}'),
              backgroundColor: NeoMiraiColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: NeoMiraiColors.error,
          ),
        );
      }
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    // For mobile, use downloads directory
    // This is a simplified version - you may want to use path_provider
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        return (await getTemporaryDirectory());
      }
      return dir;
    }
    return await getTemporaryDirectory();
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
                Text('${_history.length} pengajuan', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
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
        padding: EdgeInsets.all(Responsive.spacing(12)),
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
    final id = item['id'] as int?;

    String tanggal = '-';
    if (item['tanggal'] != null) {
      try {
        final date = DateTime.parse(item['tanggal'].toString());
        tanggal = DateFormat('dd MMM yyyy', 'id_ID').format(date);
      } catch (e) {
        tanggal = item['tanggal'].toString();
      }
    }

    final mAbsen = item['m_absen'] as String?;
    final pAbsen = item['p_absen'] as String?;
    final keterangan = item['keterangan'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.spacing(8)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(Responsive.spacing(12)),
            child: Row(
              children: [
                // Status Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                  ),
                  child: Icon(statusIcon, size: Responsive.iconSize(22), color: statusColor),
                ),
                SizedBox(width: Responsive.spacing(12)),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(statusLabel, style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w700, color: NeoMiraiColors.ink)),
                          const Spacer(),
                          Icon(Icons.check_circle, size: 14, color: NeoMiraiColors.success),
                          SizedBox(width: 4),
                          Text('Berhasil', style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.success, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: NeoMiraiColors.inkSoft),
                          SizedBox(width: 4),
                          Text(tanggal, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
                        ],
                      ),
                      // Waktu Masuk/Pulang
                      if (mAbsen != null || pAbsen != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (mAbsen != null) ...[
                              Icon(Icons.arrow_upward_rounded, size: 12, color: NeoMiraiColors.success),
                              SizedBox(width: 2),
                              Text('Masuk: ${mAbsen.substring(0, 5)}', style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.success)),
                            ],
                            if (mAbsen != null && pAbsen != null) SizedBox(width: 12),
                            if (pAbsen != null) ...[
                              Icon(Icons.arrow_downward_rounded, size: 12, color: NeoMiraiColors.info),
                              SizedBox(width: 2),
                              Text('Pulang: ${pAbsen.substring(0, 5)}', style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.info)),
                            ],
                          ],
                        ),
                      ],
                      // Keterangan
                      if (keterangan != null && keterangan.isNotEmpty && keterangan != status) ...[
                        SizedBox(height: 4),
                        Text(
                          keterangan,
                          style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Download Button
                SizedBox(width: Responsive.spacing(8)),
                GestureDetector(
                  onTap: id != null ? () => _downloadSurat(id) : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [NeoMiraiColors.gold, NeoMiraiColors.gold.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(Responsive.radius(10)),
                      boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Icon(Icons.download_rounded, size: Responsive.iconSize(18), color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 200.ms);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: NeoMiraiColors.gold),
          ),
          SizedBox(height: Responsive.spacing(12)),
          Text('Memuat...', style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(16)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: Responsive.iconSize(40), color: NeoMiraiColors.error),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Gagal Memuat', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(8)),
            Text(_errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(20)),
            GestureDetector(
              onTap: _loadHistory,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(20), vertical: Responsive.spacing(10)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold,
                  borderRadius: BorderRadius.circular(Responsive.radius(10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: Responsive.iconSize(16), color: Colors.white),
                    SizedBox(width: Responsive.spacing(6)),
                    Text('Coba Lagi', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: Colors.white)),
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
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.gold),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Belum Ada Data', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(6)),
            Text('Riwayat presensi error akan\nmuncul di sini', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
