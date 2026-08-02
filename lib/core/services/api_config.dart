/// API Configuration for SILATAR V2 Mobile App
class ApiConfig {
  // Base URL - sesuaikan dengan server production/development
  // Development: http://localhost/silatarV2/public/api
  // Production: https://domain.com/api
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Alternative - gunakan IP komputer jika emulator tidak bisa localhost
  // static const String baseUrl = 'http://192.168.1.x/silatarV2/public/api';

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // API Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String register = '/register';
  static const String user = '/user';
  static const String layanan = '/layanan';
  static const String pengajuan = '/pengajuan';
  static const String profile = '/profile';

  // Headers
  static Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
}
