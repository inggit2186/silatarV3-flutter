import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/layanan_model.dart';
import '../models/presensi_model.dart';
import 'storage_service.dart';

/// Base URL untuk API
///
/// Untuk USB debugging dengan adb reverse: gunakan http://127.0.0.1:8000/api
/// Jalankan: adb reverse tcp:8000 tcp:8000
///
/// Untuk WiFi (device dan komputer satu jaringan): gunakan http://IP_KOMPUTER:8000/api
/// Cek IP dengan: ipconfig (Windows)
const _baseUrl = 'http://127.0.0.1:8000/api';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode, Map<String, dynamic>? errors}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}

  /// API Service - Handles all HTTP requests to Laravel backend
class ApiService {
  static ApiService? _instance;
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  ApiService._();

  String? _token;
  String? _userId;

  /// Load token from storage
  Future<void> _loadTokenFromStorage() async {
    if (_token == null || _token!.isEmpty) {
      _token = await StorageService().getToken();
    }
  }

  /// Set authentication token
  void setToken(String token) {
    _token = token;
  }

  /// Get current token
  String? get token => _token;

  /// Set user ID
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Get user ID
  String? get userId => _userId;

  /// Check if user is logged in
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// Clear authentication data (logout)
  void clearAuth() {
    _token = null;
    _userId = null;
    // Clear storage on logout
    StorageService().fullLogout();
  }

