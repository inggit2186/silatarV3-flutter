import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/neo_components.dart';
import '../login/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize responsive
    Responsive.init(context);

    final isLandscape = context.isLandscape;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: NeoMiraiTheme.paperGradient,
        ),
        child: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(context)
              : _buildPortraitLayout(context),
        ),
      ),
    );
  }

  /// Portrait Layout (Phone vertical)
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      children: [
        // Top Bar with Skip
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding,
            vertical: Responsive.verticalPadding * 1.5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _navigateToLogin(context),
                child: Text(
                  'Lewati',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: NeoMiraiColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),

        // Content - Scrollable
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: Responsive.spacing(10)),

                  // Logo
                  _buildLogo(context)
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),

                  SizedBox(height: Responsive.spacing(28)),

                  // Title
                  Text(
                    'Selamat Datang',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NeoMiraiColors.ink,
                          fontSize: Responsive.fontSize(24),
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                  SizedBox(height: Responsive.spacing(6)),

                  // Subtitle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'di ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: NeoMiraiColors.inkSoft,
                              fontSize: Responsive.fontSize(18),
                            ),
                      ),
                      Text(
                        'SILATAR',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: NeoMiraiColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.fontSize(18),
                              letterSpacing: 2,
                            ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                  SizedBox(height: Responsive.spacing(12)),

                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(16),
                    ),
                    child: Text(
                      'Sistem Informasi Layanan Administrasi\nKementerian Agama Tanah Datar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoMiraiColors.inkSoft,
                            height: 1.4,
                            fontSize: Responsive.fontSize(14),
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms),

                  SizedBox(height: Responsive.spacing(32)),

                  // Features
                  _buildFeatures(context)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: Responsive.spacing(32)),
                ],
              ),
            ),
          ),
        ),

        // Bottom Action
        Padding(
          padding: EdgeInsets.all(Responsive.cardPadding(20)),
          child: Column(
            children: [
              NeoButton(
                text: 'MULAI',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => _navigateToLogin(context),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

              SizedBox(height: Responsive.spacing(12)),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NeoMiraiColors.inkSoft,
                        ),
                  ),
                  TextButton(
                    onPressed: () => _navigateToLogin(context),
                    child: Text(
                      'Masuk',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NeoMiraiColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms),
            ],
          ),
        ),
      ],
    );
  }

  /// Landscape Layout (Phone horizontal)
  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Logo
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(Responsive.spacing(24)),
            child: _buildLogo(context)
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                ),
          ),
        ),

        // Right side - Content
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(16),
              vertical: Responsive.spacing(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _navigateToLogin(context),
                    child: Text(
                      'Lewati',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoMiraiColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.spacing(8)),

                // Title
                Text(
                  'Selamat Datang',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NeoMiraiColors.ink,
                      ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms),

                SizedBox(height: Responsive.spacing(16)),

                // Button
                SizedBox(
                  width: 200,
                  child: NeoButton(
                    text: 'MULAI',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => _navigateToLogin(context),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    final logoSize = Responsive.logoSize(130);

    return Center(
      child: Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: NeoMiraiTheme.goldGradient,
          border: Border.all(
            color: NeoMiraiColors.goldLight.withValues(alpha: 0.5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.gold.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background pattern
            ...List.generate(2, (index) {
              return Container(
                width: (logoSize * 0.5) + (index * 20),
                height: (logoSize * 0.5) + (index * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NeoMiraiColors.rice.withValues(alpha: 0.1 + (index * 0.1)),
                    width: 1,
                  ),
                ),
              );
            }),

            // Main Icon
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.radius(12)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.rice.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: Responsive.iconSize(38),
                    color: NeoMiraiColors.rice,
                  ),
                ),
                SizedBox(height: Responsive.spacing(6)),
                Text(
                  'SILATAR',
                  style: TextStyle(
                    color: NeoMiraiColors.rice,
                    fontSize: Responsive.fontSize(12),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final isSmallPhone = context.isSmallPhone;

    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(isSmallPhone ? 16 : 20)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        border: Border.all(
          color: NeoMiraiColors.line.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.folder_open_rounded,
              title: 'Layanan',
              subtitle: 'Lengkap',
              color: NeoMiraiColors.gold,
              isSmall: isSmallPhone,
            ),
          ),
          Container(
            width: 1,
            height: 45,
            color: NeoMiraiColors.line.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.speed_rounded,
              title: 'Proses',
              subtitle: 'Cepat',
              color: NeoMiraiColors.night,
              isSmall: isSmallPhone,
            ),
          ),
          Container(
            width: 1,
            height: 45,
            color: NeoMiraiColors.line.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _buildFeatureItem(
              icon: Icons.verified_rounded,
              title: 'Akuntabel',
              subtitle: '',
              color: NeoMiraiColors.sun,
              isSmall: isSmallPhone,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSmall,
  }) {
    final iconSize = Responsive.featureIconSize(isSmall ? 20 : 24);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmall ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
        SizedBox(height: Responsive.spacing(6)),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: NeoMiraiColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmall ? 9 : 10,
              color: NeoMiraiColors.ash,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
