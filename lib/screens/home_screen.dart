import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/content.dart';
import '../models/product.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
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
  Timer? _bannerTimer;
  int _bannerIndex = 0;
  Timer? _promoTimer;
  int _promoIndex = 0;
  String _topCategory = 'all';
  String _feedTab = 'for_you';

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _promoTimer?.cancel();
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

  void _restartBannerTimer(int count) {
    _bannerTimer?.cancel();
    if (count < 2) return;
    _bannerTimer = Timer(
      const Duration(seconds: 4),
      () {
        if (!mounted) return;
        setState(() {
          _bannerIndex = (_bannerIndex + 1) % count;
        });
        _bannerTimer = null;
      },
    );
  }

  Widget _heroHeader(List<BannerItem> banners, List<Category> categories) {
    final width = MediaQuery.sizeOf(context).width;
    final bannerHeight = (width * .62).clamp(220.0, 390.0).toDouble();
    final byId = <String, Category>{
      for (final category in categories) category.id: category,
    };
    final shownTabs = <Map<String, String>>[
      {'id': 'all', 'label': 'كل شامل'},
      if (byId.containsKey('women')) {'id': 'women', 'label': 'نساء'},
      if (byId.containsKey('men')) {'id': 'men', 'label': 'رجال'},
      {'id': '__new', 'label': 'أحدث'},
      if (byId.containsKey('bags')) {'id': 'bags', 'label': 'حقائب'},
      if (byId.containsKey('accessories'))
        {'id': 'accessories', 'label': 'إكسسوارات'},
    ];
    final banner = banners.isEmpty
        ? null
        : banners[_bannerIndex.clamp(0, banners.length - 1)];

    if (banner != null && _bannerTimer == null && banners.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restartBannerTimer(banners.length),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: _floatingTopBar(),
        ),
        Container(
          height: 48,
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: shownTabs.map((tab) {
                final active = tab['id'] == _topCategory;
                return GestureDetector(
                  onTap: () => _openTopCategory(
                    tab['id']!,
                    tab['label']!,
                    categories,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: active
                          ? const Border(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 2.2,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      tab['label']!,
                      style: TextStyle(
                        color: active ? Colors.black : AppColors.slate600,
                        fontSize: active ? 14 : 13,
                        fontWeight:
                            active ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(
          height: bannerHeight,
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
                      Color(0x18000000),
                      Color(0x18000000),
                      Color(0xAA000000),
                    ],
                  ),
                ),
              ),
              if (banner != null) _bannerContent(banner),
              if (banners.length > 1)
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 9,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      banners.length.clamp(1, 7),
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: index == _bannerIndex ? 24 : 6,
                        height: 4,
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
              if (banners.length > 1) ...[
                Positioned(
                  left: 9,
                  top: bannerHeight / 2 - 20,
                  child: _bannerArrow(
                    Icons.chevron_left_rounded,
                    () => _changeBanner(-1, banners.length),
                  ),
                ),
                Positioned(
                  right: 9,
                  top: bannerHeight / 2 - 20,
                  child: _bannerArrow(
                    Icons.chevron_right_rounded,
                    () => _changeBanner(1, banners.length),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerContent(BannerItem banner) {
    return Positioned(
      right: 18,
      left: 18,
      bottom: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (banner.badge.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.72),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                banner.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (banner.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                banner.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 5)],
                ),
              ),
            ),
          if (banner.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                banner.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
            ),
          if (banner.code.isNotEmpty || banner.buttonText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (banner.buttonText.isNotEmpty)
                    ElevatedButton(
                      onPressed: () => _openBanner(banner),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        banner.buttonText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (banner.code.isNotEmpty) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.58),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'كود \${banner.code}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bannerArrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black.withOpacity(.38),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 27),
        ),
      ),
    );
  }

  void _changeBanner(int delta, int count) {
    if (count < 2) return;
    _bannerTimer?.cancel();
    setState(() {
      _bannerIndex = (_bannerIndex + delta + count) % count;
    });
    _restartBannerTimer(count);
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
    final rawScreens = data['screens'];
    if (rawScreens is List) {
      screens.addAll(
        rawScreens
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => item['isActive'] != false),
      );
    }

    if (screens.isEmpty) {
      screens.addAll([
        {
          'id': 'screen-1-coupons',
          'badgeText': 'للمستخدمين الجدد فقط',
          'mainTitle': 'قسائم حصرية',
          'subTitle': 'عروض جيدة',
          'coupons': [
            {
              'code': 'NEW30',
              'discount': 'خصم 30%',
              'minSpend': 'أكثر من SR149',
            },
            {
              'code': 'NEW25',
              'discount': 'خصم 25%',
              'minSpend': 'أكثر من SR379',
            },
          ],
          'backgroundColor': '#FEF6EE',
          'cardBackgroundColor': '#FFF0F2',
          'textColor': '#9F1239',
          'badgeBackgroundColor': '#FF385C',
          'borderColor': '#FED7AA',
        },
        {
          'id': 'screen-2-shipping',
          'badgeText': 'شحن سريع وآمن ⚡',
          'mainTitle': 'شحن مجاني',
          'subTitle': 'تسليم سريع لباب منزلك',
          'coupons': [
            {
              'code': 'FREESHIP',
              'discount': 'شحن مجاني',
              'minSpend': 'للطلبات فوق SR199',
            },
            {
              'code': 'FAST48',
              'discount': 'توصيل خلال 48 س',
              'minSpend': 'تتبع لحظي مضمون 🛡️',
            },
          ],
          'backgroundColor': '#E2EFDA',
          'cardBackgroundColor': '#D9EAD3',
          'textColor': '#1B5E20',
          'badgeBackgroundColor': '#166534',
          'borderColor': '#A9D08E',
        },
      ]);
    }

    final safeIndex = _promoIndex.clamp(0, screens.length - 1).toInt();
    if (screens.length > 1 && _promoTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restartPromoTimer(screens.length));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 7),
      child: _promoCard(screens[safeIndex]),
    );
  }

  void _restartPromoTimer(int count) {
    _promoTimer?.cancel();
    if (count < 2) return;
    _promoTimer = Timer(
      const Duration(seconds: 4),
      () {
        if (!mounted) return;
        setState(() => _promoIndex = (_promoIndex + 1) % count);
        _promoTimer = null;
      },
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
                              color: AppColors.emerald,
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
                  color: _parseColor(raw['badgeBackgroundColor'], AppColors.rose),
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
    final allMatches = c.categories
        .where((category) => category.id == 'all')
        .toList();
    final allCategory = allMatches.isEmpty ? null : allMatches.first;

    final source = allCategory?.styleTabs ?? c.homeStyleTabs;
    const preferred = <String>[
      'إطلالات يومية',
      'محتشمة',
      'عمل',
      'حفلات',
    ];

    final styles = <StyleTab>[];
    for (final name in preferred) {
      final found = source.where((item) => item.name == name);
      if (found.isNotEmpty) styles.add(found.first);
    }
    for (final style in source) {
      if (styles.length >= 4) break;
      if (!styles.any((item) => item.id == style.id)) {
        styles.add(style);
      }
    }

    if (styles.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = ((width - 100) / 4).clamp(125.0, 154.0).toDouble();
    final shape = _shape(c.styleTabsConfig['shape'], fallback: 'rounded');

    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(3, 2, 3, 8),
            child: Text(
              'إطلالات من أجلك',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(
            height: 176,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: styles.take(4).length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final style = styles[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowcaseScreen(
                        controller: c,
                        title: style.name,
                        category: 'all',
                        styleTab: style.name,
                        image: style.image,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: cardWidth,
                    height: 170,
                    child: ClipRRect(
                      borderRadius: _radius(shape, 23),
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
                                    Color(0xE6000000),
                                  ],
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 53,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 7,
                            left: 7,
                            bottom: 9,
                            child: Text(
                              style.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriesGrid(StoreController c) {
    final allMatches = c.categories
        .where((category) => category.id == 'all')
        .toList();
    final allCategory = allMatches.isEmpty ? null : allMatches.first;
    if (allCategory == null || allCategory.subCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final wanted = <Map<String, String>>[
      {'id': 'all-dresses', 'label': 'فساتين'},
      {'id': 'all-tops', 'label': 'ملابس علوية'},
      {'id': 'all-tees', 'label': 'تيشيرتات'},
      {'id': 'all-blouses', 'label': 'بليزر'},
      {'id': 'all-suits', 'label': 'بدلات'},
      {'id': 'all-pants', 'label': 'بناطيل'},
      {'id': 'all-sweaters', 'label': 'بلايز ثقيلة'},
      {'id': 'all-jackets', 'label': 'معاطف وجاكيتات'},
      {'id': 'all-arabic', 'label': 'ملابس عربية'},
      {'id': 'all-denim', 'label': 'الدنيم'},
    ];

    final lookup = <String, SubCategory>{
      for (final item in allCategory.subCategories) item.id: item,
    };
    final items = wanted
        .where((item) => lookup.containsKey(item['id']))
        .map((item) {
          final source = lookup[item['id']]!;
          return SubCategory(
            id: source.id,
            name: item['label']!,
            image: source.image,
          );
        })
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final dimension = ((width - 50) / 5).clamp(62.0, 96.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 9),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 2,
          mainAxisSpacing: 5,
          childAspectRatio: .83,
        ),
        itemBuilder: (_, index) {
          final sub = items[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShowcaseScreen(
                  controller: c,
                  title: sub.name,
                  category: 'all',
                  subCategory: sub.id,
                  image: sub.image,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: dimension,
                  height: dimension,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.slate100,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: sub.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: sub.image,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.category_outlined,
                          color: AppColors.slate400,
                        ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 28,
                  child: Text(
                    sub.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.03,
                      fontWeight: FontWeight.w600,
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
    const tabs = <_FeedTab>[
      _FeedTab(id: 'for_you', label: 'من أجلك'),
      _FeedTab(id: 'new', label: 'مدخلات جديدة'),
      _FeedTab(id: 'discount', label: 'خصومات'),
      _FeedTab(id: 'popular', label: 'الأكثر مبيعًا'),
    ];

    final activeId =
        tabs.any((tab) => tab.id == _feedTab) ? _feedTab : tabs.first.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 3, 18, 0),
      child: Row(
        children: tabs.map((tab) {
          final active = tab.id == activeId;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _feedTab = tab.id),
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                color: active ? Colors.black : AppColors.slate100,
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
    if (_feedTab == 'for_you' && c.recommendationTabs.isNotEmpty) {
      final all = c.recommendationTabs
          .where((tab) => tab.id == 'all')
          .toList();
      if (all.isNotEmpty) {
        final recommended = c.recommendations(all.first);
        if (recommended.isNotEmpty) return recommended;
      }
    }

    final list = c.products.toList();
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
          title: label,
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
