import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/neo_components.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/user_provider.dart';
import '../main_shell.dart';

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

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (WebP - optimized)
          Image.asset(
            'assets/images/login_bg.webp',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Fallback gradient if image not found
              return Container(
                decoration: BoxDecoration(
                  gradient: NeoMiraiTheme.paperGradient,
                ),
              );
            },
          ),

          // Dark overlay for better readability
          Container(
            color: Colors.black.withValues(alpha: 0.2),
          ),

          // Content - Centered Login Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.spacing(24),
                  vertical: Responsive.spacing(16),
                ),
                child: FadeTransition(
                  opacity: _fadeController,
                  child: _buildLoginCard(context),
                ),
              ),
            ),
          ),

          // Back Button (Top Left)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(Responsive.spacing(16)),
                child: _buildBackButton(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: Responsive.iconSize(44),
        height: Responsive.iconSize(44),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeoMiraiColors.gold.withValues(alpha: 0.9),
              NeoMiraiColors.gold,
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          boxShadow: [
            BoxShadow(
              color: NeoMiraiColors.gold.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: Responsive.iconSize(20),
          color: NeoMiraiColors.rice,
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(24)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Responsive.radius(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _rememberMe
                                ? NeoMiraiColors.gold
                                : Colors.white.withValues(alpha: 0.7),
                            width: 2,
                          ),
                          color: _rememberMe
                              ? NeoMiraiColors.gold
                              : Colors.transparent,
                          boxShadow: _rememberMe
                              ? [
                                  BoxShadow(
                                    color: NeoMiraiColors.gold.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      SizedBox(width: Responsive.spacing(10)),
                      Text(
                        'Ingat saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.fontSize(13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Forgot Password
                GestureDetector(
                  onTap: () => _showForgotPasswordDialog(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.spacing(14),
                      vertical: Responsive.spacing(6),
                    ),
                    decoration: BoxDecoration(
                      color: NeoMiraiColors.gold,
                      borderRadius: BorderRadius.circular(Responsive.radius(20)),
                      boxShadow: [
                        BoxShadow(
                          color: NeoMiraiColors.gold.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.fontSize(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.spacing(24)),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      NeoMiraiColors.gold,
                      NeoMiraiColors.gold.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Responsive.radius(14)),
                  boxShadow: [
                    BoxShadow(
                      color: NeoMiraiColors.gold.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.radius(14)),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login_rounded,
                              size: Responsive.iconSize(22),
                              color: Colors.white,
                            ),
                            SizedBox(width: Responsive.spacing(10)),
                            Text(
                              'MASUK',
                              style: TextStyle(
                                fontSize: Responsive.fontSize(15),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
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

            // Navigate to MainShell (Dashboard with persistent nav)
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // Save user to global provider
                context.read<UserProvider>().setUser(user);

                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const MainShell(),
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
}
