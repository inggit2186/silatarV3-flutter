import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../core/models/janji_temu_model.dart';
import '../../core/providers/user_provider.dart';
import 'detail_janji_temu_page.dart';
import 'buat_janji_temu_page.dart';
import 'admin_janji_temu_page.dart';

class RiwayatJanjiTemuPage extends StatefulWidget {
  const RiwayatJanjiTemuPage({super.key});

  @override
  State<RiwayatJanjiTemuPage> createState() => _RiwayatJanjiTemuPageState();
}

class _RiwayatJanjiTemuPageState extends State<RiwayatJanjiTemuPage> {
  List<JanjiTemu> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _appointments.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getMyAppointments(
        page: _currentPage,
        status: _selectedStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          if (_currentPage == 1) {
            _appointments = response.data!.data;
          } else {
            _appointments.addAll(response.data!.data);
          }
          _lastPage = response.data!.lastPage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Gagal memuat riwayat janji temu';
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

  void _loadMore() {
    if (_currentPage < _lastPage && !_isLoading) {
      _currentPage++;
      _loadAppointments();
    }
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadAppointments(refresh: true);
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
              _buildFilterSection(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildAppointmentsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BuatJanjiTemuPage()),
          );
          if (result == true) {
            _loadAppointments(refresh: true);
          }
        },
        backgroundColor: NeoMiraiColors.gold,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
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
            child: Icon(Icons.calendar_today_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Janji Temu', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Daftar janji temu Anda', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.cardPadding(16), vertical: Responsive.spacing(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Semua', null),
            SizedBox(width: Responsive.spacing(8)),
            _buildFilterChip('Menunggu', 'APPOINTMENT'),
            SizedBox(width: Responsive.spacing(8)),
            _buildFilterChip('Disetujui', 'DITERIMA'),
            SizedBox(width: Responsive.spacing(8)),
            _buildFilterChip('Ditolak', 'DITOLAK'),
            SizedBox(width: Responsive.spacing(8)),
            _buildFilterChip('Dibatalkan', 'BATAL'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => _onStatusChanged(status),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(14), vertical: Responsive.spacing(10)),
        decoration: BoxDecoration(
          color: isSelected ? NeoMiraiColors.gold : NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          border: Border.all(color: isSelected ? NeoMiraiColors.gold : NeoMiraiColors.line.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w600, color: isSelected ? Colors.white : NeoMiraiColors.ink),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_appointments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadAppointments(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification && notification.metrics.pixels == notification.metrics.maxScrollExtent) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.all(Responsive.spacing(16)),
          itemCount: _appointments.length + (_currentPage < _lastPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _appointments.length) {
              return _buildLoadMoreIndicator();
            }
            return _buildAppointmentCard(_appointments[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(JanjiTemu appointment, int index) {
    final statusColor = _getStatusColor(appointment.status);
    final statusLabel = appointment.statusLabel ?? '-';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailJanjiTemuPage(appointmentId: appointment.id),
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
            // Status & Type
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(10), vertical: Responsive.spacing(4)),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
                SizedBox(width: Responsive.spacing(8)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(8), vertical: Responsive.spacing(4)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.night.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(6)),
                  ),
                  child: Text(
                    appointment.tipe == 'asn' ? 'Pegawai' : 'Seksi',
                    style: TextStyle(fontSize: Responsive.fontSize(9), fontWeight: FontWeight.w500, color: NeoMiraiColors.night),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: Responsive.iconSize(18), color: NeoMiraiColors.inkSoft),
              ],
            ),

            SizedBox(height: Responsive.spacing(12)),

            // Waktu
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: Responsive.iconSize(16), color: NeoMiraiColors.gold),
                SizedBox(width: Responsive.spacing(8)),
                Text(
                  appointment.waktuFormatted,
                  style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink),
                ),
              ],
            ),

            SizedBox(height: Responsive.spacing(8)),

            // Keperluan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_rounded, size: Responsive.iconSize(14), color: NeoMiraiColors.ash),
                SizedBox(width: Responsive.spacing(8)),
                Expanded(
                  child: Text(
                    appointment.tujuan ?? '-',
                    style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Komen jika ada
            if (appointment.komen != null && appointment.komen!.isNotEmpty) ...[
              SizedBox(height: Responsive.spacing(8)),
              Container(
                padding: EdgeInsets.all(Responsive.spacing(10)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.paperSoft,
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: Responsive.iconSize(12), color: NeoMiraiColors.ash),
                    SizedBox(width: Responsive.spacing(6)),
                    Expanded(
                      child: Text(
                        '"${appointment.komen}"',
                        style: TextStyle(fontSize: Responsive.fontSize(10), fontStyle: FontStyle.italic, color: NeoMiraiColors.ash),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms);
  }

  Color _getStatusColor(String? status) {
    return switch (status) {
      'APPOINTMENT' => NeoMiraiColors.warning,
      'ON SITE' => NeoMiraiColors.info,
      'PENDING' => NeoMiraiColors.info,
      'DITERIMA' => NeoMiraiColors.success,
      'DITOLAK' => NeoMiraiColors.error,
      'BATAL' => NeoMiraiColors.ash,
      'EXPIRED' => NeoMiraiColors.ash,
      'SUKSES' => NeoMiraiColors.success,
      _ => NeoMiraiColors.ash,
    };
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NeoMiraiColors.gold),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat riwayat janji temu...', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
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
              onPressed: () => _loadAppointments(refresh: true),
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
            Text('Belum Ada Riwayat', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(6)),
            Text('Anda belum pernah mengajukan janji temu', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(24)),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajukan Janji Temu'),
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

  Widget _buildLoadMoreIndicator() {
    if (_currentPage >= _lastPage) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Center(child: CircularProgressIndicator(color: NeoMiraiColors.gold)),
    );
  }
}
