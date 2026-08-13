import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../janji_temu/admin_janji_temu_page.dart';
import '../simpeg/admin_simpeg_page.dart';

/// Admin section page - only accessible for admin/petugas/kasi/kasubag/kepala roles
class AdminSectionPage extends StatelessWidget {
  const AdminSectionPage({super.key});

  /// Check if user has admin access
  static bool hasAdminAccess(String? role) {
    const adminRoles = ['admin', 'superadmin', 'petugas', 'kasi', 'kasubag', 'kasubbag', 'kepala'];
    return role != null && adminRoles.contains(role.toLowerCase());
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
              _buildHeader(context),
              Expanded(
                child: _buildAdminMenus(context),
              ),
            ],
          ),
        ),
      ),
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
              gradient: NeoMiraiColors.nightGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.night.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.admin_panel_settings_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panel Admin', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Manajemen sistem', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenus(BuildContext context) {
    final menus = [
      AdminMenu(
        title: 'Kelola Janji Temu',
        subtitle: 'Setujui atau tolak janji temu dari pengguna',
        icon: Icons.calendar_month_rounded,
        color: NeoMiraiColors.night,
        page: const AdminJanjiTemuPage(),
      ),
      AdminMenu(
        title: 'Verifikasi SIMPEG',
        subtitle: 'Proses request reset password SIMPEG',
        icon: Icons.admin_panel_settings_rounded,
        color: NeoMiraiColors.gold,
        page: const AdminSimpegPage(),
      ),
      AdminMenu(
        title: 'Kelola Pengajuan',
        subtitle: 'Proses pengajuan layanan dari pengguna',
        icon: Icons.description_rounded,
        color: NeoMiraiColors.nightSoft,
        page: null, // Coming soon
      ),
      AdminMenu(
        title: 'Kelola Users',
        subtitle: 'Manajemen akun pengguna',
        icon: Icons.people_rounded,
        color: NeoMiraiColors.nightSoft,
        page: null, // Coming soon
      ),
      AdminMenu(
        title: 'Laporan',
        subtitle: 'Lihat laporan dan statistik',
        icon: Icons.analytics_rounded,
        color: NeoMiraiColors.ash,
        page: null, // Coming soon
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu Administrasi',
            style: TextStyle(
              fontSize: Responsive.fontSize(14),
              fontWeight: FontWeight.bold,
              color: NeoMiraiColors.ink,
            ),
          ),
          SizedBox(height: Responsive.spacing(12)),
          ...menus.map((menu) => _buildMenuCard(context, menu)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, AdminMenu menu) {
    return GestureDetector(
      onTap: () {
        if (menu.page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => menu.page!),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${menu.title} - Segera hadir'),
              backgroundColor: NeoMiraiColors.info,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
        }
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(12)),
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              child: Icon(menu.icon, size: Responsive.iconSize(24), color: menu.color),
            ),
            SizedBox(width: Responsive.spacing(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: NeoMiraiColors.ink,
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(2)),
                  Text(
                    menu.subtitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(11),
                      color: NeoMiraiColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: Responsive.iconSize(20),
              color: NeoMiraiColors.ash,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class AdminMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? page;

  AdminMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.page,
  });
}
