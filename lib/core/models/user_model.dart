/// User Model
class User {
  final int id;
  final String name;
  final String email;
  final String? nip;
  final String? nomorInduk;
  final String? nik;
  final String? noHp;
  final String? alamat;
  final String? tempatLahir;
  final DateTime? tanggalLahir;
  final String? jenisKelamin;
  final String? avatar;
  final String? foto;
  final String? pp;
  final String? bio;
  final String role;
  final String? unitKerja;
  final int? unitId;
  final Department? dept;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.nip,
    this.nomorInduk,
    this.nik,
    this.noHp,
    this.alamat,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.avatar,
    this.foto,
    this.pp,
    this.bio,
    required this.role,
    this.unitKerja,
    this.unitId,
    this.dept,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Parse nested dept object
    Department? dept;
    if (json['dept'] != null) {
      dept = Department.fromJson(json['dept'] as Map<String, dynamic>);
    }

    return User(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      nip: _parseStringOrNull(json['nip']),
      nomorInduk: _parseStringOrNull(json['nomor_induk']),
      nik: _parseStringOrNull(json['nik']),
      noHp: _parseStringOrNull(json['no_hp']),
      alamat: _parseStringOrNull(json['alamat']),
      tempatLahir: _parseStringOrNull(json['tempat_lahir']),
      tanggalLahir: _parseDateTime(json['tanggal_lahir']),
      jenisKelamin: _parseStringOrNull(json['jenis_kelamin']),
      avatar: _parseStringOrNull(json['avatar']),
      foto: _parseStringOrNull(json['foto']),
      pp: _parseStringOrNull(json['pp']),
      bio: _parseStringOrNull(json['bio']),
      role: _parseString(json['role'] ?? 'pegawai'),
      unitKerja: _parseStringOrNull(json['unit_kerja'] ?? json['unit_nama'] ?? json['unit_id']),
      unitId: json['unit_id'] != null ? _parseInt(json['unit_id']) : null,
      dept: dept,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is int) return value.toString();
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nip': nip,
      'nomor_induk': nomorInduk,
      'nik': nik,
      'no_hp': noHp,
      'alamat': alamat,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir?.toIso8601String(),
      'jenis_kelamin': jenisKelamin,
      'avatar': avatar,
      'foto': foto,
      'pp': pp,
      'bio': bio,
      'role': role,
      'unit_kerja': unitKerja,
      'unit_id': unitId,
      'dept': dept?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? nip,
    String? nomorInduk,
    String? nik,
    String? noHp,
    String? alamat,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? avatar,
    String? foto,
    String? pp,
    String? bio,
    String? role,
    String? unitKerja,
    int? unitId,
    Department? dept,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      nip: nip ?? this.nip,
      nomorInduk: nomorInduk ?? this.nomorInduk,
      nik: nik ?? this.nik,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      avatar: avatar ?? this.avatar,
      foto: foto ?? this.foto,
      pp: pp ?? this.pp,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      unitKerja: unitKerja ?? this.unitKerja,
      unitId: unitId ?? this.unitId,
      dept: dept ?? this.dept,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => name.isNotEmpty ? name : (email.isNotEmpty ? email : (nip ?? nomorInduk ?? '-'));

  String? get photoUrl {
    if (pp != null && pp!.isNotEmpty) return pp;
    if (avatar != null && avatar!.isNotEmpty) return avatar;
    if (foto != null && foto!.isNotEmpty) return foto;
    return null;
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get isAdmin => role == 'superadmin' || role == 'admin';
  bool get isFrontdesk => role == 'frontdesk';
  bool get isKepala => role == 'kepala';
  bool get isKasubbag => role == 'kasubbag';
}

/// Department Model - contains office location
class Department {
  final int id;
  final String? nama;
  final double? latitude;
  final double? longitude;
  final double? radius; // Radius in meters for presensi area
  final String? jamMasuk; // "07:30:00" from ktd_department
  final String? jamPulang; // "16:00:00" from ktd_department
  final HariKerja? hariKerja;

  Department({
    required this.id,
    this.nama,
    this.latitude,
    this.longitude,
    this.radius,
    this.jamMasuk,
    this.jamPulang,
    this.hariKerja,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    HariKerja? hariKerjaData;
    if (json['hari_kerja'] != null) {
      hariKerjaData = HariKerja.fromJson(json['hari_kerja'] as Map<String, dynamic>);
    }

    return Department(
      id: _parseInt(json['id']),
      nama: _parseStringOrNull(json['nama']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      radius: _parseDouble(json['radius']) ?? 100.0,
      jamMasuk: _parseStringOrNull(json['jam_masuk']),
      jamPulang: _parseStringOrNull(json['jam_pulang']),
      hariKerja: hariKerjaData,
    );
  }

  /// Format jam "07:30:00" -> "07:30"
  String? get jamMasukFormatted => _formatJam(jamMasuk);
  String? get jamPulangFormatted => _formatJam(jamPulang);

  /// Format jam "07:30:00" or "07.30.59" -> "07.30"
  String? _formatJam(String? jam) {
    if (jam == null || jam.isEmpty) return null;
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

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is int) return value.toString();
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'hari_kerja': hariKerja?.toJson(),
    };
  }
}

/// HariKerja Model - contains work schedule per day
/// Format jam: "07.30.59" (format dari database)
class HariKerja {
  final int id;
  final String? masuk;   // Jam masuk Senin-Kamis
  final String? biasa;   // Jam pulang normal Senin-Kamis (16.00.00)
  final String? jumat;  // Jam pulang hari Jumat
  final String? sabtu;  // Jam pulang hari Sabtu (null = libur)
  final String? minggu;  // Jam pulang hari Minggu (null = libur)

