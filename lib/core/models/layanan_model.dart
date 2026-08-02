/// Layanan Model - Service/Service category
class Layanan {
  final int id;
  final String nama;
  final String? deskripsi;
  final String? slug;
  final String? icon;
  final String? image;
  final int? unitId;
  final String? unitNama;
  final bool isActive;
  final int jumlahSyarat;
  final DateTime? createdAt;

  Layanan({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.slug,
    this.icon,
    this.image,
    this.unitId,
    this.unitNama,
    this.isActive = true,
    this.jumlahSyarat = 0,
    this.createdAt,
  });

  factory Layanan.fromJson(Map<String, dynamic> json) {
    return Layanan(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? json['name'] ?? '',
      deskripsi: json['deskripsi'] ?? json['description'],
      slug: json['slug'],
      icon: json['icon'],
      image: json['image'] ?? json['gambar'],
      unitId: json['unit_id'],
      unitNama: json['unit_nama'] ?? json['unit_kerja'],
      isActive: json['is_active'] ?? json['status'] == 'active' ?? true,
      jumlahSyarat: json['jumlah_syarat'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'slug': slug,
      'icon': icon,
      'image': image,
      'unit_id': unitId,
      'unit_nama': unitNama,
      'is_active': isActive,
      'jumlah_syarat': jumlahSyarat,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// Syarat (Requirements) for a service
class Syarat {
  final int id;
  final int layananId;
  final String nama;
  final String? deskripsi;
  final String type; // text, file, date, select
  final bool isRequired;
  final String? options; // untuk type select
  final int? order;

  Syarat({
    required this.id,
    required this.layananId,
    required this.nama,
    this.deskripsi,
    required this.type,
    this.isRequired = true,
    this.options,
    this.order,
  });

  factory Syarat.fromJson(Map<String, dynamic> json) {
    return Syarat(
      id: json['id'] ?? 0,
      layananId: json['layanan_id'] ?? 0,
      nama: json['nama'] ?? json['name'] ?? '',
      deskripsi: json['deskripsi'] ?? json['description'],
      type: json['type'] ?? 'text',
      isRequired: json['is_required'] ?? json['required'] ?? true,
      options: json['options'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'layanan_id': layananId,
      'nama': nama,
      'deskripsi': deskripsi,
      'type': type,
      'is_required': isRequired,
      'options': options,
      'order': order,
    };
  }
}
