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
  /// Full server payload preserved so new backend fields never get discarded.
  final Map<String, dynamic> serverData;

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
    this.serverData = const {},
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

    dynamic firstNonEmptyImage() {
      for (final value in [
        json['image'],
        json['imageUrl'],
        json['mainImage'],
        json['coverImage'],
        json['cover_image'],
        json['thumbnail'],
        json['thumbnailUrl'],
        json['image_url'],
        json['imageUrlHttps'],
        json['src'],
        json['photo'],
        json['photoUrl'],
        json['cover'],
        json['coverUrl'],
      ]) {
        final normalized = cleanImage(value);
        if (normalized.isNotEmpty) return normalized;
      }
      return '';
    }

    final image = firstNonEmptyImage();

    final galleryCandidates = <dynamic>[
      json['images'],
      json['galleryImages'],
      json['gallery'],
      json['imageUrls'],
      json['photos'],
      json['media'],
      json['mediaItems'],
      json['productImages'],
      json['photos'],
      json['variants'],
    ];

    final gallery = <String>[];

    void addMedia(dynamic candidate) {
      if (candidate is List) {
        for (final item in candidate) {
          addMedia(item);
        }
        return;
      }
      if (candidate is Map) {
        // API variants commonly expose nested images under these names.
        for (final key in const [
          'url',
          'image',
          'imageUrl',
          'src',
          'original',
          'thumbnail',
          'srcUrl',
          'photo',
          'photoUrl',
          'cover',
          'coverUrl',
          'images',
          'media',
        ]) {
          final value = candidate[key];
          if (value != null) {
            addMedia(value);
          }
        }
        return;
      }
      final normalized = cleanImage(candidate);
      if (normalized.isNotEmpty && !gallery.contains(normalized)) {
        gallery.add(normalized);
      }
    }

    for (final candidate in galleryCandidates) {
      addMedia(candidate);
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

    final rawColorMaps = <Map<String, dynamic>>[];

    final rawColors = json['colors'];
    if (rawColors is List) {
      rawColorMaps.addAll(
        rawColors.whereType<Map>().map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    }

    final rawVariants = json['variants'];
    if (rawVariants is List) {
      for (final rawVariant in rawVariants.whereType<Map>()) {
        final variant = Map<String, dynamic>.from(rawVariant);
        final color = variant['color'];
        if (color is Map) {
          final merged = <String, dynamic>{
            ...Map<String, dynamic>.from(color),
            ...variant,
          };
          rawColorMaps.add(merged);
        } else if (variant['colorName'] != null ||
            variant['colorHex'] != null ||
            variant['colorCode'] != null) {
          rawColorMaps.add(variant);
        }
      }
    }

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

    if (rawColorMaps.isNotEmpty) {
      for (final rawColor in rawColorMaps) {
        for (final key in const [
          'image',
          'imageUrl',
          'images',
          'gallery',
          'galleryImages',
          'photos',
          'media',
        ]) {
          addMedia(rawColor[key]);
        }
      }
    }

    // A few API payloads only expose a gallery, without a dedicated cover image.
    final effectiveImage = image.isNotEmpty
        ? image
        : (gallery.isNotEmpty ? gallery.first : '');

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'صنف غير مسمى').toString(),
      category: category,
      categories: categories,
      subCategory: (json['subCategory'] ?? json['subcategory'] ?? 'عام').toString(),
      subCategories: subCategories,
      styleTabs: styleTabs,
      image: effectiveImage,
      gallery: gallery.isEmpty
          ? (image.isEmpty ? const [] : [image])
          : gallery,
      originalPrice: compare > 0 ? compare : price,
      discountPrice: calculated > 0 ? calculated : number(json['discountPrice']),
      discountPercentage: effectiveDiscount,
      rating: number(json['rating']),
      reviewsCount: integer(json['reviewsCount'] ?? json['reviewCount']),
      colors: rawColorMaps
          .map(ProductColor.fromJson)
          .toList(),
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
      serverData: Map<String, dynamic>.from(json),
    );
  }
}

class ProductColor {
  final String name;
  final String hex;
  final String? image;
  final List<String> images;

  const ProductColor({
    required this.name,
    required this.hex,
    this.image,
    this.images = const [],
  });

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    String normalize(dynamic value) {
      if (value is Map) {
        value = value['url'] ??
            value['src'] ??
            value['image'] ??
            value['imageUrl'] ??
            value['original'] ??
            value['thumbnail'];
      }
      var url = value?.toString().trim() ?? '';
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

    final images = <String>[];

    void collect(dynamic value) {
      if (value is List) {
        for (final item in value) {
          collect(item);
        }
        return;
      }
      final url = normalize(value);
      if (url.isNotEmpty && !images.contains(url)) {
        images.add(url);
      }
    }

    for (final key in const [
      'image',
      'imageUrl',
      'images',
      'gallery',
      'galleryImages',
      'photos',
      'media',
    ]) {
      collect(json[key]);
    }

    return ProductColor(
      name: (json['name'] ??
              json['label'] ??
              json['colorName'] ??
              json['title'] ??
              'أساسي')
          .toString(),
      hex: (json['hex'] ??
              json['colorHex'] ??
              json['colorCode'] ??
              json['color'] ??
              '#111827')
          .toString(),
      image: images.isNotEmpty ? images.first : null,
      images: images,
    );
  }
}
