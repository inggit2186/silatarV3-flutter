import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/models/user_model.dart';
import '../../core/models/news_model.dart';
import '../../core/providers/kegiatan_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/config/app_version.dart';
import '../../core/services/patch_service.dart';
import 'package:provider/provider.dart';
import '../berita/news_slideshow.dart';
import '../kegiatan/kegiatan_page.dart';
import '../layanan/layanan_page.dart';
import '../presensi/presensi_page.dart';
import '../profile/profile_page.dart';
import '../riwayat/riwayat_presensi_page.dart';

class DashboardPage extends StatefulWidget {
  final User? user;

  const DashboardPage({super.key, this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _user;
  List<NewsModel> _news = [];
  bool _isLoadingNews = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _user = widget.user;
    _loadUserProfile();
    _loadNews();
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

  Future<void> _loadNews() async {
    final response = await ApiService.instance.getLatestNews(limit: 5);
    if (!mounted) return;

    setState(() {
      _isLoadingNews = false;
      _news = response.success
          ? (response.data ?? <NewsModel>[])
          : <NewsModel>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final isLandscape = context.isLandscape;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: NeoMiraiTheme.paperGradient),
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
        setState(() => _isLoadingNews = true);
        await _loadNews();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(Responsive.spacing(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            _buildGreetingCard(
              context,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            SizedBox(height: Responsive.spacing(20)),

            // Berita Slideshow
            NewsSlideshow(
              news: _news,
              isLoading: _isLoadingNews,
              onRetry: () {
                setState(() => _isLoadingNews = true);
                _loadNews();
              },
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            SizedBox(height: Responsive.spacing(20)),

            // Quick Actions
            _buildQuickActions(
              context,
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeContent(BuildContext context) {
    return Row(
      children: [
        // Left side - Greeting & Berita
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.spacing(16)),
            child: Column(
              children: [
                _buildGreetingCard(context).animate().fadeIn(duration: 400.ms),
                SizedBox(height: Responsive.spacing(16)),
                NewsSlideshow(
                  news: _news,
                  isLoading: _isLoadingNews,
                  onRetry: () {
                    setState(() => _isLoadingNews = true);
                    _loadNews();
                  },
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          ),
        ),

        // Right side - Quick Actions
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.spacing(16)),
            child: _buildQuickActions(
              context,
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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
        borderRadius: BorderRadius.circular(
          Responsive.radius(isSmall ? 16 : 20),
        ),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PresensiPage()),
                ),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => KegiatanProvider(),
                      child: const KegiatanPage(initialTab: 'harian'),
                    ),
                  ),
                ),
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
          borderRadius: BorderRadius.circular(
            Responsive.radius(isSmall ? 12 : 14),
          ),
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
            FutureBuilder<({String version, int versionCode})>(
              future: PatchService.instance.getCurrentVersionInfo(),
              builder: (context, snapshot) {
                final versionText =
                    snapshot.data?.version ?? AppVersion.version;
                final buildNumber =
                    snapshot.data?.versionCode ?? AppVersion.appVersionCode;
                return _buildInfoItem(
                  icon: Icons.apps_rounded,
                  title: 'SILATAR V2',
                  desc: 'Versi v$versionText (build $buildNumber)',
                );
              },
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
                    MaterialPageRoute(
                      builder: (context) => const LayananPage(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.history_rounded,
                  label: 'Riwayat Presensi',
                  isActive: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RiwayatPresensiPage(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  isActive: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
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
                borderRadius: BorderRadius.circular(
                  Responsive.radius(isSmall ? 10 : 14),
                ),
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ApiService.instance.logout();
              if (context.mounted) {
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
