import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';

class SimpegResetPasswordPage extends StatefulWidget {
  const SimpegResetPasswordPage({super.key});

  @override
  State<SimpegResetPasswordPage> createState() => _SimpegResetPasswordPageState();
}

class _SimpegResetPasswordPageState extends State<SimpegResetPasswordPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

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
      final response = await ApiService.instance.getSimpegRequests();

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

  Future<void> _submitRequest() async {
    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: NeoMiraiColors.gold, size: 24),
            SizedBox(width: Responsive.spacing(8)),
            const Expanded(child: Text('Reset Password SIMPEG')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anda akan mengirimkan request reset password SIMPEG kepada petugas.'),
              SizedBox(height: Responsive.spacing(12)),
              Container(
                padding: EdgeInsets.all(Responsive.spacing(12)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  border: Border.all(color: NeoMiraiColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: NeoMiraiColors.gold),
                    SizedBox(width: Responsive.spacing(8)),
                    Expanded(
                      child: Text(
                        'Data Anda akan dikirim ke petugas SIMPEG untuk diproses.',
                        style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: NeoMiraiColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.gold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final response = await ApiService.instance.submitSimpegResetPassword();

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message ?? 'Request berhasil dikirim'),
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
                content: Text(response.message ?? 'Gagal mengirim request'),
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
            _isSubmitting = false;
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
            child: Icon(Icons.admin_panel_settings_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SIMPEG', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Reset Password SIMPEG', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Header
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.admin_panel_settings_rounded, size: 48, color: Colors.white),
          ),

          SizedBox(height: Responsive.spacing(24)),

          // Title
          Text(
            'Reset Password SIMPEG',
            style: TextStyle(fontSize: Responsive.fontSize(20), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.spacing(8)),

          // Subtitle
          Text(
            'Kirim request reset password kepada petugas SIMPEG',
            style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: Responsive.spacing(32)),

          // Submit Button - Large and Prominent
          _buildSubmitButton(),

          SizedBox(height: Responsive.spacing(32)),

          // History Section
          _buildHistorySection(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.goldGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.gold.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submitRequest,
          borderRadius: BorderRadius.circular(Responsive.radius(16)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Responsive.spacing(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSubmitting)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(Icons.send_rounded, size: 24, color: Colors.white),
                SizedBox(width: Responsive.spacing(12)),
                Text(
                  _isSubmitting ? 'Mengirim Request...' : 'Kirim Request Reset Password',
                  style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: Responsive.iconSize(20), color: NeoMiraiColors.ink),
            SizedBox(width: Responsive.spacing(8)),
            Text('Riwayat Request', style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          ],
        ),
        SizedBox(height: Responsive.spacing(12)),
        if (_requests.isEmpty)
          _buildEmptyHistory()
        else
          ..._requests.map((req) => _buildRequestCard(req)),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(24)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.ash),
          SizedBox(height: Responsive.spacing(12)),
          Text('Belum ada riwayat request', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final createdAt = request['created_at'] ?? '';

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
                  request['judul'] ?? 'Request Reset Password',
                  style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(12)),
          _buildRequestInfoRow(Icons.calendar_today_rounded, 'Tanggal', createdAt.toString().substring(0, 10)),
          if (request['keterangan'] != null && request['keterangan'].toString().isNotEmpty) ...[
            SizedBox(height: Responsive.spacing(8)),
            _buildRequestInfoRow(Icons.description_rounded, 'Keterangan', request['keterangan']),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRequestInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: Responsive.iconSize(14), color: NeoMiraiColors.ash),
        SizedBox(width: Responsive.spacing(8)),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.ash)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'pending' => NeoMiraiColors.warning,
      'processed' => NeoMiraiColors.info,
      'completed' => NeoMiraiColors.success,
      'rejected' => NeoMiraiColors.error,
      _ => NeoMiraiColors.ash,
    };
  }

  String _getStatusLabel(String status) {
    return switch (status) {
      'pending' => 'Menunggu',
      'processed' => 'Diproses',
      'completed' => 'Selesai',
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
}
