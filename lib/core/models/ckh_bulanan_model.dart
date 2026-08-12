/// Model untuk Laporan CKH Bulanan
class CkhBulanan {
  final int id;
  final int userId;
  final String userName;
  final String nomorInduk;
  final String deptName;
  final String bulan;
  final String bulanRaw;
  final String? filename;
  final String status;
  final String statusLabel;
  final String statusColor;
  final String? alasan;
  final String? sending;
  final String? pdfUrl;

  CkhBulanan({
    required this.id,
    required this.userId,
    required this.userName,
    required this.nomorInduk,
    required this.deptName,
    required this.bulan,
    required this.bulanRaw,
    this.filename,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    this.alasan,
    this.sending,
    this.pdfUrl,
  });

  factory CkhBulanan.fromJson(Map<String, dynamic> json) {
    return CkhBulanan(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      userName: _parseString(json['user_name'] ?? 'Unknown'),
      nomorInduk: _parseString(json['nomor_induk'] ?? '-'),
      deptName: _parseString(json['dept_name'] ?? '-'),
      bulan: _parseString(json['bulan'] ?? ''),
      bulanRaw: _parseString(json['bulan_raw'] ?? ''),
      filename: json['filename']?.toString(),
      status: _parseString(json['status'] ?? 'KOSONG'),
      statusLabel: _parseString(json['status_label'] ?? 'Belum Kirim'),
      statusColor: _parseString(json['status_color'] ?? 'slate'),
      alasan: json['alasan']?.toString(),
      sending: json['sending']?.toString(),
      pdfUrl: json['pdf_url']?.toString(),
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
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'nomor_induk': nomorInduk,
      'dept_name': deptName,
      'bulan': bulan,
      'bulan_raw': bulanRaw,
      'filename': filename,
      'status': status,
      'status_label': statusLabel,
      'status_color': statusColor,
      'alasan': alasan,
      'sending': sending,
      'pdf_url': pdfUrl,
    };
  }

  bool get hasPdf => filename != null && filename!.isNotEmpty;
  bool get canDownload => status == 'DISETUJUI' || status == 'DIKIRIM';
}

/// Model untuk statistik CKH Bulanan
class CkhBulananStats {
  final int total;
  final int disetujui;
  final int dikirim;
  final int ditolak;
  final int belumKirim;

  CkhBulananStats({
    this.total = 0,
    this.disetujui = 0,
    this.dikirim = 0,
    this.ditolak = 0,
    this.belumKirim = 0,
  });

  factory CkhBulananStats.fromJson(Map<String, dynamic> json) {
    return CkhBulananStats(
      total: _parseInt(json['total']),
      disetujui: _parseInt(json['disetujui']),
      dikirim: _parseInt(json['dikirim']),
      ditolak: _parseInt(json['ditolak']),
      belumKirim: _parseInt(json['belum_kirim']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
