import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/product.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';

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
  late final PageController _galleryController;
  int _imageIndex = 0;
  ProductColor? _color;
  String? _size;
  int _quantity = 1;
  late Product _detailProduct;
  bool _loadingFullProduct = false;

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
    _detailProduct = widget.product;
    _color = _detailProduct.colors.isNotEmpty ? _detailProduct.colors.first : null;
    _size = _detailProduct.sizes.isNotEmpty ? _detailProduct.sizes.first : null;
    _loadFullProduct();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  List<String> get _images {
    final result = <String>[];

    void add(String value) {
      final image = value.trim();
      if (image.isNotEmpty && !result.contains(image)) {
        result.add(image);
      }
    }

    for (final image in _detailProduct.gallery) {
      add(image);
    }

    final color = _color;
    if (color != null) {
      for (final image in color.images) {
        add(image);
      }
      if (color.image != null) {
        add(color.image!);
      }
    }

    add(_detailProduct.image);

    if (color != null && color.images.isNotEmpty) {
      return <String>[
        ...color.images.where(result.contains),
        ...result.where((image) => !color.images.contains(image)),
      ];
    }

    return result;
  }

  Future<void> _loadFullProduct() async {
    if (_loadingFullProduct) return;
    _loadingFullProduct = true;
    try {
      final full = await widget.controller.api.fetchProductById(_detailProduct.id);
      if (!mounted || full == null) return;
      if (full.id != _detailProduct.id) return;
      setState(() {
        _detailProduct = full;
        _color = _color == null
            ? (full.colors.isNotEmpty ? full.colors.first : null)
            : full.colors.firstWhere(
                (item) => item.hex == _color!.hex,
                orElse: () => full.colors.isNotEmpty ? full.colors.first : _color!,
              );
        _size = _size != null && full.sizes.contains(_size)
            ? _size
            : (full.sizes.isNotEmpty ? full.sizes.first : null);
      });
    } catch (_) {
      // The list response remains usable when the detail endpoint is unavailable.
    } finally {
      _loadingFullProduct = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _detailProduct;
    final images = _images;
    final related = widget.controller
        .filtered(category: p.category, sort: 'for_you')
        .where((x) => x.id != p.id)
        .take(6)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'تفاصيل المنتج',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await widget.controller.toggleWishlist(p);
              if (mounted) setState(() {});
            },
            icon: Icon(
              widget.controller.isWishlisted(p)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: widget.controller.isWishlisted(p) ? AppColors.rose : null,
            ),
          ),
          IconButton(
            onPressed: () => widget.controller.selectTab(3),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColors.slate200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.07),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.roseSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  p.discountPrice.toStringAsFixed(0) + ' ' + widget.controller.currency,
                  style: const TextStyle(
                    color: AppColors.rose,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.controller.addToCart(
                        p,
                        color: _color,
                        size: _size,
                        quantity: _quantity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إضافة الصنف إلى حقيبة التسوق')),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 19),
                    label: const Text(
                      'أضف إلى حقيبة التسوق',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _gallery(images)),
          SliverToBoxAdapter(child: _summary(p)),
          if (p.colors.isNotEmpty)
            SliverToBoxAdapter(child: _colorSelector(p)),
          if (p.sizes.isNotEmpty)
            SliverToBoxAdapter(child: _sizeSelector(p)),
          SliverToBoxAdapter(child: _quantitySelector()),
          SliverToBoxAdapter(child: _trustAndPolicyCards(p)),
          SliverToBoxAdapter(child: _shippingCard()),
          SliverToBoxAdapter(child: _serverDetailsCard(p)),
          SliverToBoxAdapter(child: _reviewsCard(p)),
          if (related.isNotEmpty)
            SliverToBoxAdapter(child: _related(related)),
          const SliverToBoxAdapter(child: SizedBox(height: 15)),
        ],
      ),
    );
  }

  Widget _gallery(List<String> images) {
    return Column(
      children: [
        SizedBox(
          height: 405,
          child: Stack(
            children: [
              PageView.builder(
                controller: _galleryController,
                physics: const BouncingScrollPhysics(),
                itemCount: images.isEmpty ? 1 : images.length,
                onPageChanged: (index) {
                  if (mounted) setState(() => _imageIndex = index);
                },
                itemBuilder: (_, index) {
                  final image = images.isEmpty ? '' : images[index];
                  return Container(
                    color: AppColors.slate50,
                    child: image.isEmpty
                        ? const Center(
                            child: Icon(Icons.image_outlined, size: 52, color: AppColors.slate300),
                          )
                        : CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined, size: 48),
                            ),
                          ),
                  );
                },
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.62),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    images.isEmpty ? '1 / 1' : (_imageIndex + 1).toString() + ' / ' + images.length.toString(),
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
        ),

        if (images.length > 1)
          SizedBox(
            height: 76,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, index) {
                final active = index == _imageIndex;
                return GestureDetector(
                  onTap: () => _galleryController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  ),
                  child: Container(
                    width: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: active ? AppColors.black : AppColors.slate200,
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length.clamp(1, 9),
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: index == _imageIndex ? 18 : 5,
                  height: 4,
                  decoration: BoxDecoration(
                    color: index == _imageIndex ? AppColors.black : AppColors.slate300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _summary(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.brand.isNotEmpty)
            Text(
              p.brand,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.slate500,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            p.name,
            style: const TextStyle(
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
              const SizedBox(width: 2),
              Text(
                p.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 5),
              Text(
                '(' + p.reviewsCount.toString() + ' تقييم)',
                style: const TextStyle(fontSize: 9, color: AppColors.slate500),
              ),
              const Spacer(),
              Text(
                p.soldCount.toString() + ' تم بيع',
                style: const TextStyle(fontSize: 9, color: AppColors.slate500, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            children: [
              Text(
                p.discountPrice.toStringAsFixed(0) + ' ' + widget.controller.currency,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.rose,
                ),
              ),
              if (p.originalPrice > p.discountPrice)
                Text(
                  p.originalPrice.toStringAsFixed(0) + ' ' + widget.controller.currency,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate400,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (p.discountPercentage > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.roseSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-' + p.discountPercentage.toString() + '%',
                    style: const TextStyle(
                      color: AppColors.rose,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.description,
              style: const TextStyle(
                color: AppColors.slate500,
                fontSize: 10,
                height: 1.65,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _colorSelector(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اللون', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: p.colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final value = p.colors[index];
                final active = _color?.hex == value.hex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _color = value);
                    final colorImage = value.images.isNotEmpty
                        ? value.images.first
                        : value.image;
                    if (colorImage != null && colorImage.isNotEmpty) {
                      final target = _images.indexOf(colorImage);
                      if (target >= 0) {
                        _galleryController.animateToPage(
                          target,
                          duration: const Duration(milliseconds: 230),
                          curve: Curves.easeOut,
                        );
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _parseHex(value.hex),
                      border: Border.all(
                        color: active ? AppColors.black : AppColors.slate200,
                        width: active ? 3 : 1,
                      ),
                      boxShadow: active
                          ? [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 7)]
                          : null,
                    ),
                    child: active
                        ? const Icon(Icons.check, color: Colors.white, size: 19)
                        : null,
                  ),
                );
              },
            ),
          ),
          if (_color != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _color!.name,
                style: const TextStyle(fontSize: 9, color: AppColors.slate500, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sizeSelector(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المقاس', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: p.sizes.map((value) {
              final active = _size == value;
              return GestureDetector(
                onTap: () => setState(() => _size = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  constraints: const BoxConstraints(minWidth: 46),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.black : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active ? AppColors.black : AppColors.slate200,
                    ),
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _quantitySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 3),
      child: Row(
        children: [
          const Text('الكمية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    if (_quantity > 1) _quantity--;
                  }),
                  icon: const Icon(Icons.remove, size: 17),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    _quantity.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _quantity = (_quantity + 1).clamp(1, 99)),
                  icon: const Icon(Icons.add, size: 17),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustAndPolicyCards(Product p) {
    final raw = p.serverData;

    dynamic firstValue(List<String> keys) {
      for (final key in keys) {
        final value = raw[key];
        if (value == null) continue;
        if (value is String && value.trim().isEmpty) continue;
        return value;
      }
      return null;
    }

    final governorate =
        (widget.controller.profile?['governorate'] ?? 'أمانة العاصمة')
            .toString();

    final shippingTarget = (firstValue(
              ['shippingDestination', 'shippingTitle', 'deliveryDestination'],
            ) ??
            'الشحن إلى اليمن • $governorate')
        .toString();

    final freeShipping =
        (firstValue(['freeShippingText', 'freeDeliveryText']) ??
                'شحن مجاني (للطلبات ≥ 99.00 ر.س)')
            .toString();

    final deliveryNote =
        (firstValue(['deliveryNote', 'deliveryText', 'shippingText']) ??
                'التوصيل المتوقع: خلال 3 - 5 أيام عمل (إلى باب منزلك في $governorate)')
            .toString();

    final couponText =
        (firstValue(['couponShippingText', 'shippingCouponText']) ??
                'انضم للحصول على 15X كوبونات شحن مجاني (بقيمة 450.00 ر.س)')
            .toString();

    final returnText =
        (firstValue(['returnPolicyText', 'returnsText', 'returnPolicy']) ??
                'إرجاع مجاني خلال 14 يوم')
            .toString();

    final paymentText =
        (firstValue(['paymentPolicyText', 'paymentsText', 'paymentMethods']) ??
                'الدفع عند الاستلام متاح • مدفوعات آمنة • حماية الخصوصية 100%')
            .toString();

    final sellerText =
        (firstValue(['sellerText', 'sellerPolicyText', 'sellerName']) ??
                'تم البيع بواسطة التخفيض الصح المعتمد')
            .toString();

    final rows = <(IconData, String, String, Color)>[
      (
        Icons.location_on_outlined,
        shippingTarget,
        '',
        AppColors.slate500,
      ),
      (
        Icons.local_shipping_outlined,
        freeShipping,
        deliveryNote,
        AppColors.emerald,
      ),
      (
        Icons.local_offer_outlined,
        couponText,
        '',
        AppColors.amber,
      ),
      (
        Icons.rotate_left_rounded,
        returnText,
        '',
        AppColors.slate500,
      ),
      (
        Icons.verified_user_outlined,
        paymentText,
        '',
        AppColors.emerald,
      ),
      (
        Icons.storefront_outlined,
        sellerText,
        '',
        AppColors.ink,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 7, 0, 4),
      color: Colors.white,
      child: Column(
        children: rows.map((row) {
          return Container(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.slate200,
                  width: .7,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  row.$1,
                  color: row.$4,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        row.$2,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: row.$4,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          height: 1.45,
                        ),
                      ),
                      if (row.$3.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            row.$3,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 8.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _shippingCard() {
    final data = widget.controller.pricing;
    final profile = widget.controller.profile;
    final governorate = (profile?['governorate'] ?? 'صنعاء').toString();

    Map<String, dynamic> productShipping() {
      for (final key in const ['shipping', 'delivery', 'deliveryInfo']) {
        final value = _detailProduct.serverData[key];
        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }
      return const {};
    }

    final productData = productShipping();
    final governors = data['governorates'];
    final region = governors is Map && governors[governorate] is Map
        ? Map<String, dynamic>.from(governors[governorate] as Map)
        : const <String, dynamic>{};

    final free = productData['freeDelivery'] ??
        productData['freeShipping'] ??
        region['freeDeliveryIncluded'];
    final note = productData['note'] ??
        productData['deliveryNote'] ??
        region['deliveryNote'] ??
        'تكلفة الشحن وموعد التوصيل بحسب المحافظة وإعدادات المتجر الحالية.';
    final fee = productData['fee'] ??
        productData['deliveryFee'] ??
        data['defaultDeliveryFee'];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: AppColors.ink,
              ),
              SizedBox(width: 7),
              Text(
                'الشحن والتوصيل',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.slate500,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              if (free == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EFDA),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'شحن مجاني',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else if (fee != null)
                Text(
                  fee.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serverDetailsCard(Product p) {
    final raw = p.serverData;
    final entries = <(String, String)>[];

    void add(String label, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      if (value is Map && value.isEmpty) return;

      String valueText;
      if (value is List) {
        valueText = value
            .map(
              (item) => item is Map
                  ? (item['name'] ?? item['label'] ?? item['value'] ?? item)
                      .toString()
                  : item.toString(),
            )
            .join('، ');
      } else if (value is Map) {
        valueText =
            value.entries.map((item) => item.key.toString() + ': ' + item.value.toString()).join(' • ');
      } else {
        valueText = value.toString();
      }

      if (valueText.trim().isNotEmpty) {
        entries.add((label, valueText));
      }
    }

    const labels = <String, String>{
      'salesText': 'المبيعات',
      'storeBadgeTag': 'المتجر',
      'couponTag': 'القسيمة',
      'stockUrgency': 'المخزون',
      'stock': 'الكمية المتاحة',
      'sellersCount': 'عدد البائعين',
      'sellerName': 'البائع',
      'seller': 'البائع',
      'merchant': 'التاجر',
      'material': 'الخامة',
      'materials': 'المواد',
      'fabric': 'القماش',
      'ageGroup': 'الفئة العمرية',
      'productType': 'نوع المنتج',
      'department': 'القسم',
      'subCategory': 'التصنيف الفرعي',
      'returnPolicy': 'سياسة الإرجاع',
      'returnDays': 'مدة الإرجاع',
      'sizeGuide': 'مرجع المقاس',
      'sizeReference': 'مرجع المقاس',
      'paymentMethods': 'طرق الدفع',
      'paymentMethod': 'طريقة الدفع',
      'cashOnDelivery': 'الدفع عند الاستلام',
      'isLocalFastShipping': 'شحن محلي سريع',
      'showCardShipping': 'إظهار الشحن',
      'cardShippingText': 'معلومات الشحن',
      'shippingText': 'معلومات الشحن',
      'deliveryText': 'معلومات التوصيل',
      'trendTag': 'الترند',
      'priceDropBadge': 'تنبيه السعر',
      'badgeText': 'شارة المنتج',
      'sku': 'رمز المنتج',
    };

    for (final item in labels.entries) {
      add(item.value, raw[item.key]);
    }

    final knownKeys = labels.keys.toSet();

    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (knownKeys.contains(key)) continue;
      if (const {
        'image',
        'images',
        'gallery',
        'galleryImages',
        'imageUrls',
        'photos',
        'media',
        'mediaItems',
        'productImages',
        'variants',
        'colors',
      }.contains(key)) {
        continue;
      }

      final pretty = key
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .trim();

      if (pretty.isEmpty) continue;
      add(pretty, value);
    }

    for (final key in const [
      'features',
      'specifications',
      'attributes',
      'shipping',
      'delivery',
    ]) {
      final value = raw[key];
      if (value != null) {
        add(
          key == 'shipping' || key == 'delivery' ? 'تفاصيل الشحن' : 'المواصفات',
          value,
        );
      }
    }

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تفاصيل المنتج',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      entry.$1,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.$2,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewsCard(Product p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          const Icon(Icons.rate_review_outlined, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('التقييمات والمراجعات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  p.rating.toStringAsFixed(1) + ' نجوم • ' + p.reviewsCount.toString() + ' تقييم',
                  style: const TextStyle(fontSize: 9, color: AppColors.slate500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.slate400),
        ],
      ),
    );
  }

  Widget _related(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text('ربما يعجبك أيضاً', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
        ),
        SizedBox(
          height: 238,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final product = products[index];
              return SizedBox(
                width: 158,
                child: ProductCard(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _parseHex(String value) {
    final raw = value.replaceFirst('#', '');
    final parsed = int.tryParse(raw, radix: 16);
    if (parsed == null) return AppColors.ink;
    return raw.length == 8 ? Color(parsed) : Color(0xFF000000 | parsed);
  }
}
