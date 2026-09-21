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
  final String trendTarget;
  final int slideDuration;
  final List<BannerSubTab> subScreenTabs;

  const BannerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.targetType,
    required this.categoryTarget,
    required this.subTarget,
    required this.styleTarget,
    this.trendTarget = '',
    required this.slideDuration,
    this.subScreenTabs = const [],
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
      styleTarget: (json['targetStyleTab'] ?? json['style'] ?? '').toString(),
      trendTarget: (json['targetTrend'] ?? json['trend'] ?? '').toString(),
      slideDuration: duration.clamp(2, 20),
      subScreenTabs: json['subScreenTabs'] is List
          ? (json['subScreenTabs'] as List).whereType<Map>().map((e) =>
              BannerSubTab.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }
}

class BannerSubTab {
  final String id;
  final String name;
  final String title;
  final String image;
  final String badge;
  final List<String> linkedProductIds;

  const BannerSubTab({
    required this.id,
    required this.name,
    required this.title,
    required this.image,
    required this.badge,
    this.linkedProductIds = const [],
  });

  factory BannerSubTab.fromJson(Map<String, dynamic> json) {
    return BannerSubTab(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['label'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      badge: (json['badge'] ?? '').toString(),
      linkedProductIds: json['linkedProductIds'] is List
          ? (json['linkedProductIds'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class RecommendationTab {
  final String id;
  final String label;
  final String matchType;
  final List<String> keywords;
  final List<String> targetCategories;
  final List<String> targetSubCategories;
  final List<String> linkedProductIds;
  final bool isActive;
  final int order;

  const RecommendationTab({
    required this.id,
    required this.label,
    required this.matchType,
    this.keywords = const [],
    this.targetCategories = const [],
    this.targetSubCategories = const [],
    this.linkedProductIds = const [],
    this.isActive = true,
    this.order = 0,
  });

  factory RecommendationTab.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) => value is List
        ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const [];
    return RecommendationTab(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? json['name'] ?? '').toString(),
      matchType: (json['matchType'] ?? 'all_smart').toString(),
      keywords: strings(json['keywords']),
      targetCategories: strings(json['targetCategories']),
      targetSubCategories: strings(json['targetSubCategories']),
      linkedProductIds: strings(json['linkedProductIds']),
      isActive: json['isActive'] != false,
      order: (json['order'] is num) ? (json['order'] as num).toInt() : 0,
    );
  }
}

class TrendCampaign {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String tag;
  final String badge;
  final String daysLeft;
  final String bgImage;
  final List<String> productIds;

  const TrendCampaign({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.tag,
    this.badge = '',
    this.daysLeft = '',
    this.bgImage = '',
    this.productIds = const [],
  });

  factory TrendCampaign.fromJson(Map<String, dynamic> json) {
    return TrendCampaign(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      tag: (json['tag'] ?? json['hashtag'] ?? '').toString(),
      badge: (json['badge'] ?? '').toString(),
      daysLeft: (json['daysLeft'] ?? '').toString(),
      bgImage: (json['bgImage'] ?? json['image'] ?? '').toString(),
      productIds: json['productIds'] is List
          ? (json['productIds'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}
