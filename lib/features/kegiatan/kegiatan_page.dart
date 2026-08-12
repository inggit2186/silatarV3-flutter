import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/providers/kegiatan_provider.dart';
import 'widgets/kegiatan_harian_tab.dart';
import 'widgets/kegiatan_bulanan_tab.dart';
import 'widgets/kegiatan_form_modal.dart';

/// Main page for Laporan Kegiatan Harian
class KegiatanPage extends StatefulWidget {
  final String initialTab;

  const KegiatanPage({super.key, this.initialTab = 'harian'});

  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  late String _activeTab;
  late String _selectedMonth;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

    // Load data after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<KegiatanProvider>();
    await provider.loadKegiatan(_selectedMonth);
  }

  void _onMonthChanged(String month) {
    setState(() {
      _selectedMonth = month;
    });
    _loadData();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _showAddModal() {
    final provider = context.read<KegiatanProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: KegiatanFormModal(
          selectedMonth: _selectedMonth,
          kegiatanProvider: provider,
          onSaved: () {
            _loadData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMonthSelector(),
            _buildTabNavigation(),
            Expanded(
              child: _activeTab == 'harian'
                  ? KegiatanHarianTab(
                      searchQuery: _searchQuery,
                      onSearchChanged: _onSearchChanged,
                    )
                  : const KegiatanBulananTab(),
            ),
          ],
        ),
      ),
      floatingActionButton: _activeTab == 'harian' ? _buildFAB() : null,
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
          Container(
            padding: EdgeInsets.all(Responsive.spacing(10)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              boxShadow: [
                BoxShadow(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.event_note_rounded,
              size: Responsive.iconSize(22),
              color: Colors.white,
            ),
          ),
          SizedBox(width: Responsive.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Laporan Kegiatan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(16),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                  ),
                ),
                SizedBox(height: Responsive.spacing(2)),
                Text(
                  'Kelola kegiatan harian Anda',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(10),
                    color: NeoMiraiColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(6),
      ),
      child: GestureDetector(
        onTap: _showMonthPicker,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(14),
            vertical: Responsive.spacing(10),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            boxShadow: [
              BoxShadow(
                color: NeoMiraiColors.ink.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: const Color(0xFFEF6C00),
                size: Responsive.iconSize(18),
              ),
              SizedBox(width: Responsive.spacing(10)),
              Expanded(
                child: Text(
                  _formatMonth(_selectedMonth),
                  style: TextStyle(
                    fontSize: Responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: Responsive.iconSize(20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(6),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTab('Harian', 'harian'),
            ),
            Expanded(
              child: _buildTab('Rekap', 'rekap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, String tab) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: Responsive.spacing(10)),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(Responsive.radius(10)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSize(12),
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFFEF6C00) : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddModal,
      backgroundColor: const Color(0xFFEF6C00),
      elevation: 4,
      child: Icon(
        Icons.edit_rounded,
        color: Colors.white,
        size: Responsive.iconSize(24),
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    final currentYear = int.parse(_selectedMonth.split('-')[0]);
    final currentMonth = int.parse(_selectedMonth.split('-')[1]);

    final picked = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialYear: currentYear,
        initialMonth: currentMonth,
      ),
    );

    if (picked != null) {
      final year = picked['year']!;
      final month = picked['month']!;
      final newMonth = '$year-${month.toString().padLeft(2, '0')}';
      _onMonthChanged(newMonth);
    }
  }

  String _formatMonth(String month) {
    try {
      final date = DateFormat('yyyy-MM').parse(month);
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return month;
    }
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedYear--;
            });
          },
          icon: const Icon(Icons.chevron_left_rounded),
          color: const Color(0xFFEF6C00),
        ),
        Text(
          '$_selectedYear',
          style: TextStyle(
            fontSize: Responsive.fontSize(18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _selectedYear++;
            });
          },
          icon: const Icon(Icons.chevron_right_rounded),
          color: const Color(0xFFEF6C00),
        ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == _selectedMonth;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedMonth = month;
            });
          },
          borderRadius: BorderRadius.circular(Responsive.radius(8)),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEF6C00)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(8)),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFEF6C00)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                _monthNames[index].substring(0, 3),
                style: TextStyle(
                  fontSize: Responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
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
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: Responsive.spacing(12)),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
              ),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: Responsive.fontSize(13),
              ),
            ),
          ),
        ),
        SizedBox(width: Responsive.spacing(12)),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'year': _selectedYear,
                'month': _selectedMonth,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6C00),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: Responsive.spacing(12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
              ),
            ),
            child: Text(
              'Pilih',
              style: TextStyle(
                fontSize: Responsive.fontSize(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
