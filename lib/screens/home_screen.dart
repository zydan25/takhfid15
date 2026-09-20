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

class _FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const _FadeIn({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, row) {
                  final left = row * 2;
                  final right = left + 1;
                  return _FadeIn(
                    delay: Duration(milliseconds: row * 50),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                          const SizedBox(width: 10),
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
                    ),
                  );
                },
                childCount: (items.length / 2).ceil(),
              ),
            ),
          ),
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
                    CachedNetworkImage(
                      imageUrl: b.image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const ColoredBox(color: AppColors.ink),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.roseSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.rose.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Text(
                a,
                style: const TextStyle(
                  color: AppColors.rose,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                b,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          card('خصم -25%', 'قسيمة إضافية'),
          const SizedBox(width: 8),
          card('خصم -30%', 'على عروض مختارة'),
        ],
      ),
    );
  }

  Widget _categoryStrip(List<Category> categories) {
    return SizedBox(
      height: 115,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
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
              width: 68,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active ? AppColors.black : AppColors.slate200,
                        width: active ? 2 : 1,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: cat.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cat.image,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.category_outlined, color: AppColors.slate400),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                      color: active ? AppColors.ink : AppColors.slate500,
                      height: 1.2,
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
          final active = style.id == styleTab;

          return GestureDetector(
            onTap: () => setState(() {
              styleTab = active ? null : style.id;
              subCategory = null;
            }),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 74,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? AppColors.black
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: style.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: style.image,
                            fit: BoxFit.cover,
                          )
                        : const ColoredBox(
                            color: AppColors.slate100,
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
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: items.map((item) {
          final active = sort == item.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => setState(() => sort = item.$1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.black : AppColors.slate100,
                  borderRadius: BorderRadius.circular(8),
                  border: active
                      ? null
                      : Border.all(color: AppColors.slate200, width: 1),
                ),
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
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
