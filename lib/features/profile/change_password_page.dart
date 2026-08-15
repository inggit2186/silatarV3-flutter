import 'package:flutter/material.dart';

import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: NeoMiraiColors.rice,
      appBar: AppBar(
        title: const Text(
          'Ubah Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: NeoMiraiColors.rice,
        foregroundColor: NeoMiraiColors.ink,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              _buildPasswordForm(),
              const SizedBox(height: 32),
              _buildChangeButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.cardPadding(24)),
      margin: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.radius(16)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: Responsive.iconSize(32),
              color: NeoMiraiColors.gold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ubah Password Anda',
            style: TextStyle(
              fontSize: Responsive.fontSize(18),
              fontWeight: FontWeight.bold,
              color: NeoMiraiColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan password baru Anda kuat dan mudah diingat',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Responsive.fontSize(13),
              color: NeoMiraiColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.cardPadding(24)),
      margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.radius(8)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Responsive.radius(10)),
                ),
                child: Icon(
                  Icons.vpn_key_outlined,
                  size: Responsive.iconSize(20),
                  color: NeoMiraiColors.gold,
                ),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: Responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: NeoMiraiColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _currentPasswordController,
            label: 'Password Saat Ini',
            icon: Icons.lock_outline,
            showPassword: _showCurrentPassword,
            onToggle: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password saat ini tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'Password Baru',
            icon: Icons.lock_reset_outlined,
            showPassword: _showNewPassword,
            onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password baru tidak boleh kosong';
              }
              if (value.length < 8) {
                return 'Password harus minimal 8 karakter';
              }
              if (value == _currentPasswordController.text) {
                return 'Password baru harus berbeda dari password saat ini';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password Baru',
            icon: Icons.lock_outline,
            showPassword: _showConfirmPassword,
            onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Konfirmasi password tidak boleh kosong';
              }
              if (value != _newPasswordController.text) {
                return 'Konfirmasi password tidak cocok';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordStrengthIndicator(),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool showPassword,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: NeoMiraiColors.gold),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: NeoMiraiColors.inkSoft,
          ),
          onPressed: onToggle,
        ),
        labelStyle: TextStyle(color: NeoMiraiColors.inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          borderSide: BorderSide(color: NeoMiraiColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          borderSide: BorderSide(color: NeoMiraiColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          borderSide: const BorderSide(color: NeoMiraiColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          borderSide: const BorderSide(color: NeoMiraiColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          borderSide: const BorderSide(color: NeoMiraiColors.error, width: 2),
        ),
        filled: true,
        fillColor: NeoMiraiColors.paperSoft,
      ),
      style: TextStyle(
        fontSize: Responsive.fontSize(14),
        color: NeoMiraiColors.ink,
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    String label;
    Color color;
    double progress;

    switch (strength) {
      case 0:
        label = '';
        color = NeoMiraiColors.line;
        progress = 0;
        break;
      case 1:
        label = 'Lemah';
        color = NeoMiraiColors.error;
        progress = 0.25;
        break;
      case 2:
        label = 'Sedang';
        color = NeoMiraiColors.warning;
        progress = 0.5;
        break;
      case 3:
        label = 'Kuat';
        color = NeoMiraiColors.info;
        progress = 0.75;
        break;
      case 4:
        label = 'Sangat Kuat';
        color = NeoMiraiColors.success;
        progress = 1.0;
        break;
      default:
        label = '';
        color = NeoMiraiColors.line;
        progress = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: NeoMiraiColors.line.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        if (label.isNotEmpty)
          Row(
            children: [
              Icon(
                strength >= 3 ? Icons.check_circle : Icons.info_outline,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChangeButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: NeoMiraiColors.gold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ubah Password',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.instance.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      );

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                Text(response.message ?? 'Password berhasil diubah'),
              ],
            ),
            backgroundColor: NeoMiraiColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
          ),
        );

        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                Text(response.message ?? 'Gagal mengubah password'),
              ],
            ),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
