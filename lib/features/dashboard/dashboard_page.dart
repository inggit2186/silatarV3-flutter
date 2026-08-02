import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../layanan/layanan_page.dart';
import '../pengajuan/pengajuan_page.dart';
import '../profile/profile_page.dart';

class DashboardPage extends StatefulWidget {
  final User? user;

  const DashboardPage({super.key, this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _user;
  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'diproses': 0,
    'selesai': 0,
    'ditolak': 0,
  };
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _user = widget.user;
    _loadUserProfile();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) return;

    final response = await ApiService.instance.getProfile();
    if (response.success && response.data != null && mounted) {
      setState(() {
        _user = response.data;
      });
    }
  }

  Future<void> _loadStats() async {
    final response = await ApiService.instance.getMyPengajuan();
    if (response.success && response.data != null && mounted) {
      setState(() {
        _isLoadingStats = false;
        _stats = {
          'total': response.data?['total'] ?? 0,
          'pending': response.data?['pending'] ?? 0,
          'diproses': response.data?['diproses'] ?? 0,
          'selesai': response.data?['selesai'] ?? 0,
          'ditolak': response.data?['ditolak'] ?? 0,
        };
      });
    } else {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isLandscape = context.isLandscape;

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
                child: isLandscape
                    ? _buildLandscapeContent(context)
                    : _buildPortraitContent(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool hasPhoto = _user?.hasPhoto ?? false;
    final String? photoUrl = _user?.photoUrl;

    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(12)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar / Photo
          _buildUserAvatar(hasPhoto, photoUrl),

          SizedBox(width: Responsive.spacing(12)),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selamat Datang,',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(11),
                    color: NeoMiraiColors.inkSoft,
                  ),
                ),
                Text(
                  _user?.displayName ?? 'Warga',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(14),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menu Button
          PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(Responsive.radius(8)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.line.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: Responsive.iconSize(20),
                color: NeoMiraiColors.ink,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: NeoMiraiColors.ink),
                    SizedBox(width: Responsive.spacing(10)),
                    const Text('Profil Saya'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: NeoMiraiColors.error),
                    SizedBox(width: Responsive.spacing(10)),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(bool hasPhoto, String? photoUrl) {
    final double avatarSize = context.isSmallPhone ? 40 : 48;

    if (hasPhoto && photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildDefaultAvatar(avatarSize),
          errorWidget: (context, url, error) => _buildDefaultAvatar(avatarSize),
        ),
      );
    }

    return _buildDefaultAvatar(avatarSize);
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(Responsive.radius(8)),
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.goldGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Icon(
        Icons.person_rounded,
        size: Responsive.iconSize(20),
        color: NeoMiraiColors.rice,
      ),
    );
  }

  Widget _buildPortraitContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStats();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(Responsive.spacing(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            _buildGreetingCard(context)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),

            SizedBox(height: Responsive.spacing(20)),

            // Stats Grid
            _buildStatsSection(context)
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),

            SizedBox(height: Responsive.spacing(20)),

            // Quick Actions
            _buildQuickActions(context)
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms),

            SizedBox(height: Responsive.spacing(20)),

            // Recent Activity
            _buildRecentActivity(context)
                .animate()
                .fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeContent(BuildContext context) {
    return Row(
      children: [
        // Left side - Stats & Quick Actions
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.spacing(16)),
            child: Column(
              children: [
                _buildGreetingCard(context)
                    .animate()
                    .fadeIn(duration: 400.ms),
                SizedBox(height: Responsive.spacing(16)),
                _buildStatsSection(context)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                SizedBox(height: Responsive.spacing(16)),
                _buildQuickActions(context)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms),
              ],
            ),
          ),
        ),

        // Right side - Recent Activity
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.spacing(16)),
            child: _buildRecentActivity(context)
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Selamat Pagi';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
      greetingIcon = Icons.wb_twilight_rounded;
    } else {
      greeting = 'Selamat Malam';
      greetingIcon = Icons.nightlight_rounded;
    }

    final bool isSmall = context.isSmallPhone;

    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(isSmall ? 14 : 20)),
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.nightGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(isSmall ? 16 : 20)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.night.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      greetingIcon,
                      color: NeoMiraiColors.gold,
                      size: Responsive.iconSize(isSmall ? 18 : 22),
                    ),
                    SizedBox(width: Responsive.spacing(6)),
                    Expanded(
                      child: Text(
                        greeting,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(isSmall ? 12 : 14),
                          color: NeoMiraiColors.rice,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.spacing(4)),
                Text(
                  _user?.displayName ?? 'Warga',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(isSmall ? 16 : 20),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.rice,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.spacing(2)),
                Text(
                  'Kemenag Tanah Datar',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(isSmall ? 9 : 11),
                    color: NeoMiraiColors.rice.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: Responsive.spacing(12)),
          Container(
            padding: EdgeInsets.all(Responsive.radius(isSmall ? 10 : 12)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: Responsive.iconSize(isSmall ? 28 : 36),
              color: NeoMiraiColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final bool isSmall = context.isSmallPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Pengajuan',
          style: TextStyle(
            fontSize: Responsive.fontSize(isSmall ? 12 : 14),
            fontWeight: FontWeight.bold,
            color: NeoMiraiColors.ink,
          ),
        ),
        SizedBox(height: Responsive.spacing(8)),

        if (_isLoadingStats)
          _buildLoadingStats()
        else
          _buildStatsGrid(context),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return GridView.count(
      crossAxisCount: context.isTablet ? 5 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Responsive.spacing(8),
      crossAxisSpacing: Responsive.spacing(8),
      childAspectRatio: context.isTablet ? 1.3 : (context.isLandscape ? 1.2 : 1.1),
      children: List.generate(5, (index) => _buildStatCard(
        label: '...',
        value: '0',
        icon: Icons.history_rounded,
        color: NeoMiraiColors.ash,
        isLoading: true,
      )),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final statsData = [
      {'label': 'Total', 'value': _stats['total'].toString(), 'icon': Icons.folder_rounded, 'color': NeoMiraiColors.night},
      {'label': 'Pending', 'value': _stats['pending'].toString(), 'icon': Icons.schedule_rounded, 'color': NeoMiraiColors.warning},
      {'label': 'Diproses', 'value': _stats['diproses'].toString(), 'icon': Icons.sync_rounded, 'color': NeoMiraiColors.info},
      {'label': 'Selesai', 'value': _stats['selesai'].toString(), 'icon': Icons.check_circle_rounded, 'color': NeoMiraiColors.success},
      {'label': 'Ditolak', 'value': _stats['ditolak'].toString(), 'icon': Icons.cancel_rounded, 'color': NeoMiraiColors.error},
    ];

    return GridView.count(
      crossAxisCount: context.isTablet ? 5 : (context.isLandscape ? 5 : 3),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Responsive.spacing(8),
      crossAxisSpacing: Responsive.spacing(8),
      childAspectRatio: context.isTablet ? 1.2 : (context.isLandscape ? 1.0 : 0.95),
      children: statsData.asMap().entries.map((entry) {
        final data = entry.value;
        return _buildStatCard(
          label: data['label']!.toString(),
          value: data['value']!.toString(),
          icon: data['icon'] as IconData,
          color: data['color'] as Color,
        ).animate().fadeIn(
          delay: Duration(milliseconds: 100 * entry.key),
          duration: 300.ms,
        ).slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    final bool isSmall = context.isSmallPhone;
    final double padding = isSmall ? 6 : 10;
    final double iconSize = isSmall ? 14 : 18;
    final double valueSize = isSmall ? 16 : 18;
    final double labelSize = isSmall ? 8 : 9;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(isSmall ? 10 : 14)),
        border: Border.all(
          color: NeoMiraiColors.line.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 4 : 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Responsive.radius(6)),
            ),
            child: Icon(
              icon,
              size: Responsive.iconSize(iconSize),
              color: color,
            ),
          ),
          SizedBox(height: Responsive.spacing(isSmall ? 2 : 4)),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.fontSize(valueSize),
              fontWeight: FontWeight.bold,
              color: NeoMiraiColors.ink,
            ),
          ),
          SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSize(labelSize),
              color: NeoMiraiColors.inkSoft,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: Responsive.fontSize(13),
            fontWeight: FontWeight.bold,
            color: NeoMiraiColors.ink,
          ),
        ),
        SizedBox(height: Responsive.spacing(10)),

        // First row: Ajukan Layanan & Pengajuan Saya (bigger cards)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildActionCardV2(
                icon: Icons.add_circle_rounded,
                label: 'Ajukan Layanan',
                subtitle: 'Layanan baru',
                gradient: NeoMiraiTheme.goldGradient,
                iconBgColor: NeoMiraiColors.goldBright,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LayananPage()),
                ),
              ),
            ),
            SizedBox(width: Responsive.spacing(10)),
            Expanded(
              flex: 3,
              child: _buildActionCardV2(
                icon: Icons.history_rounded,
                label: 'Pengajuan Saya',
                subtitle: 'Lacak status',
                gradient: NeoMiraiTheme.nightGradient,
                iconBgColor: NeoMiraiColors.night,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PengajuanPage()),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: Responsive.spacing(10)),

        // Second row: Presensi, Kegiatan, Info (smaller cards)
        Row(
          children: [
            Expanded(
              child: _buildActionCardSmall(
                icon: Icons.fingerprint_rounded,
                label: 'Presensi',
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NeoMiraiColors.success,
                    NeoMiraiColors.success.withValues(alpha: 0.85),
                  ],
                ),
                onTap: () => _showComingSoon(context, 'Presensi'),
              ),
            ),
            SizedBox(width: Responsive.spacing(8)),
            Expanded(
              child: _buildActionCardSmall(
                icon: Icons.event_rounded,
                label: 'Kegiatan',
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NeoMiraiColors.warning,
                    NeoMiraiColors.warning.withValues(alpha: 0.85),
                  ],
                ),
                onTap: () => _showComingSoon(context, 'Kegiatan'),
              ),
            ),
            SizedBox(width: Responsive.spacing(8)),
            Expanded(
              child: _buildActionCardSmall(
                icon: Icons.info_rounded,
                label: 'Info',
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NeoMiraiColors.info,
                    NeoMiraiColors.info.withValues(alpha: 0.85),
                  ],
                ),
                onTap: () => _showInfoDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Large action card for main actions
  Widget _buildActionCardV2({
    required IconData icon,
    required String label,
    required String subtitle,
    required LinearGradient gradient,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    final bool isSmall = context.isSmallPhone;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(isSmall ? 12 : 16)),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(Responsive.radius(isSmall ? 14 : 18)),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(isSmall ? 10 : 12)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              child: Icon(
                icon,
                size: Responsive.iconSize(isSmall ? 24 : 28),
                color: Colors.white,
              ),
            ),
            SizedBox(width: Responsive.spacing(isSmall ? 10 : 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(isSmall ? 12 : 14),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(isSmall ? 9 : 10),
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: Responsive.iconSize(14),
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  /// Small action card for secondary actions
  Widget _buildActionCardSmall({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final bool isSmall = context.isSmallPhone;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Responsive.spacing(isSmall ? 12 : 14),
          horizontal: Responsive.spacing(isSmall ? 6 : 8),
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(Responsive.radius(isSmall ? 12 : 14)),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(isSmall ? 8 : 10)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: Responsive.iconSize(isSmall ? 22 : 26),
                color: Colors.white,
              ),
            ),
            SizedBox(height: Responsive.spacing(isSmall ? 6 : 8)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(isSmall ? 9 : 10),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction_rounded, color: Colors.white),
            SizedBox(width: Responsive.spacing(10)),
            Text('$feature sedang dalam pengembangan'),
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(20)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: NeoMiraiColors.gold),
            SizedBox(width: Responsive.spacing(10)),
            const Text('Informasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              icon: Icons.apps_rounded,
              title: 'SILATAR V2',
              desc: 'Versi 2.0.0',
            ),
            SizedBox(height: Responsive.spacing(12)),
            _buildInfoItem(
              icon: Icons.business_rounded,
              title: 'Kementerian Agama',
              desc: 'Kabupaten Tanah Datar',
            ),
            SizedBox(height: Responsive.spacing(12)),
            _buildInfoItem(
              icon: Icons.help_outline_rounded,
              title: 'Bantuan',
              desc: 'Hubungi admin untuk bantuan',
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.radius(8)),
          decoration: BoxDecoration(
            color: NeoMiraiColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Responsive.radius(10)),
          ),
          child: Icon(
            icon,
            size: Responsive.iconSize(20),
            color: NeoMiraiColors.gold,
          ),
        ),
        SizedBox(width: Responsive.spacing(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.fontSize(12),
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  color: NeoMiraiColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terakhir',
              style: TextStyle(
                fontSize: Responsive.fontSize(14),
                fontWeight: FontWeight.bold,
                color: NeoMiraiColors.ink,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PengajuanPage()),
              ),
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  color: NeoMiraiColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.spacing(8)),

        // Empty state or activity list
        _buildEmptyActivity(),
      ],
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(24)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(
          color: NeoMiraiColors.line.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(14)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: Responsive.iconSize(36),
              color: NeoMiraiColors.gold,
            ),
          ),
          SizedBox(height: Responsive.spacing(12)),
          Text(
            'Belum Ada Aktivitas',
            style: TextStyle(
              fontSize: Responsive.fontSize(13),
              fontWeight: FontWeight.w600,
              color: NeoMiraiColors.ink,
            ),
          ),
          SizedBox(height: Responsive.spacing(4)),
          Text(
            'Pengajuan layanan Anda akan\nmuncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(11),
              color: NeoMiraiColors.inkSoft,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
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
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Layanan',
                  isActive: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LayananPage()),
                  ),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.history_rounded,
                  label: 'Riwayat Presensi',
                  isActive: false,
                  onTap: () => _showComingSoon(context, 'Riwayat Presensi'),
                ),
              ),
              Expanded(
                child: _buildNavItem(
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
              color: isActive ? NeoMiraiColors.rice : NeoMiraiColors.inkSoft,
            ),
            SizedBox(height: Responsive.spacing(2)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(isSmall ? 8 : 10),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? NeoMiraiColors.rice : NeoMiraiColors.inkSoft,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
