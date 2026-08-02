import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(16)),
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
          // User Avatar
          Container(
            padding: EdgeInsets.all(Responsive.radius(8)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
            ),
            child: Icon(
              Icons.person_rounded,
              size: Responsive.iconSize(24),
              color: NeoMiraiColors.rice,
            ),
          ),
          SizedBox(width: Responsive.spacing(12)),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: Responsive.fontSize(15),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                  ),
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

    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(20)),
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.nightGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
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
                      size: Responsive.iconSize(22),
                    ),
                    SizedBox(width: Responsive.spacing(8)),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(14),
                        color: NeoMiraiColors.rice,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.spacing(6)),
                Text(
                  _user?.displayName ?? 'Warga',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.rice,
                  ),
                ),
                SizedBox(height: Responsive.spacing(4)),
                Text(
                  'Kementerian Agama Tanah Datar',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(11),
                    color: NeoMiraiColors.rice.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(Responsive.radius(12)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: Responsive.iconSize(36),
              color: NeoMiraiColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Pengajuan',
          style: TextStyle(
            fontSize: Responsive.fontSize(14),
            fontWeight: FontWeight.bold,
            color: NeoMiraiColors.ink,
          ),
        ),
        SizedBox(height: Responsive.spacing(12)),

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
      mainAxisSpacing: Responsive.spacing(10),
      crossAxisSpacing: Responsive.spacing(10),
      childAspectRatio: context.isTablet ? 1.3 : 1.1,
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
      mainAxisSpacing: Responsive.spacing(10),
      crossAxisSpacing: Responsive.spacing(10),
      childAspectRatio: context.isTablet ? 1.3 : (context.isLandscape ? 1.2 : 1.1),
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
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(12)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(
          color: NeoMiraiColors.line.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Responsive.radius(10)),
            ),
            child: Icon(
              icon,
              size: Responsive.iconSize(20),
              color: color,
            ),
          ),
          SizedBox(height: Responsive.spacing(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.fontSize(20),
              fontWeight: FontWeight.bold,
              color: NeoMiraiColors.ink,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSize(10),
              color: NeoMiraiColors.inkSoft,
            ),
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
            fontSize: Responsive.fontSize(14),
            fontWeight: FontWeight.bold,
            color: NeoMiraiColors.ink,
          ),
        ),
        SizedBox(height: Responsive.spacing(12)),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline_rounded,
                label: 'Ajukan\nLayanan',
                color: NeoMiraiColors.gold,
                gradient: NeoMiraiTheme.goldGradient,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LayananPage()),
                ),
              ),
            ),
            SizedBox(width: Responsive.spacing(12)),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history_rounded,
                label: 'Pengajuan\nSaya',
                color: NeoMiraiColors.info,
                gradient: NeoMiraiTheme.nightGradient,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PengajuanPage()),
                ),
              ),
            ),
            SizedBox(width: Responsive.spacing(12)),
            Expanded(
              child: _buildActionCard(
                icon: Icons.help_outline_rounded,
                label: 'Panduan\nPenggunaan',
                color: NeoMiraiColors.ink,
                gradient: LinearGradient(
                  colors: [NeoMiraiColors.ash, NeoMiraiColors.line],
                ),
                onTap: () => _showGuideDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(14)),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(Responsive.radius(16)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: Responsive.iconSize(28),
              color: NeoMiraiColors.rice,
            ),
            SizedBox(height: Responsive.spacing(8)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(11),
                fontWeight: FontWeight.w600,
                color: NeoMiraiColors.rice,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
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
            horizontal: Responsive.spacing(16),
            vertical: Responsive.spacing(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Layanan',
                isActive: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LayananPage()),
                ),
              ),
              _buildNavItem(
                icon: Icons.description_rounded,
                label: 'Pengajuan',
                isActive: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PengajuanPage()),
                ),
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isActive: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.spacing(14),
          vertical: Responsive.spacing(8),
        ),
        decoration: isActive
            ? BoxDecoration(
                gradient: NeoMiraiTheme.goldGradient,
                borderRadius: BorderRadius.circular(Responsive.radius(14)),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: Responsive.iconSize(22),
              color: isActive ? NeoMiraiColors.rice : NeoMiraiColors.inkSoft,
            ),
            SizedBox(height: Responsive.spacing(4)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? NeoMiraiColors.rice : NeoMiraiColors.inkSoft,
              ),
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

  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(20)),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: NeoMiraiColors.gold),
            SizedBox(width: Responsive.spacing(10)),
            const Text('Panduan Penggunaan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideItem(
                icon: Icons.add_circle_outline,
                title: '1. Ajukan Layanan',
                desc: 'Pilih layanan yang dibutuhkan dan lengkapi persyaratan',
              ),
              _buildGuideItem(
                icon: Icons.description_outlined,
                title: '2. Upload Berkas',
                desc: 'Siapkan dan upload dokumen yang diperlukan',
              ),
              _buildGuideItem(
                icon: Icons.notifications_outlined,
                title: '3. Pantau Status',
                desc: 'Lacak status pengajuan Anda secara realtime',
              ),
              _buildGuideItem(
                icon: Icons.check_circle_outline,
                title: '4. Ambil Hasil',
                desc: 'Ambil hasil layanan di kantor terkait',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoMiraiColors.gold,
              foregroundColor: NeoMiraiColors.rice,
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.spacing(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(8)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Responsive.radius(10)),
            ),
            child: Icon(
              icon,
              size: Responsive.iconSize(18),
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
      ),
    );
  }
}
