import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/phone_formatter.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;

  // Controllers for form fields
  late TextEditingController _nameController;
  late TextEditingController _nipController;
  late TextEditingController _emailController;
  late TextEditingController _noHpController;
  late TextEditingController _alamatController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _tanggalLahirController;
  late TextEditingController _bioController;
  String? _jenisKelamin;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _nipController = TextEditingController(text: user?.nomorInduk ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    // Format phone for display (add 0 prefix)
    _noHpController = TextEditingController(
      text: PhoneFormatter.formatForDisplay(user?.noHp),
    );
    _alamatController = TextEditingController(text: user?.alamat ?? '');
    _tempatLahirController = TextEditingController(text: user?.tempatLahir ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');

    // Format tanggal lahir for display
    if (user?.tanggalLahir != null) {
      final date = user!.tanggalLahir!;
      _tanggalLahirController = TextEditingController(
        text: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
      );
    } else {
      _tanggalLahirController = TextEditingController();
    }

    _jenisKelamin = user?.jenisKelamin;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: NeoMiraiColors.rice,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: NeoMiraiColors.rice,
        foregroundColor: NeoMiraiColors.ink,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPhotoSection(user),
              _buildPersonalInfoSection(),
              _buildContactInfoSection(),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(User? user) {
    final bool hasPhoto = user?.hasPhoto ?? false;
    final String? photoUrl = user?.photoUrl;

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
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: NeoMiraiTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NeoMiraiColors.gold.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      )
                    : hasPhoto && photoUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: NeoMiraiColors.rice,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: NeoMiraiColors.rice,
                          ),
              ),
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeoMiraiColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: NeoMiraiColors.ink.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isUploadingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap untuk mengubah foto',
            style: TextStyle(
              fontSize: Responsive.fontSize(12),
              color: NeoMiraiColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
                  Icons.person_outline_rounded,
                  size: Responsive.iconSize(20),
                  color: NeoMiraiColors.gold,
                ),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Text(
                'Informasi Pribadi',
                style: TextStyle(
                  fontSize: Responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: NeoMiraiColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: 'Nama Lengkap',
            icon: Icons.badge_outlined,
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nipController,
            label: 'NIP (Nomor Induk Pegawai)',
            icon: Icons.credit_card_outlined,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildGenderDropdown(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _tempatLahirController,
            label: 'Tempat Lahir',
            icon: Icons.location_city_outlined,
          ),
          const SizedBox(height: 16),
          _buildDateField(),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
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
                  Icons.contact_phone_outlined,
                  size: Responsive.iconSize(20),
                  color: NeoMiraiColors.gold,
                ),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Text(
                'Informasi Kontak',
                style: TextStyle(
                  fontSize: Responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: NeoMiraiColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _noHpController,
            label: 'Nomor HP',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty && !PhoneFormatter.isValid(value)) {
                return 'Format nomor HP tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _alamatController,
            label: 'Alamat',
            icon: Icons.home_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
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
                  Icons.info_outline_rounded,
                  size: Responsive.iconSize(20),
                  color: NeoMiraiColors.gold,
                ),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Text(
                'Informasi Tambahan',
                style: TextStyle(
                  fontSize: Responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: NeoMiraiColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _bioController,
            label: 'Bio / Deskripsi Diri',
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: NeoMiraiColors.gold),
        suffixIcon: readOnly ? Icon(Icons.lock_outline, size: 18, color: NeoMiraiColors.inkSoft) : null,
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
        counterText: maxLength != null ? '' : null,
      ),
      style: TextStyle(
        fontSize: Responsive.fontSize(14),
        color: NeoMiraiColors.ink,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _jenisKelamin,
      decoration: InputDecoration(
        labelText: 'Jenis Kelamin',
        prefixIcon: const Icon(Icons.wc_outlined, color: NeoMiraiColors.gold),
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
        filled: true,
        fillColor: NeoMiraiColors.paperSoft,
      ),
      items: const [
        DropdownMenuItem(value: 'L', child: Text('Pria')),
        DropdownMenuItem(value: 'P', child: Text('Wanita')),
      ],
      onChanged: (value) {
        setState(() {
          _jenisKelamin = value;
        });
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _tanggalLahirController,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: 'Tanggal Lahir',
        prefixIcon: const Icon(Icons.calendar_today_outlined, color: NeoMiraiColors.gold),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: NeoMiraiColors.inkSoft),
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
        filled: true,
        fillColor: NeoMiraiColors.paperSoft,
      ),
      style: TextStyle(
        fontSize: Responsive.fontSize(14),
        color: NeoMiraiColors.ink,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
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
                      'Simpan Perubahan',
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.radius(20)),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.spacing(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NeoMiraiColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  fontSize: Responsive.fontSize(18),
                  fontWeight: FontWeight.bold,
                  color: NeoMiraiColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(Responsive.radius(8)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: NeoMiraiColors.gold),
                ),
                title: const Text('Ambil Foto'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(Responsive.radius(8)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: NeoMiraiColors.gold),
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadPhoto(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                Text('Gagal mengambil foto: $e'),
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
    }
  }

  Future<void> _uploadPhoto(String filePath) async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final response = await ApiService.instance.updateProfilePhoto(filePath);

      if (response.success && mounted) {
        final photoUrl = response.data?['foto_url'];
        if (photoUrl != null) {
          context.read<UserProvider>().updatePhoto(photoUrl);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                Text(response.message ?? 'Foto berhasil diupdate'),
              ],
            ),
            backgroundColor: NeoMiraiColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                Text(response.message ?? 'Gagal mengupdate foto'),
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
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final user = context.read<UserProvider>().user;
    DateTime initialDate = user?.tanggalLahir ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: NeoMiraiColors.gold,
              onPrimary: Colors.white,
              surface: NeoMiraiColors.rice,
              onSurface: NeoMiraiColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _tanggalLahirController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse tanggal lahir
      DateTime? tanggalLahir;
      if (_tanggalLahirController.text.isNotEmpty) {
        final parts = _tanggalLahirController.text.split('/');
        if (parts.length == 3) {
          tanggalLahir = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      // Format phone for storage (strip 0/+62/62 prefix)
      final phoneForStorage = PhoneFormatter.formatForStorage(_noHpController.text);

      final response = await ApiService.instance.updateProfile(
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        nik: _nipController.text.isNotEmpty ? _nipController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        noHp: phoneForStorage.isNotEmpty ? phoneForStorage : null,
        alamat: _alamatController.text.isNotEmpty ? _alamatController.text : null,
        tempatLahir: _tempatLahirController.text.isNotEmpty ? _tempatLahirController.text : null,
        tanggalLahir: tanggalLahir?.toIso8601String(),
        jenisKelamin: _jenisKelamin,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      if (response.success && mounted) {
        // Update user in provider
        context.read<UserProvider>().updateUser(response.data!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: Responsive.spacing(10)),
                Text(response.message ?? 'Profil berhasil diupdate'),
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
                Text(response.message ?? 'Gagal mengupdate profil'),
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
