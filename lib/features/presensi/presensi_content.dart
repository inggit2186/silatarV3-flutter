import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/neo_mirai_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/services/api_service.dart';
import '../../core/models/user_model.dart';

class PresensiContent extends StatefulWidget {
  const PresensiContent({super.key});

  @override
  State<PresensiContent> createState() => _PresensiContentState();
}

class _PresensiContentState extends State<PresensiContent> {
  final MapController _mapController = MapController();

  // Location state
  LocationResult? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Default office location (fallback)
  static const LatLng _defaultOfficeLocation = LatLng(-0.4651, 100.6196);
  static const double _defaultRadius = 100.0;

  // Presensi state
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String? _statusMasuk;
  String? _statusPulang;
  double? _selisihMasuk; // dalam detik
  double? _selisihPulang; // dalam detik

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPresensiHariIni();
  }

  Future<void> _loadPresensiHariIni() async {
    final response = await ApiService.instance.getPresensiHariIni();
    if (response.success && response.data != null && mounted) {
      setState(() {
        if (response.data!.masuk != null) {
          final jam = response.data!.masuk!.jam;
          final parts = jam.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            _checkInTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
          }
          _statusMasuk = response.data!.status;
          _selisihMasuk = response.data!.masuk!.selisih;
        }
        if (response.data!.pulang != null) {
          final jam = response.data!.pulang!.jam;
          final parts = jam.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            _checkOutTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
          }
          _statusPulang = response.data!.status;
          _selisihPulang = response.data!.pulang!.selisih;
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Get department data from user provider
  Department? get _department => context.read<UserProvider>().user?.dept;
  HariKerja? get _hariKerja => _department?.hariKerja;

  // Get office location
  LatLng get _officeLocation {
    final dept = _department;
    if (dept?.latitude != null && dept?.longitude != null) {
      return LatLng(dept!.latitude!, dept.longitude!);
    }
    return _defaultOfficeLocation;
  }

  // Get radius
  double get _radiusInMeters => _department?.radius ?? _defaultRadius;

  // Check if today is a work day
  bool get _isWorkDay {
    final hk = _hariKerja;

    // If no hari_kerja data, default to Mon-Fri workdays
    if (hk == null) {
      final day = DateTime.now().weekday;
      // Default: Mon(1) to Fri(5) is workday, Sat(6) and Sun(7) is holiday
      return day >= 1 && day <= 5;
    }

    // Use hari_kerja data
    return hk.isWorkDayToday;
  }

  // Get current day of week (Dart format: 1=Mon, 7=Sun)
  int get _currentDayOfWeek => DateTime.now().weekday;

  // Get jam masuk from dept
  String get _jamMasukText {
    final dept = _department;
    if (dept?.jamMasuk != null) {
      return dept!.jamMasukFormatted ?? '<None>';
    }
    return '<None>';
  }

  // Get jam pulang based on current day
  String get _jamPulangText {
    final dept = _department;
    final hk = _hariKerja;
    final day = _currentDayOfWeek;

    // Prioritas 1: dari hari_kerja schedule
    if (hk != null) {
      final jamPulang = hk.getJamPulang(day);
      if (jamPulang != null) return jamPulang.format();
    }

    // Prioritas 2: dari ktd_department.jam_pulang
    if (dept?.jamPulang != null) {
      return dept!.jamPulangFormatted ?? '<None>';
    }

    return '<None>';
  }

  // Check if it's presensi masuk time (00:00 - 11:59)
  bool get _isPresensiMasukTime => DateTime.now().hour < 12;
  String get _presensiLabel => _isPresensiMasukTime ? 'PRESENSI MASUK' : 'PRESENSI PULANG';

  // Check if already presensi today
  bool get _hasPresensiHariIni {
    // Cek apakah sudah ada presensi masuk atau pulang hari ini
    final hasMasuk = _checkInTime != null && _isSameDay(_checkInTime!, DateTime.now());

    // Untuk presensi masuk: hanya bisa 1x (belum ada masuk)
    // Untuk presensi pulang: bisa update berkali-kali (ambil yang paling baru)
    if (_isPresensiMasukTime) {
      return hasMasuk;
    } else {
      // Presensi pulang: selalu bisa (update berkali-kali)
      return false;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _isWithinRadius {
    if (_currentLocation == null) return false;
    final locationService = LocationService();
    return locationService.isWithinRadius(
      _currentLocation!.toLatLng(),
      _officeLocation,
      _radiusInMeters,
    );
  }

  double? get _distanceToOffice {
    if (_currentLocation == null) return null;
    final locationService = LocationService();
    return locationService.calculateDistance(
      _currentLocation!.toLatLng(),
      _officeLocation,
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    final locationService = LocationService();
    final result = await locationService.getCurrentPosition();

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        if (result != null) {
          _currentLocation = result;
        } else {
          _locationError = 'Tidak dapat mendapatkan lokasi. Pastikan GPS aktif dan permission diberikan.';
        }
      });
    }
  }

  void _centerOnUserLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!.toLatLng(), 17);
    }
  }

  void _centerOnOffice() {
    _mapController.move(_officeLocation, 17);
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final user = context.watch<UserProvider>().user;

    return Container(
      decoration: BoxDecoration(gradient: NeoMiraiTheme.paperGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header (fixed)
            _buildHeader(context, user?.displayName ?? 'Warga'),
            // Location status (fixed)
            _buildLocationStatus(),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
                child: Column(
                  children: [
                    SizedBox(height: Responsive.spacing(16)),
                    // Map
                    _buildMap(),
                    SizedBox(height: Responsive.spacing(16)),
                    // Presensi button card
                    _buildPresensiCard(),
                    SizedBox(height: Responsive.spacing(16)),
                    // Work summary
                    _buildWorkSummary(),
                    SizedBox(height: Responsive.spacing(16)),
                    // Weekly schedule
                    _buildWorkDayInfo(),
                    SizedBox(height: Responsive.spacing(16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(16)),
      child: Row(
        children: [
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
                Text('Presensi', style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                SizedBox(height: Responsive.spacing(2)),
                Text(userName, style: TextStyle(fontSize: Responsive.fontSize(11), color: NeoMiraiColors.inkSoft)),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            icon: _isLoadingLocation
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: NeoMiraiColors.gold))
                : Icon(Icons.refresh_rounded, color: NeoMiraiColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(16)),
      padding: EdgeInsets.all(Responsive.spacing(12)),
      decoration: BoxDecoration(
        color: _getLocationStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
        border: Border.all(color: _getLocationStatusColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_getLocationStatusIcon(), color: _getLocationStatusColor(), size: Responsive.iconSize(20)),
          SizedBox(width: Responsive.spacing(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getLocationStatusTitle(), style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: _getLocationStatusColor())),
                if (_currentLocation != null) ...[
                  SizedBox(height: 2),
                  Text(
                    '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft),
                  ),
                ],
                if (_locationError != null) ...[
                  SizedBox(height: 2),
                  Text(_locationError!, style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.error), maxLines: 2),
                ],
              ],
            ),
          ),
          if (_distanceToOffice != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(10), vertical: Responsive.spacing(4)),
              decoration: BoxDecoration(
                color: _isWithinRadius ? NeoMiraiColors.success.withValues(alpha: 0.2) : NeoMiraiColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(Responsive.radius(8)),
              ),
              child: Text(
                LocationService().getDistanceText(_distanceToOffice!),
                style: TextStyle(
                  fontSize: Responsive.fontSize(11),
                  fontWeight: FontWeight.w600,
                  color: _isWithinRadius ? NeoMiraiColors.success : NeoMiraiColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Color _getLocationStatusColor() {
    if (_isLoadingLocation) return NeoMiraiColors.warning;
    if (_locationError != null) return NeoMiraiColors.error;
    if (_currentLocation == null) return NeoMiraiColors.ash;
    if (_isWithinRadius) return NeoMiraiColors.success;
    return NeoMiraiColors.error;
  }

  IconData _getLocationStatusIcon() {
    if (_isLoadingLocation) return Icons.location_searching_rounded;
    if (_locationError != null) return Icons.location_off_rounded;
    if (_currentLocation == null) return Icons.location_disabled_rounded;
    if (_isWithinRadius) return Icons.location_on_rounded;
    return Icons.location_off_rounded;
  }

  String _getLocationStatusTitle() {
    if (_isLoadingLocation) return 'Mendeteksi lokasi...';
    if (_locationError != null) return 'Lokasi tidak tersedia';
    if (_currentLocation == null) return 'Lokasi belum dideteksi';
    if (_isWithinRadius) return 'Dalam area presensi';
    return 'Di luar area presensi';
  }

  Widget _buildMap() {
    return Container(
      height: 200,
      margin: EdgeInsets.all(Responsive.spacing(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        boxShadow: [BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation?.toLatLng() ?? _officeLocation,
                initialZoom: 17,
                minZoom: 15,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.silatar_v2',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _officeLocation,
                      radius: _radiusInMeters,
                      useRadiusInMeter: true,
                      color: NeoMiraiColors.gold.withValues(alpha: 0.15),
                      borderColor: NeoMiraiColors.gold,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _officeLocation,
                      width: 50,
                      height: 50,
                      child: _buildOfficeMarker(),
                    ),
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!.toLatLng(),
                        width: 40,
                        height: 40,
                        child: _buildUserMarker(),
                      ),
                  ],
                ),
              ],
            ),
            if (_isLoadingLocation)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(Responsive.spacing(16)),
                    decoration: BoxDecoration(
                      color: NeoMiraiColors.rice,
                      borderRadius: BorderRadius.circular(Responsive.radius(12)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: NeoMiraiColors.gold),
                        SizedBox(height: Responsive.spacing(8)),
                        Text('Mendeteksi lokasi...', style: TextStyle(fontSize: Responsive.fontSize(12))),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Column(
                children: [
                  _buildMapButton(Icons.my_location_rounded, _centerOnUserLocation, NeoMiraiColors.gold),
                  SizedBox(height: 8),
                  _buildMapButton(Icons.business_rounded, _centerOnOffice, NeoMiraiColors.night),
                ],
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.rice,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(NeoMiraiColors.gold, 'Area Presensi'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NeoMiraiColors.rice,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, color: NeoMiraiColors.ink)),
      ],
    );
  }

  Widget _buildOfficeMarker() {
    return Container(
      decoration: BoxDecoration(
        color: NeoMiraiColors.gold,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: NeoMiraiColors.gold.withValues(alpha: 0.5), blurRadius: 8)],
      ),
      child: Icon(Icons.business_rounded, color: Colors.white, size: 24),
    );
  }

  Widget _buildUserMarker() {
    final color = _isWithinRadius ? NeoMiraiColors.success : NeoMiraiColors.error;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
      ),
      child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildWorkDayInfo() {
    final hk = _hariKerja;
    final isWorkDay = hk?.isWorkDayToday ?? true;
    final todayName = HariKerja.getDayName(_currentDayOfWeek);

    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.radius(8)),
                decoration: BoxDecoration(
                  gradient: NeoMiraiTheme.goldGradient,
                  borderRadius: BorderRadius.circular(Responsive.radius(10)),
                ),
                child: Icon(Icons.schedule_rounded, size: Responsive.iconSize(18), color: Colors.white),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jadwal Presensi', style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
                    SizedBox(height: 2),
                    Text(
                      isWorkDay ? todayName : 'LIBUR',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(11),
                        fontWeight: FontWeight.w600,
                        color: isWorkDay ? NeoMiraiColors.info : NeoMiraiColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              if (isWorkDay)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NeoMiraiColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: NeoMiraiColors.success),
                      SizedBox(width: 4),
                      Text('Hari Kerja', style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: NeoMiraiColors.success)),
                    ],
                  ),
                ),
              if (!isWorkDay)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NeoMiraiColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.weekend_rounded, size: 14, color: NeoMiraiColors.warning),
                      SizedBox(width: 4),
                      Text('Libur', style: TextStyle(fontSize: Responsive.fontSize(10), fontWeight: FontWeight.w600, color: NeoMiraiColors.warning)),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: Responsive.spacing(16)),

          // Jam kerja hari ini
          if (isWorkDay) ...[
            Container(
              padding: EdgeInsets.all(Responsive.spacing(12)),
              decoration: BoxDecoration(
                gradient: NeoMiraiTheme.nightGradient,
                borderRadius: BorderRadius.circular(Responsive.radius(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildJamKerjaItem(Icons.login_rounded, 'Jam Masuk', _jamMasukText, NeoMiraiColors.success),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildJamKerjaItem(Icons.logout_rounded, 'Jam Pulang', _jamPulangText, NeoMiraiColors.info),
                ],
              ),
            ),
          ],

          SizedBox(height: Responsive.spacing(16)),

          // Jadwal Mingguan
          Text('Jadwal Mingguan', style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(10)),
          _buildWeeklySchedule(hk),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildJamKerjaItem(IconData icon, String label, String jam, Color color) {
    return Column(
      children: [
        Icon(icon, size: Responsive.iconSize(20), color: color),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: Responsive.fontSize(9), color: Colors.white70)),
        Text(jam, style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildWeeklySchedule(HariKerja? hk) {
    final dept = _department;

    // Default values if data is null
    final jamMasukDept = dept?.jamMasukFormatted ?? '<None>';
    final jamPulangDept = dept?.jamPulangFormatted ?? '<None>';

    // Use hk data or fallback to dept data
    final jamMasuk = hk?.masuk != null ? _formatJamKerja(hk!.masuk) : jamMasukDept;
    final biasa = hk?.biasa != null ? _formatJamKerja(hk!.biasa) : jamPulangDept;
    final jumat = hk?.jumat != null ? _formatJamKerja(hk!.jumat) : '<None>';
    final sabtu = hk?.sabtu != null ? _formatJamKerja(hk!.sabtu) : null;
    final minggu = hk?.minggu != null ? _formatJamKerja(hk!.minggu) : null;

    // Check if it's a work day (sabtu/minggu null = libur)
    final isSabtuLibur = sabtu == null;
    final isMingguLibur = minggu == null;

    final days = [
      {'name': 'Senin', 'day': DateTime.monday, 'jam': jamMasuk, 'pulang': biasa, 'isLibur': false},
      {'name': 'Selasa', 'day': DateTime.tuesday, 'jam': jamMasuk, 'pulang': biasa, 'isLibur': false},
      {'name': 'Rabu', 'day': DateTime.wednesday, 'jam': jamMasuk, 'pulang': biasa, 'isLibur': false},
      {'name': 'Kamis', 'day': DateTime.thursday, 'jam': jamMasuk, 'pulang': biasa, 'isLibur': false},
      {'name': 'Jumat', 'day': DateTime.friday, 'jam': jamMasuk, 'pulang': jumat, 'isLibur': false},
      {'name': 'Sabtu', 'day': DateTime.saturday, 'jam': jamMasuk, 'pulang': sabtu, 'isLibur': isSabtuLibur},
      {'name': 'Minggu', 'day': DateTime.sunday, 'jam': jamMasuk, 'pulang': minggu, 'isLibur': isMingguLibur},
    ];

    return Column(
      children: days.map((day) {
        final isToday = day['day'] == _currentDayOfWeek;
        final isLibur = day['isLibur'] as bool;
        final pulang = day['pulang'] as String?;

        return Container(
          margin: EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isToday
                ? NeoMiraiColors.gold.withValues(alpha: 0.1)
                : (isLibur ? NeoMiraiColors.ash.withValues(alpha: 0.05) : NeoMiraiColors.rice),
            borderRadius: BorderRadius.circular(Responsive.radius(10)),
            border: isToday
                ? Border.all(color: NeoMiraiColors.gold, width: 1.5)
                : Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Nama hari
              SizedBox(
                width: 60,
                child: Text(
                  day['name'] as String,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(11),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday ? NeoMiraiColors.gold : NeoMiraiColors.ink,
                  ),
                ),
              ),
              // Jam masuk & pulang
              if (!isLibur && day['jam'] != null) ...[
                Icon(Icons.login_rounded, size: 12, color: NeoMiraiColors.success),
                SizedBox(width: 4),
                Text(
                  day['jam'] as String,
                  style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft),
                ),
                SizedBox(width: 12),
                Icon(Icons.logout_rounded, size: 12, color: NeoMiraiColors.info),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pulang ?? '--:--',
                    style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft),
                  ),
                ),
              ],
              if (isLibur) ...[
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.weekend_rounded, size: 14, color: NeoMiraiColors.ash),
                      SizedBox(width: 6),
                      Text(
                        'Libur',
                        style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.ash),
                      ),
                    ],
                  ),
                ),
              ],
              if (isToday)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: NeoMiraiColors.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Hari Ini',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatJamKerja(String? jam) {
    if (jam == null || jam.isEmpty) return '--:--';
    // Format: "07.30.59" atau "07:30:59" -> "07.30"
    try {
      final parts = jam.split(RegExp(r'[:\.]'));
      if (parts.length >= 2) {
        return '${parts[0]}.${parts[1]}';
      }
    } catch (e) {
      // Return original if parsing fails
    }
    return jam;
  }

  Widget _buildPresensiCard() {
    // Determine colors and state
    final bool isPresensiMasuk = _isPresensiMasukTime;
    final Color buttonColor = isPresensiMasuk ? NeoMiraiColors.success : NeoMiraiColors.info;
    final String title = isPresensiMasuk ? 'Presensi Masuk' : 'Presensi Pulang';

    // Determine subtitle
    String subtitle;
    final hasPulangToday = _checkOutTime != null && _isSameDay(_checkOutTime!, DateTime.now());

    if (!_isWorkDay) {
      subtitle = 'Bukan hari kerja';
    } else if (_hasPresensiHariIni) {
      if (isPresensiMasuk) {
        subtitle = 'Presensi masuk sudah dilakukan';
      } else {
        subtitle = 'Belum presensi masuk hari ini';
      }
    } else if (!_isWithinRadius) {
      subtitle = 'Mendekati area presensi';
    } else if (!isPresensiMasuk && hasPulangToday) {
      subtitle = 'Update presensi pulang (ambil yang paling baru)';
    } else {
      subtitle = 'Tekan fingerprint untuk presensi';
    }

    // Check if already presensi
    DateTime? savedTime = isPresensiMasuk ? _checkInTime : _checkOutTime;

    // Check if button should be enabled
    bool isEnabled = _isWorkDay && _currentLocation != null && _isWithinRadius && !_hasPresensiHariIni;

    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(24)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(24)),
        boxShadow: [
          BoxShadow(color: NeoMiraiColors.ink.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Jam indicator
          _buildJamIndicator(),
          SizedBox(height: Responsive.spacing(16)),

          // Title
          Text(title, style: TextStyle(fontSize: Responsive.fontSize(18), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
          SizedBox(height: Responsive.spacing(4)),
          Text(subtitle, style: TextStyle(fontSize: Responsive.fontSize(12), color: NeoMiraiColors.inkSoft), textAlign: TextAlign.center),

          // Fingerprint button
          SizedBox(height: Responsive.spacing(20)),
          _buildFingerprintButton(isEnabled, buttonColor),

          // Info text
          SizedBox(height: Responsive.spacing(8)),
          Text(
            'Klik Icon Fingerprint untuk Mengambil Presensi',
            style: TextStyle(
              fontSize: Responsive.fontSize(9),
              color: NeoMiraiColors.ash,
            ),
            textAlign: TextAlign.center,
          ),

          // Saved time indicator
          if (savedTime != null && _isSameDay(savedTime, DateTime.now())) ...[
            SizedBox(height: Responsive.spacing(16)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(16), vertical: Responsive.spacing(10)),
              decoration: BoxDecoration(
                color: NeoMiraiColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Responsive.radius(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: Responsive.iconSize(18), color: NeoMiraiColors.success),
                  SizedBox(width: Responsive.spacing(8)),
                  Text(
                    isPresensiMasuk ? 'Tercatat: ${_formatTime(savedTime)}' : 'Terakhir: ${_formatTime(savedTime)} (bisa update)',
                    style: TextStyle(fontSize: Responsive.fontSize(12), fontWeight: FontWeight.w600, color: NeoMiraiColors.success),
                  ),
                ],
              ),
            ),
            // Status TERLAMBAT atau PULANG CEPAT
            if (isPresensiMasuk ? _statusMasuk == 'TERLAMBAT' : _statusPulang == 'PULANG_CEPAT') ...[
              SizedBox(height: Responsive.spacing(8)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(12), vertical: Responsive.spacing(6)),
                decoration: BoxDecoration(
                  color: NeoMiraiColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Responsive.radius(12)),
                  border: Border.all(color: NeoMiraiColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded, size: Responsive.iconSize(14), color: NeoMiraiColors.error),
                    SizedBox(width: Responsive.spacing(6)),
                    Text(
                      _buildStatusText(isPresensiMasuk),
                      style: TextStyle(
                        fontSize: Responsive.fontSize(10),
                        fontWeight: FontWeight.w600,
                        color: NeoMiraiColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Disabled reason
          if (!isEnabled && !_hasPresensiHariIni) ...[
            Text(
              _getDisabledReason(),
              style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFingerprintButton(bool isEnabled, Color color) {
    return GestureDetector(
      onTap: isEnabled ? _handlePresensi : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? color.withValues(alpha: 0.12) : NeoMiraiColors.ash.withValues(alpha: 0.1),
          border: Border.all(
            color: isEnabled ? color : NeoMiraiColors.ash,
            width: 3,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint_rounded,
              size: 64,
              color: isEnabled ? color : NeoMiraiColors.ash,
            ),
            SizedBox(height: Responsive.spacing(4)),
            Text(
              isEnabled ? 'TAP' : 'Nonaktif',
              style: TextStyle(
                fontSize: Responsive.fontSize(10),
                fontWeight: FontWeight.bold,
                color: isEnabled ? color : NeoMiraiColors.ash,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJamIndicator() {
    final now = DateTime.now();
    final hk = _hariKerja;
    final isTerlambat = hk?.isTerlambat(now) ?? false;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(16), vertical: Responsive.spacing(10)),
      decoration: BoxDecoration(
        gradient: _isPresensiMasukTime ? NeoMiraiTheme.goldGradient : NeoMiraiTheme.nightGradient,
        borderRadius: BorderRadius.circular(Responsive.radius(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: Responsive.iconSize(16), color: Colors.white),
          SizedBox(width: Responsive.spacing(8)),
          Text(
            'Jam ${_formatTime(now)}',
            style: TextStyle(fontSize: Responsive.fontSize(14), fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(width: Responsive.spacing(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Responsive.spacing(8), vertical: Responsive.spacing(2)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Responsive.radius(10)),
            ),
            child: Text(
              _isPresensiMasukTime ? 'MASUK' : 'PULANG',
              style: TextStyle(fontSize: Responsive.fontSize(9), fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisabledReason() {
    if (!_isWorkDay) return '• Bukan hari kerja';
    if (_currentLocation == null) return '• Lokasi belum terdeteksi';
    if (!_isWithinRadius) return '• Berada di luar area presensi';
    return '';
  }

  Widget _buildWorkSummary() {
    Duration? workDuration;
    if (_checkInTime != null && _checkOutTime != null) {
      if (_isSameDay(_checkInTime!, _checkOutTime!)) {
        workDuration = _checkOutTime!.difference(_checkInTime!);
      }
    }

    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(16)),
      decoration: BoxDecoration(
        color: NeoMiraiColors.rice,
        borderRadius: BorderRadius.circular(Responsive.radius(16)),
        border: Border.all(color: NeoMiraiColors.line.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, size: Responsive.iconSize(18), color: NeoMiraiColors.gold),
              SizedBox(width: Responsive.spacing(8)),
              Text('Ringkasan Hari Ini', style: TextStyle(fontSize: Responsive.fontSize(13), fontWeight: FontWeight.bold, color: NeoMiraiColors.ink)),
            ],
          ),
          SizedBox(height: Responsive.spacing(16)),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Jam Masuk',
                  _checkInTime != null && _isSameDay(_checkInTime!, DateTime.now()) ? _formatTime(_checkInTime!) : '--:--',
                  Icons.login_rounded,
                  NeoMiraiColors.success,
                ),
              ),
              SizedBox(width: Responsive.spacing(12)),
              Expanded(
                child: _buildSummaryItem(
                  'Jam Pulang',
                  _checkOutTime != null && _isSameDay(_checkOutTime!, DateTime.now()) ? _formatTime(_checkOutTime!) : '--:--',
                  Icons.logout_rounded,
                  NeoMiraiColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacing(12)),
          _buildSummaryItem(
            'Total Jam Kerja',
            workDuration != null ? _formatDuration(workDuration) : '--:--',
            Icons.timer_rounded,
            NeoMiraiColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(12)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Responsive.radius(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: Responsive.iconSize(14), color: color),
              SizedBox(width: Responsive.spacing(6)),
              Text(label, style: TextStyle(fontSize: Responsive.fontSize(10), color: NeoMiraiColors.inkSoft)),
            ],
          ),
          SizedBox(height: Responsive.spacing(4)),
          Text(value, style: TextStyle(fontSize: Responsive.fontSize(16), fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Format selisih detik ke "X jam X menit X detik"
  String _formatSelisih(double? detik) {
    if (detik == null || detik <= 0) return '';

    final jam = (detik ~/ 3600);
    final menit = ((detik % 3600) ~/ 60);
    final det = (detik % 60).toInt();

    final parts = <String>[];
    if (jam > 0) parts.add('$jam jam');
    if (menit > 0) parts.add('$menit menit');
    if (det > 0) parts.add('$det detik');

    return parts.join(' ');
  }

  String _buildStatusText(bool isMasuk) {
    if (isMasuk) {
      if (_statusMasuk == 'TERLAMBAT') {
        return 'TERLAMBAT ${_formatSelisih(_selisihMasuk)}';
      }
    } else {
      if (_statusPulang == 'PULANG_CEPAT') {
        return 'PULANG CEPAT ${_formatSelisih(_selisihPulang)}';
      }
    }
    return '';
  }

  void _handlePresensi() async {
    if (_currentLocation == null) return;

    final now = DateTime.now();
    final isMasuk = _isPresensiMasukTime;
    final jenis = isMasuk ? 'masuk' : 'pulang';
    final distance = _distanceToOffice;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: Responsive.spacing(10)),
            Text('Mengirim presensi $jenis...'),
          ],
        ),
        backgroundColor: NeoMiraiColors.info,
        duration: const Duration(seconds: 10),
      ),
    );

    // Call API
    final response = await ApiService.instance.simpanPresensi(
      jenis: jenis,
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      jarakMeter: distance,
    );

    // Remove loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (response.success) {
      // Update state
      setState(() {
        if (isMasuk) {
          _checkInTime = now;
        } else {
          _checkOutTime = now;
        }
      });

      // Show success
      _showSuccessSnackbar(
        'Presensi $jenis berhasil!',
        now,
        response.message,
      );
    } else {
      // Show error
      if (mounted) {
        // Jika message mengandung "sudah dilakukan", treat sebagai success
        final msg = response.message ?? 'Gagal menyimpan presensi';
        if (msg.toLowerCase().contains('sudah dilakukan') || msg.toLowerCase().contains('sudah ada')) {
          // Presensi sudah ada, update state
          setState(() {
            if (isMasuk) {
              _checkInTime = now;
            } else {
              _checkOutTime = now;
            }
          });

          // Show success
          _showSuccessSnackbar(
            'Presensi $jenis berhasil diupdate!',
            now,
            'Data presensi telah diperbarui',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: Responsive.spacing(10)),
                  Expanded(child: Text(msg)),
                ],
              ),
              backgroundColor: NeoMiraiColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
            ),
          );
        }
      }
    }
  }

  void _showSuccessSnackbar(String message, DateTime time, [String? serverMessage]) {
    final displayMessage = serverMessage ?? message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: Responsive.spacing(10)),
            Expanded(child: Text('$displayMessage Pukul ${_formatTime(time)}')),
          ],
        ),
        backgroundColor: NeoMiraiColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(12))),
      ),
    );
  }
}
