import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class AcaraPresensiPage extends StatefulWidget {
  final int acaraId;
  final String judul;
  final double? acaraLatitude;
  final double? acaraLongitude;
  final int? acaraRadius;

  const AcaraPresensiPage({
    super.key,
    required this.acaraId,
    required this.judul,
    this.acaraLatitude,
    this.acaraLongitude,
    this.acaraRadius,
  });

  @override
  State<AcaraPresensiPage> createState() => _AcaraPresensiPageState();
}

class _AcaraPresensiPageState extends State<AcaraPresensiPage> {
  bool _isProcessing = false;
  Position? _currentPosition;
  bool _isGettingLocation = false;
  String? _locationError;
  double? _distanceToAcara;
  File? _photoFile;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Izin lokasi ditolak';
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Izin lokasi ditolak permanen';
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Calculate distance to acara
      double? distance;
      if (widget.acaraLatitude != null && widget.acaraLongitude != null) {
        distance = _calculateDistance(
          widget.acaraLatitude!,
          widget.acaraLongitude!,
          position.latitude,
          position.longitude,
        );
      }

      setState(() {
        _currentPosition = position;
        _distanceToAcara = distance;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Gagal mendapatkan lokasi: $e';
        _isGettingLocation = false;
      });
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters

    final lat1Rad = lat1 * (3.141592653589793 / 180);
    final lon1Rad = lon1 * (3.141592653589793 / 180);
    final lat2Rad = lat2 * (3.141592653589793 / 180);
    final lon2Rad = lon2 * (3.141592653589793 / 180);

    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;

    final a = (dLat / 2) * (dLat / 2) +
        (lat1Rad) * (lat2Rad) * (dLon / 2) * (dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );

