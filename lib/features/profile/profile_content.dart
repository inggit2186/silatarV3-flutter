import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/providers/user_provider.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final user = context.watch<UserProvider>().user;

    return Container(
      decoration: BoxDecoration(gradient: NeoMiraiTheme.paperGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildProfileInfo(context, user),
              _buildMenuItems(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.cardPadding(16), vertical: Responsive.spacing(12)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(12)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.person_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profil', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Informasi Akun Anda', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, user) {
    final bool hasPhoto = user?.hasPhoto ?? false;
    final String? photoUrl = user?.photoUrl;
    final String displayName = user?.displayName ?? 'Warga';
    final String? email = user?.email;

    return Container(
      margin: EdgeInsets.all(Responsive.spacing(16)),
      padding: EdgeInsets.all(Responsive.cardPadding(20)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: hasPhoto && photoUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorWidget: (context, url, error) => Icon(Icons.person_rounded, size: 40, color: NeoMiraiColors.rice),
                    ),
                  )
                : Icon(Icons.person_rounded, size: 40, color: NeoMiraiColors.rice),
          ),
          SizedBox(height: Responsive.spacing(16)),
          // Name
          Text(displayName, style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          if (email != null) ...[
            SizedBox(height: Responsive.spacing(4)),
            Text(email, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildMenuItem(context, icon: Icons.person_outline_rounded, title: 'Edit Profil', onTap: () => _showComingSoon(context, 'Edit Profil')),
          Divider(height: 1, color: NeoMiraiColors.line.withValues(alpha: 0.5)),
          _buildMenuItem(context, icon: Icons.lock_outline_rounded, title: 'Ubah Password', onTap: () => _showComingSoon(context, 'Ubah Password')),
          Divider(height: 1, color: NeoMiraiColors.line.withValues(alpha: 0.5)),
          _buildMenuItem(context, icon: Icons.notifications_outlined, title: 'Notifikasi', onTap: () => _showComingSoon(context, 'Notifikasi')),
          Divider(height: 1, color: NeoMiraiColors.line.withValues(alpha: 0.5)),
          _buildMenuItem(context, icon: Icons.help_outline_rounded, title: 'Bantuan', onTap: () => _showComingSoon(context, 'Bantuan')),
          Divider(height: 1, color: NeoMiraiColors.line.withValues(alpha: 0.5)),
          _buildMenuItem(context, icon: Icons.info_outline_rounded, title: 'Tentang Aplikasi', onTap: () => _showInfoDialog(context)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(Responsive.radius(8)),
        decoration: BoxDecoration(color: NeoMiraiColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Responsive.radius(10))),
        child: Icon(icon, size: Responsive.iconSize(20), color: NeoMiraiColors.gold),
      ),
      title: Text(title, style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w500, color: NeoMiraiColors.ink)),
      trailing: Icon(Icons.chevron_right_rounded, size: Responsive.iconSize(20), color: NeoMiraiColors.inkSoft),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.construction_rounded, color: Colors.white), SizedBox(width: Responsive.spacing(10)), Text('$feature - Fitur dalam pengembangan')]),
        backgroundColor: NeoMiraiColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(20))),
        title: Row(children: [Icon(Icons.info_outline_rounded, color: NeoMiraiColors.gold), SizedBox(width: Responsive.spacing(10)), const Text('Tentang Aplikasi')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(icon: Icons.apps_rounded, title: 'SILATAR V2', desc: 'Versi 2.0.0'),
            SizedBox(height: Responsive.spacing(12)),
            _buildInfoItem(icon: Icons.business_rounded, title: 'Kementerian Agama', desc: 'Kabupaten Tanah Datar'),
            SizedBox(height: Responsive.spacing(12)),
            _buildInfoItem(icon: Icons.code_rounded, title: 'Developer', desc: 'Tim IT Kemenag Tanah Datar'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: NeoMiraiColors.gold, foregroundColor: NeoMiraiColors.rice),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String title, required String desc}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.radius(8)),
          decoration: BoxDecoration(color: NeoMiraiColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Responsive.radius(10))),
          child: Icon(icon, size: Responsive.iconSize(20), color: NeoMiraiColors.gold),
        ),
        SizedBox(width: Responsive.spacing(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: Responsive.fontSize(12))),
              Text(desc, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
            ],
          ),
        ),
      ],
    );
  }
}
