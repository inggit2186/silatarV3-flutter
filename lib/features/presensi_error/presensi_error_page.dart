import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import 'presensi_error_history_page.dart';

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
  DateTime? _tanggalLupa;
  bool _isSubmitting = false;
  String? _photoBase64;
  bool _showPhotoCapture = false;

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
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
      _showSnackBar('Pilih jenis presensi terlebih dahulu');
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

    if (_selectedAlasan == 'LUPA_PRESNSI_PUSAKA' && _tanggalLupa == null) {
      _showSnackBar('Pilih tanggal lupa presensi');
      return;
    }

    // Tampilkan dialog pengambilan foto
    await _showPhotoCaptureDialog();
  }

  Future<void> _showPhotoCaptureDialog() async {
    setState(() => _showPhotoCapture = true);

    // Ambil foto langsung
    final photoBase64 = await _capturePhoto();

    if (photoBase64 == null) {
      setState(() => _showPhotoCapture = false);
      return;
    }

    setState(() {
      _photoBase64 = photoBase64;
      _showPhotoCapture = false;
    });

    // Submit setelah foto diambil
    await _doSubmit();
  }

  Future<String?> _capturePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto: $e', isError: true);
    }
    return null;
  }

  Future<void> _doSubmit() async {
    if (_photoBase64 == null) return;

    setState(() => _isSubmitting = true);

    try {
      String? tanggalLupaFormatted;
      if (_tanggalLupa != null) {
        tanggalLupaFormatted = DateFormat('yyyy-MM-dd').format(_tanggalLupa!);
      }

      final response = await ApiService.instance.submitPresensiError(
        jenis: _selectedJenis!,
        alasan: _selectedAlasan!,
        keteranganTugasLuar: _selectedAlasan == 'TUGAS_LUAR' ? _keteranganController.text : null,
        tanggalLupa: tanggalLupaFormatted,
        foto: _photoBase64!,
      );

      setState(() => _isSubmitting = false);

      if (response.success) {
        _showSnackBar(response.message ?? 'Presensi error berhasil disimpan', isError: false);
        _resetForm();
        _loadTodayStatus();
        // Redirect ke halaman riwayat
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PresensiErrorHistoryPage()),
          );
        }
      } else {
        _showSnackBar(response.message ?? 'Gagal menyimpan', isError: true);
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
      _tanggalLupa = null;
      _photoBase64 = null;
      _showPhotoCapture = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: Responsive.spacing(8)),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? NeoMiraiColors.error : NeoMiraiColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(10))),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: NeoMiraiColors.paperSoft,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _showPhotoCapture
                        ? _buildPhotoCaptureState()
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: Responsive.cardPadding(16),
        right: Responsive.cardPadding(16),
        top: Responsive.spacing(MediaQuery.of(context).padding.top + 12),
        bottom: Responsive.spacing(12),
      ),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        boxShadow: [
          BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(Responsive.radius(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.paperSoft,
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
              ),
              child: Icon(Icons.arrow_back_rounded, size: Responsive.iconSize(22), color: NeoMiraiColors.ink),
            ),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Container(
            padding: EdgeInsets.all(Responsive.radius(10)),
            decoration: BoxDecoration(
              gradient: NeoMiraiTheme.goldGradient,
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(Icons.warning_amber_rounded, size: Responsive.iconSize(22), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presensi Error', style: TextStyle(fontSize: Responsive.fontSize(17), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                Text('Laporkan presensi alternatif', style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
          // Tombol Riwayat dengan label
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PresensiErrorHistoryPage()),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(12), vertical: Responsive.spacing(8)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(10)),
                border: Border.all(color: NeoMiraiColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: Responsive.iconSize(18), color: NeoMiraiColors.gold),
                  SizedBox(width: Responsive.spacing(6)),
                  Text('Riwayat', style: TextStyle(fontSize: Responsive.fontSize(11), fontWeight: FontWeight.w600, color: NeoMiraiColors.gold)),
                ],
              ),
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
          // Info Banner
          Container(
            padding: EdgeInsets.all(Responsive.spacing(14)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NeoMiraiColors.warning.withValues(alpha: 0.15),
                  NeoMiraiColors.warning.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(Responsive.radius(16)),
              border: Border.all(color: NeoMiraiColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.radius(10)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Responsive.radius(10)),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: NeoMiraiColors.warning, size: Responsive.iconSize(22)),
                ),
                SizedBox(width: Responsive.spacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Presensi Bermasalah?', style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: NeoMiraiColors.warning)),
                      SizedBox(height: Responsive.spacing(2)),
                      Text('Laporkan presensi alternatif dengan foto bukti', style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.warning)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms),

          SizedBox(height: Responsive.spacing(20)),

          // Status Section
          Text('Status Hari Ini', style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(10)),
          Container(
            padding: EdgeInsets.all(Responsive.spacing(14)),
            decoration: BoxDecoration(
              color: NeoMiraiColors.rice,
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(child: _buildStatusBadge('Masuk', sudahMasuk, Icons.login_rounded, NeoMiraiColors.success)),
                SizedBox(width: Responsive.spacing(10)),
                Expanded(child: _buildStatusBadge('Pulang', sudahPulang, Icons.logout_rounded, NeoMiraiColors.info)),
                SizedBox(width: Responsive.spacing(10)),
                Expanded(child: _buildStatusBadge('Error', sudahError, Icons.error_outline_rounded, NeoMiraiColors.warning)),
              ],
            ),
          ),

          SizedBox(height: Responsive.spacing(24)),

          // Jenis Presensi
          Text('Jenis Presensi', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w700, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(10)),
          Row(
            children: [
              Expanded(child: _buildJenisCard('Masuk', 'masuk', Icons.arrow_upward_rounded, sudahMasuk)),
              SizedBox(width: Responsive.spacing(12)),
              Expanded(child: _buildJenisCard('Pulang', 'pulang', Icons.arrow_downward_rounded, sudahPulang)),
            ],
          ),

          SizedBox(height: Responsive.spacing(24)),

          // Alasan
          Text('Alasan Pengaduan', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w700, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(10)),
          _buildAlasanCard('Sistem Error', 'SISTEM_ERROR', Icons.computer_rounded, 'Sistem presensi\nmengalami gangguan', NeoMiraiColors.error),
          SizedBox(height: Responsive.spacing(10)),
          _buildAlasanCard('Tugas Luar', 'TUGAS_LUAR', Icons.directions_run_rounded, 'Sedang bertugas\ndi luar kantor', NeoMiraiColors.warning),
          SizedBox(height: Responsive.spacing(10)),
          _buildAlasanCard('Lupa Presensi', 'LUPA_PRESNSI_PUSAKA', Icons.schedule_rounded, 'Lupa presensi\ndi hari tertentu', Colors.purple),

          // Keterangan Tugas Luar
          if (_selectedAlasan == 'TUGAS_LUAR') ...[
            SizedBox(height: Responsive.spacing(16)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(14)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                border: Border.all(color: NeoMiraiColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: Responsive.iconSize(16), color: NeoMiraiColors.warning),
                      SizedBox(width: Responsive.spacing(6)),
                      Text('Keterangan Tugas Luar', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.warning)),
                    ],
                  ),
                  SizedBox(height: Responsive.spacing(10)),
                  TextField(
                    controller: _keteranganController,
                    maxLines: 2,
                    style: TextStyle(fontSize: Responsive.fontSize(12)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Dinas ke KUA X',
                      hintStyle: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.ash),
                      filled: true,
                      fillColor: NeoMiraiColors.rice,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.radius(10)), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.all(Responsive.spacing(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tanggal Lupa
          if (_selectedAlasan == 'LUPA_PRESNSI_PUSAKA') ...[
            SizedBox(height: Responsive.spacing(16)),
            Container(
              padding: EdgeInsets.all(Responsive.spacing(14)),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: Responsive.iconSize(16), color: Colors.purple),
                      SizedBox(width: Responsive.spacing(6)),
                      Text('Tanggal Lupa Presensi', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: Colors.purple)),
                    ],
                  ),
                  SizedBox(height: Responsive.spacing(10)),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: EdgeInsets.all(Responsive.spacing(14)),
                      decoration: BoxDecoration(
                        color: NeoMiraiColors.rice,
                        borderRadius: BorderRadius.circular(Responsive.radius(10)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded, size: Responsive.iconSize(20), color: Colors.purple),
                          SizedBox(width: Responsive.spacing(12)),
                          Expanded(
                            child: Text(
                              _tanggalLupa != null
                                  ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_tanggalLupa!)
                                  : 'Pilih Tanggal',
                              style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w500, color: _tanggalLupa != null ? NeoMiraiColors.ink : NeoMiraiColors.ash),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: NeoMiraiColors.ash),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: Responsive.spacing(32)),

          // Submit Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [NeoMiraiColors.gold, NeoMiraiColors.gold.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(Responsive.radius(14)),
              boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: Responsive.spacing(16)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(14))),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: Responsive.iconSize(20)),
                        SizedBox(width: Responsive.spacing(10)),
                        Text('Ambil Foto & Kirim', style: TextStyle(fontSize: Responsive.fontSize(15), fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 200.ms),

          SizedBox(height: Responsive.spacing(40)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool isActive, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: Responsive.spacing(10)),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : NeoMiraiColors.ash.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Responsive.radius(10)),
      ),
      child: Column(
        children: [
          Icon(icon, size: Responsive.iconSize(18), color: isActive ? color : NeoMiraiColors.ash),
          SizedBox(height: Responsive.spacing(6)),
          Text(label, style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: isActive ? color : NeoMiraiColors.ash)),
          if (isActive) ...[
            SizedBox(height: Responsive.spacing(2)),
            Icon(Icons.check_circle_rounded, size: 12, color: color),
          ],
        ],
      ),
    );
  }

  Widget _buildJenisCard(String label, String value, IconData icon, bool sudahAda) {
    final isSelected = _selectedJenis == value;
    final color = NeoMiraiColors.gold;

    return GestureDetector(
      onTap: () => setState(() => _selectedJenis = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(Responsive.spacing(16)),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(14)),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(12)),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : NeoMiraiColors.ash.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: Responsive.iconSize(26), color: isSelected ? color : NeoMiraiColors.ash),
            ),
            SizedBox(height: Responsive.spacing(10)),
            Text(label, style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w700, color: isSelected ? color : NeoMiraiColors.ink)),
            if (sudahAda) ...[
              SizedBox(height: Responsive.spacing(4)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(8), vertical: 2),
                decoration: BoxDecoration(color: NeoMiraiColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Responsive.radius(4))),
                child: Text('Sudah Ada', style: TextStyle(fontSize: Responsive.fontSize(8), color: NeoMiraiColors.success, fontWeight: FontWeight.w500)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlasanCard(String label, String value, IconData icon, String subtitle, Color color) {
    final isSelected = _selectedAlasan == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedAlasan = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(Responsive.spacing(16)),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(Responsive.radius(14)),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(12)),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              child: Icon(icon, size: Responsive.iconSize(24), color: color),
            ),
            SizedBox(width: Responsive.spacing(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.w700, color: isSelected ? color : NeoMiraiColors.ink)),
                  SizedBox(height: Responsive.spacing(2)),
                  Text(subtitle, style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft, height: 1.3)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(Responsive.radius(4)),
              decoration: BoxDecoration(
                color: isSelected ? color : NeoMiraiColors.ash.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(isSelected ? Icons.check_rounded : Icons.circle_outlined, size: Responsive.iconSize(16), color: isSelected ? Colors.white : NeoMiraiColors.ash),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCaptureState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.cardPadding(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.radius(20)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt_rounded, size: Responsive.iconSize(56), color: NeoMiraiColors.gold),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            SizedBox(height: Responsive.spacing(24)),
            Text('Siapkan Kamera', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(8)),
            Text('Ambil foto bukti presensi\nAnda akan diarahkan ke kamera', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft, height: 1.5)),
            SizedBox(height: Responsive.spacing(32)),
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 3, color: NeoMiraiColors.gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, color: NeoMiraiColors.gold),
          ),
          SizedBox(height: Responsive.spacing(16)),
          Text('Memuat data...', style: TextStyle(fontSize: Responsive.fontSize(13), color: NeoMiraiColors.inkSoft)),
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
            SizedBox(height: Responsive.spacing(20)),
            Text('Gagal Memuat', style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            SizedBox(height: Responsive.spacing(8)),
            Text(_errorMessage ?? 'Terjadi kesalahan', textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft)),
            SizedBox(height: Responsive.spacing(24)),
            GestureDetector(
              onTap: _loadTodayStatus,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(24), vertical: Responsive.spacing(12)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.gold,
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: Responsive.iconSize(18), color: Colors.white),
                    SizedBox(width: Responsive.spacing(8)),
                    Text('Coba Lagi', style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
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
      initialDate: _tanggalLupa ?? yesterday,
      firstDate: yesterday,
      lastDate: yesterday,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: NeoMiraiColors.gold,
              onPrimary: Colors.white,
              surface: NeoMiraiColors.rice,
              onSurface: NeoMiraiColors.ink,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: NeoMiraiColors.rice,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(16))),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _tanggalLupa = picked);
    }
  }
}
