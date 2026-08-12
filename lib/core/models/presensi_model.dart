/// Presensi Model - sesuai dengan struktur ktd_presensi
class Presensi {
  final int id;
  final int? userNip;
  final int? deptId;
  final String tanggal;
  final String? mAbsen;
  final double? mLatitude;
  final double? mLongitude;
  final double? mDistance;
  final String? mLocation;
  final String? pAbsen;
  final double? pLatitude;
  final double? pLongitude;
  final double? pDistance;
  final String? pLocation;
  final String? status;
  final String? keterangan;
  final DateTime? createdAt;

  Presensi({
    required this.id,
    this.userNip,
    this.deptId,
    required this.tanggal,
    this.mAbsen,
    this.mLatitude,
    this.mLongitude,
    this.mDistance,
    this.mLocation,
    this.pAbsen,
    this.pLatitude,
    this.pLongitude,
    this.pDistance,
    this.pLocation,
    this.status,
    this.keterangan,
    this.createdAt,
  });

  factory Presensi.fromJson(Map<String, dynamic> json) {
    return Presensi(
      id: _parseInt(json['id']),
      userNip: _parseIntOrNull(json['user_nip']),
      deptId: _parseIntOrNull(json['dept_id']),
      tanggal: _parseString(json['tanggal']),
      mAbsen: _parseStringOrNull(json['m_absen']),
      mLatitude: _parseDouble(json['m_latitude']),
      mLongitude: _parseDouble(json['m_longitude']),
      mDistance: _parseDouble(json['m_distance']),
      mLocation: _parseStringOrNull(json['m_location']),
      pAbsen: _parseStringOrNull(json['p_absen']),
      pLatitude: _parseDouble(json['p_latitude']),
      pLongitude: _parseDouble(json['p_longitude']),
      pDistance: _parseDouble(json['p_distance']),
      pLocation: _parseStringOrNull(json['p_location']),
      status: _parseStringOrNull(json['status']),
      keterangan: _parseStringOrNull(json['keterangan']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  bool get hasMasuk => mAbsen != null && mAbsen!.isNotEmpty;
  bool get hasPulang => pAbsen != null && pAbsen!.isNotEmpty;
  bool get isTelat => status == 'telat';
  bool get isPulangCepat => status == 'pulang_cepat';

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Data jam presensi masuk/pulang
class PresensiJam {
  final String jam;
  final double? latitude;
  final double? longitude;
  final double? jarakMeter;
  final double? selisih;

  PresensiJam({
    required this.jam,
    this.latitude,
    this.longitude,
    this.jarakMeter,
    this.selisih,
  });

  factory PresensiJam.fromJson(Map<String, dynamic> json) {
    return PresensiJam(
      jam: json['jam'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      jarakMeter: _parseDouble(json['jarak_meter']),
      selisih: _parseDouble(json['selisih']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Response untuk presensi hari ini
class PresensiHariIni {
  final String tanggal;
  final String? status;
  final PresensiJam? masuk;
  final PresensiJam? pulang;

  PresensiHariIni({
    required this.tanggal,
    this.status,
    this.masuk,
    this.pulang,
  });

  factory PresensiHariIni.fromJson(Map<String, dynamic> json) {
    return PresensiHariIni(
      tanggal: json['tanggal'] ?? '',
      status: json['status'],
      masuk: json['masuk'] != null ? PresensiJam.fromJson(json['masuk']) : null,
      pulang: json['pulang'] != null ? PresensiJam.fromJson(json['pulang']) : null,
    );
  }

  bool get hasMasuk => masuk != null;
  bool get hasPulang => pulang != null;
  bool get isTerlambat => status == 'TERLAMBAT';
  bool get isPulangCepat => status == 'PULANG_CEPAT';
  bool get isPulangNormal => status == 'PULANG';
}

/// Response untuk history presensi
class PresensiHistory {
  final int bulan;
  final int tahun;
  final int total;
  final List<Presensi> data;

  PresensiHistory({
    required this.bulan,
    required this.tahun,
    required this.total,
    required this.data,
  });

  factory PresensiHistory.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return PresensiHistory(
      bulan: _parseInt(json['bulan']) ?? 1,
      tahun: _parseInt(json['tahun']) ?? 2024,
      total: _parseInt(json['total']) ?? 0,
      data: dataList.map((e) => Presensi.fromJson(e)).toList(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
