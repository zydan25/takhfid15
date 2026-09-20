import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../state/store_controller.dart';

class ProductDetailsScreen extends StatefulWidget {
  final StoreController controller;
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.controller,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  ProductColor? color;
  String? size;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    color = widget.product.colors.isNotEmpty
        ? widget.product.colors.first
        : null;
    size = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => widget.controller.toggleWishlist(p),
            icon: Icon(
              widget.controller.isWishlisted(p)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: widget.controller.isWishlisted(p)
                  ? AppColors.rose
                  : null,
            ),
          ),
          IconButton(
            onPressed: () => widget.controller.selectTab(3),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 400,
            child: PageView.builder(
              itemCount: p.gallery.isEmpty ? 1 : p.gallery.length,
              itemBuilder: (_, index) {
                final image = p.gallery.isEmpty ? p.image : p.gallery[index];
                if (image.isEmpty) {
                  return const ColoredBox(
                    color: AppColors.page,
                    child: Center(
                      child: Icon(Icons.image_outlined, size: 50),
                    ),
                  );
                }
                return Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.page,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 50),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 14, 13, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.brand,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      '★ ' + p.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '(' + p.reviewsCount.toString() + ')',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      p.soldCount.toString() + ' تم بيع',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      p.discountPrice.toStringAsFixed(2) + ' ' + widget.controller.currency,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.rose,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.originalPrice.toStringAsFixed(0) + ' ' + widget.controller.currency,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.roseSoft,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '-' + p.discountPercentage.toString() + '%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.rose,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (p.description.isNotEmpty)
                  Text(
                    p.description,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      color: AppColors.slate500,
                    ),
                  ),
                if (p.colors.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'اللون',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    children: p.colors.map((value) {
                      return ChoiceChip(
                        label: Text(
                          value.name,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        selected: color?.hex == value.hex,
                        onSelected: (_) => setState(() => color = value),
                      );
                    }).toList(),
                  ),
                ],
                if (p.sizes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'المقاس',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: p.sizes.map((value) {
                      return ChoiceChip(
                        label: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        selected: size == value,
                        onSelected: (_) => setState(() => size = value),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'الكمية',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() {
                        quantity = quantity <= 1 ? 1 : quantity - 1;
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: () => setState(() => quantity += 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.controller.addToCart(
                        p,
                        color: color,
                        size: size,
                        quantity: quantity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تمت إضافة الصنف إلى السلة'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'أضف إلى حقيبة التسوق',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.controller.toggleWishlist(p),
                        child: Text(
                          widget.controller.isWishlisted(p)
                              ? 'إزالة من المفضلة'
                              : 'أضف للمفضلة',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showSizeGuide(context),
                        child: const Text(
                          'دليل المقاسات',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _info('الشحن إلى اليمن',
                    'تكلفة الشحن وطريقته تتغير حسب المحافظة وإعدادات الخادم.'),
                _info('التقييمات والمراجعات',
                    'تصميم منطقة المراجعات مطابق للنسخة المرجعية، ويُستكمل مصدر البيانات عند تثبيت عقد API المخصص للمراجعات.'),
                _info('ربما يعجبك أيضاً',
                    'أصناف مقترحة مرتبطة بالفئة والترند الحالي.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String title, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(text,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.slate500,
                height: 1.5,
              )),
        ],
      ),
    );
  }

  void _showSizeGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(18, 6, 18, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('دليل المقاسات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            SizedBox(height: 9),
            Text(
              'استخدم قياسات المنتج الفعلية وقارنها بقياسات جسمك قبل اختيار المقاس.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.slate500,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