  HariKerja({
    required this.id,
    this.masuk,
    this.biasa,
    this.jumat,
    this.sabtu,
    this.minggu,
  });

  factory HariKerja.fromJson(Map<String, dynamic> json) {
    return HariKerja(
      id: _parseInt(json['id']),
      masuk: _parseStringOrNull(json['masuk']),
      biasa: _parseStringOrNull(json['biasa']),
      jumat: _parseStringOrNull(json['jumat']),
      sabtu: _parseStringOrNull(json['sabtu']),
      minggu: _parseStringOrNull(json['minggu']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'masuk': masuk,
      'biasa': biasa,
      'jumat': jumat,
      'sabtu': sabtu,
      'minggu': minggu,
    };
  }

  /// Parse jam string "07.30.59" atau "07:30:59" ke TimeOfDay
  /// Returns null jika jam string null atau invalid
  TimeOfDay? parseJam(String? jamString) {
    if (jamString == null || jamString.isEmpty) return null;
    try {
      if (jamString.contains(':')) {
        // Format "07:30:59" -> hour=7, minute=30
        final parts = jamString.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        }
      } else if (jamString.contains('.')) {
        // Format "07.30.59" -> hour=7, minute=30
        final parts = jamString.split('.');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // Invalid format
    }
    return null;
  }

  /// Get jam masuk (Senin-Kamis)
  TimeOfDay? get jamMasuk => parseJam(masuk);

  /// Get jam pulang berdasarkan hari
  /// Senin-Kamis = biasa, Jumat = jumat, Sabtu = sabtu, Minggu = minggu
  /// Returns null jika hari tersebut libur
  TimeOfDay? getJamPulang(int dayOfWeek) {
    switch (dayOfWeek) {
      case DateTime.monday:
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return parseJam(biasa);
      case DateTime.friday:
        return parseJam(jumat);
      case DateTime.saturday:
        return parseJam(sabtu);
      case DateTime.sunday:
        return parseJam(minggu);
      default:
        return null;
    }
  }

  /// Check apakah hari ini adalah hari kerja
  /// Jika jam pulang null, berarti LIBUR
  bool isWorkDay(int dayOfWeek) {
    return getJamPulang(dayOfWeek) != null;
  }

  /// Check apakah hari ini adalah hari kerja (untuk dayOfWeek Dart: 1=Mon, 7=Sun)
  bool get isWorkDayToday => isWorkDay(DateTime.now().weekday);

  /// Get nama hari dalam Bahasa Indonesia
  static String getDayName(int dayOfWeek) {
    const days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) return days[dayOfWeek];
    return '';
  }

  /// Get semua nama hari kerja
  List<String> get workDayNames {
    final days = <String>[];
    for (int i = 1; i <= 7; i++) {
      if (isWorkDay(i)) {
        days.add(getDayName(i));
      }
    }
    return days;
  }

  /// Check apakah user terlambat
  /// Returns true jika absen masuk setelah jam masuk
  bool isTerlambat(DateTime absenTime) {
    final jamMasukData = jamMasuk;
    if (jamMasukData == null) return false;

    // Bandingkan jam absen dengan jam masuk
    final absenMinutes = absenTime.hour * 60 + absenTime.minute;
    final masukMinutes = jamMasukData.hour * 60 + jamMasukData.minute;

    return absenMinutes > masukMinutes;
  }

  /// Check apakah user pulang cepat
  /// Returns true jika absen pulang sebelum jam pulang
  bool isPulangCepat(DateTime absenTime, int dayOfWeek) {
    final jamPulangData = getJamPulang(dayOfWeek);
    if (jamPulangData == null) return false;

    // Bandingkan jam absen dengan jam pulang
    final absenMinutes = absenTime.hour * 60 + absenTime.minute;
    final pulangMinutes = jamPulangData.hour * 60 + jamPulangData.minute;

    return absenMinutes < pulangMinutes;
  }
}

/// Simple TimeOfDay class untuk parsing jam dari string
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  String format() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int toMinutes() => hour * 60 + minute;
}
