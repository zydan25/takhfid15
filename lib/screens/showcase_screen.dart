import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';

class ShowcaseScreen extends StatelessWidget {
  final StoreController controller;
  final String title;
  final String subtitle;
  final String? image;
  final String category;
  final String? subCategory;
  final String? styleTab;
  final bool saleOnly;

  const ShowcaseScreen({
    super.key,
    required this.controller,
    required this.title,
    this.subtitle = '',
    this.image,
    this.category = 'all',
    this.subCategory,
    this.styleTab,
    this.saleOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = controller.filtered(
      category: category,
      subCategory: subCategory,
      styleTab: styleTab,
      saleOnly: saleOnly,
      sort: saleOnly ? 'discount' : 'for_you',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(controller: controller),
              ),
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => controller.selectTab(3),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (image != null && image!.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 230,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: image!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.ink,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x10000000),
                            Color(0xD8000000),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                height: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 5),
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
                  if (saleOnly)
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, row) {
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
                                wishlisted:
                                    controller.isWishlisted(items[right]),
                                onOpen: () => _open(context, items[right]),
                                onWishlist: () => controller
                                    .toggleWishlist(items[right]),
                                onCart: () =>
                                    controller.addToCart(items[right]),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ProductCard(
                          product: items[left],
                          index: left,
                          wishlisted:
                              controller.isWishlisted(items[left]),
                          onOpen: () => _open(context, items[left]),
                          onWishlist: () =>
                              controller.toggleWishlist(items[left]),
                          onCart: () =>
                              controller.addToCart(items[left]),
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: (items.length / 2).ceil(),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 18),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          controller: controller,
          product: product,
        ),
      ),
    );
  }
}