      if (photo != null) {
        setState(() {
          _photoFile = File(photo.path);
        });

        // Convert to base64 with compression
        final bytes = await _photoFile!.readAsBytes();
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
          ),
        );
      }
    }
  }

  Future<void> _submitHadir() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lokasi belum tersedia'),
          backgroundColor: NeoMiraiColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
        ),
      );
      return;
    }

    // Check if photo is required (only if acara has location)
    if (widget.acaraLatitude != null && widget.acaraLongitude != null && widget.acaraRadius != null && widget.acaraRadius! > 0) {
      if (_photoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Harap ambil foto terlebih dahulu'),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await ApiService.instance.submitHadir(
        widget.acaraId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        distance: _distanceToAcara,
        location: 'Lokasi presensi acara',
        foto: _photoBase64,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Presensi berhasil'),
              backgroundColor: NeoMiraiColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Gagal mengirim presensi'),
              backgroundColor: NeoMiraiColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: NeoMiraiColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(Responsive.spacing(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: Responsive.spacing(16)),
                      _buildLocationStatus(),
                      SizedBox(height: Responsive.spacing(20)),
                      _buildPhotoSection(),
                      SizedBox(height: Responsive.spacing(20)),
                      _buildSubmitButton(),
                      SizedBox(height: Responsive.spacing(24)),
                      _buildInfo(),
                    ],
                  ),
                ),
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
            child: Icon(Icons.fingerprint_rounded, size: Responsive.iconSize(26), color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presensi Acara', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text(widget.judul, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(20)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 20, color: NeoMiraiColors.gold),
              SizedBox(width: Responsive.spacing(8)),
              Text('Lokasi Anda', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            ],
          ),
          SizedBox(height: Responsive.spacing(16)),

          if (_isGettingLocation) ...[
            Center(child: CircularProgressIndicator(color: NeoMiraiColors.gold)),
            SizedBox(height: Responsive.spacing(12)),
            Center(child: Text('Mendapatkan lokasi...', style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft))),
          ] else if (_locationError != null) ...[
            Container(
              padding: EdgeInsets.all(Responsive.spacing(12)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Responsive.radius(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 18, color: NeoMiraiColors.error),
                  SizedBox(width: Responsive.spacing(8)),
                  Expanded(child: Text(_locationError!, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.error))),
                ],
              ),
            ),
            SizedBox(height: Responsive.spacing(12)),
            Center(
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoMiraiColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
                ),
              ),
            ),
          ] else if (_currentPosition != null) ...[
            // Koordinat
            _buildLocationInfoRow(
              Icons.my_location_rounded,
              'Koordinat',
              '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
            ),
            SizedBox(height: Responsive.spacing(8)),

            // Jarak ke acara
            if (_distanceToAcara != null) ...[
              _buildLocationInfoRow(
                Icons.straighten_rounded,
                'Jarak ke Acara',
                '${_distanceToAcara!.toStringAsFixed(0)} meter',
              ),
              SizedBox(height: Responsive.spacing(8)),

              // Radius info
              if (widget.acaraRadius != null && widget.acaraRadius! > 0) ...[
                _buildLocationInfoRow(
                  Icons.radio_button_checked_rounded,
                  'Radius Acara',
                  '${widget.acaraRadius} meter',
                ),
                SizedBox(height: Responsive.spacing(8)),

                // Status check
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(12)),
                  decoration: BoxDecoration(
                    color: _distanceToAcara! <= widget.acaraRadius!
                        ? NeoMiraiColors.success.withValues(alpha: 0.1)
                        : NeoMiraiColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                    border: Border.all(
                      color: _distanceToAcara! <= widget.acaraRadius!
                          ? NeoMiraiColors.success
                          : NeoMiraiColors.error,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _distanceToAcara! <= widget.acaraRadius!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 18,
                        color: _distanceToAcara! <= widget.acaraRadius!
                            ? NeoMiraiColors.success
                            : NeoMiraiColors.error,
                      ),
                      SizedBox(width: Responsive.spacing(8)),
                      Expanded(
                        child: Text(
                          _distanceToAcara! <= widget.acaraRadius!
                              ? 'Anda berada di dalam radius lokasi acara'
                              : 'Anda berada di luar radius lokasi acara',
                          style: TextStyle(
                            fontSize: Responsive.fontSize(12),
                            color: _distanceToAcara! <= widget.acaraRadius!
                                ? NeoMiraiColors.success
                                : NeoMiraiColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: EdgeInsets.all(Responsive.spacing(12)),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: NeoMiraiColors.success),
                      SizedBox(width: Responsive.spacing(8)),
                      Expanded(
                        child: Text(
                          'Anda bisa presensi dari lokasi mana saja',
                          style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              _buildLocationInfoRow(
                Icons.info_outline_rounded,
                'Status',
                'Menghitung jarak ke lokasi acara...',
              ),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLocationInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: NeoMiraiColors.ash),
        SizedBox(width: Responsive.spacing(8)),
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.ash)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(20)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.ink.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_rounded, size: 20, color: NeoMiraiColors.gold),
              SizedBox(width: Responsive.spacing(8)),
              Text('Foto Lokasi', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            ],
          ),
          SizedBox(height: Responsive.spacing(16)),

          if (_photoFile != null) ...[
            // Show photo preview
            ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.radius(12)),
              child: Image.file(
                _photoFile!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: Responsive.spacing(12)),
            Center(
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Ambil Ulang Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoMiraiColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
                ),
              ),
            ),
          ] else ...[
            // Show camera button
            Center(
              child: GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Responsive.radius(16)),
                    border: Border.all(
                      color: NeoMiraiColors.gold,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 40, color: NeoMiraiColors.gold),
                      SizedBox(height: Responsive.spacing(8)),
                      Text(
                        'Ambil Foto',
                        style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.gold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: NeoMiraiTheme.goldGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        boxShadow: [
          BoxShadow(
            color: NeoMiraiColors.gold.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_isProcessing || _currentPosition == null) ? null : _submitHadir,
          borderRadius: BorderRadius.circular(Responsive.radius(16)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Responsive.spacing(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else
                  Icon(Icons.fingerprint_rounded, size: 28, color: Colors.white),
                SizedBox(width: Responsive.spacing(12)),
                Text(
                  _isProcessing ? 'Mengirim Presensi...' : 'Presensi Hadir',
                  style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: NeoMiraiColors.gold),
          SizedBox(width: Responsive.spacing(8)),
          Expanded(
            child: Text(
              widget.acaraRadius != null && widget.acaraRadius! > 0
                  ? 'Pastikan Anda berada di dalam radius lokasi acara dan mengambil foto.'
                  : 'Anda bisa presensi dari lokasi mana saja. Foto opsional.',
              style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
