import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/neo_components.dart';
import '../../core/services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: NeoMiraiTheme.paperGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(Responsive.spacing(16)),
                  child: Column(
                    children: [
                      // Profile Card
                      _buildProfileCard(context)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      SizedBox(height: Responsive.spacing(20)),

                      // Menu Items
                      _buildMenuSection(context)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms),

                      SizedBox(height: Responsive.spacing(20)),

                      // Logout Button
                      _buildLogoutButton(context)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(16)),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice,
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                boxShadow: [
                  BoxShadow(
                    color: NeoMiraiColors.ink.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: Responsive.iconSize(18),
                color: NeoMiraiColors.ink,
              ),
            ),
          ),
          SizedBox(width: Responsive.spacing(16)),
          Expanded(
            child: Text(
              'Profil Saya',
              style: TextStyle(
                fontSize: Responsive.fontSize(20),
                fontWeight: FontWeight.bold,
                color: NeoMiraiColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(24)),
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.nightGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(24)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.night.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: EdgeInsets.all(Responsive.radius(16)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Responsive.radius(20)),
            ),
            child: Icon(
              Icons.person_rounded,
              size: Responsive.iconSize(56),
              color: NeoMiraiColors.gold,
            ),
          ),
          SizedBox(height: Responsive.spacing(16)),

          // Name
          Text(
            'Nama User',
            style: TextStyle(
              fontSize: Responsive.fontSize(20),
              fontWeight: FontWeight.bold,
              color: NeoMiraiColors.rice,
            ),
          ),
          SizedBox(height: Responsive.spacing(4)),

          // Role Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(14),
              vertical: Responsive.spacing(6),
            ),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Responsive.radius(18)),
            ),
            child: Text(
              'Pegawai',
              style: TextStyle(
                fontSize: Responsive.fontSize(11),
                fontWeight: FontWeight.w600,
                color: NeoMiraiColors.gold,
              ),
            ),
          ),
          SizedBox(height: Responsive.spacing(16)),

          // Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoItem(
                icon: Icons.badge_outlined,
                label: 'NIP',
                value: '-',
              ),
              Container(
                width: 1,
                height: 30,
                color: NeoMiraiColors.rice.withValues(alpha: 0.3),
                margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
              ),
              _buildInfoItem(
                icon: Icons.email_outlined,
                label: 'Email',
                value: '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: Responsive.iconSize(16),
          color: NeoMiraiColors.rice.withValues(alpha: 0.8),
        ),
        SizedBox(width: Responsive.spacing(6)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                color: NeoMiraiColors.rice.withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                fontWeight: FontWeight.w600,
                color: NeoMiraiColors.rice,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profil',
            subtitle: 'Ubah informasi akun Anda',
            onTap: () => _showComingSoon(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Ubah Password',
            subtitle: 'Update password akun',
            onTap: () => _showComingSoon(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            subtitle: 'Pengaturan notifikasi',
            onTap: () => _showComingSoon(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Pusat Bantuan',
            subtitle: 'FAQ dan kontak support',
            onTap: () => _showComingSoon(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi 1.0.0',
            showArrow: false,
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Responsive.radius(20)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.spacing(16)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              child: Icon(
                icon,
                size: Responsive.iconSize(20),
                color: NeoMiraiColors.gold,
              ),
            ),
            SizedBox(width: Responsive.spacing(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(13),
                      fontWeight: FontWeight.w600,
                      color: NeoMiraiColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(11),
                      color: NeoMiraiColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                size: Responsive.iconSize(20),
                color: NeoMiraiColors.inkSoft,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: Responsive.spacing(70),
      color: NeoMiraiColors.line.withValues(alpha: 0.5),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: NeoButton(
        text: 'LOGOUT',
        icon: Icons.logout_rounded,
        isOutlined: true,
        color: NeoMiraiColors.error,
        onPressed: () => _handleLogout(context),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur dalam pengembangan'),
        backgroundColor: NeoMiraiColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(20)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(8)),
              decoration: BoxDecoration(
                gradient: NeoMiraiTheme.goldGradient,
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: NeoMiraiColors.rice,
                size: Responsive.iconSize(24),
              ),
            ),
            SizedBox(width: Responsive.spacing(12)),
            const Text('SILATAR'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portal Layanan Online',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: NeoMiraiColors.ink,
              ),
            ),
            SizedBox(height: Responsive.spacing(4)),
            Text(
              'Kementerian Agama\nKabupaten Tanah Datar',
              style: TextStyle(
                fontSize: Responsive.fontSize(12),
                color: NeoMiraiColors.inkSoft,
              ),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(12)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: NeoMiraiColors.gold,
                    size: Responsive.iconSize(18),
                  ),
                  SizedBox(width: Responsive.spacing(10)),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(12),
                      color: NeoMiraiColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.gold,
              foregroundColor: NeoMiraiColors.rice,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(20)),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: NeoMiraiColors.error),
            SizedBox(width: Responsive.spacing(10)),
            const Text('Konfirmasi Logout'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.instance.logout();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.error,
              foregroundColor: NeoMiraiColors.rice,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
