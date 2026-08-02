/// User Model
class User {
  final int id;
  final String name;
  final String email;
  final String? nip;
  final String? nomorInduk;
  final String? avatar;
  final String? foto;
  final String? pp;
  final String role;
  final String? unitKerja;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.nip,
    this.nomorInduk,
    this.avatar,
    this.foto,
    this.pp,
    required this.role,
    this.unitKerja,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      nip: _parseStringOrNull(json['nip']),
      nomorInduk: _parseStringOrNull(json['nomor_induk']),
      avatar: _parseStringOrNull(json['avatar']),
      foto: _parseStringOrNull(json['foto']),
      pp: _parseStringOrNull(json['pp']),
      role: _parseString(json['role'] ?? 'pegawai'),
      unitKerja: _parseStringOrNull(json['unit_kerja'] ?? json['unit_nama'] ?? json['unit_id']),
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
      'avatar': avatar,
      'foto': foto,
      'pp': pp,
      'role': role,
      'unit_kerja': unitKerja,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Get display name (prioritas name > email > NIP)
  String get displayName => name.isNotEmpty ? name : (email.isNotEmpty ? email : (nip ?? nomorInduk ?? '-'));

  /// Get photo URL (prioritas: pp > avatar > foto)
  String? get photoUrl {
    if (pp != null && pp!.isNotEmpty) return pp;
    if (avatar != null && avatar!.isNotEmpty) return avatar;
    if (foto != null && foto!.isNotEmpty) return foto;
    return null;
  }

  /// Check if user has photo
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Check if user is admin
  bool get isAdmin => role == 'superadmin' || role == 'admin';

  /// Check if user is frontdesk
  bool get isFrontdesk => role == 'frontdesk';

  /// Check if user is kepala
  bool get isKepala => role == 'kepala';

  /// Check if user is kasubbag
  bool get isKasubbag => role == 'kasubbag';
}
