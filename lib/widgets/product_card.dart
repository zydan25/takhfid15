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
  final String currencyLabel;
  final Map<String, dynamic>? pricing;

  const ProductCard({
    super.key,
    required this.product,
    required this.wishlisted,
    required this.onOpen,
    required this.onWishlist,
    required this.onCart,
    this.index = 0,
    this.currencyLabel = 'YER',
    this.pricing,
  });

  double _rate(String currency) {
    final data = pricing ?? const <String, dynamic>{};

    double value(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    final direct = currency == 'SAR'
        ? value(data['sarToYerRateNorth'] ?? data['sarRate'])
        : currency == 'USD'
            ? value(data['usdToYerRateNorth'] ?? data['usdRate'])
            : 1.0;

    if (direct > 0) return direct;

    final sanaa = data['صنعاء'];
    if (sanaa is Map) {
      final nested = currency == 'SAR'
          ? value(sanaa['sarToYerRate'] ?? sanaa['sarRate'])
          : currency == 'USD'
              ? value(sanaa['usdToYerRate'] ?? sanaa['usdRate'])
              : 1.0;
      if (nested > 0) return nested;
    }

    return currency == 'SAR' ? 140 : currency == 'USD' ? 535 : 1;
  }

  String _displayPrice(double yerAmount) {
    switch (currencyLabel.toUpperCase()) {
      case 'SAR':
        return '${(yerAmount / _rate('SAR')).toStringAsFixed(2)} ر.س';
      case 'USD':
        return '${(yerAmount / _rate('USD')).toStringAsFixed(2)}';
      default:
        return '${yerAmount.toStringAsFixed(0)} ر.ي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tall = index.isOdd;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: tall ? 3 / 4.5 : 3 / 3.8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.slate100),
                  if (product.image.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.slate300),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rose.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.white.withOpacity(0.95),
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: InkWell(
                        onTap: onWishlist,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            wishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
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
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.brand,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C3AED),
                          height: 1,
                        ),
                      ),
                    ),
                  if (product.brand.isNotEmpty)
                    const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (product.discountPercentage > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.roseSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${product.discountPercentage}%',
                            style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      if (product.discountPercentage > 0)
                        const SizedBox(width: 6),
                      if (product.originalPrice > product.discountPrice)
                        Expanded(
                          child: Text(
                            _displayPrice(product.originalPrice),
                            style: const TextStyle(
                              color: AppColors.slate400,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _displayPrice(product.discountPrice),
                        style: const TextStyle(
                          color: AppColors.rose,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      if (product.couponText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'قسيمة',
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.slate500,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${product.soldCount} تم بيع',
                              style: const TextStyle(
                                color: AppColors.slate400,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: AppColors.white,
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.slate200, width: 1),
                        ),
                        elevation: 1,
                        shadowColor: Colors.black.withOpacity(0.05),
                        child: InkWell(
                          onTap: onCart,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.add_shopping_cart_outlined,
                              size: 16,
                              color: AppColors.ink,
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
