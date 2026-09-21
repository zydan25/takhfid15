import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/content.dart';
import '../models/product.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/top_bar.dart';
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
  String _category = 'all';
  String? _subCategory;
  String? _styleTab;
  String? _recommendationTab;
  String _sort = 'for_you';

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

    final items = c.filtered(
      category: _category,
      subCategory: _subCategory,
      styleTab: _styleTab,
      sort: _sort,
    );

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: c.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: StoreTopBar(
              onSearch: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchScreen(controller: c)),
              ),
              onWishlist: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WishlistScreen(controller: c)),
              ),
              onNotifications: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen(controller: c)),
              ),
              onVisualSearch: () => _showInfo(
                context,
                'البحث البصري',
                'يمكن تفعيل البحث بالصورة وربطه بعقد البحث في الخادم.',
              ),
            ),
          ),
          SliverToBoxAdapter(child: _quickCategoryBar(c.categories)),
          SliverToBoxAdapter(child: _hero(c.banners)),
          SliverToBoxAdapter(child: _announcementStrip()),
          SliverToBoxAdapter(child: _styleStrip(c.categories)),
          SliverToBoxAdapter(child: _subCategoryStrip(c.categories)),
          if (c.recommendationTabs.isNotEmpty)
            SliverToBoxAdapter(child: _recommendationSection()),
          SliverToBoxAdapter(child: _sortTabs()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
            sliver: _productGrid(items),
          ),
        ],
      ),
    );
  }

  Widget _productGrid(List<Product> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, row) {
          final left = row * 2;
          final right = left + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: right < items.length
                      ? ProductCard(
                          product: items[right],
                          index: right,
                          wishlisted: widget.controller.isWishlisted(items[right]),
                          onOpen: () => _open(items[right]),
                          onWishlist: () => widget.controller.toggleWishlist(items[right]),
                          onCart: () => widget.controller.addToCart(items[right]),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ProductCard(
                    product: items[left],
                    index: left,
                    wishlisted: widget.controller.isWishlisted(items[left]),
                    onOpen: () => _open(items[left]),
                    onWishlist: () => widget.controller.toggleWishlist(items[left]),
                    onCart: () => widget.controller.addToCart(items[left]),
                  ),
                ),
              ],
            ),
          );
        },
        childCount: (items.length / 2).ceil(),
      ),
    );
  }

  Widget _quickCategoryBar(List<Category> categories) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final category = categories[index];
          final active = category.id == _category;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() {
              _category = category.id;
              _subCategory = null;
              _styleTab = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.black : AppColors.slate50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active ? AppColors.black : AppColors.slate200,
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : AppColors.slate600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero(List<BannerItem> banners) {
    if (banners.isEmpty) {
      return Container(
        height: 214,
        margin: const EdgeInsets.only(top: 2),
        color: AppColors.ink,
        alignment: Alignment.center,
        child: const Text(
          'التخفيض الصح',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (_bannerTimer == null && banners.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restartBannerTimer());
    }

    return SizedBox(
      height: 236,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _bannerIndex = index);
              _restartBannerTimer();
            },
            itemBuilder: (_, index) {
              final b = banners[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShowcaseScreen(
                      controller: widget.controller,
                      title: b.title,
                      subtitle: b.subtitle,
                      image: b.image,
                      category: b.categoryTarget,
                      subCategory: b.targetType == 'subcategory' ? b.subTarget : null,
                      styleTab: b.targetType == 'styleTab' ? b.styleTarget : null,
                      saleOnly: b.targetType == 'flashSale',
                      trend: b.targetType == 'trend'
                          ? (b.targetStyle.isNotEmpty ? b.targetStyle : null)
                          : null,
                      banner: b,
                    ),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: b.image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.ink),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x65000000),
                            Color(0x10000000),
                            Color(0xCC000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 15,
                      left: 15,
                      bottom: 17,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (b.title.isNotEmpty)
                            Text(
                              b.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          if (b.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              b.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.rose,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              child: Text(
                                'شاهد العروض',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (banners.length > 1)
            Positioned(
              right: 0,
              left: 0,
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length.clamp(1, 6),
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: index == _bannerIndex ? 18 : 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(index == _bannerIndex ? 1 : .45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _restartBannerTimer() {
    _bannerTimer?.cancel();
    final banners = widget.controller.banners;
    if (banners.length < 2) return;
    final index = _bannerIndex.clamp(0, banners.length - 1);
    final seconds = banners[index].slideDuration.clamp(2, 20);
    _bannerTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      _bannerIndex = (_bannerIndex + 1) % banners.length;
      _bannerController.animateToPage(
        _bannerIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      _restartBannerTimer();
    });
  }

  Widget _announcementStrip() {
    final rawScreens = widget.controller.announcements['screens'];
    if (rawScreens is! List || rawScreens.isEmpty ||
        widget.controller.announcements['isEnabled'] == false) {
      return const SizedBox.shrink();
    }

    final screens = rawScreens.whereType<Map>().toList();
    if (screens.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 4),
      child: Row(
        children: screens.take(2).map((raw) {
          final bg = _parseColor(raw['backgroundColor'], const Color(0xFFF8FAFC));
          final cardBg = _parseColor(raw['cardBackgroundColor'], Colors.white);
          final text = _parseColor(raw['textColor'], AppColors.rose);
          final title = (raw['mainTitle'] ?? raw['title'] ?? '').toString();
          final subtitle = (raw['subTitle'] ?? '').toString();
          final badge = (raw['badgeText'] ?? '').toString();
          final coupons = raw['coupons'] is List ? (raw['coupons'] as List) : const [];
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _parseColor(raw['borderColor'], text).withOpacity(.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge.isNotEmpty)
                    Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: text, fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: text.withOpacity(.75), fontSize: 8, fontWeight: FontWeight.w700),
                    ),
                  if (coupons.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: coupons.take(1).map((coupon) {
                        final c = coupon is Map ? Map<String, dynamic>.from(coupon) : <String, dynamic>{};
                        return Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              (c['code'] ?? c['discount'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: text, fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _styleStrip(List<Category> categories) {
    final current = categories.where((item) => item.id == _category).toList();
    final styles = current.isEmpty ? <StyleTab>[] : current.first.styleTabs;
    if (styles.isEmpty) return const SizedBox.shrink();

    return _mediaStrip(
      title: 'إطلالات من أجلك',
      subtitle: 'تنسيقات مختارة تناسب الفئة الحالية',
      items: styles,
      selectedId: _styleTab,
      onTap: (style) => setState(() {
        _styleTab = _styleTab == style.id ? null : style.id;
        _subCategory = null;
      }),
    );
  }

  Widget _subCategoryStrip(List<Category> categories) {
    final current = categories.where((item) => item.id == _category).toList();
    final subs = current.isEmpty ? <SubCategory>[] : current.first.subCategories;
    if (subs.isEmpty) return const SizedBox.shrink();

    return _mediaStrip(
      title: 'التصنيفات',
      subtitle: 'اختر قسماً لعرض المنتجات مباشرة',
      items: subs,
      selectedId: _subCategory,
      onTap: (sub) {
        setState(() {
          _subCategory = sub.id.isNotEmpty ? sub.id : sub.name;
          _styleTab = null;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShowcaseScreen(
              controller: widget.controller,
              title: sub.name,
              category: _category,
              subCategory: sub.name,
              image: sub.image,
            ),
          ),
        );
      },
    );
  }

  Widget _mediaStrip<T>({
    required String title,
    required String subtitle,
    required List<T> items,
    required String? selectedId,
    required ValueChanged<T> onTap,
  }) {
    final shape = (widget.controller.categoryTabsConfig['shape'] ?? 'circle').toString();
    final squareRatio = widget.controller.categoryTabsConfig['isSquareRatio'] != false;
    final size = (widget.controller.categoryTabsConfig['size'] ?? 'medium').toString();

    double dimension = size == 'small' ? 58 : size == 'large' ? 80 : 70;
    final height = squareRatio ? dimension : dimension + 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 7, 11, 1),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8, color: AppColors.slate400, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: height + 31,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = items[index];
              final id = item is StyleTab
                  ? item.id
                  : item is SubCategory
                      ? item.id.isNotEmpty ? item.id : item.name
                      : index.toString();
              final name = item is StyleTab
                  ? item.name
                  : item is SubCategory
                      ? item.name
                      : '';
              final image = item is StyleTab
                  ? item.image
                  : item is SubCategory
                      ? item.image
                      : '';
              final selected = id == selectedId;

              return GestureDetector(
                onTap: () => onTap(item),
                child: SizedBox(
                  width: dimension + 2,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        width: dimension,
                        height: dimension,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: shape == 'circle'
                              ? null
                              : BorderRadius.circular(
                                  shape == 'rounded' ? 18 : shape == 'curved' ? 25 : 5,
                                ),
                          border: selected
                              ? Border.all(color: AppColors.black, width: 2)
                              : Border.all(color: AppColors.slate200, width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: image,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.image_outlined, color: AppColors.slate400),
                              )
                            : const Icon(Icons.category_outlined, color: AppColors.slate400),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          height: 1.15,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                          color: selected ? AppColors.ink : AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _recommendationSection() {
    final tabs = widget.controller.recommendationTabs;
    var activeId = _recommendationTab ?? (tabs.isEmpty ? '' : tabs.first.id);
    final active = tabs.where((item) => item.id == activeId).toList();
    final selected = active.isEmpty ? tabs.first : active.first;
    final products = widget.controller.recommendations(selected).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(11, 9, 11, 4),
          child: Text('مقترحات من أجلك', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, index) {
              final tab = tabs[index];
              final activeTab = tab.id == selected.id;
              return GestureDetector(
                onTap: () => setState(() => _recommendationTab = tab.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: activeTab ? AppColors.black : AppColors.slate50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: activeTab ? AppColors.black : AppColors.slate200),
                  ),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: activeTab ? Colors.white : AppColors.slate600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (products.isNotEmpty)
          SizedBox(
            height: 235,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final product = products[index];
                return SizedBox(
                  width: 155,
                  child: ProductCard(
                    product: product,
                    index: index,
                    wishlisted: widget.controller.isWishlisted(product),
                    onOpen: () => _open(product),
                    onWishlist: () => widget.controller.toggleWishlist(product),
                    onCart: () => widget.controller.addToCart(product),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _sortTabs() {
    const tabs = <Map<String, String>>[
      {'id': 'for_you', 'label': 'التوصية'},
      {'id': 'discount', 'label': 'الأعلى خصمًا'},
      {'id': 'popular', 'label': 'الأكثر مبيعًا'},
      {'id': 'rating', 'label': 'الأعلى تقييمًا'},
      {'id': 'price-low', 'label': 'الأقل سعرًا'},
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final tab = tabs[index];
          final active = _sort == tab['id'];
          return GestureDetector(
            onTap: () => setState(() => _sort = tab['id']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.black : AppColors.slate50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: active ? AppColors.black : AppColors.slate200),
              ),
              child: Text(
                tab['label']!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : AppColors.slate600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _open(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          controller: widget.controller,
          product: product,
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 5, 18, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate500, fontSize: 10, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(dynamic raw, Color fallback) {
    final value = raw?.toString() ?? '';
    if (!value.startsWith('#') || (value.length != 7 && value.length != 9)) return fallback;
    final hex = value.substring(1);
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return value.length == 9 ? Color(parsed) : Color(0xFF000000 | parsed);
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
      children: [
        const SizedBox(
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          height: 225,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.slate100),
          ),
        ),
        const SizedBox(height: 12),
        for (int row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
