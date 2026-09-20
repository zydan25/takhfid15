class Product {
  final String id;
  final String name;
  final String category;
  final List<String> categories;
  final String subCategory;
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

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.categories,
    required this.subCategory,
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

    final image = (json['image'] ?? '').toString();
    final rawGallery =
        json['galleryImages'] is List ? json['galleryImages'] : json['gallery'];
    final gallery = rawGallery is List
        ? rawGallery.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final category =
        (json['category'] ?? json['categoryId'] ?? 'all').toString();
    final rawCats = json['categories'];
    final categories = rawCats is List && rawCats.isNotEmpty
        ? rawCats.map((e) => e.toString()).toList()
        : <String>['all', category];
    final discountPrice = number(json['discountPrice'] ?? json['price']);
    final original = number(json['originalPrice']);
    final originalPrice = original > 0 ? original : discountPrice;
    final rawDiscount =
        integer(json['discountPercentage'] ?? json['discount']);
    final discount = rawDiscount > 0
        ? rawDiscount
        : (originalPrice > discountPrice
            ? (((originalPrice - discountPrice) / originalPrice) * 100).round()
            : 0);

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'صنف غير مسمى').toString(),
      category: category,
      categories: categories,
      subCategory: (json['subCategory'] ?? 'عام').toString(),
      image: image,
      gallery: gallery.isEmpty ? (image.isEmpty ? const [] : [image]) : gallery,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      discountPercentage: discount,
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
      inStock: json['inStock'] != false,
      brand: (json['brand'] ?? 'SHEIN').toString(),
      description: (json['description'] ?? '').toString(),
      soldCount: integer(json['soldCount']),
    );
  }
}

class ProductColor {
  final String name;
  final String hex;
  const ProductColor({required this.name, required this.hex});

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    return ProductColor(
      name: (json['name'] ?? 'أساسي').toString(),
      hex: (json['hex'] ?? '#111827').toString(),
    );
  }
}
