import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool wishlisted;
  final VoidCallback onOpen;
  final VoidCallback onWishlist;
  final VoidCallback onCart;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.wishlisted,
    required this.onOpen,
    required this.onWishlist,
    required this.onCart,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tall = index.isOdd;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: tall ? 3 / 4.7 : 3 / 3.65,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.page),
                  if (product.image.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 38,
                          color: AppColors.slate500,
                        ),
                      ),
                    ),
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-' +
                              product.discountPercentage.toString() +
                              '%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Material(
                      color: Colors.white.withOpacity(.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onWishlist,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            wishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: wishlisted
                                ? AppColors.rose
                                : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        product.brand,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  if (product.brand.isNotEmpty)
                    const SizedBox(height: 5),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.discountPercentage > 0)
                        Text(
                          '-' +
                              product.discountPercentage.toString() +
                              '%',
                          style: const TextStyle(
                            color: AppColors.rose,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const SizedBox(width: 5),
                      if (product.originalPrice > product.discountPrice)
                        Expanded(
                          child: Text(
                            product.originalPrice.toStringAsFixed(0) +
                                ' ر.س',
                            style: const TextStyle(
                              color: AppColors.slate500,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.roseSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.discountPrice.toStringAsFixed(2) +
                          ' ر.س' +
                          (product.couponText == null
                              ? ''
                              : '  |  بعد القسيمة'),
                      style: const TextStyle(
                        color: AppColors.rose,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '★ ' +
                              product.rating.toStringAsFixed(1) +
                              '  •  ' +
                              product.soldCount.toString() +
                              ' تم بيع',
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.slate200),
                        ),
                        child: InkWell(
                          onTap: onCart,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(
                              Icons.add_shopping_cart_outlined,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
