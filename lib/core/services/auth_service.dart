import 'api_client.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class AuthService {
  final ApiClient _api = ApiClient();
  final StorageService _storage = StorageService();

  /// Login user
  /// POST /api/auth/login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        '/auth/login',
        data: {
          'login': email,
          'password': password,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        // Save token and user data
        final token = data['data']['token'];
        await _storage.setToken(token);

        return AuthResponse.fromJson(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Register new user
  /// POST /api/auth/register
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? nik,
    String? phone,
  }) async {
    try {
      final response = await _api.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          if (nik != null) 'nik': nik,
          if (phone != null) 'phone': phone,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        final token = data['data']['token'];
        await _storage.setToken(token);

        return AuthResponse.fromJson(data['data']);
      } else {
        throw ApiException(
          data['message'] ?? 'Registrasi gagal',
          errors: data['errors'],
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Get current user
  /// GET /api/auth/me
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');

      final data = response.data;
      if (data['success'] == true) {
        return UserModel.fromJson(data['data']['user']);
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil data user');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Logout
  /// POST /api/auth/logout
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      // Ignore errors, still clear local data
    } finally {
      await _storage.clearAll();
    }
  }

  /// Update profile
  /// PUT /api/auth/update-profile
  Future<UserModel> updateProfile({
    String? name,
    String? nik,
    String? noHp,
    String? alamat,
    String? tempatLahir,
    String? tanggalLahir,
    String? jenisKelamin,
  }) async {
    try {
      final response = await _api.put(
        '/auth/update-profile',
        data: {
          if (name != null) 'name': name,
          if (nik != null) 'nik': nik,
          if (noHp != null) 'no_hp': noHp,
          if (alamat != null) 'alamat': alamat,
          if (tempatLahir != null) 'tempat_lahir': tempatLahir,
          if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
          if (jenisKelamin != null) 'jenis_kelamin': jenisKelamin,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        return UserModel.fromJson(data['data']['user']);
      } else {
        throw ApiException(data['message'] ?? 'Gagal update profile');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Change password
  /// PUT /api/auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _api.put(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );

      final data = response.data;
      if (data['success'] != true) {
        throw ApiException(data['message'] ?? 'Gagal ubah password');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _storage.isLoggedIn();
  }
}

/// Response model for auth operations
class AuthResponse {
  final UserModel user;
  final String token;
  final String tokenType;

  AuthResponse({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'],
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }
}

/// User model
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? nik;
  final String? noHp;
  final String? alamat;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? foto;
  final String status;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nik,
    this.noHp,
    this.alamat,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.foto,
    required this.status,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'other',
      nik: json['nik'],
      noHp: json['no_hp'],
      alamat: json['alamat'],
      tempatLahir: json['tempat_lahir'],
      tanggalLahir: json['tanggal_lahir'],
      jenisKelamin: json['jenis_kelamin'],
      foto: json['foto'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