  /// Get headers with auth token
  Map<String, String> get _headers {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Parse response body (handle both JSON string and Map)
  Map<String, dynamic> _parseBody(dynamic body) {
    if (body is String) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    return body as Map<String, dynamic>;
  }

  /// Check for validation errors in response
  Map<String, dynamic>? _extractErrors(Map<String, dynamic> body) {
    if (body.containsKey('errors') && body['errors'] is Map) {
      return body['errors'] as Map<String, dynamic>;
    }
    return null;
  }

  // ============ AUTHENTICATION ============

  /// Login with NIP/Email and password
  Future<ApiResponse<User>> login(String nipOrEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': nipOrEmail, // bisa email atau NIP (nomor_induk)
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract token and user data
        final token = body['token'] ?? body['access_token'] ?? body['data']?['token'];
        if (token != null) {
          setToken(token.toString());
          // Save token to storage
          StorageService().setToken(token.toString());
        }

        // Extract user data
        final userData = body['user'] ?? body['data']?['user'] ?? body['data'];
        if (userData != null) {
          setUserId(userData['id'].toString());
          return ApiResponse.success(
            User.fromJson(userData as Map<String, dynamic>),
            message: body['message'] ?? 'Login berhasil',
          );
        }

        // Return basic user if no user data
        return ApiResponse.error('Data user tidak ditemukan', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        return ApiResponse.error(
          body['message'] ?? 'Validasi gagal',
          statusCode: response.statusCode,
          errors: _extractErrors(body),
        );
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          body['message'] ?? 'NIP/Email atau password salah',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Terjadi kesalahan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } on http.ClientException catch (e) {
      return ApiResponse.error('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Logout
  Future<ApiResponse<bool>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      // Clear local auth regardless of server response
      clearAuth();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(true, message: 'Logout berhasil');
      } else {
        return ApiResponse.error(
          'Logout gagal',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      clearAuth();
      return ApiResponse.success(true, message: 'Logout berhasil (offline)');
    } catch (e) {
      clearAuth();
      return ApiResponse.success(true, message: 'Logout berhasil');
    }
  }

  /// Get current user profile
  Future<ApiResponse<User>> getProfile() async {
    try {
      // Load token from storage if not loaded
      await _loadTokenFromStorage();

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        // Response format: { data: { user: {...} } }
        final data = body['data'];
        final userData = data is Map && data.containsKey('user') ? data['user'] : data;
        return ApiResponse.success(User.fromJson(userData));
      } else if (response.statusCode == 401) {
        clearAuth();
        return ApiResponse.error('Sesi berakhir, silakan login ulang', statusCode: 401);
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengambil data profil',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============ LAYANAN (SERVICES) ============

  /// Get all services (layanan)
  Future<ApiResponse<List<Layanan>>> getLayananList({
    int page = 1,
    int perPage = 12,
    String? search,
    int? unitId,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (unitId != null) queryParams['unit_id'] = unitId.toString();
      if (isActive != null) queryParams['is_active'] = isActive ? '1' : '0';

      final uri = Uri.parse('$_baseUrl/layanan')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> dataList = body['data'] ?? body['layanan'] ?? [];
        final layananList = dataList
            .map((json) => Layanan.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(layananList);
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengambil daftar layanan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Get single service detail
  Future<ApiResponse<Layanan>> getLayananDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/layanan/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        final data = body['data'] ?? body['layanan'] ?? body;
        return ApiResponse.success(Layanan.fromJson(data));
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Layanan tidak ditemukan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Get requirements (syarat) for a service
  Future<ApiResponse<List<Syarat>>> getSyaratList(int layananId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/layanan/$layananId/syarat'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> dataList = body['data'] ?? body['syarat'] ?? [];
        final syaratList = dataList
            .map((json) => Syarat.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(syaratList);
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengambil persyaratan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============ PENGAJUAN (REQUESTS) ============

  /// Get user's submission history
  Future<ApiResponse<Map<String, dynamic>>> getMyPengajuan({
    int page = 1,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse('$_baseUrl/pengajuan')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(body);
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengambil daftar pengajuan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Submit new request
  Future<ApiResponse<Map<String, dynamic>>> submitPengajuan({
    required int layananId,
    required Map<String, dynamic> answers,
    List<File>? files,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/pengajuan'),
      );

      request.headers.addAll(_headers);
      request.fields['layanan_id'] = layananId.toString();

      // Add answers
      answers.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add files
      if (files != null) {
        for (var i = 0; i < files.length; i++) {
          request.files.add(
            await http.MultipartFile.fromPath('files[$i]', files[i].path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse)
          .timeout(const Duration(seconds: 60));

      final body = _parseBody(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          body['data'] ?? body,
          message: body['message'] ?? 'Pengajuan berhasil diajukan',
        );
      } else if (response.statusCode == 422) {
        return ApiResponse.error(
          body['message'] ?? 'Validasi gagal',
          statusCode: response.statusCode,
          errors: _extractErrors(body),
        );
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengajukan layanan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } on http.ClientException catch (e) {
      return ApiResponse.error('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Get submission detail
  Future<ApiResponse<Map<String, dynamic>>> getPengajuanDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pengajuan/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(body['data'] ?? body);
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Pengajuan tidak ditemukan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Cancel submission
  Future<ApiResponse<bool>> cancelPengajuan(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pengajuan/$id/cancel'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(true, message: body['message'] ?? 'Pengajuan berhasil dibatalkan');
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal membatalkan pengajuan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============ STATISTICS ============

  /// Get dashboard statistics
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/stats'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(body['data'] ?? body);
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengambil statistik',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  // ============ PRESENSI ============

  /// Simpan presensi (masuk/pulang)
  Future<ApiResponse<Presensi>> simpanPresensi({
    required String jenis,
    required double latitude,
    required double longitude,
    double? jarakMeter,
    String? keterangan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/presensi'),
        headers: _headers,
        body: jsonEncode({
          'jenis': jenis,
          'latitude': latitude,
          'longitude': longitude,
          'jarak_meter': jarakMeter,
          'keterangan': keterangan,
        }),
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = body['data'];
        final presensi = data is Map && data.containsKey('presensi')
            ? data['presensi']
            : data;
        return ApiResponse.success(
          Presensi.fromJson(presensi),
          message: body['message'],
        );
      } else if (response.statusCode == 400) {
        return ApiResponse.error(
          body['message'] ?? 'Presensi sudah dilakukan',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal menyimpan presensi',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Ambil presensi hari ini
  Future<ApiResponse<PresensiHariIni>> getPresensiHariIni() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/presensi/today'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        final data = body['data'];
        return ApiResponse.success(PresensiHariIni.fromJson(data));
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengambil data presensi',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }

  /// Ambil riwayat presensi
  Future<ApiResponse<PresensiHistory>> getPresensiHistory({int? bulan, int? tahun}) async {
    try {
      final queryParams = <String, String>{};
      if (bulan != null) queryParams['bulan'] = bulan.toString();
      if (tahun != null) queryParams['tahun'] = tahun.toString();

      final uri = Uri.parse('$_baseUrl/presensi/history')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      final body = _parseBody(response.body);

      if (response.statusCode == 200) {
        final data = body['data'];
        return ApiResponse.success(PresensiHistory.fromJson(data));
      } else {
        return ApiResponse.error(
          body['message'] ?? 'Gagal mengambil riwayat presensi',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('Tidak ada koneksi internet');
    } catch (e) {
      return ApiResponse.error('Terjadi kesalahan: $e');
    }
  }
}
