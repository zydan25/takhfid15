class Product {
  final String id;
  final String name;
  final String category;
  final List<String> categories;
  final String subCategory;
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

    final image = (json['image'] ?? '').toString();
    final rawGallery =
        json['images'] is List
            ? json['images']
            : (json['galleryImages'] is List ? json['galleryImages'] : json['gallery']);
    final gallery = rawGallery is List
        ? rawGallery.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final category =
        (json['categoryId'] ?? json['category'] ?? 'all').toString();
    final rawCategories = json['categories'];
    final categories = rawCategories is List && rawCategories.isNotEmpty
        ? rawCategories.map((e) => e.toString()).toList()
        : <String>['all', category];

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

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'صنف غير مسمى').toString(),
      category: category,
      categories: categories,
      subCategory: (json['subCategory'] ?? json['subcategory'] ?? 'عام').toString(),
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
