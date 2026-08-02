import 'api_client.dart';
import 'auth_service.dart';

class LayananService {
  final ApiClient _api = ApiClient();

  /// Get all layanan (katalog)
  /// GET /api/layanan
  Future<PaginatedResponse<LayananModel>> getLayanan({
    int page = 1,
    int perPage = 12,
    String? search,
    String? kategori,
    int? unitId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (kategori != null) 'kategori': kategori,
        if (unitId != null) 'unit_id': unitId,
      };

      final response = await _api.get(
        '/layanan',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((json) => LayananModel.fromJson(json))
            .toList();

        return PaginatedResponse(
          items: items,
          currentPage: data['meta']['current_page'],
          lastPage: data['meta']['last_page'],
          perPage: data['meta']['per_page'],
          total: data['meta']['total'],
        );
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil data layanan');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Get single layanan detail
  /// GET /api/layanan/{id}
  Future<LayananDetailModel> getLayananDetail(int id) async {
    try {
      final response = await _api.get('/layanan/$id');

      final data = response.data;
      if (data['success'] == true) {
        return LayananDetailModel.fromJson(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil detail layanan');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Get syarat/layanan requirements
  /// GET /api/layanan/{id}/syarat
  Future<SyaratResponse> getSyarat(int layananId) async {
    try {
      final response = await _api.get('/layanan/$layananId/syarat');

      final data = response.data;
      if (data['success'] == true) {
        return SyaratResponse.fromJson(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil persyaratan');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Get all units (satuan kerja)
  /// GET /api/units
  Future<List<UnitModel>> getUnits() async {
    try {
      final response = await _api.get('/units');

      final data = response.data;
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => UnitModel.fromJson(json))
            .toList();
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil daftar unit');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }
}

/// Paginated response model
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMorePages => currentPage < lastPage;
}

/// Layanan model (list item)
class LayananModel {
  final int id;
  final String nama;
  final String? deskripsi;
  final String? kategori;
  final String? estimasi;
  final String? ikon;
  final bool isActive;

  LayananModel({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.kategori,
    this.estimasi,
    this.ikon,
    required this.isActive,
  });

  factory LayananModel.fromJson(Map<String, dynamic> json) {
    return LayananModel(
      id: json['id'],
      nama: json['nama'],
      deskripsi: json['deskripsi'],
      kategori: json['kategori'],
      estimasi: json['estimasi'],
      ikon: json['ikon'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

/// Layanan detail model
class LayananDetailModel {
  final int id;
  final String nama;
  final String? deskripsi;
  final String? kategori;
  final String? estimasi;
  final String? ikon;
  final double? biaya;
  final int? unitId;
  final UnitModel? unit;
  final bool isActive;

  LayananDetailModel({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.kategori,
    this.estimasi,
    this.ikon,
    this.biaya,
    this.unitId,
    this.unit,
    required this.isActive,
  });

  factory LayananDetailModel.fromJson(Map<String, dynamic> json) {
    return LayananDetailModel(
      id: json['id'],
      nama: json['nama'],
      deskripsi: json['deskripsi'],
      kategori: json['kategori'],
      estimasi: json['estimasi'],
      ikon: json['ikon'],
      biaya: json['biaya'] != null
          ? double.tryParse(json['biaya'].toString())
          : null,
      unitId: json['unit_id'],
      unit: json['unit'] != null ? UnitModel.fromJson(json['unit']) : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

/// Unit model
class UnitModel {
  final int id;
  final String nama;
  final String? kode;
  final String? alamat;
  final String? noTelp;
  final String? email;

  UnitModel({
    required this.id,
    required this.nama,
    this.kode,
    this.alamat,
    this.noTelp,
    this.email,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'],
      nama: json['nama'],
      kode: json['kode'],
      alamat: json['alamat'],
      noTelp: json['no_telp'],
      email: json['email'],
    );
  }
}

/// Syarat model
class SyaratModel {
  final int id;
  final String nama;
  final String? tipe;
  final String? deskripsi;
  final bool isRequired;

  SyaratModel({
    required this.id,
    required this.nama,
    this.tipe,
    this.deskripsi,
    required this.isRequired,
  });

  factory SyaratModel.fromJson(Map<String, dynamic> json) {
    return SyaratModel(
      id: json['id'],
      nama: json['nama'],
      tipe: json['tipe'],
      deskripsi: json['deskripsi'],
      isRequired: json['is_required'] == 1 || json['is_required'] == true,
    );
  }
}

/// Syarat response model
class SyaratResponse {
  final int layananId;
  final String layananNama;
  final List<SyaratModel> syarat;

  SyaratResponse({
    required this.layananId,
    required this.layananNama,
    required this.syarat,
  });

  factory SyaratResponse.fromJson(Map<String, dynamic> json) {
    return SyaratResponse(
      layananId: json['layanan_id'],
      layananNama: json['layanan_nama'],
      syarat: (json['syarat'] as List)
          .map((s) => SyaratModel.fromJson(s))
          .toList(),
    );
  }
}
