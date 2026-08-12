/// Model untuk item kegiatan (satu baris kegiatan)
class KegiatanItem {
  final int? id;
  final String kegiatan;
  final int volume;
  final String satuan;

  KegiatanItem({
    this.id,
    required this.kegiatan,
    this.volume = 0,
    this.satuan = 'Kegiatan',
  });

  /// Create from JSON (from Laravel API)
  factory KegiatanItem.fromJson(Map<String, dynamic> json) {
    return KegiatanItem(
      id: _parseInt(json['id']),
      kegiatan: _parseString(json['k'] ?? json['kegiatan'] ?? ''),
      volume: _parseInt(json['v'] ?? json['volume'] ?? 0),
      satuan: _parseString(json['s'] ?? json['satuan'] ?? 'Kegiatan'),
    );
  }

  /// Convert to JSON (for Laravel API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'k': kegiatan,
      'v': volume,
      's': satuan,
    };
  }

  /// Create copy with updated fields
  KegiatanItem copyWith({
    int? id,
    String? kegiatan,
    int? volume,
    String? satuan,
  }) {
    return KegiatanItem(
      id: id ?? this.id,
      kegiatan: kegiatan ?? this.kegiatan,
      volume: volume ?? this.volume,
      satuan: satuan ?? this.satuan,
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
}

/// Model untuk kegiatan harian (satu hari bisa banyak kegiatan)
class KegiatanHarian {
  final String date;
  final String label;
  final List<KegiatanItem> items;
  final int entries;
  final int volume;

  KegiatanHarian({
    required this.date,
    required this.label,
    required this.items,
    this.entries = 0,
    this.volume = 0,
  });

  /// Create from JSON (from Laravel API)
  factory KegiatanHarian.fromJson(Map<String, dynamic> json) {
    return KegiatanHarian(
      date: _parseString(json['date']),
      label: _parseString(json['label']),
      items: (json['items'] as List?)
              ?.map((item) => KegiatanItem.fromJson(item))
              .toList() ??
          [],
      entries: _parseInt(json['entries']),
      volume: _parseInt(json['volume']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'label': label,
      'items': items.map((item) => item.toJson()).toList(),
      'entries': entries,
      'volume': volume,
    };
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
}

/// Model untuk rekap kegiatan bulanan
class KegiatanRekap {
  final int totalEntries;
  final int totalDays;
  final int totalVolume;
  final DateTime? latestUpdate;

  KegiatanRekap({
    this.totalEntries = 0,
    this.totalDays = 0,
    this.totalVolume = 0,
    this.latestUpdate,
  });

  /// Create from JSON (from Laravel API)
  factory KegiatanRekap.fromJson(Map<String, dynamic> json) {
    return KegiatanRekap(
      totalEntries: _parseInt(json['entries']),
      totalDays: _parseInt(json['days']),
      totalVolume: _parseInt(json['volume']),
      latestUpdate: json['latest_update'] != null
          ? DateTime.tryParse(json['latest_update'].toString())
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'entries': totalEntries,
      'days': totalDays,
      'volume': totalVolume,
      'latest_update': latestUpdate?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
