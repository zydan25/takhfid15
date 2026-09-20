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
import 'wishlist_screen.dart';
import 'showcase_screen.dart';

class HomeScreen extends StatefulWidget {
  final StoreController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController bannersController = PageController();
  Timer? bannerTimer;
  int bannerIndex = 0;
  String category = 'all';
  String? subCategory;
  String? styleTab;
  String sort = 'for_you';

  @override
  void dispose() {
    bannerTimer?.cancel();
    bannersController.dispose();
    super.dispose();
  }

  void restartBannerTimer() {
    bannerTimer?.cancel();
    final banners = widget.controller.banners;
    if (banners.length < 2) return;
    final index = bannerIndex.clamp(0, banners.length - 1);
    bannerTimer = Timer(
      Duration(seconds: banners[index].slideDuration),
      () {
        if (!mounted) return;
        bannerIndex = (bannerIndex + 1) % banners.length;
        bannersController.animateToPage(
          bannerIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
        restartBannerTimer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (c.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (c.error != null && c.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: AppColors.slate500),
              const SizedBox(height: 10),
              const Text(
                'تعذر الاتصال بالخادم',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                c.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.slate500),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: c.refresh,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final items = c.filtered(
      category: category,
      subCategory: subCategory,
      styleTab: styleTab,
      sort: sort,
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
                MaterialPageRoute(
                  builder: (_) => SearchScreen(controller: c),
                ),
              ),
              onWishlist: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WishlistScreen(controller: c),
                ),
              ),
              onNotifications: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(controller: c),
                ),
              ),
              onVisualSearch: () => _showInfo(
                context,
                'البحث البصري',
                'واجهة البحث البصري موجودة في النسخة المرجعية. سيتم ربط رفع الصورة بعقد الخادم قبل الاعتماد النهائي.',
              ),
            ),
          ),
          SliverToBoxAdapter(child: _hero(c.banners)),
          SliverToBoxAdapter(child: _couponStrip()),
          SliverToBoxAdapter(child: _categoryStrip(c.categories)),
          SliverToBoxAdapter(child: _styleStrip(c.categories)),
          SliverToBoxAdapter(child: _sortTabs()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, row) {
                final left = row * 2;
                final right = left + 1;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: right < items.length
                            ? ProductCard(
                                product: items[right],
                                index: right,
                                wishlisted: c.isWishlisted(items[right]),
                                onOpen: () => _open(items[right]),
                                onWishlist: () => c.toggleWishlist(items[right]),
                                onCart: () => c.addToCart(items[right]),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ProductCard(
                          product: items[left],
                          index: left,
                          wishlisted: c.isWishlisted(items[left]),
                          onOpen: () => _open(items[left]),
                          onWishlist: () => c.toggleWishlist(items[left]),
                          onCart: () => c.addToCart(items[left]),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: (items.length / 2).ceil(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
        ],
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

  Widget _hero(List<BannerItem> banners) {
    if (banners.isEmpty) {
      return Container(
        height: 220,
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

    if (bannerTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => restartBannerTimer());
    }

    return SizedBox(
      height: 245,
      child: Stack(
        children: [
          PageView.builder(
            controller: bannersController,
            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() => bannerIndex = index);
              restartBannerTimer();
            },
            itemBuilder: (_, index) {
              final b = banners[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowcaseScreen(
                        controller: widget.controller,
                        title: b.title,
                        subtitle: b.subtitle,
                        image: b.image,
                        category: b.targetType == 'category' ||
                                b.targetType == 'subcategory' ||
                                b.targetType == 'styleTab'
                            ? b.categoryTarget
                            : 'all',
                        subCategory: b.targetType == 'subcategory'
                            ? b.subTarget
                            : null,
                        styleTab: b.targetType == 'styleTab'
                            ? b.styleTarget
                            : null,
                        saleOnly: b.targetType == 'flashSale',
                      ),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      b.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.ink),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x99000000),
                            Color(0x12000000),
                            Color(0xBB000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15,
                      right: 15,
                      bottom: 17,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (b.subtitle.isNotEmpty)
                            Text(
                              b.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rose,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'شاهد العروض',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
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
              left: 0,
              right: 0,
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  banners.length.clamp(1, 6),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == bannerIndex ? 18 : 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(i == bannerIndex ? 1 : .45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _couponStrip() {
    Widget card(String a, String b) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.roseSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                a,
                style: const TextStyle(
                  color: AppColors.rose,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                b,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          card('خصم -25%', 'قسيمة إضافية'),
          const SizedBox(width: 2),
          card('خصم -30%', 'على عروض مختارة'),
        ],
      ),
    );
  }

  Widget _categoryStrip(List<Category> categories) {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final cat = categories[index];
          final active = cat.id == category;
          return GestureDetector(
            onTap: () => setState(() {
              category = cat.id;
              subCategory = null;
              styleTab = null;
            }),
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.page,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? AppColors.black : AppColors.slate200,
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: cat.image.isNotEmpty
                        ? Image.network(cat.image, fit: BoxFit.cover)
                        : const Icon(Icons.category_outlined),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _styleStrip(List<Category> categories) {
    final current = categories.where((x) => x.id == category).toList();
    if (current.isEmpty || current.first.styleTabs.isEmpty) {
      return const SizedBox.shrink();
    }
    final styles = current.first.styleTabs;
    return SizedBox(
      height: 119,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(9, 2, 9, 8),
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final style = styles[index];
          return SizedBox(
            width: 76,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 74,
                    height: 84,
                    child: style.image.isNotEmpty
                        ? Image.network(style.image, fit: BoxFit.cover)
                        : const ColoredBox(color: AppColors.slate100),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  style.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sortTabs() {
    const items = [
      ('for_you', 'من أجلك'),
      ('new', 'مدخلات جديدة'),
      ('discount', 'خصومات'),
      ('popular', 'الأكثر مبيعاً'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
      child: Row(
        children: items.map((item) {
          final active = sort == item.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: InkWell(
              onTap: () => setState(() => sort = item.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                color: active ? AppColors.black : const Color(0xFFF5F5F6),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.ink,
                    fontSize: 10,
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

  void _showInfo(BuildContext context, String title, String text) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 5, 18, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                height: 1.6,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
