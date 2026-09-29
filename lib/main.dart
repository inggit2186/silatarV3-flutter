import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/neo_mirai_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/patch_service.dart';
import 'core/services/update_service.dart';
import 'core/widgets/update_dialog.dart';
import 'core/models/user_model.dart';
import 'core/providers/user_provider.dart';
import 'features/welcome/welcome_page.dart';
import 'features/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize storage service
  await StorageService().init();

  // Initialize flutter_patcher for hot code push
  await PatchService.instance.initialize();

  // Set status bar style - transparent for splash with image
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const SILATARApp());
}

class SILATARApp extends StatelessWidget {
  const SILATARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'SILATAR V2',
        debugShowCheckedModeBanner: false,
        theme: NeoMiraiTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checkedUpdate = false;
  UpdateInfo? _pendingUpdate;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Check for updates in background
    // Enable check in debug mode for testing (set to true to always check)
    final bool enableUpdateCheck = true; // Change to false to disable in debug
    if ((!kDebugMode || enableUpdateCheck) && !_checkedUpdate) {
      _checkedUpdate = true;
      _pendingUpdate = await UpdateService.instance.checkForUpdate();
      debugPrint('[Splash] Update check completed: ${_pendingUpdate != null ? "Update available" : "No update"}');
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Show update dialog if update available
    if (_pendingUpdate != null && _pendingUpdate!.hasUpdate) {
      await _showUpdateDialog();
    }

    // Continue navigation
    if (!mounted) return;
    await _navigateToDestination();
  }

  Future<void> _showUpdateDialog() async {
    if (!mounted || _pendingUpdate == null) return;

    final info = _pendingUpdate!;

    // For APK updates, use progress callback
    Future<UpdateResult> Function(double, String)? onUpdateWithProgress;
    Function(UpdateResult)? onUpdate;

    if (info.isApk) {
      // APK update with progress
      onUpdateWithProgress = (progress, status) async {
        // Download and install APK
        return await UpdateService.instance.downloadAndInstall(
          downloadUrl: info.downloadUrl,
          version: info.version,
          md5: info.md5,
          onProgress: (p, s) {
            // Progress will be handled by the dialog's internal state
            debugPrint('[APK Update] Progress: ${(p * 100).toStringAsFixed(0)}% - $s');
          },
        );
      };
    } else {
      // Patch update without progress
      onUpdate = (result) async {
        return await UpdateService.instance.applyUpdate(info);
      };
    }

    await showUpdateDialog(
      context: context,
      info: info,
      barrierDismissible: !info.isMandatory,
      onUpdate: onUpdate ?? (_) async => UpdateResult(success: true, message: ''),
      onUpdateWithProgress: onUpdateWithProgress,
      onLater: info.isMandatory
          ? null
          : () {
              Navigator.pop(context);
            },
      onRestart: () {
        debugPrint('[Splash] Restart app to apply changes');
      },
    );
  }

  Future<void> _navigateToDestination() async {
    // Check if user is logged in (remember me)
    final isLoggedIn = await StorageService().isLoggedIn();

    if (isLoggedIn) {
      // Load token into ApiService
      final token = await StorageService().getToken();
      if (token != null) {
        ApiService.instance.setToken(token);
      }

      // Fetch fresh user data from API
      final response = await ApiService.instance.getProfile();

      if (response.success && response.data != null && mounted) {
        final user = response.data!;
        context.read<UserProvider>().setUser(user);

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
        return;
      }

      // API failed - use cached data
      final userData = await StorageService().getUser();
      if (userData != null && mounted) {
        final user = User.fromJson(userData);
        context.read<UserProvider>().setUser(user);

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
        return;
      }
    }

    // Not logged in - go to Welcome
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WelcomePage(),
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Fallback gradient if image not found
              return Container(
                decoration: BoxDecoration(
                  gradient: NeoMiraiTheme.nightGradient,
                ),
              );
            },
          ),

          // Gradient overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Loading Indicator with animated rings
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated Loading Indicator
                  _buildAnimatedLoader()
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 2000.ms, curve: Curves.linear),

                  const SizedBox(height: 24),

                  // Loading Text
                  Text(
                    'Memuat...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeIn(duration: 800.ms)
                      .then()
                      .fadeOut(duration: 800.ms),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLoader() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          // Outer ring
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                NeoMiraiColors.gold.withValues(alpha: 0.8),
              ),
            ),
          ),
          // Inner ring
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                NeoMiraiColors.gold.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Center dot
          Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoMiraiColors.gold,
                boxShadow: [
                  BoxShadow(
                    color: NeoMiraiColors.gold.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
