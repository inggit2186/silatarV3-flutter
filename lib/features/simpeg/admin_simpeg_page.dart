import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';

class AdminSimpegPage extends StatefulWidget {
  const AdminSimpegPage({super.key});

  @override
  State<AdminSimpegPage> createState() => _AdminSimpegPageState();
}

class _AdminSimpegPageState extends State<AdminSimpegPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getAdminSimpegRequests(
        status: _selectedStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response.data!);
          _isLoading = false;
        });
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

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadRequests();
  }

  Future<void> _verifyRequest(int id, String currentStatus) async {
    if (_isProcessing) return;

    String selectedStatus = currentStatus;
    final TextEditingController keteranganController = TextEditingController(
      text: currentStatus == 'pending' ? 'Request sedang diproses' : '',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
          title: Row(
            children: [
              Icon(Icons.verified_rounded, color: NeoMiraiColors.gold, size: 24),
              SizedBox(width: Responsive.spacing(8)),
              const Expanded(child: Text('Verifikasi Request')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Selection
                Text('Status Verifikasi', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(8)),
                Wrap(
                  spacing: Responsive.spacing(8),
                  runSpacing: Responsive.spacing(8),
                  children: [
                    _buildStatusOption('DIPROSES', 'Diproses', Icons.sync_rounded, NeoMiraiColors.info, selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                    _buildStatusOption('SUKSES', 'Sukses', Icons.check_circle_rounded, NeoMiraiColors.success, selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                    _buildStatusOption('GAGAL', 'Gagal', Icons.cancel_rounded, NeoMiraiColors.error, selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                    _buildStatusOption('DITOLAK', 'Ditolak', Icons.block_rounded, NeoMiraiColors.ash, selectedStatus, (val) {
                      setDialogState(() => selectedStatus = val);
                    }),
                  ],
                ),

                SizedBox(height: Responsive.spacing(16)),

                // Keterangan
                Text('Keterangan', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(8)),
                TextField(
                  controller: keteranganController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Masukkan keterangan...',
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: NeoMiraiColors.inkSoft)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'status': selectedStatus,
                'keterangan': keteranganController.text,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoMiraiColors.gold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final response = await ApiService.instance.verifySimpegRequest(
          id,
          status: result['status']!,
          keterangan: result['keterangan']!,
        );

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Verifikasi berhasil'),
                backgroundColor: NeoMiraiColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
              ),
            );
            _loadRequests();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Gagal memverifikasi'),
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

  Widget _buildStatusOption(String value, String label, IconData icon, Color color, String selectedStatus, Function(String) onTap) {
    final isSelected = selectedStatus == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(12), vertical: Responsive.spacing(8)),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
          border: Border.all(
            color: isSelected ? color : NeoMiraiColors.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : NeoMiraiColors.ash),
            SizedBox(width: Responsive.spacing(6)),
            Text(label, style: TextStyle(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w600, color: isSelected ? color : NeoMiraiColors.ink)),
          ],
        ),
      ),
    );
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
                        : _buildRequestsList(),
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
                Text('Verifikasi SIMPEG', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Proses request reset password', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
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
            _buildFilterChip('Pending', 'pending'),
            SizedBox(width: Responsive.spacing(8)),
            _buildFilterChip('Diproses', 'diproses'),
            SizedBox(width: Responsive.spacing(8)),
            _buildFilterChip('Sukses', 'sukses'),
            SizedBox(width: Responsive.spacing(8)),
            _buildFilterChip('Gagal', 'gagal'),
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

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        itemCount: _requests.length,
        itemBuilder: (context, index) => _buildRequestCard(_requests[index], index),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final status = request['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final nama = request['nama'] ?? '-';
    final nip = request['user_nip']?.toString() ?? '-';
    final email = request['email'] ?? '-';
    final telp = request['telp']?.toString() ?? '-';
    final keterangan = request['keterangan'] ?? '';
    final createdAt = request['created_at']?.toString().substring(0, 10) ?? '-';

    return Container(
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
          // Header with status
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
                child: Text(nama, style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
              ),
            ],
          ),

          SizedBox(height: Responsive.spacing(12)),

          // Info rows
          _buildInfoRow(Icons.badge_rounded, 'NIP', nip),
          SizedBox(height: Responsive.spacing(6)),
          _buildInfoRow(Icons.email_rounded, 'Email', email),
          SizedBox(height: Responsive.spacing(6)),
          _buildInfoRow(Icons.phone_rounded, 'Telp', telp),
          SizedBox(height: Responsive.spacing(6)),
          _buildInfoRow(Icons.calendar_today_rounded, 'Tanggal', createdAt),

          if (keterangan.isNotEmpty) ...[
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
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: NeoMiraiColors.ash),
                  SizedBox(width: Responsive.spacing(6)),
                  Expanded(
                    child: Text(keterangan, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: Responsive.spacing(12)),

          // Verify button
          if (status == 'pending' || status == 'diproses')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _verifyRequest(request['id'], status),
                icon: Icon(Icons.verified_rounded, size: 18),
                label: Text(_isProcessing ? 'Memproses...' : 'Verifikasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoMiraiColors.gold,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: Responsive.spacing(12)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(10))),
                ),
              ),
            ),
        ],
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

  Color _getStatusColor(String status) {
    return switch (status) {
      'pending' => NeoMiraiColors.warning,
      'diproses' => NeoMiraiColors.info,
      'sukses' => NeoMiraiColors.success,
      'gagal' => NeoMiraiColors.error,
      'rejected' => NeoMiraiColors.ash,
      _ => NeoMiraiColors.ash,
    };
  }

  String _getStatusLabel(String status) {
    return switch (status) {
      'pending' => 'Menunggu',
      'diproses' => 'Diproses',
      'sukses' => 'Sukses',
      'gagal' => 'Gagal',
      'rejected' => 'Ditolak',
      _ => status,
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
              onPressed: _loadRequests,
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
            Text('Tidak ada request SIMPEG yang perlu diproses', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
