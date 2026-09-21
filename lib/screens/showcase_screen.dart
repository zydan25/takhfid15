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
  final String sort;
  final BannerItem? banner;
  final List<String> linkedProductIds;

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
    this.sort = 'for_you',
    this.banner,
    this.linkedProductIds = const [],
  });

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  late String _sort;
  String? _selectedSubTab;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort;
  }

  @override
  Widget build(BuildContext context) {
    final bannerTabs = widget.banner?.subScreenTabs ?? const <BannerSubTab>[];
    final selected =
        bannerTabs.where((item) => item.id == _selectedSubTab).toList();

    List<Product> items;
    final directIds = selected.isNotEmpty
        ? selected.first.linkedProductIds
        : widget.linkedProductIds;

    if (directIds.isNotEmpty) {
      items = widget.controller.productsByIds(directIds);
      items = _sortProducts(items);
    } else {
      final mappedSub = _resolveSubCategory(widget.subCategory);

      // If the selected subcategory itself declares product IDs, use those
      // before falling back to text/category matching.
      final subLinked = _subcategoryLinkedIds(mappedSub);
      if (subLinked.isNotEmpty) {
        items = widget.controller.productsByIds(subLinked);
        items = _sortProducts(items);
      } else {
        items = widget.controller.filtered(
          category: widget.category.isEmpty ? 'all' : widget.category,
          subCategory: mappedSub,
          styleTab: widget.styleTab,
          trend: widget.trend,
          saleOnly: widget.saleOnly,
          sort: widget.saleOnly ? 'discount' : _sort,
        );
      }
    }

    final related = _relatedItems();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: widget.controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (widget.image != null && widget.image!.isNotEmpty)
              SliverToBoxAdapter(child: _hero())
            else
              SliverToBoxAdapter(child: _plainHeader()),
            if (bannerTabs.isNotEmpty)
              SliverToBoxAdapter(child: _bannerSubTabs(bannerTabs)),
            if (related.isNotEmpty && _selectedSubTab == null)
              SliverToBoxAdapter(child: _relatedStrip(related)),
            SliverToBoxAdapter(child: _sortBar()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 5),
                child: Row(
                  children: [
                    Text(
                      '${items.length} صنف',
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
            if (items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Text(
                      'لا توجد منتجات مطابقة لهذا العرض',
                      style: TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(9, 2, 9, 28),
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

  Widget _plainHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.slate200),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
            Expanded(
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SearchScreen(controller: widget.controller),
                ),
              ),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    final width = MediaQuery.sizeOf(context).width;
    final height = (width * .68).clamp(255.0, 490.0).toDouble();

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.image!,
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
                  Color(0x42000000),
                  Color(0x10000000),
                  Color(0x98000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            left: 12,
            child: Row(
              children: [
                _circleAction(
                  Icons.arrow_forward_rounded,
                  () => Navigator.pop(context),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(
                            controller: widget.controller,
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 49,
                        color: Colors.white.withOpacity(.95),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.slate500,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ابحث عن موديل، لون أو مقاس',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.slate500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.search,
                              color: AppColors.ink,
                              size: 25,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                _circleAction(
                  Icons.shopping_bag_outlined,
                  () => widget.controller.selectTab(3),
                ),
              ],
            ),
          ),
          Positioned(
            right: 15,
            left: 15,
            bottom: 18,
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
                        fontWeight: FontWeight.w700,
                        height: 1.4,
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

  Widget _circleAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(.93),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 47,
          height: 47,
          child: Icon(icon, size: 24, color: AppColors.ink),
        ),
      ),
    );
  }

  List<String> _subcategoryLinkedIds(String? subCategory) {
    if (subCategory == null || subCategory.isEmpty) return const [];

    for (final category in widget.controller.categories) {
      for (final sub in category.subCategories) {
        if (sub.id == subCategory || sub.name == subCategory) {
          if (sub.linkedProductIds.isNotEmpty) {
            return sub.linkedProductIds;
          }

          // Match same-named subcategory in another department.
          for (final siblingCategory in widget.controller.categories) {
            for (final sibling in siblingCategory.subCategories) {
              if (sibling.name == sub.name &&
                  sibling.linkedProductIds.isNotEmpty) {
                return sibling.linkedProductIds;
              }
            }
          }
        }
      }
    }

    return const [];
  }

  List<Product> _sortProducts(List<Product> input) {
    final result = input.toList();
    switch (_sort) {
      case 'discount':
        result.sort(
          (a, b) => b.discountPercentage.compareTo(a.discountPercentage),
        );
        break;
      case 'popular':
        result.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price-low':
        result.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
        break;
      case 'price-high':
        result.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
        break;
    }
    return result;
  }

  List<SubCategory> _relatedItems() {
    // For a subcategory opened from the home screen, locate its parent on the
    // server so the category page still shows the complete circular browser.
    if (widget.category.isNotEmpty && widget.category != 'all') {
      final category = widget.controller.categories
          .where((item) => item.id == widget.category)
          .toList();
      return category.isEmpty ? const [] : category.first.subCategories;
    }

    if (widget.subCategory != null && widget.subCategory!.isNotEmpty) {
      for (final category in widget.controller.categories) {
        if (category.subCategories.any(
          (sub) =>
              sub.id == widget.subCategory || sub.name == widget.subCategory,
        )) {
          return category.subCategories;
        }
      }
    }

    final all = widget.controller.categories
        .where((item) => item.id == 'all')
        .toList();
    return all.isEmpty ? const [] : all.first.subCategories;
  }

  Widget _relatedStrip(List<SubCategory> items) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 7),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final sub = items[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShowcaseScreen(
                  controller: widget.controller,
                  title: sub.name,
                  category: widget.category,
                  subCategory: sub.id.isEmpty ? sub.name : sub.id,
                  image: sub.image,
                  linkedProductIds: sub.linkedProductIds,
                ),
              ),
            ),
            child: SizedBox(
              width: 82,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
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
                  Text(
                    sub.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
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

  Widget _bannerSubTabs(List<BannerSubTab> tabs) {
    return SizedBox(
      height: 111,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
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
              width: 82,
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.slate100,
                      border: Border.all(
                        color:
                            active ? AppColors.black : AppColors.slate200,
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: tab.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: tab.image,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.grid_view_rounded),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight:
                          active ? FontWeight.w900 : FontWeight.w700,
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

  Widget _sortBar() {
    final tabs = <Map<String, dynamic>>[
      {
        'id': 'for_you',
        'label': 'التوصية',
        'icon': Icons.keyboard_arrow_down_rounded,
      },
      {
        'id': 'popular',
        'label': 'أوسع منتشرة',
        'icon': Icons.swap_vert_rounded,
      },
      {
        'id': 'price-low',
        'label': 'السعر',
        'icon': Icons.swap_vert_rounded,
      },
      {
        'id': 'filter',
        'label': 'تصنيف',
        'icon': Icons.tune_rounded,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 1, 10, 1),
      child: Row(
        children: tabs.map((tab) {
          final active = _sort == tab['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (tab['id'] == 'filter') return;
                setState(() => _sort = tab['id'] as String);
              },
              child: Container(
                height: 55,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.black : Colors.white,
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 17,
                      color: active ? Colors.white : AppColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        tab['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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

  String? _resolveSubCategory(String? value) {
    if (value == null || value.isEmpty) return null;
    final category = widget.controller.categories
        .where((item) => item.id == widget.category)
        .toList();
    if (category.isNotEmpty) {
      final matched = category.first.subCategories.where(
        (item) => item.id == value || item.name == value,
      );
      if (matched.isNotEmpty) return matched.first.id;
    }
    return value;
  }
}
