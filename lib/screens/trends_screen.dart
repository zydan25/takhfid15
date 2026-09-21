import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/content.dart';
import '../models/product.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';
import 'wishlist_screen.dart';

class TrendsScreen extends StatefulWidget {
  final StoreController controller;

  const TrendsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  int campaignIndex = 0;
  String selectedHash = '';
  String search = '';
  String sort = 'none';
  bool recommendedOnly = false;
  bool popularOnly = false;
  bool fastShippingOnly = false;
  bool listView = false;

  @override
  Widget build(BuildContext context) {
    final campaigns = widget.controller.campaigns.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final campaign = campaigns.isEmpty
        ? null
        : campaigns[campaignIndex.clamp(0, campaigns.length - 1)];

    final base = _campaignProducts(campaign);
    final filtered = _filterProducts(base);

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: widget.controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (campaign != null)
            SliverToBoxAdapter(child: _hero(campaign))
          else
            const SliverToBoxAdapter(child: SizedBox(height: 250)),
          SliverToBoxAdapter(child: _campaignsStrip(campaigns)),
          SliverToBoxAdapter(child: _hashtags()),
          SliverToBoxAdapter(child: _filters(filtered.length)),
          if (filtered.isEmpty)
            SliverToBoxAdapter(child: _empty())
          else if (listView)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _product(filtered[index], index),
                  ),
                  childCount: filtered.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, index) => _product(filtered[index], index),
                  childCount: filtered.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 9,
                  childAspectRatio: .61,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _topBar(TrendCampaign? campaign) {
    final placeholder =
        campaign?.title.isNotEmpty == true ? campaign!.title : 'ترندات الفساتين والحفلات الساحرة';

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          child: Row(
            children: [
              IconButton(
                onPressed: () => widget.controller.selectTab(3),
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WishlistScreen(controller: widget.controller),
                  ),
                ),
                icon: const Icon(Icons.favorite_border_rounded),
              ),
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F6),
                    border: Border.all(color: const Color(0xFFE0E1E5)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _openSearch,
                        child: Container(
                          width: 30,
                          height: 30,
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => search = value),
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: placeholder,
                            hintStyle: const TextStyle(
                              fontSize: 10,
                              color: AppColors.slate400,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showInfo('تم تفعيل البحث بالصور 📷'),
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          size: 17,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              IconButton(
                onPressed: () => setState(() => listView = !listView),
                icon: Icon(
                  listView ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(TrendCampaign campaign) {
    final width = MediaQuery.sizeOf(context).width;
    final height = (width * .93).clamp(470.0, 690.0).toDouble();
    final linked = widget.controller.productsByIds(campaign.productIds);
    final preview = (linked.isNotEmpty ? linked : widget.controller.products)
        .take(3)
        .toList();

    return GestureDetector(
      onTap: () => _openCampaign(campaign),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: campaign.bgImage.isNotEmpty
                  ? campaign.bgImage
                  : campaign.image,
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
                    Color(0x28000000),
                    Color(0x08000000),
                    Color(0xD0000000),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    IconButton(
                      onPressed: _openSearch,
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 29,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'ترندات',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Color(0x80000000),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 11,
              right: 11,
              bottom: 15,
              child: Container(
                padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
                decoration: BoxDecoration(
                  color: const Color(0xCE171713),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(.28),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x60000000),
                      blurRadius: 18,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (campaign.daysLeft.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B20DD),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                campaign.daysLeft,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              campaign.hashtag + ' ' + campaign.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (campaign.subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            campaign.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (preview.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: SizedBox(
                            height: 208,
                            child: Row(
                              children: preview.map((product) {
                                final image = _primaryImage(product);
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _openProduct(product),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          6,
                                          6,
                                          6,
                                          5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: image.isEmpty
                                                    ? const ColoredBox(
                                                        color:
                                                            AppColors.slate100,
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.image_outlined,
                                                            color:
                                                                AppColors.slate400,
                                                          ),
                                                        ),
                                                      )
                                                    : CachedNetworkImage(
                                                        imageUrl: image,
                                                        fit: BoxFit.cover,
                                                        width:
                                                            double.infinity,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              product.brand.isEmpty
                                                  ? 'SHEIN'
                                                  : product.brand,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              product.discountPrice
                                                      .toStringAsFixed(2) +
                                                  ' ' +
                                                  widget.controller.currency,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hashtags() {
    final tags = widget.controller.hashtags.toList();
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: tags.length,
          separatorBuilder: (_, __) => const SizedBox(width: 5),
          itemBuilder: (_, index) {
            final tag = tags[index];
            final active = tag == selectedHash;
            return ChoiceChip(
              selected: active,
              selectedColor: Colors.black,
              side: BorderSide(
                color: active ? Colors.black : const Color(0xFFE1E1E3),
              ),
              label: Text(
                tag,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.ink,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onSelected: (_) => setState(() {
                selectedHash = active ? '' : tag;
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _filters(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: _filterButton(
              recommendedOnly ? 'التوصية ✓' : 'التوصية',
              onTap: () => setState(() => recommendedOnly = !recommendedOnly),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _filterButton(
              popularOnly ? 'أوسع منتشرة ✓' : 'أوسع منتشرة',
              onTap: () => setState(() => popularOnly = !popularOnly),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(child: _sortButton()),
          const SizedBox(width: 5),
          Expanded(
            child: _filterButton(
              fastShippingOnly ? 'تصنيف ✓' : 'تصنيف',
              onTap: _openFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(
    String label, {
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F4F2),
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: Color(0xFFE0DDD8)),
          padding: const EdgeInsets.symmetric(horizontal: 3),
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _sortButton() {
    final label = sort == 'desc'
        ? 'السعر ↓'
        : sort == 'asc'
            ? 'السعر ↑'
            : 'السعر';

    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: () => setState(() {
          sort = sort == 'none'
              ? 'desc'
              : sort == 'desc'
                  ? 'asc'
                  : 'none';
        }),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              sort == 'none' ? const Color(0xFFF5F4F2) : Colors.black,
          foregroundColor:
              sort == 'none' ? AppColors.ink : Colors.white,
          side: const BorderSide(color: Color(0xFFE0DDD8)),
          padding: const EdgeInsets.symmetric(horizontal: 3),
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  List<Product> _campaignProducts(TrendCampaign? campaign) {
    if (campaign == null) return widget.controller.products;

    final linked = widget.controller.productsByIds(campaign.productIds);
    if (linked.isNotEmpty) return linked;

    final terms = <String>[
      campaign.hashtag,
      ...campaign.title.split(' '),
      ...campaign.subtitle.split(' '),
    ]
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.length > 2)
        .toSet();

    final matched = widget.controller.products.where((product) {
      final values = <String>[
        ...product.trends,
        product.name,
        product.description,
        product.subCategory,
        ...product.subCategories,
      ].map((value) => value.toLowerCase());

      return terms.any(
        (term) => values.any((value) => value.contains(term)),
      );
    }).toList();

    return matched.isNotEmpty ? matched : widget.controller.products;
  }

  List<Product> _filterProducts(List<Product> input) {
    var result = input.toList();

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((product) {
        final values = <String>[
          product.name,
          product.description,
          product.brand,
          product.sku,
          ...product.trends,
        ].map((value) => value.toLowerCase());
        return values.any((value) => value.contains(q));
      }).toList();
    }

    if (selectedHash.isNotEmpty) {
      final hash = selectedHash.toLowerCase();
      final matched = result.where((product) {
        return product.trends
            .map((item) => item.toLowerCase())
            .any((item) => item.contains(hash));
      }).toList();
      if (matched.isNotEmpty) result = matched;
    }

    if (recommendedOnly) {
      final recommended = result
          .where((p) => p.serverData['isRecommended'] == true)
          .toList();
      result = recommended.isNotEmpty
          ? recommended
          : result.where((p) => p.rating >= 4.8).toList();
    }

    if (popularOnly) {
      final popular = result
          .where((p) => p.serverData['isMostPopular'] == true)
          .toList();
      result = popular.isNotEmpty
          ? popular
          : result
              .where((p) => p.soldCount > 0 || p.reviewsCount >= 100)
              .toList();
    }

    if (fastShippingOnly) {
      result = result.where(
        (p) =>
            p.serverData['isLocalFastShipping'] == true ||
            p.serverData['showCardShipping'] == true,
      ).toList();
    }

    if (sort == 'asc') {
      result.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
    } else if (sort == 'desc') {
      result.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
    }

    return result;
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

  Widget _empty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 45,
            color: AppColors.slate400,
          ),
          SizedBox(height: 10),
          Text(
            'لا توجد أصناف مطابقة للتصفية الحالية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'أعد ضبط الفلاتر أو اختر تشكيلة أخرى من الأعلى.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'تصنيف وتصفية الأصناف',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'الفلاتر مبنية من بيانات المنتجات القادمة من الخادم.',
                style: TextStyle(fontSize: 9, color: AppColors.slate500),
              ),
              const SizedBox(height: 12),
              _filterSection(
                'حسب نوع الصنف',
                _values((p) => p.serverData['productType']),
              ),
              _filterSection(
                'حسب اللون',
                widget.controller.products
                    .expand((p) => p.colors.map((c) => c.name))
                    .where((v) => v.trim().isNotEmpty)
                    .toSet()
                    .toList(),
              ),
              _filterSection(
                'حسب الخامة / القماش',
                _values(
                  (p) => [
                    p.serverData['material'],
                    p.serverData['fabric'],
                    p.serverData['materials'],
                  ],
                ),
              ),
              _filterSection(
                'حسب المقاس',
                widget.controller.products
                    .expand((p) => p.sizes)
                    .where((v) => v.trim().isNotEmpty)
                    .toSet()
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSection(String title, List<String> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 5,
            runSpacing: 5,
            children: values
                .map(
                  (value) => Chip(
                    label: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> _values(dynamic Function(Product) getter) {
    final values = <String>[];
    for (final product in widget.controller.products) {
      final value = getter(product);
      if (value is List) {
        values.addAll(
          value
              .where((item) => item != null)
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty),
        );
      } else if (value != null && value.toString().trim().isNotEmpty) {
        values.add(value.toString());
      }
    }
    return values.toSet().toList()..sort();
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(controller: widget.controller),
      ),
    );
  }

  void _showInfo(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }
}
