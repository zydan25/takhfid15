import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';

class TrendsScreen extends StatefulWidget {
  final StoreController controller;
  const TrendsScreen({super.key, required this.controller});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  String selected = '';

  @override
  Widget build(BuildContext context) {
    final term = selected.toLowerCase();
    final items = term.isEmpty
        ? widget.controller.products
        : widget.controller.products.where((product) {
            return product.name.toLowerCase().contains(term) ||
                product.description.toLowerCase().contains(term) ||
                product.category.toLowerCase().contains(term);
          }).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'ترندات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(controller: widget.controller),
                ),
              ),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () => widget.controller.selectTab(3),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ],
        ),
        SliverToBoxAdapter(child: _campaigns()),
        if (widget.controller.hashtags.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 49,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: widget.controller.hashtags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, index) {
                  final tag = widget.controller.hashtags[index];
                  final active = tag == selected;
                  return ChoiceChip(
                    selected: active,
                    selectedColor: AppColors.black,
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.ink,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => selected = active ? '' : tag);
                    },
                  );
                },
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
                              wishlisted: widget.controller
                                  .isWishlisted(items[right]),
                              onOpen: () => _open(items[right]),
                              onWishlist: () => widget.controller
                                  .toggleWishlist(items[right]),
                              onCart: () =>
                                  widget.controller.addToCart(items[right]),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: ProductCard(
                        product: items[left],
                        index: left,
                        wishlisted:
                            widget.controller.isWishlisted(items[left]),
                        onOpen: () => _open(items[left]),
                        onWishlist: () =>
                            widget.controller.toggleWishlist(items[left]),
                        onCart: () =>
                            widget.controller.addToCart(items[left]),
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: (items.length / 2).ceil(),
          ),
        ),
      ],
    );
  }

  Widget _campaigns() {
    final campaigns = widget.controller.campaigns;
    if (campaigns.isEmpty) {
      return Container(
        height: 205,
        color: AppColors.ink,
        alignment: Alignment.center,
        child: const Text(
          'عروض الترند',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return SizedBox(
      height: 205,
      child: PageView(
        children: campaigns.map((campaign) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (campaign.image.isNotEmpty)
                Image.network(campaign.image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x99000000),
                      Color(0x14000000),
                      Color(0xCC000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (campaign.tag.isNotEmpty)
                      Text(
                        campaign.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    Text(
                      campaign.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (campaign.subtitle.isNotEmpty)
                      Text(
                        campaign.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _open(dynamic product) {
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
}
