/// JanjiTemu Model - sesuai dengan API response
class JanjiTemu {
  final int id;
  final String? nomorInduk;
  final String? namaPengaju;
  final String? asal;
  final String? waktu;
  final String? waktuRaw;
  final String? tujuan;
  final String? tipe;
  final String? status;
  final String? statusLabel;
  final String? statusColor;
  final String? komen;
  final String? staffPenangan;
  final bool? canCancel;
  final bool? canProcess;
  final DateTime? createdAt;

  // Detail fields
  final String? targetNama;
  final Map<String, dynamic>? targetDetail;

  JanjiTemu({
    required this.id,
    this.nomorInduk,
    this.namaPengaju,
    this.asal,
    this.waktu,
    this.waktuRaw,
    this.tujuan,
    this.tipe,
    this.status,
    this.statusLabel,
    this.statusColor,
    this.komen,
    this.staffPenangan,
    this.canCancel,
    this.canProcess,
    this.createdAt,
    this.targetNama,
    this.targetDetail,
  });

  factory JanjiTemu.fromJson(Map<String, dynamic> json) {
    // Parse targetDetail safely - could be Map or String (JSON)
    Map<String, dynamic>? parsedTargetDetail;
    final dynamic targetDetailRaw = json['target_detail'] ?? json['target'];

    // Safe type checking for targetDetail
    if (targetDetailRaw != null && targetDetailRaw is! String) {
      try {
        parsedTargetDetail = targetDetailRaw as Map<String, dynamic>;
      } catch (e) {
        parsedTargetDetail = null;
      }
    }

    // Parse boolean fields safely (API might return int 0/1 instead of bool)
    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return null;
    }

    // Parse string fields safely (API might return int or other types)
    String? parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      if (value is bool) return value.toString();
      return null;
    }

    return JanjiTemu(
      id: json['id'] ?? 0,
      nomorInduk: parseString(json['nomor_induk'] ?? json['nomor_induk_pengaju']),
      namaPengaju: parseString(json['nama_pengaju'] ?? json['nama']),
      asal: parseString(json['asal']),
      waktu: parseString(json['waktu']),
      waktuRaw: parseString(json['waktu_raw']),
      tujuan: parseString(json['tujuan']),
      tipe: parseString(json['tipe']),
      status: parseString(json['status']),
      statusLabel: parseString(json['status_label']),
      statusColor: parseString(json['status_color']),
      komen: parseString(json['komen']),
      staffPenangan: parseString(json['staff_penangan'] ?? json['staff_nama']),
      canCancel: parseBool(json['can_cancel'] ?? json['can_process']),
      canProcess: parseBool(json['can_process']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      targetNama: parseString(json['target_nama']),
      targetDetail: parsedTargetDetail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomor_induk': nomorInduk,
      'nama_pengaju': namaPengaju,
      'asal': asal,
      'waktu': waktu,
      'tujuan': tujuan,
      'tipe': tipe,
      'status': status,
      'status_label': statusLabel,
      'status_color': statusColor,
      'komen': komen,
      'staff_penangan': staffPenangan,
      'target_nama': targetNama,
      'target_detail': targetDetail,
    };
  }

  /// Get status color for UI
  String get statusColorHex {
    return switch (status) {
      'APPOINTMENT' => '#FCD34D', // yellow
      'PENDING' => '#60A5FA', // blue
      'APPROVED' => '#34D399', // emerald
      'REJECTED' => '#F87171', // red
      'CANCELLED' => '#9CA3AF', // gray
      _ => '#9CA3AF', // gray
    };
  }

  /// Check if can be cancelled
  bool get isCancellable {
    return status == 'APPOINTMENT' || status == 'PENDING';
  }

  /// Get formatted waktu
  String get waktuFormatted {
    if (waktu != null) {
      return waktu!;
    }
    if (waktuRaw != null) {
      return waktuRaw!;
    }
    return '-';
  }
}

/// JanjiTemu History Response
class JanjiTemuHistory {
  final List<JanjiTemu> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  JanjiTemuHistory({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory JanjiTemuHistory.fromJson(Map<String, dynamic> json) {
    // Helper function for safe int parsing
    int parseIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    final List<dynamic> dataList = json['data'] ?? [];
    final List<JanjiTemu> appointments = [];

    for (var item in dataList) {
      if (item is Map<String, dynamic>) {
        try {
          appointments.add(JanjiTemu.fromJson(item));
        } catch (e) {
          // Skip invalid items
        }
      }
    }

    return JanjiTemuHistory(
      data: appointments,
      currentPage: parseIntValue(json['current_page'], 1),
      lastPage: parseIntValue(json['last_page'], 1),
      perPage: parseIntValue(json['per_page'], 10),
      total: parseIntValue(json['total'], 0),
    );
  }
}

/// Department Model for Janji Temu
class JanjiTemuDepartment {
  final int id;
  final String nama;

  JanjiTemuDepartment({
    required this.id,
    required this.nama,
  });

  factory JanjiTemuDepartment.fromJson(Map<String, dynamic> json) {
    return JanjiTemuDepartment(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
    );
  }
}

/// Employee Model for Janji Temu
class Employee {
  final int id;
  final String name;
  final String? nomorInduk;
  final String? jabatan;
  final bool isHead;

  Employee({
    required this.id,
    required this.name,
    this.nomorInduk,
    this.jabatan,
    this.isHead = false,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert to String
    String? safeToString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    // Helper to safely convert to bool
    bool safeToBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return Employee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nomorInduk: safeToString(json['nomor_induk']),
      jabatan: safeToString(json['jabatan']),
      isHead: safeToBool(json['is_head']),
    );
  }
}
