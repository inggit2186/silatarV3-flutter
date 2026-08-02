import 'api_client.dart';
import 'auth_service.dart';

class PengajuanService {
  final ApiClient _api = ApiClient();

  /// Get user's pengajuan list
  /// GET /api/pengajuan
  Future<PengajuanPaginatedResponse> getPengajuanList({
    int page = 1,
    int perPage = 10,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
      };

      final response = await _api.get(
        '/pengajuan',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((json) => PengajuanListItem.fromJson(json))
            .toList();

        return PengajuanPaginatedResponse(
          items: items,
          currentPage: data['meta']['current_page'],
          lastPage: data['meta']['last_page'],
          perPage: data['meta']['per_page'],
          total: data['meta']['total'],
        );
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil data pengajuan');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Create new pengajuan
  /// POST /api/pengajuan
  Future<CreatePengajuanResponse> createPengajuan({
    required int layananId,
    required int unitId,
    List<JawabanModel>? jawaban,
    String? catatan,
    bool isDraft = false,
  }) async {
    try {
      final response = await _api.post(
        '/pengajuan',
        data: {
          'layanan_id': layananId,
          'unit_id': unitId,
          'catatan': catatan,
          'is_draft': isDraft,
          if (jawaban != null)
            'jawaban': jawaban.map((j) => j.toJson()).toList(),
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        return CreatePengajuanResponse.fromJson(data['data']);
      } else {
        throw ApiException(
          data['message'] ?? 'Gagal membuat pengajuan',
          errors: data['errors'],
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Get pengajuan detail
  /// GET /api/pengajuan/{id}
  Future<PengajuanDetailModel> getPengajuanDetail(int id) async {
    try {
      final response = await _api.get('/pengajuan/$id');

      final data = response.data;
      if (data['success'] == true) {
        return PengajuanDetailModel.fromJson(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil detail pengajuan');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Update pengajuan
  /// PUT /api/pengajuan/{id}
  Future<void> updatePengajuan({
    required int id,
    List<JawabanModel>? jawaban,
    String? catatan,
    bool submit = false,
  }) async {
    try {
      final response = await _api.put(
        '/pengajuan/$id',
        data: {
          if (catatan != null) 'catatan': catatan,
          if (jawaban != null)
            'jawaban': jawaban.map((j) => j.toJson()).toList(),
          'submit': submit,
        },
      );

      final data = response.data;
      if (data['success'] != true) {
        throw ApiException(data['message'] ?? 'Gagal update pengajuan');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Delete pengajuan (DRAFT only)
  /// DELETE /api/pengajuan/{id}
  Future<void> deletePengajuan(int id) async {
    try {
      final response = await _api.delete('/pengajuan/$id');

      final data = response.data;
      if (data['success'] != true) {
        throw ApiException(data['message'] ?? 'Gagal hapus pengajuan');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Upload file for pengajuan
  /// POST /api/pengajuan/{id}/upload
  Future<UploadResponse> uploadFile({
    required int pengajuanId,
    required String filePath,
    String? syaratId,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final response = await _api.uploadFile(
        '/pengajuan/$pengajuanId/upload',
        filePath,
        fileName,
        data: {
          if (syaratId != null) 'syarat_id': syaratId,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        return UploadResponse.fromJson(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Gagal upload file');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }

  /// Get pengajuan tracking
  /// GET /api/pengajuan/{id}/tracking
  Future<TrackingResponse> getTracking(int id) async {
    try {
      final response = await _api.get('/pengajuan/$id/tracking');

      final data = response.data;
      if (data['success'] == true) {
        return TrackingResponse.fromJson(data['data']);
      } else {
        throw ApiException(data['message'] ?? 'Gagal mengambil tracking');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal koneksi: ${e.toString()}');
    }
  }
}

/// Jawaban model for form submission
class JawabanModel {
  final int syaratId;
  final String jawaban;

  JawabanModel({
    required this.syaratId,
    required this.jawaban,
  });

  Map<String, dynamic> toJson() => {
        'syarat_id': syaratId,
        'jawaban': jawaban,
      };
}

/// Pengajuan list item model
class PengajuanListItem {
  final int id;
  final String noPengajuan;
  final String tanggalPengajuan;
  final String status;
  final StatusDisplay statusDisplay;
  final String? layananNama;
  final String? layananIkon;
  final String? unitNama;
  final String? catatan;

  PengajuanListItem({
    required this.id,
    required this.noPengajuan,
    required this.tanggalPengajuan,
    required this.status,
    required this.statusDisplay,
    this.layananNama,
    this.layananIkon,
    this.unitNama,
    this.catatan,
  });

  factory PengajuanListItem.fromJson(Map<String, dynamic> json) {
    return PengajuanListItem(
      id: json['id'],
      noPengajuan: json['no_pengajuan'],
      tanggalPengajuan: json['tanggal_pengajuan'],
      status: json['status'],
      statusDisplay: StatusDisplay.fromJson(json['status_display']),
      layananNama: json['layanan_nama'],
      layananIkon: json['layanan_ikon'],
      unitNama: json['unit_nama'],
      catatan: json['catatan'],
    );
  }
}

/// Status display model
class StatusDisplay {
  final String label;
  final String color;
  final String icon;

  StatusDisplay({
    required this.label,
    required this.color,
    required this.icon,
  });

  factory StatusDisplay.fromJson(Map<String, dynamic> json) {
    return StatusDisplay(
      label: json['label'] ?? 'Unknown',
      color: json['color'] ?? 'gray',
      icon: json['icon'] ?? 'default',
    );
  }
}

/// Pengajuan paginated response
class PengajuanPaginatedResponse {
  final List<PengajuanListItem> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PengajuanPaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMorePages => currentPage < lastPage;
}

/// Create pengajuan response
class CreatePengajuanResponse {
  final int id;
  final String noPengajuan;
  final String status;

  CreatePengajuanResponse({
    required this.id,
    required this.noPengajuan,
    required this.status,
  });

  factory CreatePengajuanResponse.fromJson(Map<String, dynamic> json) {
    return CreatePengajuanResponse(
      id: json['id'],
      noPengajuan: json['no_pengajuan'],
      status: json['status'],
    );
  }
}

/// Berkas model (uploaded file)
class BerkasModel {
  final int id;
  final String nama;
  final String path;
  final String tipe;

  BerkasModel({
    required this.id,
    required this.nama,
    required this.path,
    required this.tipe,
  });

  factory BerkasModel.fromJson(Map<String, dynamic> json) {
    return BerkasModel(
      id: json['id'],
      nama: json['nama'],
      path: json['path'],
      tipe: json['tipe'],
    );
  }
}

/// Pengajuan detail model
class PengajuanDetailModel {
  final int id;
  final String noPengajuan;
  final String tanggal;
  final String status;
  final StatusDisplay statusDisplay;
  final String? catatan;
  final int? layananId;
  final String? layananNama;
  final String? layananEstimasi;
  final String? layananIkon;
  final String? unitNama;
  final List<JawabanDetailModel> jawaban;
  final List<BerkasModel> berkas;
  final DateTime? updatedAt;

  PengajuanDetailModel({
    required this.id,
    required this.noPengajuan,
    required this.tanggal,
    required this.status,
    required this.statusDisplay,
    this.catatan,
    this.layananId,
    this.layananNama,
    this.layananEstimasi,
    this.layananIkon,
    this.unitNama,
    required this.jawaban,
    required this.berkas,
    this.updatedAt,
  });

  factory PengajuanDetailModel.fromJson(Map<String, dynamic> json) {
    return PengajuanDetailModel(
      id: json['id'],
      noPengajuan: json['no_pengajuan'],
      tanggal: json['tanggal'],
      status: json['status'],
      statusDisplay: StatusDisplay.fromJson(json['status_display']),
      catatan: json['catatan'],
      layananId: json['layanan_id'],
      layananNama: json['layanan_nama'],
      layananEstimasi: json['layanan_estimasi'],
      layananIkon: json['layanan_ikon'],
      unitNama: json['unit_nama'],
      jawaban: (json['jawaban'] as List?)
              ?.map((j) => JawabanDetailModel.fromJson(j))
              .toList() ??
          [],
      berkas: (json['berkas'] as List?)
              ?.map((b) => BerkasModel.fromJson(b))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}

/// Jawaban detail model
class JawabanDetailModel {
  final int id;
  final String nama;
  final String? tipe;
  final bool isRequired;
  final String jawaban;

  JawabanDetailModel({
    required this.id,
    required this.nama,
    this.tipe,
    required this.isRequired,
    required this.jawaban,
  });

  factory JawabanDetailModel.fromJson(Map<String, dynamic> json) {
    return JawabanDetailModel(
      id: json['id'],
      nama: json['nama'],
      tipe: json['tipe'],
      isRequired: json['is_required'] == 1 || json['is_required'] == true,
      jawaban: json['jawaban'],
    );
  }
}

/// Tracking response model
class TrackingResponse {
  final int pengajuanId;
  final String noPengajuan;
  final StatusDisplay currentStatus;
  final List<ActivityModel> activities;

  TrackingResponse({
    required this.pengajuanId,
    required this.noPengajuan,
    required this.currentStatus,
    required this.activities,
  });

  factory TrackingResponse.fromJson(Map<String, dynamic> json) {
    return TrackingResponse(
      pengajuanId: json['pengajuan_id'],
      noPengajuan: json['no_pengajuan'],
      currentStatus: StatusDisplay.fromJson(json['current_status']),
      activities: (json['activities'] as List?)
              ?.map((a) => ActivityModel.fromJson(a))
              .toList() ??
          [],
    );
  }
}

/// Activity model for tracking
class ActivityModel {
  final int id;
  final String deskripsi;
  final String waktu;
  final String? tipe;

  ActivityModel({
    required this.id,
    required this.deskripsi,
    required this.waktu,
    this.tipe,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      deskripsi: json['deskripsi'],
      waktu: json['waktu'],
      tipe: json['tipe'],
    );
  }
}

/// Upload response model
class UploadResponse {
  final int id;
  final String nama;
  final String path;

  UploadResponse({
    required this.id,
    required this.nama,
    required this.path,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      id: json['id'],
      nama: json['nama'],
      path: json['path'],
    );
  }
}
