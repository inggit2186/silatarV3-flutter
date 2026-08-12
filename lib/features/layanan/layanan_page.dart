import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../dashboard/dashboard_page.dart';
import '../profile/profile_page.dart';
import '../presensi/presensi_page.dart';
import '../riwayat/riwayat_presensi_page.dart';

class LayananPage extends StatefulWidget {
  const LayananPage({super.key});

  @override
  State<LayananPage> createState() => _LayananPageState();
}

class _LayananPageState extends State<LayananPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Service menu data - light backgrounds with dark icons/text
  final List<ServiceMenu> _services = [
    // Menu Utama (atas)
    ServiceMenu(
      title: 'Presensi',
      subtitle: 'Ambil Presensi Staff',
      icon: Icons.fingerprint_rounded,
      bgColor: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF2E7D32),
      titleColor: const Color(0xFF1B5E20),
      subtitleColor: const Color(0xFF388E3C),
    ),
    ServiceMenu(
      title: 'Riwayat Presensi',
      subtitle: 'Riwayat Presensi Staff',
      icon: Icons.history_rounded,
      bgColor: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1565C0),
      titleColor: const Color(0xFF0D47A1),
      subtitleColor: const Color(0xFF1976D2),
    ),
    ServiceMenu(
      title: 'Layanan',
      subtitle: 'Ajukan layanan',
      icon: Icons.grid_view_rounded,
      bgColor: const Color(0xFFFFF8E1),
      iconColor: const Color(0xFFF9A825),
      titleColor: const Color(0xFFF57F17),
      subtitleColor: const Color(0xFFFBC02D),
    ),
    ServiceMenu(
      title: 'Pengajuan',
      subtitle: 'Lacak Status layanan',
      icon: Icons.description_rounded,
      bgColor: const Color(0xFFE8EAF6),
      iconColor: const Color(0xFF3949AB),
      titleColor: const Color(0xFF1A237E),
      subtitleColor: const Color(0xFF3949AB),
    ),
    // Menu Lainnya
    ServiceMenu(
      title: 'Kegiatan',
      subtitle: 'Laporan Kegiatan Harian',
      icon: Icons.event_note_rounded,
      bgColor: const Color(0xFFFFF3E0),
      iconColor: const Color(0xFFEF6C00),
      titleColor: const Color(0xFFE65100),
      subtitleColor: const Color(0xFFF57C00),
    ),
    ServiceMenu(
      title: 'Laporan',
      subtitle: 'Laporan CKH Bulanan',
      icon: Icons.assignment_rounded,
      bgColor: const Color(0xFFEFEBE9),
      iconColor: const Color(0xFF5D4037),
      titleColor: const Color(0xFF3E2723),
      subtitleColor: const Color(0xFF4E342E),
    ),
    ServiceMenu(
      title: 'Janji Temu',
      subtitle: 'Ajukan Janji Temu',
      icon: Icons.calendar_month_rounded,
      bgColor: const Color(0xFFF3E5F5),
      iconColor: const Color(0xFF7B1FA2),
      titleColor: const Color(0xFF4A148C),
      subtitleColor: const Color(0xFF6A1B9A),
    ),
    ServiceMenu(
      title: 'SIMPEG',
      subtitle: 'Reset Password SIMPEG',
      icon: Icons.admin_panel_settings_rounded,
      bgColor: const Color(0xFFE0F7FA),
      iconColor: const Color(0xFF00838F),
      titleColor: const Color(0xFF006064),
      subtitleColor: const Color(0xFF00838F),
    ),
    ServiceMenu(
      title: 'Acara',
      subtitle: 'Kegiatan Kankemenag',
      icon: Icons.celebration_rounded,
      bgColor: const Color(0xFFFFFDE7),
      iconColor: const Color(0xFFFBC02D),
      titleColor: const Color(0xFFF57F17),
      subtitleColor: const Color(0xFFF9A825),
    ),
    ServiceMenu(
      title: 'Cuti',
      subtitle: 'Pelaporan Cuti/Izin',
      icon: Icons.beach_access_rounded,
      bgColor: const Color(0xFFEDE7F6),
      iconColor: const Color(0xFF7C4DFF),
      titleColor: const Color(0xFF4527A0),
      subtitleColor: const Color(0xFF5E35B1),
    ),
    ServiceMenu(
      title: 'Error',
      subtitle: 'Presensi Error/Tugas Luar',
      icon: Icons.error_outline_rounded,
      bgColor: const Color(0xFFFFEBEE),
      iconColor: const Color(0xFFD32F2F),
      titleColor: const Color(0xFFB71C1C),
      subtitleColor: const Color(0xFFC62828),
    ),
    ServiceMenu(
      title: 'Pengaduan',
      subtitle: 'Laporan/Pengaduan',
      icon: Icons.report_problem_rounded,
      bgColor: const Color(0xFFECEFF1),
      iconColor: const Color(0xFF546E7A),
      titleColor: const Color(0xFF37474F),
      subtitleColor: const Color(0xFF455A64),
    ),
  ];

  List<ServiceMenu> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((s) =>
      s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.subtitle.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final bool isTablet = context.isTablet;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: NeoMiraiTheme.paperGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              Expanded(
                child: _buildContent(context, isTablet),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(12)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [
                BoxShadow(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.apps_rounded,
              size: Responsive.iconSize(26),
              color: Colors.white,
            ),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu Pelayanan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(18),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                  ),
                ),
                SizedBox(height: Responsive.spacing(2)),
                Text(
                  'Pilih Menu yang Anda Inginkan',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(11),
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(14)),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Cari menu...',
            hintStyle: TextStyle(
              color: NeoMiraiColors.inkSoft,
              fontSize: Responsive.fontSize(12),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: NeoMiraiColors.inkSoft,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: NeoMiraiColors.inkSoft),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(16),
              vertical: Responsive.spacing(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet) {
    final filteredServices = _filteredServices;

    if (filteredServices.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 4 : 3,
              mainAxisSpacing: Responsive.spacing(10),
              crossAxisSpacing: Responsive.spacing(10),
              childAspectRatio: isTablet ? 0.85 : 0.88,
            ),
            itemCount: filteredServices.length,
            itemBuilder: (context, index) {
              return _buildServiceCard(
                context,
                filteredServices[index],
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceMenu service, int index) {
    final bool isSmall = context.isSmallPhone;

    return GestureDetector(
      onTap: () => _onServiceTap(context, service),
      child: Container(
        decoration: BoxDecoration(
          color: service.bgColor,
          borderRadius: BorderRadius.circular(Responsive.radius(isSmall ? 14 : 16)),
          boxShadow: [
            BoxShadow(
              color: service.iconColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              right: -10,
              bottom: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: service.iconColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(isSmall ? 8 : 10)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.radius(isSmall ? 10 : 12)),
                      decoration: BoxDecoration(
                        color: service.iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        service.icon,
                        size: Responsive.iconSize(isSmall ? 24 : 28),
                        color: service.iconColor,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(isSmall ? 6 : 8)),
                    Text(
                      service.title,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(isSmall ? 10 : 11),
                        fontWeight: FontWeight.bold,
                        color: service.titleColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.spacing(2)),
                    Text(
                      service.subtitle,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(isSmall ? 7 : 8),
                        color: service.subtitleColor,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 50 * index),
      duration: 300.ms,
    ).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState(BuildContext context) {
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
              child: Icon(
                Icons.search_off_rounded,
                size: Responsive.iconSize(48),
                color: NeoMiraiColors.gold,
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text(
              'Menu Tidak Ditemukan',
              style: TextStyle(
                fontSize: Responsive.fontSize(15),
                fontWeight: FontWeight.bold,
                color: NeoMiraiColors.ink,
              ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              'Coba kata kunci lain',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: NeoMiraiColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onServiceTap(BuildContext context, ServiceMenu service) {
    switch (service.title) {
      case 'Presensi':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PresensiPage()),
        );
        break;
      case 'Riwayat Presensi':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RiwayatPresensiPage()),
        );
        break;
      case 'Layanan':
        // TODO: Navigate to Layanan catalog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.construction_rounded, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                const Expanded(child: Text('Fitur Layanan dalam pengembangan')),
              ],
            ),
            backgroundColor: NeoMiraiColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
          ),
        );
        break;
      case 'Pengajuan':
        // TODO: Navigate to Pengajuan tracking
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.construction_rounded, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                const Expanded(child: Text('Fitur Pengajuan dalam pengembangan')),
              ],
            ),
            backgroundColor: NeoMiraiColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.radius(6)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  ),
                  child: Icon(
                    service.icon,
                    color: Colors.white,
                    size: Responsive.iconSize(18),
                  ),
                ),
                SizedBox(width: Responsive.spacing(12)),
                Expanded(
                  child: Text('${service.title} - Fitur dalam pengembangan'),
                ),
              ],
            ),
            backgroundColor: NeoMiraiColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
          ),
        );
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    return Container(
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(isSmall ? 6 : 12),
            vertical: Responsive.spacing(isSmall ? 6 : 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: false,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardPage()),
                  ),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  label: 'Layanan',
                  isActive: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: Icons.history_rounded,
                  label: 'Riwayat',
                  isActive: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RiwayatPresensiPage()),
                  ),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  isActive: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final bool isSmall = context.isSmallPhone;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(isSmall ? 6 : 10),
          vertical: Responsive.spacing(isSmall ? 6 : 8),
        ),
        decoration: isActive
            ? BoxDecoration(
                gradient: NeoMiraiTheme.goldGradient,
                borderRadius: BorderRadius.circular(Responsive.radius(isSmall ? 10 : 14)),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: Responsive.iconSize(isSmall ? 20 : 22),
              color: isActive ? Colors.white : NeoMiraiColors.inkSoft,
            ),
            SizedBox(height: Responsive.spacing(2)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(isSmall ? 8 : 10),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.white : NeoMiraiColors.inkSoft,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

}

class ServiceMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  ServiceMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
  });
}
