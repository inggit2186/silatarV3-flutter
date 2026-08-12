import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/kegiatan_model.dart';
import '../services/api_config.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

/// Kegiatan Service - Handles all API calls for laporan kegiatan
class KegiatanService {
  static KegiatanService? _instance;
  static KegiatanService get instance => _instance ??= KegiatanService._();
  KegiatanService._();

  /// Get kegiatan bulanan
  Future<ApiResponse<Map<String, dynamic>>> getKegiatanBulanan({
    required String month,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatan}')
          .replace(queryParameters: {'month': month});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(data['data']);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal memuat data');
        }
      } else {
        return ApiResponse.error(
          'Gagal memuat data',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Simpan kegiatan harian baru
  Future<ApiResponse<Map<String, dynamic>>> storeKegiatan({
    required String tanggal,
    required List<KegiatanItem> items,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final body = {
        'tanggal': tanggal,
        'items': items.map((item) => item.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatanHarian}'),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(data['data']);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal menyimpan kegiatan');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Gagal menyimpan kegiatan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Update kegiatan berdasarkan tanggal
  Future<ApiResponse<Map<String, dynamic>>> updateKegiatanByDate({
    required String tanggal,
    required List<KegiatanItem> items,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final body = {
        'tanggal': tanggal,
        'items': items.map((item) => item.toJson()).toList(),
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatanDay}'),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(data['data']);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal update kegiatan');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Gagal update kegiatan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Hapus kegiatan berdasarkan tanggal
  Future<ApiResponse<void>> deleteKegiatanByDate({
    required String tanggal,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatanDay}'),
        headers: ApiConfig.authHeaders(token),
        body: json.encode({'tanggal': tanggal}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(null);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal hapus kegiatan');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Gagal hapus kegiatan',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Update item kegiatan tertentu
  Future<ApiResponse<Map<String, dynamic>>> updateKegiatanItem({
    required int activityId,
    required KegiatanItem item,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatan}/$activityId'),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(item.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(data['data']);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal update item');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Gagal update item',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Hapus item kegiatan tertentu
  Future<ApiResponse<void>> deleteKegiatanItem({
    required int activityId,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatan}/$activityId'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(null);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal hapus item');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Gagal hapus item',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Get rekap bulanan
  Future<ApiResponse<KegiatanRekap>> getRekapBulanan({
    required String month,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatanRekap}')
          .replace(queryParameters: {'month': month});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final rekap = KegiatanRekap.fromJson(data['data']);
          return ApiResponse.success(rekap);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal memuat rekap');
        }
      } else {
        return ApiResponse.error(
          'Gagal memuat rekap',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Get laporan CKH bulanan
  Future<ApiResponse<Map<String, dynamic>>> getBulanan({
    required String year,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatan}/bulanan')
          .replace(queryParameters: {'year': year});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(data['data']);
        } else {
          return ApiResponse.error(data['message'] ?? 'Gagal memuat data');
        }
      } else {
        return ApiResponse.error(
          'Gagal memuat data',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Download PDF Laporan Kegiatan
  Future<ApiResponse<Uint8List>> downloadPdf({
    required String month,
    String? signatureName,
    String? signatureNip,
  }) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) {
        return ApiResponse.error('Token tidak valid');
      }

      final params = {'month': month};
      if (signatureName != null && signatureName.isNotEmpty) {
        params['signature_name'] = signatureName;
      }
      if (signatureNip != null && signatureNip.isNotEmpty) {
        params['signature_nip'] = signatureNip;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kegiatan}/pdf')
          .replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        // Check if response is PDF
        if (response.headers['content-type']?.contains('application/pdf') == true) {
          return ApiResponse.success(response.bodyBytes);
        } else {
          // Response is JSON (error)
          final data = json.decode(response.body);
          return ApiResponse.error(data['message'] ?? 'Gagal download PDF');
        }
      } else {
        try {
          final data = json.decode(response.body);
          return ApiResponse.error(data['message'] ?? 'Gagal download PDF');
        } catch (_) {
          return ApiResponse.error(
            'Gagal download PDF',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }
}
