import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/content.dart';
import '../models/product.dart';
import '../state/store_controller.dart';
import 'notifications_screen.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';
import 'showcase_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final StoreController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;
  String _topCategory = 'all';
  String _feedTab = 'for_you';

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (c.loading && c.products.isEmpty && c.categories.isEmpty) {
      return const _HomeSkeleton();
    }

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: c.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _heroHeader(c.banners, c.categories)),
          SliverToBoxAdapter(child: _promoStrip()),
          SliverToBoxAdapter(child: _looksSection(c)),
          SliverToBoxAdapter(child: _categoriesGrid(c)),
          SliverToBoxAdapter(child: _feedTabs(c)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 28),
            sliver: _productGrid(_feedProducts(c)),
          ),
        ],
      ),
    );
  }

  Widget _heroHeader(List<BannerItem> banners, List<Category> categories) {
    final width = MediaQuery.sizeOf(context).width;
    final height = (width * .68).clamp(255.0, 490.0).toDouble();

    final tabs = <Map<String, String>>[
      {'id': 'all', 'label': 'كل شامل'},
      ...categories
          .where((item) => item.id.isNotEmpty && item.id != 'all')
          .map((item) => {'id': item.id, 'label': item.name}),
    ];

    if (!tabs.any((item) => item['label'] == 'أحدث')) {
      tabs.insert(tabs.length > 2 ? 3 : tabs.length, {'id': '__new', 'label': 'أحدث'});
    }

    final shownTabs = tabs.take(6).toList();
    final banner = banners.isEmpty
        ? null
        : banners[_bannerIndex.clamp(0, banners.length - 1)];

    if (banner != null && _bannerTimer == null && banners.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restartBannerTimer());
    }

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (banner != null)
            GestureDetector(
              onTap: () => _openBanner(banner),
              child: CachedNetworkImage(
                imageUrl: banner.image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: AppColors.ink),
              ),
            )
          else
            const ColoredBox(color: AppColors.ink),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x42000000),
                  Color(0x12000000),
                  Color(0x12000000),
                  Color(0x50000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            left: 12,
            child: _floatingTopBar(),
          ),
          Positioned(
            top: 117,
            right: 12,
            left: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: shownTabs.map((tab) {
                  final active = tab['id'] == _topCategory;
                  return GestureDetector(
                    onTap: () => _openTopCategory(
                      tab['id']!,
                      tab['label']!,
                      categories,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(
                        border: active
                            ? const Border(
                                bottom: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        tab['label']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: active ? 14 : 12,
                          fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (banners.length > 1)
            Positioned(
              right: 0,
              left: 0,
              bottom: 11,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length.clamp(1, 7),
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: index == _bannerIndex ? 26 : 7,
                    height: 5,
                    decoration: BoxDecoration(
                      color: index == _bannerIndex
                          ? Colors.white
                          : Colors.white54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _floatingTopBar() {
    return Row(
      children: [
        _roundAction(
          icon: Icons.favorite_border,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  WishlistScreen(controller: widget.controller),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _roundAction(
          icon: Icons.grid_view_rounded,
          onTap: () => widget.controller.selectTab(1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchScreen(controller: widget.controller),
                ),
              ),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.96),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 26,
                      color: AppColors.ink,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ابحث عن موديل، لون، مقاس...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 24,
                      color: AppColors.slate500,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _roundAction(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  NotificationsScreen(controller: widget.controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(.94),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 47,
          height: 47,
          child: Icon(icon, color: AppColors.ink, size: 25),
        ),
      ),
    );
  }

  Widget _promoStrip() {
    final data = widget.controller.announcements;
    if (data['isEnabled'] == false) return const SizedBox.shrink();

    final screens = <Map<String, dynamic>>[];
    for (final key in const ['screens', 'cards', 'items', 'strips', 'banners']) {
      final raw = data[key];
      if (raw is List) {
        screens.addAll(
          raw.whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    if (screens.isEmpty && _looksLikePromo(data)) {
      screens.add(Map<String, dynamic>.from(data));
    }

    if (screens.isEmpty) {
      screens.add({
        'badgeText': 'للمستخدمين الجدد فقط',
        'mainTitle': 'عروض جديدة',
        'subTitle': 'خصومات حصرية للطلب الأول',
        'coupons': [
          {'discount': 'خصم 30%', 'minOrder': 'أكثر من SR149'},
          {'discount': 'خصم 25%', 'minOrder': 'أكثر من SR379'},
        ],
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 6),
      child: Column(
        children: screens.take(2).map(_promoCard).toList(),
      ),
    );
  }

  bool _looksLikePromo(Map<String, dynamic> data) {
    const keys = [
      'mainTitle',
      'title',
      'subTitle',
      'subtitle',
      'coupons',
      'discount',
      'discountText',
      'badgeText',
      'shipping',
    ];
    return keys.any(data.containsKey);
  }

  Widget _promoCard(Map<String, dynamic> raw) {
    final bg = _parseColor(raw['backgroundColor'], const Color(0xFFFFF8F1));
    final cardBg = _parseColor(
      raw['cardBackgroundColor'],
      const Color(0xFFFFF2F0),
    );
    final text = _parseColor(
      raw['textColor'],
      const Color(0xFF9A2041),
    );
    final border = _parseColor(
      raw['borderColor'],
      const Color(0xFFF2D6B2),
    );

    final badge = (raw['badgeText'] ?? raw['badge'] ?? '').toString();
    final title =
        (raw['mainTitle'] ?? raw['title'] ?? 'عروض جديدة').toString();
    final subtitle =
        (raw['subTitle'] ?? raw['subtitle'] ?? '').toString();

    final couponRaw = raw['coupons'] ?? raw['offers'] ?? raw['discounts'];
    final coupons = couponRaw is List
        ? couponRaw.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];

    final benefitRaw = raw['benefits'];
    final benefits = benefitRaw is List
        ? benefitRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final effectiveCoupons = coupons.isEmpty
        ? <Map<String, dynamic>>[
            if ((raw['discount'] ?? raw['discountText']) != null)
              {
                'discount':
                    (raw['discount'] ?? raw['discountText']).toString(),
                'minOrder': (raw['minOrder'] ?? '').toString(),
              },
          ]
        : coupons;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(10, 13, 10, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(top: badge.isNotEmpty ? 4 : 0),
            child: Column(
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: text.withOpacity(.75),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (effectiveCoupons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Row(
                      children: effectiveCoupons.take(3).map((coupon) {
                        final discount =
                            (coupon['discount'] ??
                                    coupon['discountText'] ??
                                    coupon['code'] ??
                                    '')
                                .toString();
                        final minOrder =
                            (coupon['minOrder'] ??
                                    coupon['minimum'] ??
                                    coupon['subtitle'] ??
                                    '')
                                .toString();

                        return Expanded(
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: border.withOpacity(.65)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  discount,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (minOrder.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      minOrder,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: text.withOpacity(.88),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (benefits.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 5,
                      runSpacing: 4,
                      children: benefits.take(4).map((benefit) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (badge.isNotEmpty)
            Positioned(
              top: -2,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rose.withOpacity(.16),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _looksSection(StoreController c) {
    var styles = c.homeStyleTabs;
    if (styles.isEmpty) {
      final seen = <String>{};
      final collected = <StyleTab>[];
      for (final category in c.categories) {
        for (final style in category.styleTabs) {
          final key = style.id.isNotEmpty ? style.id : style.name;
          if (seen.add(key)) collected.add(style);
        }
      }
      styles = collected;
    }

    styles = styles.take(4).toList();
    if (styles.isEmpty) return const SizedBox.shrink();

    final shape = _shape(
      c.styleTabsConfig.isNotEmpty
          ? c.styleTabsConfig['shape']
          : c.categoryTabsConfig['styleShape'],
      fallback: 'rounded',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 3, 2, 7),
            child: Text(
              'إطلالات من أجلك',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: styles.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              childAspectRatio: .92,
            ),
            itemBuilder: (_, index) {
              final style = styles[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShowcaseScreen(
                      controller: widget.controller,
                      title: style.name,
                      category: 'all',
                      styleTab: style.id.isNotEmpty ? style.id : style.name,
                      image: style.image,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: _radius(shape, 24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (style.image.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: style.image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: AppColors.slate100,
                            child: Icon(Icons.image_outlined),
                          ),
                        )
                      else
                        const ColoredBox(
                          color: AppColors.slate100,
                          child: Icon(Icons.auto_awesome_outlined),
                        ),
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xDE000000),
                              ],
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 45,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        left: 6,
                        bottom: 7,
                        child: Text(
                          style.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _categoriesGrid(StoreController c) {
    final categories =
        c.categories.where((item) => item.id != 'all').take(10).toList();
    if (categories.isEmpty) return const SizedBox.shrink();

    final configuredShape = _shape(
      c.categoryTabsConfig['shape'],
      fallback: 'circle',
    );
    final configuredSize = (c.categoryTabsConfig['size'] ?? 'medium').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 7,
          crossAxisSpacing: 2,
          childAspectRatio: .9,
        ),
        itemBuilder: (_, index) {
          final category = categories[index];
          final rawDimension = configuredSize == 'small'
              ? 55.0
              : configuredSize == 'large'
                  ? 75.0
                  : 66.0;
          final dimension = rawDimension.clamp(
            48.0,
            (MediaQuery.sizeOf(context).width - 42) / 5,
          );

          return GestureDetector(
            onTap: () {
              _topCategory = category.id;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShowcaseScreen(
                    controller: widget.controller,
                    title: category.name,
                    category: category.id,
                    image: category.image,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: dimension,
                  height: dimension,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    shape: configuredShape == 'circle'
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: configuredShape == 'circle'
                        ? null
                        : _radius(configuredShape, 18),
                    border: Border.all(
                      color: AppColors.slate200,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: category.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: category.image,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.category_outlined,
                          color: AppColors.slate400,
                        ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _feedTabs(StoreController c) {
    final dynamicTabs = c.recommendationTabs;
    final tabs = dynamicTabs.isNotEmpty
        ? dynamicTabs
            .take(4)
            .map(
              (tab) => _FeedTab(
                id: tab.id,
                label: tab.label,
              ),
            )
            .toList()
        : const [
            _FeedTab(id: 'for_you', label: 'من أجلك'),
            _FeedTab(id: 'new', label: 'مدخلات جديدة'),
            _FeedTab(id: 'discount', label: 'خصومات'),
            _FeedTab(id: 'popular', label: 'الأكثر مبيعًا'),
          ];

    final activeId = tabs.any((tab) => tab.id == _feedTab)
        ? _feedTab
        : tabs.first.id;

    if (activeId != _feedTab && mounted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _feedTab = activeId),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
      child: Row(
        children: tabs.map((tab) {
          final active = tab.id == activeId;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _feedTab = tab.id),
              child: Container(
                height: 46,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.black : AppColors.slate50,
                  border: Border.all(
                    color: active ? Colors.black : AppColors.slate200,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Product> _feedProducts(StoreController c) {
    if (c.recommendationTabs.isNotEmpty) {
      final active = c.recommendationTabs
          .where((tab) => tab.id == _feedTab)
          .toList();
      if (active.isNotEmpty) {
        final list = c.recommendations(active.first);
        if (list.isNotEmpty) return list;
      }
    }

    var list = c.products.toList();
    switch (_feedTab) {
      case 'new':
        return list.reversed.take(30).toList();
      case 'discount':
        list.sort(
          (a, b) => b.discountPercentage.compareTo(a.discountPercentage),
        );
        return list;
      case 'popular':
        list.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        return list;
      default:
        return list;
    }
  }

  Widget _productGrid(List<Product> items) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'لا توجد منتجات لعرضها الآن',
              style: TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, row) {
          final left = row * 2;
          final right = left + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: right < items.length
                      ? _product(items[right], right)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _product(items[left], left),
                ),
              ],
            ),
          );
        },
        childCount: (items.length / 2).ceil(),
      ),
    );
  }

  Widget _product(Product product, int index) {
    return ProductCard(
      product: product,
      index: index,
      wishlisted: widget.controller.isWishlisted(product),
      onOpen: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            controller: widget.controller,
            product: product,
          ),
        ),
      ),
      onWishlist: () => widget.controller.toggleWishlist(product),
      onCart: () => widget.controller.addToCart(product),
    );
  }

  void _openBanner(BannerItem b) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowcaseScreen(
          controller: widget.controller,
          title: b.title,
          subtitle: b.subtitle,
          image: b.image,
          category: b.categoryTarget.isEmpty ? 'all' : b.categoryTarget,
          subCategory:
              b.targetType == 'subcategory' ? b.subTarget : null,
          styleTab: b.targetType == 'styleTab' ? b.styleTarget : null,
          saleOnly: b.targetType == 'flashSale',
          trend: b.targetType == 'trend'
              ? (b.trendTarget.isNotEmpty ? b.trendTarget : null)
              : null,
          banner: b,
        ),
      ),
    );
  }

  void _openTopCategory(
    String id,
    String label,
    List<Category> categories,
  ) {
    setState(() => _topCategory = id);

    if (id == 'all') {
      widget.controller.selectTab(0);
      return;
    }

    if (id == '__new') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShowcaseScreen(
            controller: widget.controller,
            title: label,
            category: 'all',
            sort: 'new',
          ),
        ),
      );
      return;
    }

    final matched = categories.where((item) => item.id == id).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowcaseScreen(
          controller: widget.controller,
          title: matched.isEmpty ? label : matched.first.name,
          category: id,
          image: matched.isEmpty ? null : matched.first.image,
        ),
      ),
    );
  }

  String _shape(dynamic raw, {required String fallback}) {
    final value = (raw ?? fallback).toString().toLowerCase();
    if (value.contains('circle')) return 'circle';
    if (value.contains('square')) return 'square';
    if (value.contains('curv')) return 'curved';
    if (value.contains('round')) return 'rounded';
    return fallback;
  }

  BorderRadius _radius(String shape, double radius) {
    switch (shape) {
      case 'circle':
        return BorderRadius.circular(radius * 2);
      case 'curved':
        return BorderRadius.circular(radius);
      case 'rounded':
        return BorderRadius.circular(radius * .65);
      default:
        return BorderRadius.circular(4);
    }
  }

  Color _parseColor(dynamic raw, Color fallback) {
    final value = raw?.toString() ?? '';
    if (!value.startsWith('#') || (value.length != 7 && value.length != 9)) {
      return fallback;
    }
    final parsed = int.tryParse(value.substring(1), radix: 16);
    if (parsed == null) return fallback;
    return value.length == 9
        ? Color(parsed)
        : Color(0xFF000000 | parsed);
  }
}

class _FeedTab {
  final String id;
  final String label;
  const _FeedTab({required this.id, required this.label});
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 28),
      children: [
        const SizedBox(
          height: 250,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.slate100,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(
          height: 116,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            4,
            (_) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          children: List.generate(
            10,
            (_) => const Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.slate100,
                ),
                SizedBox(height: 5),
                SizedBox(
                  width: 45,
                  height: 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.slate100),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
