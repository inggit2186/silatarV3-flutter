/// User Model
class User {
  final int id;
  final String name;
  final String email;
  final String? nip;
  final String? avatar;
  final String role;
  final String? unitKerja;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.nip,
    this.avatar,
    required this.role,
    this.unitKerja,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      nip: json['nip'],
      avatar: json['avatar'],
      role: json['role'] ?? 'pegawai',
      unitKerja: json['unit_kerja'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nip': nip,
      'avatar': avatar,
      'role': role,
      'unit_kerja': unitKerja,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Get display name (prioritas name > email > NIP)
  String get displayName => name.isNotEmpty ? name : (email.isNotEmpty ? email : (nip ?? '-'));

  /// Check if user is admin
  bool get isAdmin => role == 'superadmin' || role == 'admin';

  /// Check if user is frontdesk
  bool get isFrontdesk => role == 'frontdesk';

  /// Check if user is kepala
  bool get isKepala => role == 'kepala';

  /// Check if user is kasubbag
  bool get isKasubbag => role == 'kasubbag';
}
