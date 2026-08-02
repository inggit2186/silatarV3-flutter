import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/neo_components.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/models/user_model.dart';
import '../dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatController.dispose();
    super.dispose();
  }

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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding,
        ),
        child: Column(
          children: [
            SizedBox(height: Responsive.verticalPadding * 2),

            // Back Button & Header
            _buildHeader(context)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: -0.2, end: 0),

            SizedBox(height: Responsive.spacing(16)),

            // Floating Illustration
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                );
              },
              child: _buildIllustration(context)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                  ),
            ),

            SizedBox(height: Responsive.spacing(20)),

            // Login Card
            _buildLoginCard(context)
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.1, end: 0),

            SizedBox(height: Responsive.spacing(20)),

            // Register Link
            _buildRegisterLink(context)
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms),

            SizedBox(height: Responsive.spacing(24)),
          ],
        ),
      ),
    );
  }

  /// Landscape Layout (Phone horizontal)
  Widget _buildLandscapeLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Illustration
        Expanded(
          flex: 1,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              );
            },
            child: _buildIllustrationLandscape(context)
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms),
          ),
        ),

        // Right side - Form
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(Responsive.spacing(16)),
              child: Column(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildBackButton(context),
                  ),

                  SizedBox(height: Responsive.spacing(8)),

                  _buildLoginCard(context)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  SizedBox(height: Responsive.spacing(16)),

                  _buildRegisterLink(context)
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Back Button
        _buildBackButton(context),

        const Spacer(),

        // Logo Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacing(12),
            vertical: Responsive.spacing(8),
          ),
          decoration: BoxDecoration(
            color: NeoMiraiColors.rice,
            borderRadius: BorderRadius.circular(Responsive.radius(12)),
            border: Border.all(
              color: NeoMiraiColors.line.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: NeoMiraiColors.ink.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.radius(6)),
                decoration: BoxDecoration(
                  gradient: NeoMiraiTheme.goldGradient,
                  borderRadius: BorderRadius.circular(Responsive.radius(6)),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  size: Responsive.iconSize(16),
                  color: NeoMiraiColors.rice,
                ),
              ),
              SizedBox(width: Responsive.spacing(8)),
              Text(
                'SILATAR',
                style: TextStyle(
                  fontSize: Responsive.fontSize(13),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: NeoMiraiColors.gold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        border: Border.all(
          color: NeoMiraiColors.line.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: Responsive.iconSize(18),
          color: NeoMiraiColors.ink,
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    final isSmallPhone = context.isSmallPhone;
    final width = Responsive.width(isSmallPhone ? 0.7 : 0.75);
    final height = Responsive.height(isSmallPhone ? 0.2 : 0.22);

    return Container(
      width: width,
      height: height,
      constraints: const BoxConstraints(
        maxWidth: 280,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.nightGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(24)),
        border: Border.all(
          color: NeoMiraiColors.nightSoft.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.night.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoMiraiColors.nightSoft.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.radius(isSmallPhone ? 14 : 16)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Responsive.radius(20)),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: Responsive.iconSize(isSmallPhone ? 40 : 50),
                    color: NeoMiraiColors.gold,
                  ),
                ),
                SizedBox(height: Responsive.spacing(10)),
                const Text(
                  'MASUK',
                  style: TextStyle(
                    color: NeoMiraiColors.rice,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Akses akun Anda',
                  style: TextStyle(
                    color: NeoMiraiColors.rice.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationLandscape(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.nightGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(24)),
        border: Border.all(
          color: NeoMiraiColors.nightSoft.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.night.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_rounded,
              size: Responsive.iconSize(50),
              color: NeoMiraiColors.gold,
            ),
            SizedBox(height: Responsive.spacing(12)),
            const Text(
              'SILATAR',
              style: TextStyle(
                color: NeoMiraiColors.rice,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            Text(
              'Layanan Agama Tanah Datar',
              style: TextStyle(
                color: NeoMiraiColors.rice.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(24)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(24)),
        border: Border.all(
          color: NeoMiraiColors.line.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Selamat Datang! 👋',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: NeoMiraiColors.ink,
                    fontSize: Responsive.fontSize(18),
                  ),
            ),
            SizedBox(height: Responsive.spacing(6)),
            Text(
              'Masukkan email dan password untuk melanjutkan.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: NeoMiraiColors.inkSoft,
                    height: 1.4,
                    fontSize: Responsive.fontSize(12),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: Responsive.spacing(20)),

            // Email Field
            NeoTextField(
              controller: _emailController,
              label: 'NIP / Email',
              hint: '1978xx atau nama@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'NIP atau Email tidak boleh kosong';
                }
                // Accept NIP (digits only) or email (contains @)
                final isNip = RegExp(r'^[0-9]+$').hasMatch(value);
                final isEmail = value.contains('@') && value.contains('.');
                if (!isNip && !isEmail) {
                  return 'Format NIP atau Email tidak valid';
                }
                return null;
              },
            ),

            SizedBox(height: Responsive.spacing(16)),

            // Password Field
            NeoPasswordField(
              controller: _passwordController,
              label: 'Password',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                if (value.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
            ),

            SizedBox(height: Responsive.spacing(12)),

            // Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remember Me
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _rememberMe
                                ? NeoMiraiColors.gold
                                : NeoMiraiColors.ash,
                            width: 1.5,
                          ),
                          color: _rememberMe
                              ? NeoMiraiColors.gold
                              : Colors.transparent,
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: NeoMiraiColors.rice,
                              )
                            : null,
                      ),
                      SizedBox(width: Responsive.spacing(8)),
                      Text(
                        'Ingat saya',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: NeoMiraiColors.inkSoft,
                              fontSize: Responsive.fontSize(11),
                            ),
                      ),
                    ],
                  ),
                ),

                // Forgot Password
                TextButton(
                  onPressed: () {
                    _showForgotPasswordDialog(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Lupa password?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NeoMiraiColors.gold,
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.fontSize(11),
                        ),
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.spacing(20)),

            // Login Button
            NeoButton(
              text: 'MASUK',
              icon: Icons.login_rounded,
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),

            SizedBox(height: Responsive.spacing(16)),

            // Divider
            const NeoDivider(text: 'atau'),

            SizedBox(height: Responsive.spacing(16)),

            // Social Login Buttons
            Row(
              children: [
                Expanded(
                  child: NeoSocialButton(
                    text: 'Google',
                    icon: Icons.g_mobiledata_rounded,
                    color: const Color(0xFFDB4437),
                    onPressed: () {
                      _showSnackBar(context, 'Login dengan Google dalam pengembangan');
                    },
                  ),
                ),
                SizedBox(width: Responsive.spacing(10)),
                Expanded(
                  child: NeoSocialButton(
                    text: 'Apple',
                    icon: Icons.apple_rounded,
                    color: const Color(0xFF000000),
                    onPressed: () {
                      _showSnackBar(context, 'Login dengan Apple dalam pengembangan');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: NeoMiraiColors.inkSoft,
              ),
        ),
        GestureDetector(
          onTap: () {
            _showRegisterInfo(context);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.spacing(14),
              vertical: Responsive.spacing(6),
            ),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(18)),
              boxShadow: [
                BoxShadow(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daftar Sekarang',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NeoMiraiColors.rice,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(width: Responsive.spacing(4)),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: Responsive.iconSize(14),
                  color: NeoMiraiColors.rice,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call API login
        final response = await ApiService.instance.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (response.success && response.data != null) {
            // Login success
            User user = response.data!;

            // Save remember me preference and user data
            if (_rememberMe) {
              await StorageService().setRememberMe(true);
              await StorageService().setUser(user.toJson());
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: NeoMiraiColors.rice),
                    SizedBox(width: Responsive.spacing(10)),
                    Expanded(
                      child: Text('Login berhasil! Selamat datang, ${user.displayName}'),
                    ),
                  ],
                ),
                backgroundColor: NeoMiraiColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );

            // Navigate to Dashboard
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        DashboardPage(user: user),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                  (route) => false, // Remove all previous routes
                );
              }
            });
          } else {
            // Login failed
            String errorMsg = response.message ?? 'Login gagal';
            if (response.errors != null) {
              // Get first error message
              final firstError = response.errors!.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: NeoMiraiColors.rice),
                    SizedBox(width: Responsive.spacing(10)),
                    Expanded(child: Text(errorMsg)),
                  ],
                ),
                backgroundColor: NeoMiraiColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: NeoMiraiColors.rice),
                  SizedBox(width: Responsive.spacing(10)),
                  const Expanded(child: Text('Tidak dapat terhubung ke server')),
                ],
              ),
              backgroundColor: NeoMiraiColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: NeoMiraiColors.rice,
            borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(24))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(Responsive.cardPadding(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: NeoMiraiColors.ash.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(20)),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.radius(10)),
                        decoration: BoxDecoration(
                          color: NeoMiraiColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Responsive.radius(12)),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: NeoMiraiColors.gold,
                          size: Responsive.iconSize(24),
                        ),
                      ),
                      SizedBox(width: Responsive.spacing(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lupa Password?',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Masukkan email untuk reset',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: NeoMiraiColors.inkSoft,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: Responsive.spacing(20)),

                  // Email Field
                  NeoTextField(
                    controller: emailController,
                    label: 'NIP / Email',
                    hint: '1978xx atau nama@email.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: Responsive.spacing(20)),

                  // Send Button
                  NeoButton(
                    text: 'KIRIM LINK RESET',
                    icon: Icons.send_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackBar(context, 'Link reset sudah dikirim ke email');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRegisterInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.radius(24))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(Responsive.cardPadding(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.ash.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: Responsive.spacing(20)),

                // Icon
                Container(
                  padding: EdgeInsets.all(Responsive.radius(16)),
                  decoration: BoxDecoration(
                    gradient: NeoMiraiTheme.goldGradient,
                    borderRadius: BorderRadius.circular(Responsive.radius(20)),
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    color: NeoMiraiColors.rice,
                    size: Responsive.iconSize(40),
                  ),
                ),
                SizedBox(height: Responsive.spacing(16)),

                // Title
                Text(
                  'Pendaftaran Warga',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: Responsive.spacing(6)),
                Text(
                  'Pendaftaran dilakukan melalui website SILATAR.\nSilakan buka website untuk mendaftar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NeoMiraiColors.inkSoft,
                        height: 1.4,
                      ),
                ),
                SizedBox(height: Responsive.spacing(20)),

                // Info Card
                Container(
                  padding: EdgeInsets.all(Responsive.radius(14)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(14)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: NeoMiraiColors.info,
                        size: Responsive.iconSize(20),
                      ),
                      SizedBox(width: Responsive.spacing(10)),
                      Expanded(
                        child: Text(
                          'Hubungi admin jika mengalami kesulitan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: NeoMiraiColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.spacing(20)),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: NeoButton(
                    text: 'TUTUP',
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
