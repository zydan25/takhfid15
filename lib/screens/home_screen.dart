import 'dart:async';
import 'dart:math' as math;

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

    return ColoredBox(
      color: Colors.white,
      child: RefreshIndicator(
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
    // Reference screenshot is 716px wide and the hero occupies ~482px.
    // Keep the same proportion across phones.
    final bannerHeight = (width * .675).clamp(300.0, 520.0).toDouble();
    final tabs = widget.controller.homeTopTabs;
    final banner = banners.isEmpty
        ? null
        : banners[_bannerIndex.clamp(0, banners.length - 1)];

    if (banner != null && _bannerTimer == null && banners.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restartBannerTimer(banners.length),
      );
    }

    return SizedBox(
      height: bannerHeight,
      child: ClipRect(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (banners.length < 2 || velocity.abs() < 120) return;
            _bannerTimer?.cancel();
            setState(() {
              _bannerIndex = velocity > 0
                  ? (_bannerIndex - 1 + banners.length) % banners.length
                  : (_bannerIndex + 1) % banners.length;
            });
            _restartBannerTimer(banners.length);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (banner != null)
                CachedNetworkImage(
                  imageUrl: banner.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(
                    color: AppColors.slate100,
                  ),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppColors.slate100,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.slate400,
                        size: 34,
                      ),
                    ),
                  ),
                )
              else
                const ColoredBox(color: AppColors.slate100),

              if (banner != null && (banner.title.isNotEmpty || banner.subtitle.isNotEmpty))
                Positioned(
                  right: 16,
                  left: 16,
                  bottom: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (banner.badge.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.48),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            banner.badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      if (banner.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 5,
                                ),
                              ],
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
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              $overlayMarker
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .22, .72, 1],
                        colors: [
                          Color(0x18000000),
                          Color(0x05000000),
                          Color(0x00000000),
                          Color(0x16000000),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Header overlays the hero, exactly like the reference.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(13, width * .115, 13, 0),
                  child: _floatingTopBar(),
                ),
              ),

              // Server-driven top category navigation, over the banner.
              if (tabs.isNotEmpty)
                Positioned(
                  top: width * .19,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: width * .055,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: false,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: tabs.map((tab) {
                          final active = tab.id == _topCategory;
                          return GestureDetector(
                            onTap: () => _openTopCategory(tab),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 7),
                              padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: active
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: active ? 3 : 0,
                                  ),
                                ),
                              ),
                              child: Text(
                                tab.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: active
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                  height: 1,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x70000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

              if (banners.length > 1)
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      banners.length.clamp(1, 7),
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _bannerIndex ? 26 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: index == _bannerIndex
                              ? Colors.white
                              : Colors.white70,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promoMarker({
    required IconData icon,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return Material(
      color: Colors.white.withOpacity(.94),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: AppColors.ink, size: 27),
              if (badge != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: badge,
                ),
            ],
          ),
        ),
      ),
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
    final width = MediaQuery.sizeOf(context).width;
    final searchWidth = math.min(width * .615, 255.0);

    final searchHeight = width * .098;
    final actionWidth = width * .068;

    return Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _headerAction(
          icon: Icons.favorite_border_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WishlistScreen(controller: widget.controller),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: searchWidth,
          height: searchHeight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(controller: widget.controller),
                ),
              ),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.97),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.13),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Container(
                      width: searchHeight * .82,
                      height: searchHeight * .82,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8F410F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.slate500,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'ابحث عن فساتين، أحذية، ملابس أو عروض...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _headerAction(
          icon: Icons.calendar_month_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  NotificationsScreen(controller: widget.controller),
            ),
          ),
          badge: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.rose,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _headerAction(
          icon: Icons.mail_outline_rounded,
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

  Widget _headerAction({
    required IconData icon,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final actionWidth = width * .068;
    final actionHeight = width * .098;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: actionWidth,
          height: actionHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.white, size: width * .048),
              if (badge != null)
                Positioned(
                  top: actionHeight * .08,
                  right: actionWidth * .03,
                  child: badge,
                ),
            ],
          ),
        ),
      ),
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
    final width = MediaQuery.sizeOf(context).width;
    final data = widget.controller.announcements.isNotEmpty
        ? widget.controller.announcements
        : (widget.controller.storeConfig['announcements'] is Map
            ? Map<String, dynamic>.from(
                widget.controller.storeConfig['announcements'] as Map,
              )
            : <String, dynamic>{});

    if (data.isEmpty || data['isEnabled'] == false) {
      return const SizedBox.shrink();
    }

    final rawScreens = data['screens'];
    final screens = rawScreens is List
        ? rawScreens
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => item['isActive'] != false)
            .toList()
        : <Map<String, dynamic>>[];

    if (screens.isEmpty) return const SizedBox.shrink();

    screens.sort(
      (a, b) =>
          ((a['order'] is num) ? a['order'] as num : 0)
              .compareTo((b['order'] is num) ? b['order'] as num : 0),
    );

    final index =
        widget.controller.announcements['autoFlip'] == true
            ? _promoIndex % screens.length
            : 0;
    final raw = screens[index];

    if (_promoTimer == null &&
        screens.length > 1 &&
        data['autoFlip'] != false) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restartPromoTimer(
          screens.length,
        ),
      );
    }

    final bg = _parseColor(
      raw['backgroundColor'],
      const Color(0xFFFEF6EE),
    );
    final cardBg = _parseColor(
      raw['cardBackgroundColor'],
      const Color(0xFFFFF0F2),
    );
    final textColor = _parseColor(
      raw['textColor'],
      const Color(0xFF9F1239),
    );
    final border = _parseColor(
      raw['borderColor'],
      const Color(0xFFFED7AA),
    );
    final badgeBg = _parseColor(
      raw['badgeBackgroundColor'],
      AppColors.rose,
    );
    final badge = (raw['badgeText'] ?? raw['badge'] ?? '').toString();
    final title =
        (raw['mainTitle'] ?? raw['title'] ?? 'قسائم حصرية').toString();
    final subtitle =
        (raw['subTitle'] ?? raw['subtitle'] ?? 'عروض جيدة').toString();

    final rawCoupons = raw['coupons'] ?? raw['offers'] ?? raw['discounts'];
    final coupons = rawCoupons is List
        ? rawCoupons
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .take(2)
            .toList()
        : <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Container(
        height: width * .15,
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: width * .20,
                  child: Padding(
                    padding: EdgeInsets.only(top: badge.isNotEmpty ? 11 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor.withOpacity(.82),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      for (var i = 0; i < coupons.length; i++) ...[
                        if (i > 0) const SizedBox(width: 7),
                        Expanded(
                          child: Container(
                            height: width * .114,
                            padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: border.withOpacity(.8),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (coupons[i]['discount'] ??
                                          coupons[i]['discountText'] ??
                                          '')
                                      .toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  (coupons[i]['minSpend'] ??
                                          coupons[i]['minOrder'] ??
                                          coupons[i]['minimum'] ??
                                          '')
                                      .toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor.withOpacity(.82),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (badge.isNotEmpty)
              Positioned(
                right: 5,
                top: -12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: badgeBg.withOpacity(.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _promoMiniCard(Map<String, dynamic> raw) {
    final bg = _parseColor(
      raw['backgroundColor'],
      const Color(0xFFFFF8F1),
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
    final title = (raw['mainTitle'] ?? raw['title'] ?? '').toString();
    final couponRaw = raw['coupons'] ?? raw['offers'] ?? raw['discounts'];
    final coupons = couponRaw is List
        ? couponRaw.whereType<Map>().toList()
        : const <Map>[];
    final firstCoupon = coupons.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(coupons.first);
    final discount =
        (firstCoupon['discount'] ?? firstCoupon['discountText'] ?? '').toString();
    final minSpend =
        (firstCoupon['minSpend'] ?? firstCoupon['minOrder'] ?? firstCoupon['minimum'] ?? '').toString();

    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  badge.isEmpty ? title : badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.local_offer_outlined, size: 13),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  discount.isEmpty ? 'عرض متاح' : discount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (minSpend.isNotEmpty)
                Flexible(
                  child: Text(
                    minSpend,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: text.withOpacity(.72),
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
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
                      fontSize: 11,
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
                        fontSize: 7,
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
                            padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(10),
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
                                    fontSize: 12,
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
    final allMatches = c.categories.where((x) => x.id == 'all').toList();
    final allCategory = allMatches.isEmpty ? null : allMatches.first;
    final source = allCategory?.styleTabs ?? c.homeStyleTabs;
    if (source.isEmpty) return const SizedBox.shrink();

    final preferred = <String>['إطلالات يومية', 'محتشمة', 'عمل', 'حفلات'];
    final styles = <StyleTab>[];
    for (final name in preferred) {
      final found = source.where((x) => x.name == name);
      if (found.isNotEmpty) styles.add(found.first);
    }
    for (final style in source) {
      if (styles.length >= 4) break;
      if (!styles.any((x) => x.id == style.id)) styles.add(style);
    }

    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width * .202).clamp(62.0, 112.0).toDouble();
    final shape = _shape(c.styleTabsConfig['shape'], fallback: 'rounded');

    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          SizedBox(
            height: 104,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: styles.take(4).length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
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
                    height: 98,
                    child: ClipRRect(
                      borderRadius: _radius(shape, 18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          style.image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: style.image,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const ColoredBox(color: AppColors.slate100),
                                )
                              : const ColoredBox(color: AppColors.slate100),
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
                                height: 43,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5,
                            left: 5,
                            bottom: 7,
                            child: Text(
                              style.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
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
    final all = c.categories.where((x) => x.id == 'all').toList();
    final category = all.isEmpty ? null : all.first;
    if (category == null || category.subCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final lookup = <String, SubCategory>{
      for (final item in category.subCategories) item.id: item,
    };

    const referenceOrder = <String>[
      'all-dresses',
      'all-tops',
      'all-tees',
      'all-blouses',
      'all-suits',
      'all-denim',
      'all-arabic',
      'all-jackets',
      'all-knit',
      'all-bottoms',
    ];

    final items = <SubCategory>[
      ...referenceOrder
          .where(lookup.containsKey)
          .map((id) => lookup[id]!)
    ];

    // Keep the reference's first ten visible items, then append any additional
    // server categories so the horizontal rows remain genuinely scrollable.
    for (final sub in category.subCategories) {
      if (!items.any((item) => item.id == sub.id)) {
        items.add(sub);
      }
    }

    Widget tile(SubCategory sub) => GestureDetector(
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
          child: SizedBox(
            width: 59,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.slate100,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: sub.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: sub.image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(
                                Icons.category_outlined,
                                color: AppColors.slate400,
                              ),
                        )
                      : const Icon(
                          Icons.category_outlined,
                          color: AppColors.slate400,
                        ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 25,
                  child: Text(
                    sub.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8.5,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    Widget row(List<SubCategory> values) => SizedBox(
          height: 76,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            scrollDirection: Axis.horizontal,
            reverse: true,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 1),
            itemBuilder: (_, i) => tile(values[i]),
          ),
        );

    final firstRow = items.take(5).toList();
    final secondRow = items.skip(5).take(5).toList();
    final extras = items.skip(10).toList();
    if (extras.isNotEmpty) {
      firstRow.addAll(extras.take(3));
      secondRow.addAll(extras.skip(3));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 6),
      child: Column(
        children: [
          const SizedBox(height: 4),
          row(firstRow),
          if (secondRow.isNotEmpty) row(secondRow),
        ],
      ),
    );
  }

  IconData _feedIcon(String id) {
    switch (id) {
      case 'new':
        return Icons.auto_awesome_outlined;
      case 'discount':
        return Icons.sell_outlined;
      case 'popular':
        return Icons.emoji_events_outlined;
      default:
        return Icons.auto_awesome_rounded;
    }
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
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 2),
      child: SizedBox(
        height: 41,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Row(
              children: tabs.map((tab) {
                final active = tab.id == activeId;
                return GestureDetector(
                  onTap: () => setState(() => _feedTab = tab.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 118,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? Colors.black : const Color(0xFFF5F5F6),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: active ? Colors.black : const Color(0xFFE1E1E3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _feedIcon(tab.id),
                          size: 14,
                          color: active ? Colors.white : AppColors.slate500,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active ? Colors.white : AppColors.ink,
                              fontSize: 10.5,
                              fontWeight:
                                  active ? FontWeight.w900 : FontWeight.w800,
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
        ),
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
      currencyLabel: widget.controller.currency,
      pricing: widget.controller.pricing,
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

  void _openTopCategory(HomeTopTab tab) {
    setState(() => _topCategory = tab.id);

    if (tab.targetType == 'new' || tab.id == '__new') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShowcaseScreen(
            controller: widget.controller,
            title: tab.label,
            category: tab.categoryId.isEmpty ? 'all' : tab.categoryId,
            sort: 'new',
          ),
        ),
      );
      return;
    }

    if (tab.targetType == 'style') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShowcaseScreen(
            controller: widget.controller,
            title: tab.label,
            category: tab.categoryId,
            styleTab: tab.styleTab.isEmpty ? tab.label : tab.styleTab,
          ),
        ),
      );
      return;
    }

    if (tab.targetType == 'trend') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShowcaseScreen(
            controller: widget.controller,
            title: tab.label,
            category: tab.categoryId.isEmpty ? 'all' : tab.categoryId,
            trend: tab.trend.isEmpty ? null : tab.trend,
          ),
        ),
      );
      return;
    }

    final categoryId =
        tab.categoryId.isEmpty ? tab.id : tab.categoryId;
    final matched = widget.controller.categories
        .where((item) => item.id == categoryId)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowcaseScreen(
          controller: widget.controller,
          title: tab.label,
          category: categoryId,
          subCategory: tab.subCategoryId.isEmpty ? null : tab.subCategoryId,
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
