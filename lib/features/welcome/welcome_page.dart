import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/update_service.dart';
import '../login/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/welcome_bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: NeoMiraiTheme.nightGradient,
                ),
              );
            },
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Button at bottom
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.horizontalPadding,
                    vertical: Responsive.cardPadding(24),
                  ),
                  child: _buildStartButton(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => _navigateToLogin(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.spacing(14),
                horizontal: Responsive.spacing(24),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFD4AF37), // Gold
                    Color(0xFFB8860B), // Dark Goldenrod
                    Color(0xFFDAA520), // Goldenrod
                  ],
                ),
                borderRadius: BorderRadius.circular(Responsive.radius(50)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFDAA520).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text with futuristic style
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFFFF8DC), // Cornsilk
                        Colors.white,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      'MULAI',
                      style: TextStyle(
                        fontFamily: 'Chakra Petch',
                        fontSize: Responsive.fontSize(18),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Arrow icon with glow
                  Container(
                    padding: EdgeInsets.all(Responsive.radius(8)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: Responsive.iconSize(18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Version text
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(12),
            vertical: Responsive.spacing(4),
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
          ),
          child: Text(
            'Versi Aplikasi : v${UpdateService.currentVersion} (${UpdateService.currentVersionCode})',
            style: TextStyle(
              fontSize: Responsive.fontSize(10),
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
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
