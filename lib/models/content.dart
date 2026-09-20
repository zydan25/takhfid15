class Category {
  final String id;
  final String name;
  final String image;
  final List<SubCategory> subCategories;
  final List<StyleTab> styleTabs;

  const Category({
    required this.id,
    required this.name,
    required this.image,
    this.subCategories = const [],
    this.styleTabs = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? 'all').toString(),
      name: (json['name'] ?? 'قسم').toString(),
      image: (json['image'] ?? '').toString(),
      subCategories: json['subCategories'] is List
          ? (json['subCategories'] as List).whereType<Map>().map((e) {
              return SubCategory.fromJson(Map<String, dynamic>.from(e));
            }).toList()
          : const [],
      styleTabs: json['styleTabs'] is List
          ? (json['styleTabs'] as List).whereType<Map>().map((e) {
              return StyleTab.fromJson(Map<String, dynamic>.from(e));
            }).toList()
          : const [],
    );
  }
}

class SubCategory {
  final String id;
  final String name;
  final String image;
  const SubCategory({
    required this.id,
    required this.name,
    required this.image,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
    );
  }
}

class StyleTab {
  final String id;
  final String name;
  final String image;
  const StyleTab({
    required this.id,
    required this.name,
    required this.image,
  });

  factory StyleTab.fromJson(Map<String, dynamic> json) {
    return StyleTab(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
    );
  }
}

class BannerItem {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String targetType;
  final String categoryTarget;
  final String subTarget;
  final String styleTarget;
  final int slideDuration;

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.targetType,
    required this.categoryTarget,
    required this.subTarget,
    required this.styleTarget,
    required this.slideDuration,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    final rawDuration = json['slideDuration'];
    final duration =
        rawDuration is num ? rawDuration.toInt() : int.tryParse('$rawDuration') ?? 4;
    return BannerItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'عرض').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      targetType: (json['targetType'] ?? 'category').toString(),
      categoryTarget:
          (json['categoryTarget'] ?? json['categoryId'] ?? 'all').toString(),
      subTarget: (json['targetSubCategory'] ?? '').toString(),
      styleTarget: (json['targetStyleTab'] ?? '').toString(),
      slideDuration: duration.clamp(2, 20),
    );
  }
}

class TrendCampaign {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String tag;

  const TrendCampaign({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.tag,
  });

  factory TrendCampaign.fromJson(Map<String, dynamic> json) {
    return TrendCampaign(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      tag: (json['tag'] ?? json['hashtag'] ?? '').toString(),
    );
  }
}
