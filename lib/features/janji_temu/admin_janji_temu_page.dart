import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../core/models/janji_temu_model.dart';

class AdminJanjiTemuPage extends StatefulWidget {
  const AdminJanjiTemuPage({super.key});

  @override
  State<AdminJanjiTemuPage> createState() => _AdminJanjiTemuPageState();
}

class _AdminJanjiTemuPageState extends State<AdminJanjiTemuPage> {
  List<JanjiTemu> _appointments = [];
  bool _isLoading = true;
  bool _isProcessing = false;
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
      final response = await ApiService.instance.getAdminAppointments(
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
          _errorMessage = response.message ?? 'Gagal memuat data janji temu';
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

  Future<void> _approveAppointment(int id) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await ApiService.instance.approveJanjiTemu(id);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Janji temu berhasil disetujui'),
              backgroundColor: NeoMiraiColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
          _loadAppointments(refresh: true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal menyetujui janji temu'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectAppointment(int id) async {
    final TextEditingController komenController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
        title: Row(
          children: [
            Icon(Icons.cancel_rounded, color: NeoMiraiColors.error, size: 24),
            SizedBox(width: Responsive.spacing(8)),
            const Text('Tolak Janji Temu?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan alasan penolakan:'),
            SizedBox(height: Responsive.spacing(12)),
            TextField(
              controller: komenController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.radius(8))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: NeoMiraiColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      if (_isProcessing) return;

      setState(() {
        _isProcessing = true;
      });

      try {
        final response = await ApiService.instance.rejectJanjiTemu(
          id,
          komen: komenController.text.isEmpty ? 'Ditolak oleh petugas' : komenController.text,
        );

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Janji temu berhasil ditolak'),
                backgroundColor: NeoMiraiColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
              ),
            );
            _loadAppointments(refresh: true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Gagal menolak janji temu'),
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
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
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
            child: Icon(Icons.admin_panel_settings_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kelola Janji Temu', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Setujui atau tolak janji temu', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
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
    final canProcess = appointment.canProcess == true;

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.spacing(12)),
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
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
                child: Text(
                  appointment.namaPengaju ?? '-',
                  style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(12)),
          _buildInfoRow(Icons.access_time_rounded, 'Waktu', appointment.waktuFormatted),
          SizedBox(height: Responsive.spacing(8)),
          _buildInfoRow(Icons.person_rounded, 'Tujuan', appointment.targetNama ?? '-'),
          SizedBox(height: Responsive.spacing(8)),
          _buildInfoRow(Icons.description_rounded, 'Keperluan', appointment.tujuan ?? '-', maxLines: 2),
          if (canProcess) ...[
            SizedBox(height: Responsive.spacing(16)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _approveAppointment(appointment.id),
                    icon: _isProcessing
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isProcessing ? 'Memproses...' : 'Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeoMiraiColors.success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: NeoMiraiColors.success.withValues(alpha: 0.5),
                      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(10))),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.spacing(12)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _rejectAppointment(appointment.id),
                    icon: _isProcessing
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.close_rounded, size: 18),
                    label: Text(_isProcessing ? 'Memproses...' : 'Tolak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeoMiraiColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: NeoMiraiColors.error.withValues(alpha: 0.5),
                      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(10))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms);
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
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
          child: Text(
            value,
            style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.ink),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
          Text('Memuat data...', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
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
              child: Icon(Icons.inbox_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.gold),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Tidak Ada Data', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(6)),
            Text('Tidak ada janji temu yang perlu diproses', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
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
