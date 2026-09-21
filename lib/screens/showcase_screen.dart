import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/content.dart';
import '../models/product.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';

class ShowcaseScreen extends StatefulWidget {
  final StoreController controller;
  final String title;
  final String subtitle;
  final String? image;
  final String category;
  final String? subCategory;
  final String? styleTab;
  final String? trend;
  final bool saleOnly;
  final BannerItem? banner;

  const ShowcaseScreen({
    super.key,
    required this.controller,
    required this.title,
    this.subtitle = '',
    this.image,
    this.category = 'all',
    this.subCategory,
    this.styleTab,
    this.trend,
    this.saleOnly = false,
    this.banner,
  });

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  String? _selectedSubTab;

  @override
  Widget build(BuildContext context) {
    final bannerTabs = widget.banner?.subScreenTabs ?? const <BannerSubTab>[];
    final selected = bannerTabs.where((item) => item.id == _selectedSubTab).toList();

    List<Product> items;
    if (selected.isNotEmpty && selected.first.linkedProductIds.isNotEmpty) {
      items = widget.controller.productsByIds(selected.first.linkedProductIds);
    } else {
      final mappedSub = _resolveSubCategory(widget.subCategory);
      items = widget.controller.filtered(
        category: widget.category.isEmpty ? 'all' : widget.category,
        subCategory: mappedSub,
        styleTab: widget.styleTab,
        trend: widget.trend,
        saleOnly: widget.saleOnly,
        sort: widget.saleOnly ? 'discount' : 'for_you',
      );

      if (selected.isNotEmpty) {
        final name = selected.first.name;
        if (items.isEmpty) {
          final keywords = name.split(RegExp(r'\s+')).where((x) => x.length > 2).toList();
          items = widget.controller.products.where((product) {
            final haystack = product.name + ' ' + product.description + ' ' + product.category;
            return keywords.any((key) => haystack.contains(key));
          }).toList();
          if (name.contains('أسعار')) {
            items.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
          }
        }
      }
    }

    final shownSubcategories = _categorySubcategories();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SearchScreen(controller: widget.controller)),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => widget.controller.selectTab(3),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: widget.controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (widget.image != null && widget.image!.isNotEmpty)
              SliverToBoxAdapter(child: _hero()),
            if (bannerTabs.isNotEmpty)
              SliverToBoxAdapter(child: _bannerSubTabs(bannerTabs)),
            if (shownSubcategories.isNotEmpty && widget.subCategory == null && _selectedSubTab == null)
              SliverToBoxAdapter(child: _subcategoryGrid(shownSubcategories)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 12, 11, 5),
                child: Row(
                  children: [
                    Text(
                      items.length.toString() + ' صنف',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (widget.saleOnly)
                      const Text(
                        'الأعلى خصمًا',
                        style: TextStyle(
                          color: AppColors.rose,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(9, 2, 9, 22),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, row) {
                    final left = row * 2;
                    final right = left + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: right < items.length
                                ? _product(items[right], right)
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 7),
                          Expanded(child: _product(items[left], left)),
                        ],
                      ),
                    );
                  },
                  childCount: (items.length / 2).ceil(),
                ),
              ),
            ),
          ],
        ),
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

  Widget _hero() {
    return SizedBox(
      height: 228,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.image!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.ink),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x12000000), Color(0xD8000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            right: 13,
            left: 13,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                if (widget.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerSubTabs(List<BannerSubTab> tabs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(11, 11, 11, 2),
          child: Text(
            'تصفح العرض',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
        SizedBox(
          height: 107,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 7),
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (_, index) {
              final tab = tabs[index];
              final active = tab.id == _selectedSubTab;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedSubTab = active ? null : tab.id;
                }),
                child: SizedBox(
                  width: 75,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.slate100,
                          border: Border.all(
                            color: active ? AppColors.black : AppColors.slate200,
                            width: active ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: tab.image.isNotEmpty
                            ? CachedNetworkImage(imageUrl: tab.image, fit: BoxFit.cover)
                            : const Icon(Icons.grid_view_rounded, color: AppColors.slate400),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                          color: active ? AppColors.ink : AppColors.slate500,
                          height: 1.1,
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

  List<SubCategory> _categorySubcategories() {
    final category = widget.controller.categories
        .where((item) => item.id == widget.category)
        .cast<Category?>()
        .firstWhere((item) => item != null, orElse: () => null);
    return category?.subCategories ?? const <SubCategory>[];
  }

  String? _resolveSubCategory(String? value) {
    if (value == null || value.isEmpty) return null;
    final category = widget.controller.categories.where((item) => item.id == widget.category);
    if (category.isNotEmpty) {
      final matched = category.first.subCategories.where(
        (item) => item.id == value || item.name == value,
      );
      if (matched.isNotEmpty) return matched.first.id;
    }
    return value;
  }

  Widget _subcategoryGrid(List<SubCategory> items) {
    final shape = (widget.controller.categoryTabsConfig['shape'] ?? 'circle').toString();
    final size = (widget.controller.categoryTabsConfig['size'] ?? 'medium').toString();
    final dimension = size == 'small' ? 62.0 : size == 'large' ? 82.0 : 72.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(11, 10, 11, 4),
          child: Text(
            'استكشف التصنيفات',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Wrap(
            spacing: 8,
            runSpacing: 10,
            children: items.map((sub) {
              final radius = shape == 'circle'
                  ? 100.0
                  : shape == 'curved'
                      ? 22.0
                      : shape == 'rounded'
                          ? 14.0
                          : 3.0;
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 38) / 4,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowcaseScreen(
                        controller: widget.controller,
                        title: sub.name,
                        category: widget.category,
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
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(radius),
                          shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                          border: Border.all(color: AppColors.slate200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: sub.image.isNotEmpty
                            ? CachedNetworkImage(imageUrl: sub.image, fit: BoxFit.cover)
                            : const Icon(Icons.category_outlined),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
