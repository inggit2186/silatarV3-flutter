import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/models/presensi_model.dart';

class RiwayatPresensiPage extends StatefulWidget {
  const RiwayatPresensiPage({super.key});

  @override
  State<RiwayatPresensiPage> createState() => _RiwayatPresensiPageState();
}

class _RiwayatPresensiPageState extends State<RiwayatPresensiPage> {
  PresensiHistory? _history;
  bool _isLoading = true;
  String? _errorMessage;

  // Filter bulan & tahun
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.instance.getPresensiHistory(
      bulan: _selectedMonth,
      tahun: _selectedYear,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _history = response.data;
        } else {
          _errorMessage = response.message ?? 'Gagal memuat riwayat presensi';
        }
      });
    }
  }

  void _onMonthChanged(int month, int year) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
    });
    _loadRiwayat();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: NeoMiraiTheme.paperGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, user?.displayName ?? 'Warga'),
              _buildFilterSection(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
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
            child: Icon(Icons.history_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Presensi', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text(userName, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
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
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              label: '${_getMonthName(_selectedMonth)} $_selectedYear',
              icon: Icons.calendar_today_rounded,
              onTap: _showMonthPicker,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(14), vertical: Responsive.spacing(10)),
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          border: Border.all(color: NeoMiraiColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Responsive.iconSize(16), color: NeoMiraiColors.gold),
            SizedBox(width: Responsive.spacing(8)),
            Text(label, style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
            SizedBox(width: Responsive.spacing(4)),
            Icon(Icons.chevron_right_rounded, size: Responsive.iconSize(14), color: NeoMiraiColors.inkSoft),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Future<void> _showMonthPicker() async {
    final picked = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialYear: _selectedYear,
        initialMonth: _selectedMonth,
      ),
    );

    if (picked != null) {
      final year = picked['year']!;
      final month = picked['month']!;
      _onMonthChanged(month, year);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NeoMiraiColors.gold),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat riwayat presensi...', style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
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
            Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(16)),
            ElevatedButton.icon(
              onPressed: _loadRiwayat,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Muat Ulang', style: TextStyle(fontSize: Responsive.fontSize(12))),
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

  Widget _buildHistoryList() {
    final data = _history?.data ?? [];

    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRiwayat,
      color: NeoMiraiColors.gold,
      child: ListView.builder(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return _buildPresensiCard(data[index], index);
        },
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
            Text(
              'Tidak ada data presensi untuk ${_getMonthName(_selectedMonth)} $_selectedYear',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresensiCard(Presensi presensi, int index) {
    final hasMasuk = presensi.hasMasuk;
    final hasPulang = presensi.hasPulang;
    final isTelat = presensi.isTelat;
    final isPulangCepat = presensi.isPulangCepat;

    // Determine status color
    Color statusColor = NeoMiraiColors.success;
    String statusText = 'Normal';
    if (isTelat) {
      statusColor = NeoMiraiColors.warning;
      statusText = 'Terlambat';
    } else if (isPulangCepat) {
      statusColor = NeoMiraiColors.error;
      statusText = 'Pulang Cepat';
    }

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
          // Date & Status
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(10), vertical: Responsive.spacing(4)),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(presensi.tanggal),
                style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft),
              ),
            ],
          ),

          SizedBox(height: Responsive.spacing(12)),

          // Jam Masuk & Pulang
          Row(
            children: [
              Expanded(
                child: _buildTimeColumn(
                  icon: Icons.login_rounded,
                  label: 'Masuk',
                  time: presensi.mAbsen ?? '--:--',
                  color: NeoMiraiColors.success,
                  hasData: hasMasuk,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: NeoMiraiColors.line.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildTimeColumn(
                  icon: Icons.logout_rounded,
                  label: 'Pulang',
                  time: presensi.pAbsen ?? '--:--',
                  color: NeoMiraiColors.info,
                  hasData: hasPulang,
                ),
              ),
            ],
          ),

          // Distance info
          if (presensi.mDistance != null || presensi.pDistance != null) ...[
            SizedBox(height: Responsive.spacing(12)),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: Responsive.iconSize(14), color: NeoMiraiColors.inkSoft),
                SizedBox(width: Responsive.spacing(6)),
                Text(
                  'Jarak: ${presensi.mDistance?.toStringAsFixed(1) ?? '-'}m (masuk) | ${presensi.pDistance?.toStringAsFixed(1) ?? '-'}m (pulang)',
                  style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms);
  }

  Widget _buildTimeColumn({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
    required bool hasData,
  }) {
    return Column(
      children: [
        Icon(icon, size: Responsive.iconSize(18), color: hasData ? color : NeoMiraiColors.ash),
        SizedBox(height: Responsive.spacing(4)),
        Text(label, style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft)),
        Text(
          time,
          style: TextStyle(
            fontSize: Responsive.fontSize(14),
            fontWeight: FontWeight.bold,
            color: hasData ? color : NeoMiraiColors.ash,
          ),
        ),
      ],
    );
  }

  String _formatDate(String tanggal) {
    try {
      final parts = tanggal.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[2]);
        final month = _getMonthName(int.parse(parts[1]));
        return '$day $month ${parts[0]}';
      }
    } catch (e) {
      // Return original format if parsing fails
    }
    return tanggal;
  }
}

/// Dialog untuk memilih bulan dan tahun
class _MonthYearPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _MonthYearPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
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
            _buildYearSelector(),
            SizedBox(height: Responsive.spacing(16)),
            _buildMonthGrid(),
            SizedBox(height: Responsive.spacing(16)),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _selectedYear > currentYear - 4
              ? () => setState(() => _selectedYear--)
              : null,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(16), vertical: Responsive.spacing(8)),
          decoration: BoxDecoration(
            color: NeoMiraiColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Responsive.radius(8)),
          ),
          child: Text(
            '$_selectedYear',
            style: TextStyle(
              fontSize: Responsive.fontSize(16),
              fontWeight: FontWeight.bold,
              color: NeoMiraiColors.gold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _selectedYear < currentYear
              ? () => setState(() => _selectedYear++)
              : null,
        ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == _selectedMonth;
        return GestureDetector(
          onTap: () => setState(() => _selectedMonth = month),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? NeoMiraiColors.gold : NeoMiraiColors.rice,
              borderRadius: BorderRadius.circular(Responsive.radius(8)),
              border: Border.all(
                color: isSelected ? NeoMiraiColors.gold : NeoMiraiColors.line.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                _monthNames[index].substring(0, 3),
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : NeoMiraiColors.ink,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: TextStyle(color: NeoMiraiColors.inkSoft),
          ),
        ),
        SizedBox(width: Responsive.spacing(8)),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'year': _selectedYear,
              'month': _selectedMonth,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: NeoMiraiColors.gold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(8)),
            ),
          ),
          child: const Text('Pilih'),
        ),
      ],
    );
  }
}
