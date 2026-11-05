/// News Model - Berita/News item
class NewsModel {
  final int id;
  final String title;
  final String slug;
  final String? category;
  final String? excerpt;
  final String? content;
  final String? image;
  final String? imageUrl;
  final DateTime? publishDate;
  final bool isFeatured;
  final bool isSlideshow;

  NewsModel({
    required this.id,
    required this.title,
    required this.slug,
    this.category,
    this.excerpt,
    this.content,
    this.image,
    this.imageUrl,
    this.publishDate,
    this.isFeatured = false,
    this.isSlideshow = false,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      category: json['category']?.toString(),
      excerpt: json['excerpt']?.toString(),
      content: json['content']?.toString(),
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      publishDate: json['publish_date'] != null
          ? DateTime.tryParse(json['publish_date'].toString())
          : null,
      isFeatured: json['is_featured'] == true,
      isSlideshow: json['is_slideshow'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'category': category,
      'excerpt': excerpt,
      'content': content,
      'image': image,
      'image_url': imageUrl,
      'publish_date': publishDate?.toIso8601String(),
      'is_featured': isFeatured,
      'is_slideshow': isSlideshow,
    };
  }

  /// Apakah berita memiliki cover image
  bool get hasCover => (imageUrl ?? '').isNotEmpty;
}

/// Hasil paginasi daftar berita
class NewsPage {
  final List<NewsModel> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  NewsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory NewsPage.empty() => NewsPage(
    items: const [],
    currentPage: 1,
    lastPage: 1,
    perPage: 12,
    total: 0,
  );

  /// Masih ada halaman berikutnya
  bool get hasMore => currentPage < lastPage;

  /// Gabungkan dengan halaman berikutnya
  NewsPage append(NewsPage next) {
    return NewsPage(
      items: [...items, ...next.items],
      currentPage: next.currentPage,
      lastPage: next.lastPage,
      perPage: next.perPage,
      total: next.total,
    );
  }
}

/// Kategori berita beserta jumlah beritanya
class NewsCategory {
  final String category;
  final int total;

  NewsCategory({required this.category, required this.total});

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    return NewsCategory(
      category: json['category']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// Label yang enak dibaca (mis. "pengumuman" -> "Pengumuman")
  String get label {
    if (category.isEmpty) return '';
    return category
        .split(RegExp(r'[_\-\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
