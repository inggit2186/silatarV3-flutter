/// News Model - Berita/News item
class NewsModel {
  final int id;
  final String title;
  final String slug;
  final String? category;
  final String? excerpt;
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
      'image': image,
      'image_url': imageUrl,
      'publish_date': publishDate?.toIso8601String(),
      'is_featured': isFeatured,
      'is_slideshow': isSlideshow,
    };
  }
}
