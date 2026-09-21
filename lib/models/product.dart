class Product {
  final String id;
  final String name;
  final String category;
  final List<String> categories;
  final String subCategory;
  final List<String> subCategories;
  final List<String> styleTabs;
  final String image;
  final List<String> gallery;
  final double originalPrice;
  final double discountPrice;
  final int discountPercentage;
  final double rating;
  final int reviewsCount;
  final List<ProductColor> colors;
  final List<String> sizes;
  final bool inStock;
  final String brand;
  final String description;
  final int soldCount;
  final String? couponText;
  final String? videoUrl;
  final List<String> trends;
  final String sku;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.categories,
    required this.subCategory,
    this.subCategories = const [],
    required this.styleTabs,
    required this.image,
    required this.gallery,
    required this.originalPrice,
    required this.discountPrice,
    required this.discountPercentage,
    required this.rating,
    required this.reviewsCount,
    required this.colors,
    required this.sizes,
    required this.inStock,
    required this.brand,
    required this.description,
    required this.soldCount,
    required this.couponText,
    required this.videoUrl,
    this.trends = const [],
    required this.sku,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int integer(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    dynamic imageValue(dynamic value) {
      if (value is Map) {
        return value['url'] ??
            value['src'] ??
            value['image'] ??
            value['imageUrl'] ??
            value['original'] ??
            value['thumbnail'];
      }
      return value;
    }

    String cleanImage(dynamic value) {
      final extracted = imageValue(value);
      var url = extracted?.toString().trim() ?? '';
      if (url.isEmpty) return '';
      if (url.startsWith('//')) return 'https:$url';
      if (url.startsWith('http://') ||
          url.startsWith('https://') ||
          url.startsWith('data:') ||
          url.startsWith('blob:')) {
        return url;
      }
      if (url.startsWith('/')) return 'https://whats.alattab.site$url';
      return 'https://whats.alattab.site/$url';
    }

    final image = cleanImage(
      json['image'] ??
          json['imageUrl'] ??
          json['mainImage'] ??
          json['coverImage'] ??
          json['cover_image'] ??
          json['thumbnail'] ??
          json['thumbnailUrl'] ??
          json['image_url'] ??
          json['imageUrlHttps'],
    );

    final galleryCandidates = <dynamic>[
      json['images'],
      json['galleryImages'],
      json['gallery'],
      json['imageUrls'],
      json['photos'],
      json['media'],
      json['mediaItems'],
    ];

    final gallery = <String>[];
    for (final candidate in galleryCandidates) {
      if (candidate is List) {
        for (final item in candidate) {
          if (item is Map) {
            final value = item['url'] ??
                item['image'] ??
                item['imageUrl'] ??
                item['src'];
            final normalized = cleanImage(value);
            if (normalized.isNotEmpty && !gallery.contains(normalized)) {
              gallery.add(normalized);
            }
          } else {
            final normalized = cleanImage(item);
            if (normalized.isNotEmpty && !gallery.contains(normalized)) {
              gallery.add(normalized);
            }
          }
        }
      }
    }

    final category =
        (json['categoryId'] ?? json['category'] ?? 'all').toString();
    final rawCategories = json['categories'];
    final categories = rawCategories is List && rawCategories.isNotEmpty
        ? rawCategories.map((e) => e.toString()).toList()
        : <String>['all', category];

    final rawSubCategories = json['subCategories'];
    final subCategories = rawSubCategories is List
        ? rawSubCategories.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final rawStyles = json['styleTabs'] ?? json['styleTabIds'] ?? json['styles'];
    final styleTabs = rawStyles is List
        ? rawStyles.map((e) => e.toString()).toList()
        : <String>[];

    final price = number(json['price']);
    final compare = number(json['compareAtPrice'] ?? json['originalPrice']);
    final discountValue = number(json['discountValue']);
    final discountType = (json['discountType'] ?? 'none').toString();
    final calculated = discountType == 'percent'
        ? price - price * discountValue / 100
        : discountType == 'fixed'
            ? price - discountValue
            : price;
    final serverDiscount = integer(
      json['discountPercentage'] ?? json['discount'],
    );
    final effectiveDiscount = serverDiscount > 0
        ? serverDiscount
        : (compare > calculated && compare > 0)
            ? (((compare - calculated) / compare) * 100).round()
            : 0;

    if (json['colors'] is List) {
      for (final rawColor in (json['colors'] as List).whereType<Map>()) {
        final value = rawColor['image'] ?? rawColor['imageUrl'];
        final normalized = cleanImage(value);
        if (normalized.isNotEmpty && !gallery.contains(normalized)) {
          gallery.add(normalized);
        }
      }
    }

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'صنف غير مسمى').toString(),
      category: category,
      categories: categories,
      subCategory: (json['subCategory'] ?? json['subcategory'] ?? 'عام').toString(),
      subCategories: subCategories,
      styleTabs: styleTabs,
      image: image,
      gallery: gallery.isEmpty
          ? (image.isEmpty ? const [] : [image])
          : gallery,
      originalPrice: compare > 0 ? compare : price,
      discountPrice: calculated > 0 ? calculated : number(json['discountPrice']),
      discountPercentage: effectiveDiscount,
      rating: number(json['rating']),
      reviewsCount: integer(json['reviewsCount'] ?? json['reviewCount']),
      colors: json['colors'] is List
          ? (json['colors'] as List).whereType<Map>().map((e) {
              return ProductColor.fromJson(Map<String, dynamic>.from(e));
            }).toList()
          : const [],
      sizes: json['sizes'] is List
          ? (json['sizes'] as List).map((e) => e.toString()).toList()
          : const [],
      inStock: json['active'] != false &&
          (json['stock'] == null || integer(json['stock']) > 0),
      brand: (json['brand'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      soldCount: integer(json['soldCount']),
      couponText: json['couponText']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      trends: json['trends'] is List
          ? (json['trends'] as List).map((e) => e.toString()).toList()
          : const [],
      sku: (json['sku'] ?? '').toString(),
    );
  }
}

class ProductColor {
  final String name;
  final String hex;
  final String? image;

  const ProductColor({
    required this.name,
    required this.hex,
    this.image,
  });

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    return ProductColor(
      name: (json['name'] ?? json['label'] ?? 'أساسي').toString(),
      hex: (json['hex'] ?? json['color'] ?? '#111827').toString(),
      image: json['image']?.toString() ?? json['imageUrl']?.toString(),
    );
  }
}
