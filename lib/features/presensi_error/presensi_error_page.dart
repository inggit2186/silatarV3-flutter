import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/user_provider.dart';

/// Page for Presensi Error - laporan presensi alternatif jika sistem error
class PresensiErrorPage extends StatefulWidget {
  const PresensiErrorPage({super.key});

  @override
  State<PresensiErrorPage> createState() => _PresensiErrorPageState();
}

class _PresensiErrorPageState extends State<PresensiErrorPage> {
  Map<String, dynamic>? _todayStatus;
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedJenis;
  String? _selectedAlasan;
  final _keteranganController = TextEditingController();
  final _tanggalLupaController = TextEditingController();
  bool _isSubmitting = false;

  Position? _currentPosition;
  String? _currentAddress;
  double? _distance;

  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _tanggalLupaController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getPresensiErrorToday();

      if (response.success && response.data != null) {
        setState(() {
          _todayStatus = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Gagal memuat data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedJenis == null) {
      _showSnackBar('Pilih jenis presensi (Masuk atau Pulang)');
      return;
    }

    if (_selectedAlasan == null) {
      _showSnackBar('Pilih alasan pengaduan');
      return;
    }

    if (_selectedAlasan == 'TUGAS_LUAR' && _keteranganController.text.isEmpty) {
      _showSnackBar('Keterangan tugas luar wajib diisi');
      return;
    }

    if (_selectedAlasan == 'LUPA_PRESNSI_PUSAKA' && _tanggalLupaController.text.isEmpty) {
      _showSnackBar('Tanggal lupa presensi wajib diisi');
      return;
    }

    if (_photoBase64 == null) {
      _showSnackBar('Foto bukti wajib diupload');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.instance.submitPresensiError(
        jenis: _selectedJenis!,
        alasan: _selectedAlasan!,
        keteranganTugasLuar: _selectedAlasan == 'TUGAS_LUAR' ? _keteranganController.text : null,
        tanggalLupa: _selectedAlasan == 'LUPA_PRESNSI_PUSAKA' ? _tanggalLupaController.text : null,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        jarakMeter: _distance,
        alamat: _currentAddress,
        foto: _photoBase64!,
      );

      setState(() => _isSubmitting = false);

      if (response.success) {
        _showSnackBar(response.message ?? 'Presensi error berhasil disimpan', isError: false);
        _resetForm();
        _loadTodayStatus();
      } else {
        _showSnackBar(response.message ?? 'Gagal menyimpan presensi error', isError: true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedJenis = null;
      _selectedAlasan = null;
      _keteranganController.clear();
      _tanggalLupaController.clear();
      _photoBase64 = null;
    });
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('GPS tidak aktif', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Izin lokasi ditolak', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Izin lokasi ditolak permanen', isError: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentPosition = position;
        _distance = position.accuracy;
      });
    } catch (e) {
      _showSnackBar('Gagal mendapatkan lokasi: $e', isError: true);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() {
        _photoBase64 = base64Str;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? NeoMiraiColors.error : NeoMiraiColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: NeoMiraiTheme.paperGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(16),
        vertical: Responsive.spacing(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice,
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.arrow_back_rounded, size: Responsive.iconSize(20), color: NeoMiraiColors.ink),
            ),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Container(
            padding: EdgeInsets.all(Responsive.radius(12)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(Icons.error_outline_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presensi Error', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text('Laporan presensi alternatif', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final todayStatus = _todayStatus;
    final sudahMasuk = todayStatus?['sudah_masuk'] ?? false;
    final sudahPulang = todayStatus?['sudah_pulang'] ?? false;
    final sudahError = todayStatus?['sudah_presensi_error'] ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.spacing(12)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              border: Border.all(color: NeoMiraiColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: NeoMiraiColors.error, size: Responsive.iconSize(20)),
                SizedBox(width: Responsive.spacing(10)),
                Expanded(
                  child: Text(
                    'Halaman alternatif jika presensi utama bermasalah',
                    style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.error),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          SizedBox(height: Responsive.spacing(20)),

          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final user = userProvider.user;
              return Container(
                padding: EdgeInsets.all(Responsive.spacing(16)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.rice,
                  borderRadius: BorderRadius.circular(Responsive.radius(16)),
                  boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: NeoMiraiTheme.goldGradient,
                        borderRadius: BorderRadius.circular(Responsive.radius(12)),
                      ),
                      child: Icon(Icons.person_rounded, color: Colors.white, size: Responsive.iconSize(24)),
                    ),
                    SizedBox(width: Responsive.spacing(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Pengguna',
                            style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink),
                          ),
                          SizedBox(height: Responsive.spacing(4)),
                          Text(
                            'NIP: ${user?.nip ?? user?.nomorInduk ?? '-'}',
                            style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
            },
          ),

          SizedBox(height: Responsive.spacing(20)),

          Container(
            padding: EdgeInsets.all(Responsive.spacing(16)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.rice,
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status Hari Ini', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(12)),
                Row(
                  children: [
                    Expanded(child: _buildStatusChip('Masuk', sudahMasuk)),
                    SizedBox(width: Responsive.spacing(8)),
                    Expanded(child: _buildStatusChip('Pulang', sudahPulang)),
                    SizedBox(width: Responsive.spacing(8)),
                    Expanded(child: _buildStatusChip('Error', sudahError)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          SizedBox(height: Responsive.spacing(20)),

          Text('Ajukan Presensi Error', style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink))
              .animate().fadeIn(delay: 300.ms, duration: 300.ms),

          SizedBox(height: Responsive.spacing(12)),

          _buildSectionCard(
            title: 'Jenis Presensi',
            icon: Icons.schedule_rounded,
            iconColor: NeoMiraiColors.gold,
            child: Column(
              children: [
                _buildRadioOption(
                  label: 'Masuk',
                  subtitle: sudahMasuk ? 'Ulangi presensi masuk' : 'Laporkan jam kehadiran',
                  value: 'masuk',
                  groupValue: _selectedJenis,
                  color: NeoMiraiColors.success,
                  onChanged: (v) => setState(() => _selectedJenis = v),
                ),
                SizedBox(height: Responsive.spacing(8)),
                _buildRadioOption(
                  label: 'Pulang',
                  subtitle: sudahPulang ? 'Ulangi presensi pulang' : 'Laporkan jam pulang',
                  value: 'pulang',
                  groupValue: _selectedJenis,
                  color: NeoMiraiColors.info,
                  onChanged: (v) => setState(() => _selectedJenis = v),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

          SizedBox(height: Responsive.spacing(12)),

          _buildSectionCard(
            title: 'Alasan Pengaduan',
            icon: Icons.warning_rounded,
            iconColor: NeoMiraiColors.error,
            child: Column(
              children: [
                _buildRadioOption(
                  label: 'Sistem Error',
                  subtitle: 'Presensi utama mengalami gangguan',
                  value: 'SISTEM_ERROR',
                  groupValue: _selectedAlasan,
                  color: NeoMiraiColors.error,
                  onChanged: (v) => setState(() => _selectedAlasan = v),
                ),
                SizedBox(height: Responsive.spacing(8)),
                _buildRadioOption(
                  label: 'Tugas Luar',
                  subtitle: 'Sedang bertugas di luar kantor',
                  value: 'TUGAS_LUAR',
                  groupValue: _selectedAlasan,
                  color: NeoMiraiColors.warning,
                  onChanged: (v) => setState(() => _selectedAlasan = v),
                ),
                SizedBox(height: Responsive.spacing(8)),
                _buildRadioOption(
                  label: 'Lupa Presensi',
                  subtitle: 'Lupa melakukan presensi di hari tertentu',
                  value: 'LUPA_PRESNSI_PUSAKA',
                  groupValue: _selectedAlasan,
                  color: Colors.purple,
                  onChanged: (v) => setState(() => _selectedAlasan = v),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

          if (_selectedAlasan == 'TUGAS_LUAR') ...[
            SizedBox(height: Responsive.spacing(12)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(16)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice,
                borderRadius: BorderRadius.circular(Responsive.radius(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keterangan Tugas Luar', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
                  SizedBox(height: Responsive.spacing(8)),
                  TextField(
                    controller: _keteranganController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Dinas ke KUA Banuhampu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
          ],

          if (_selectedAlasan == 'LUPA_PRESNSI_PUSAKA') ...[
            SizedBox(height: Responsive.spacing(12)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(16)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.rice,
                borderRadius: BorderRadius.circular(Responsive.radius(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal Lupa Presensi', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
                  SizedBox(height: Responsive.spacing(8)),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        hintText: 'Pilih tanggal',
                        suffixIcon: Icon(Icons.calendar_today_rounded, color: NeoMiraiColors.gold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
                      ),
                      child: Text(
                        _tanggalLupaController.text.isEmpty ? 'Pilih tanggal' : _tanggalLupaController.text,
                        style: TextStyle(color: _tanggalLupaController.text.isEmpty ? NeoMiraiColors.inkSoft : NeoMiraiColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
          ],

          SizedBox(height: Responsive.spacing(12)),

          _buildSectionCard(
            title: 'Foto Bukti',
            icon: Icons.camera_alt_rounded,
            iconColor: NeoMiraiColors.gold,
            child: Column(
              children: [
                if (_photoBase64 != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Responsive.radius(12)),
                    child: Image.memory(
                      base64Decode(_photoBase64!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(8)),
                  TextButton.icon(
                    onPressed: () => setState(() => _photoBase64 = null),
                    icon: Icon(Icons.delete_rounded, color: NeoMiraiColors.error),
                    label: Text('Hapus Foto', style: TextStyle(color: NeoMiraiColors.error)),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(20)),
                      decoration: BoxDecoration(
                        border: Border.all(color: NeoMiraiColors.gold, width: 2),
                        borderRadius: BorderRadius.circular(Responsive.radius(12)),
                        color: NeoMiraiColors.gold.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: Responsive.iconSize(40), color: NeoMiraiColors.gold),
                          SizedBox(height: Responsive.spacing(8)),
                          Text('Ambil Foto', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.gold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 300.ms),

          SizedBox(height: Responsive.spacing(20)),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoMiraiColors.gold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: Responsive.spacing(14)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Kirim Laporan', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold)),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 300.ms),

          SizedBox(height: Responsive.spacing(32)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.radius(8)),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Responsive.radius(8)),
                ),
                child: Icon(icon, color: iconColor, size: Responsive.iconSize(18)),
              ),
              SizedBox(width: Responsive.spacing(10)),
              Text(title, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            ],
          ),
          SizedBox(height: Responsive.spacing(12)),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String subtitle,
    required String value,
    required String? groupValue,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: EdgeInsets.all(Responsive.spacing(12)),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : NeoMiraiColors.line,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Responsive.radius(12)),
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            SizedBox(width: Responsive.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
                  Text(subtitle, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.spacing(8),
        vertical: Responsive.spacing(6),
      ),
      decoration: BoxDecoration(
        color: isActive ? NeoMiraiColors.success.withValues(alpha: 0.1) : NeoMiraiColors.ash.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(8)),
      ),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isActive ? NeoMiraiColors.success : NeoMiraiColors.ash,
            size: Responsive.iconSize(18),
          ),
          SizedBox(height: Responsive.spacing(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSize(10),
              fontWeight: FontWeight.w600,
              color: isActive ? NeoMiraiColors.success : NeoMiraiColors.ash,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NeoMiraiColors.gold),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat data...', style: TextStyle(fontSize: Responsive.fontSize(14), color: NeoMiraiColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: Responsive.iconSize(48), color: NeoMiraiColors.error),
            ),
            SizedBox(height: Responsive.spacing(16)),
            Text('Gagal Memuat', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(6)),
            Text(_errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(24)),
            ElevatedButton.icon(
              onPressed: _loadTodayStatus,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoMiraiColors.gold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(20), vertical: Responsive.spacing(12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: yesterday,
      firstDate: yesterday,
      lastDate: now,
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => _tanggalLupaController.text = formatted);
    }
  }
}
