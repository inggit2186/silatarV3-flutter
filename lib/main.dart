import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'core/theme/neo_mirai_theme.dart';
import 'core/utils/responsive.dart';
import 'core/services/storage_service.dart';
import 'core/models/user_model.dart';
import 'features/welcome/welcome_page.dart';
import 'features/dashboard/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService().init();

  // Set status bar style - matching web theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const SILATARApp());
}

class SILATARApp extends StatelessWidget {
  const SILATARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SILATAR V2',
      debugShowCheckedModeBanner: false,
      theme: NeoMiraiTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  Future<void> _navigateToWelcome() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check if user is logged in (remember me)
    final isLoggedIn = await StorageService().isLoggedIn();

    if (isLoggedIn) {
      // Try to get saved user data
      final userData = await StorageService().getUser();

      if (userData != null && mounted) {
        // Auto login - navigate to Dashboard
        final user = User.fromJson(userData);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DashboardPage(user: user),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
        return;
      }
    }

    // Normal flow - go to Welcome
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive
    Responsive.init(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeoMiraiColors.night,
              NeoMiraiColors.nightSoft,
              NeoMiraiColors.gold,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Animated Logo
                    _buildLogo()
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 600.ms),

                    const SizedBox(height: 32),

                    // App Name
                    const Text(
                      'SILATAR',
                      style: TextStyle(
                        fontFamily: 'Chakra Petch',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: NeoMiraiColors.rice,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 4),

                    const Text(
                      'V2',
                      style: TextStyle(
                        fontFamily: 'Chakra Petch',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: NeoMiraiColors.goldBright,
                        letterSpacing: 4,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms),

                    const SizedBox(height: 12),

                    // Tagline
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Layanan Kementerian Agama Tanah Datar',
                        style: TextStyle(
                          fontSize: 13,
                          color: NeoMiraiColors.rice,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms),

                    const SizedBox(height: 60),

                    // Loading Indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          NeoMiraiColors.gold.withValues(alpha: 0.9),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 1000.ms, duration: 400.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NeoMiraiColors.gold.withValues(alpha: 0.3),
            NeoMiraiColors.rice.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: NeoMiraiColors.gold.withValues(alpha: 0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.gold.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pattern
          ...List.generate(2, (index) {
            return Container(
              width: 80 + (index * 30),
              height: 80 + (index * 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.1 + (index * 0.1)),
                  width: 1,
                ),
              ),
            );
          }),

          // Center icon
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  size: 40,
                  color: NeoMiraiColors.rice,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
