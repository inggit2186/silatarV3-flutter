/// Model untuk item kegiatan (satu baris kegiatan)
class KegiatanItem {
  final int? id;
  final String kegiatan;
  final int volume;
  final String satuan;
  final String? jamMulai;
  final int? durasiMenit;

  KegiatanItem({
    this.id,
    required this.kegiatan,
    this.volume = 0,
    this.satuan = 'Kegiatan',
    this.jamMulai,
    this.durasiMenit,
  });

  /// Create from JSON (from Laravel API)
  factory KegiatanItem.fromJson(Map<String, dynamic> json) {
    return KegiatanItem(
      id: _parseNullableInt(json['id']),
      kegiatan: _parseString(json['k'] ?? json['kegiatan'] ?? ''),
      volume: _parseInt(json['v'] ?? json['volume'] ?? 0),
      satuan: _parseString(json['s'] ?? json['satuan'] ?? 'Kegiatan'),
      jamMulai: _parseNullableString(json['jam_mulai'] ?? json['jm']),
      durasiMenit: _parseNullableInt(json['durasi_menit'] ?? json['dm']),
    );
  }

  /// Convert to JSON (for Laravel API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'k': kegiatan,
      'v': volume,
      's': satuan,
      'jm': jamMulai,
      'dm': durasiMenit,
    };
  }

  /// Create copy with updated fields.
  ///
  /// Gunakan [clearJamMulai] / [clearDurasiMenit] untuk mengosongkan nilai
  /// (karena `null` pada parameter biasa berarti "pertahankan nilai lama").
  KegiatanItem copyWith({
    int? id,
    String? kegiatan,
    int? volume,
    String? satuan,
    String? jamMulai,
    int? durasiMenit,
    bool clearJamMulai = false,
    bool clearDurasiMenit = false,
  }) {
    return KegiatanItem(
      id: id ?? this.id,
      kegiatan: kegiatan ?? this.kegiatan,
      volume: volume ?? this.volume,
      satuan: satuan ?? this.satuan,
      jamMulai: clearJamMulai ? null : (jamMulai ?? this.jamMulai),
      durasiMenit: clearDurasiMenit ? null : (durasiMenit ?? this.durasiMenit),
    );
  }

  /// Urutan kronologis berdasarkan jam mulai (menit sejak tengah malam).
  /// Item tanpa jam mulai diletakkan di akhir (nilai lebih besar).
  int get urutanMenit => menitDariJam(jamMulai) ?? (24 * 60 + 1);

  /// Ubah jam `HH:MM` menjadi menit sejak tengah malam. Null bila kosong/invalid.
  static int? menitDariJam(String? value) {
    final jam = normalisasiJam(value);
    if (jam.isEmpty) {
      return null;
    }

    final parts = jam.split(':');
    if (parts.length < 2) {
      return null;
    }

    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h > 23 || m > 59) {
      return null;
    }

    return h * 60 + m;
  }

  /// Format durasi menit menjadi label ringkas.
  /// Contoh: 90 → "1 jam 30 menit", 60 → "1 jam", 45 → "45 menit", 0 → null.
  static String? formatDurasi(int? durasiMenit) {
    if (durasiMenit == null || durasiMenit <= 0) {
      return null;
    }

    final jam = durasiMenit ~/ 60;
    final menit = durasiMenit % 60;

    if (jam == 0) {
      return '$menit menit';
    }
    if (menit == 0) {
      return '$jam jam';
    }
    return '$jam jam $menit menit';
  }

  /// Label waktu pelaksanaan, mencerminkan App\Support\WaktuPelaksanaan::label()
  /// Contoh: "08:00-09:30 WIB (90 menit)", "08:00 WIB", "90 menit", atau null.
  String? get waktuLabel => formatWaktuLabel(jamMulai, durasiMenit);

  /// Format label waktu pelaksanaan.
  static String? formatWaktuLabel(String? jamMulai, int? durasiMenit) {
    final jam = normalisasiJam(jamMulai);
    final durasi = (durasiMenit != null && durasiMenit > 0)
        ? durasiMenit
        : null;

    if (jam.isEmpty && durasi == null) {
      return null;
    }

    if (durasi == null) {
      return '$jam WIB';
    }

    final selesai = hitungSelesai(jam, durasi);
    if (selesai == null) {
      return '$durasi menit';
    }

    return '$jam-$selesai WIB ($durasi menit)';
  }

  /// Normalisasi jam menjadi format 24 jam (HH:MM).
  static String normalisasiJam(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final match24 = RegExp(
      r'^(\d{1,2})[:.](\d{2})(?::\d{2})?$',
    ).firstMatch(trimmed);
    if (match24 != null) {
      final jam = int.tryParse(match24.group(1)!);
      final menit = int.tryParse(match24.group(2)!);
      if (jam != null && menit != null && jam <= 23 && menit <= 59) {
        return '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}';
      }
      return trimmed;
    }

    final match12 = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp])[Mm]?$',
    ).firstMatch(trimmed);
    if (match12 != null) {
      var jam = int.tryParse(match12.group(1)!);
      final menit = int.tryParse(match12.group(2)!);
      final isPm = match12.group(3)!.toLowerCase() == 'p';
      if (jam != null && menit != null) {
        if (isPm && jam < 12) jam += 12;
        if (!isPm && jam == 12) jam = 0;
        if (jam <= 23 && menit <= 59) {
          return '${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}';
        }
      }
    }

    return trimmed;
  }

  /// Hitung jam selesai dari jam mulai + durasi (menit).
  static String? hitungSelesai(String jamMulai, int durasiMenit) {
    final parts = jamMulai.split(':');
    if (parts.length < 2) {
      return null;
    }

    final jam = int.tryParse(parts[0]);
    final menit = int.tryParse(parts[1]);
    if (jam == null || menit == null || jam > 23 || menit > 59) {
      return null;
    }

    final selesai = DateTime(
      2000,
      1,
      1,
      jam,
      menit,
    ).add(Duration(minutes: durasiMenit));
    return '${selesai.hour.toString().padLeft(2, '0')}:${selesai.minute.toString().padLeft(2, '0')}';
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null || value == '') return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
    final items =
        (json['items'] as List?)
            ?.map((item) => KegiatanItem.fromJson(item))
            .toList() ??
        [];

    // Urutkan kronologis: kegiatan ber-jam lebih dulu,
    // yang tanpa jam mulai diletakkan di akhir.
    items.sort((a, b) => a.urutanMenit.compareTo(b.urutanMenit));

    return KegiatanHarian(
      date: _parseString(json['date']),
      label: _parseString(json['label']),
      items: items,
      entries: _parseInt(json['entries']),
      volume: _parseInt(json['volume']),
    );
  }

  /// Total durasi seluruh kegiatan hari ini (menit).
  int get totalDurasiMenit => items.fold(
    0,
    (sum, item) =>
        sum +
        ((item.durasiMenit != null && item.durasiMenit! > 0)
            ? item.durasiMenit!
            : 0),
  );

  /// Label total durasi hari ini. Contoh: "2 jam 30 menit", null bila kosong.
  String? get totalDurasiLabel =>
      totalDurasiMenit > 0 ? KegiatanItem.formatDurasi(totalDurasiMenit) : null;

  /// Kegiatan yang punya jam mulai (untuk ringkasan rentang waktu).
  Iterable<KegiatanItem> get itemBerWaktu =>
      items.where((item) => item.urutanMenit <= 24 * 60);

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
  final int totalDurasiMenit;
  final DateTime? latestUpdate;

  KegiatanRekap({
    this.totalEntries = 0,
    this.totalDays = 0,
    this.totalVolume = 0,
    this.totalDurasiMenit = 0,
    this.latestUpdate,
  });

  /// Label total durasi bulan ini. Contoh: "12 jam 30 menit", null bila kosong.
  String? get totalDurasiLabel => KegiatanItem.formatDurasi(totalDurasiMenit);

  /// Create from JSON (from Laravel API)
  factory KegiatanRekap.fromJson(Map<String, dynamic> json) {
    return KegiatanRekap(
      totalEntries: _parseInt(json['entries']),
      totalDays: _parseInt(json['days']),
      totalVolume: _parseInt(json['volume']),
      totalDurasiMenit: _parseInt(json['total_durasi_menit']),
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
      'total_durasi_menit': totalDurasiMenit,
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
