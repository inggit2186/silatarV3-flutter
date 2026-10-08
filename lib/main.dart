import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/neo_mirai_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/apk_update_service.dart';
import 'core/services/patch_service.dart';
import 'core/services/update_service.dart';
import 'core/config/app_version.dart';
import 'core/widgets/update_dialog.dart';
import 'core/models/user_model.dart';
import 'core/providers/user_provider.dart';
import 'features/welcome/welcome_page.dart';
import 'features/main_shell.dart';

/// Keys for SharedPreferences
class PrefsKeys {
  static const String pendingMandatoryApk = 'pending_mandatory_apk';
  static const String pendingMandatoryApkVersion = 'pending_mandatory_apk_version';
  static const String pendingMandatoryApkVersionCode = 'pending_mandatory_apk_version_code';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize storage service
  await StorageService().init();

  // Initialize flutter_patcher for hot code push
  // _checkApkUpgrade() akan dipanggil otomatis di initialize()
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
        locale: const Locale('id', 'ID'),
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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
  bool _pendingMandatoryApk = false;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  /// Check if there's a pending mandatory APK install
  Future<void> _checkPendingMandatoryApk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPending = prefs.getBool(PrefsKeys.pendingMandatoryApk) ?? false;
      if (hasPending) {
        final pendingVersion = prefs.getString(PrefsKeys.pendingMandatoryApkVersion);
        final pendingVersionCode = prefs.getInt(PrefsKeys.pendingMandatoryApkVersionCode);
        debugPrint('[Splash] Pending mandatory APK found: $pendingVersion ($pendingVersionCode)');
        setState(() {
          _pendingMandatoryApk = true;
        });
      }
    } catch (e) {
      debugPrint('[Splash] Error checking pending APK: $e');
    }
  }

  /// Clear pending mandatory APK when successfully installed
  Future<void> _clearPendingMandatoryApk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefsKeys.pendingMandatoryApk);
      await prefs.remove(PrefsKeys.pendingMandatoryApkVersion);
      await prefs.remove(PrefsKeys.pendingMandatoryApkVersionCode);
      debugPrint('[Splash] Pending mandatory APK cleared');
    } catch (e) {
      debugPrint('[Splash] Error clearing pending APK: $e');
    }
  }

  /// Set pending mandatory APK
  Future<void> _setPendingMandatoryApk(UpdateInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefsKeys.pendingMandatoryApk, true);
      await prefs.setString(PrefsKeys.pendingMandatoryApkVersion, info.version);
      await prefs.setInt(PrefsKeys.pendingMandatoryApkVersionCode, info.versionCode);
      debugPrint('[Splash] Pending mandatory APK set: ${info.version} (${info.versionCode})');
    } catch (e) {
      debugPrint('[Splash] Error setting pending APK: $e');
    }
  }

  Future<void> _initializeAndNavigate() async {
    // Check for pending mandatory APK install first
    await _checkPendingMandatoryApk();

    // If there's a pending mandatory APK, check if APK was already installed.
    // Dengan hybrid approach: Bandingkan appVersionCode
    if (_pendingMandatoryApk) {
      final prefs = await SharedPreferences.getInstance();
      final pendingVersionCode = prefs.getInt(PrefsKeys.pendingMandatoryApkVersionCode);
      final pendingVersion = prefs.getString(PrefsKeys.pendingMandatoryApkVersion);

      debugPrint('[Splash] ===== PENDING APK CHECK =====');
      debugPrint('[Splash] pendingMandatoryApk = $_pendingMandatoryApk');
      debugPrint('[Splash] pendingVersion = $pendingVersion');
      debugPrint('[Splash] pendingVersionCode = $pendingVersionCode');
      debugPrint('[Splash] current AppVersion.appVersionCode = ${AppVersion.appVersionCode}');
      debugPrint('[Splash] current AppVersion.version = ${AppVersion.version}');

      // Bandingkan appVersionCode
      final currentAppVersionCode = AppVersion.appVersionCode;
      if (pendingVersionCode != null) {
        if (pendingVersionCode <= currentAppVersionCode) {
          // APK sudah terinstall dengan versi >= yang ditunggu.
          debugPrint('[Splash] ✅ APK already installed — clearing pending');
          await _clearPendingMandatoryApk();
          setState(() => _pendingMandatoryApk = false);
        } else {
          debugPrint('[Splash] ❌ APK NOT yet installed (pending > current) — keep pending');
        }
      } else {
        // pendingVersionCode null — tidak valid, clearkan saja
        debugPrint('[Splash] ❌ pendingVersionCode is NULL — clearing pending');
        await _clearPendingMandatoryApk();
        setState(() => _pendingMandatoryApk = false);
      }
      debugPrint('[Splash] ===== END PENDING CHECK =====');
    }

    // Check for updates in background
    // Enable check in debug mode for testing (set to true to always check)
    final bool enableUpdateCheck = true; // Change to false to disable in debug
    if ((!kDebugMode || enableUpdateCheck) && !_checkedUpdate) {
      _checkedUpdate = true;
      // If mandatory APK is pending, skip update check
      if (!_pendingMandatoryApk) {
        debugPrint('[Splash] Calling checkForUpdate()...');
        _pendingUpdate = await UpdateService.instance.checkForUpdate();
        debugPrint('[Splash] Update check completed: ${_pendingUpdate != null ? "Update available: ${_pendingUpdate!.version} (${_pendingUpdate!.versionCode}) type=${_pendingUpdate!.updateType}" : "No update"}');
      } else {
        debugPrint('[Splash] Skipping update check - pending mandatory APK');
      }
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // Show update dialog if:
    // 1. Update available, or
    // 2. Pending mandatory APK install
    debugPrint('[Splash] Decision: _pendingMandatoryApk=$_pendingMandatoryApk _pendingUpdate=${_pendingUpdate?.versionCode} hasUpdate=${_pendingUpdate?.hasUpdate}');
    if (_pendingMandatoryApk || (_pendingUpdate != null && _pendingUpdate!.hasUpdate)) {
      debugPrint('[Splash] ✅ Showing update dialog');
      await _showUpdateDialog();
    } else {
      debugPrint('[Splash] ❌ Skipping dialog — no pending APK and no update');
    }

    // Continue navigation only if no pending mandatory APK
    if (!mounted) return;
    await _navigateToDestination();
  }

  Future<void> _showUpdateDialog() async {
    if (!mounted) return;

    UpdateInfo info;

    // Check if we have pending mandatory APK
    if (_pendingMandatoryApk) {
      final prefs = await SharedPreferences.getInstance();
      final pendingVersionCode = prefs.getInt(PrefsKeys.pendingMandatoryApkVersionCode) ?? 1;

      // Check for actual update info from backend
      final freshUpdate = await UpdateService.instance.checkForUpdate();

      // Jika API return null (APK disabled / sudah diinstall), cek apakah
      // APK sudah terinstall dengan versi >= pending. Jika ya, clearkan
      // pending state dan skip dialog.
      if (freshUpdate == null) {
        // APK update disabled / already installed
        // Gunakan AppVersion.appVersionCode sebagai source of truth
        final currentAppVersionCode = AppVersion.appVersionCode;
        debugPrint('[Splash] APK update disabled in backend: pending=$pendingVersionCode current=$currentAppVersionCode');

        if (pendingVersionCode <= currentAppVersionCode) {
          // APK sudah diinstall (atau pending tidak valid) — clearkan dan skip
          debugPrint('[Splash] APK already installed — clearing pending and skipping dialog');
          await _clearPendingMandatoryApk();
          setState(() => _pendingMandatoryApk = false);
          // Check if there's a non-mandatory update available
          _pendingUpdate = null;
        }
        // else: API null tapi APK belum diinstall → skip dialog (tidak ada URL untuk download)
        // User bisa coba lagi di kesempatan berikutnya
        return;
      }

      info = freshUpdate;
    } else if (_pendingUpdate != null) {
      info = _pendingUpdate!;
    } else {
      return;
    }

    if (info.isApk) {
      // APK update with progress callback
      await showUpdateDialog(
        context: context,
        info: info,
        barrierDismissible: false, // Always non-dismissible for APK mandatory
        onUpdate: (_) async => UpdateResult(success: true, message: ''),
        onApkDownloadWithProgress: (onProgress) async {
          // Download APK with progress updates
          final result = await ApkUpdateService.instance.downloadAndInstall(
            downloadUrl: info.downloadUrl,
            version: info.version,
            md5: info.md5,
            onProgress: onProgress,
          );

          if (result.success) {
            return ApkInstallCallbackResult(
              downloadSuccess: true,
              filePath: result.filePath,
              message: result.message,
            );
          } else {
            return ApkInstallCallbackResult(
              downloadSuccess: false,
              error: result.error,
              message: result.error,
            );
          }
        },
        // Called when user clicks Install Update button
        onMandatoryInstallTriggered: () {
          debugPrint('[Splash] Mandatory APK install triggered');
          _setPendingMandatoryApk(info);
        },
        onLater: null, // Never show "Nanti" for mandatory APK
        onRestart: () {
          debugPrint('[Splash] APK installed, restart app');
        },
      );
    } else {
      // Patch update
      await showUpdateDialog(
        context: context,
        info: info,
        barrierDismissible: !info.isMandatory,
        onUpdate: (_) async {
          return await UpdateService.instance.applyUpdate(info);
        },
        onLater: info.isMandatory
            ? null
            : () {
                Navigator.pop(context);
              },
        onRestart: () {
          debugPrint('[Splash] Patch applied, restart app');
        },
      );
    }
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

      // Try to fetch fresh user data from API
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

      // API failed (network error or non-401 error) - try to use cached data
      // This ensures auto-login works even when API is temporarily unavailable
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

      // Both API failed and no cached data - token might be invalid, go to Welcome
      debugPrint('[Splash] Auto-login failed: API error and no cached data');
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

