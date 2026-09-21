import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/cart.dart';
import '../state/store_controller.dart';
import 'chat_screen.dart';
import 'order_status_screen.dart';
import 'product_details_screen.dart';

class CartScreen extends StatelessWidget {
  final StoreController controller;

  const CartScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = controller.cart;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context, items.length),
            _filterRow(),
            Expanded(
              child: items.isEmpty
                  ? _empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 140),
                      children: [
                        _shippingProgress(),
                        const SizedBox(height: 10),
                        ...items.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _item(
                                  context,
                                  entry.value,
                                  entry.key,
                                ),
                              ),
                            ),
                        const SizedBox(height: 8),
                        _supportButton(context),
                      ],
                    ),
            ),
            if (items.isNotEmpty) _bottomSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int count) {
    final governorate =
        (controller.profile?['governorate'] ?? 'أمانة العاصمة').toString();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 9),
      child: Row(
        children: [
          IconButton(
            onPressed: () => controller.selectTab(0),
            icon: const Icon(Icons.close_rounded, size: 27),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'حقيبة\nالتسوق ($count)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 154),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7EAF1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.rose,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'يتم الشحن إلى: ' + governorate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.clearCart,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 9),
      child: SizedBox(
        width: double.infinity,
        height: 34,
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: _pill('جميع', active: true),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _pill('الكمية على وشك الانتهاء 🔥'),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 88,
              child: _pill(
                'حسب الفئة',
                icon: Icons.keyboard_arrow_down_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(
    String text, {
    bool active = false,
    IconData? icon,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? Colors.black : const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? Colors.black : const Color(0xFFE8EAF0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: active ? Colors.white : AppColors.ink),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white : AppColors.ink,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shippingProgress() {
    final data = controller.pricing;
    final governorate =
        (controller.profile?['governorate'] ?? 'صنعاء').toString();
    final governors = data['governorates'];
    final region = governors is Map && governors[governorate] is Map
        ? Map<String, dynamic>.from(governors[governorate] as Map)
        : const <String, dynamic>{};

    final rawThreshold = region['freeDeliveryThreshold'] ??
        data['freeDeliveryThresholdYer'] ??
        data['freeShippingThreshold'];
    final threshold = rawThreshold is num ? rawThreshold.toDouble() : 0.0;
    final subtotal = controller.cartTotal;
    final free = region['freeDeliveryIncluded'] == true ||
        (threshold > 0 && subtotal >= threshold);
    final remaining = threshold > subtotal ? threshold - subtotal : 0.0;
    final progress = threshold > 0
        ? (subtotal / threshold).clamp(0.0, 1.0)
        : (free ? 1.0 : .35);

    String message;
    if (free) {
      message = 'الشحن مجاني لهذا الطلب';
    } else if (threshold > 0) {
      message =
          'شحن مجاني للطلبات فوق ' + threshold.toStringAsFixed(0);
    } else {
      message = 'شحن مجاني حسب إعدادات المحافظة';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E6EA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.circle,
                color: AppColors.emerald,
                size: 10,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!free && remaining > 0)
                Text(
                  'متبقي ' + remaining.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: const Color(0xFFE9F2E6),
              valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, CartItem item, int index) {
    final p = item.product;
    final image = p.image.isNotEmpty
        ? p.image
        : (p.gallery.isNotEmpty ? p.gallery.first : '');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              controller: controller,
              product: p,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 9, 9, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE5E6EA)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: image.isEmpty
                          ? const ColoredBox(
                              color: AppColors.slate100,
                              child: Icon(Icons.image_outlined),
                            )
                          : CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) {
                                final fallback = p.gallery
                                    .where((x) => x.isNotEmpty && x != image)
                                    .toList();
                                if (fallback.isEmpty) {
                                  return const ColoredBox(
                                    color: AppColors.slate100,
                                    child: Icon(Icons.broken_image_outlined),
                                  );
                                }
                                return CachedNetworkImage(
                                  imageUrl: fallback.first,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? const Color(0xFFFF5A00)
                            : Colors.black,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14),
                        ),
                      ),
                      child: Text(
                        (p.serverData['stockUrgency'] ??
                                (p.inStock ? 'متوفر' : 'نفذت الكمية'))
                            .toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => controller.removeFromCart(item),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.slate400,
                            size: 21,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          p.brand.isEmpty ? 'SHEIN' : p.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (p.serverData['storeBadgeTag'] != null)
                      Text(
                        p.serverData['storeBadgeTag'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        '◉ ' + item.color.name + '  •  ' + item.size,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (p.discountPercentage > 0)
                      const Text(
                        'تم شراؤها بهذا السعر',
                        style: TextStyle(
                          color: AppColors.rose,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          controller.currency == 'SAR'
                              ? p.discountPrice.toStringAsFixed(2) + ' ر.س'
                              : p.discountPrice.toStringAsFixed(0) + ' ر.ي',
                          style: const TextStyle(
                            color: AppColors.rose,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        _quantity(item),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quantity(CartItem item) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE3E6EA)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                controller.updateQuantity(item, item.quantity - 1),
            icon: const Icon(Icons.remove, size: 16),
          ),
          Text(
            item.quantity.toString(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                controller.updateQuantity(item, item.quantity + 1),
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _supportButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: controller.profile == null
            ? null
            : () async {
                final session = await controller.ensureChat();
                if (!context.mounted) return;
                if (session == null || session.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تعذر فتح محادثة خدمة العملاء'),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      controller: controller,
                      sessionId: session,
                      title: 'محادثة خدمة العملاء',
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
        label: const Text(
          'محادثة خدمة العملاء',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  Widget _bottomSummary(BuildContext context) {
    final subtotal = controller.cartTotal;
    final currency = controller.currency == 'SAR' ? 'ر.س' : 'ر.ي';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE4E6EA))),
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 16,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الإجمالي المختار (' +
                        controller.cartCount.toString() +
                        ')',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtotal.toStringAsFixed(2) + ' ' + currency,
                    style: const TextStyle(
                      fontSize: 19,
                      color: AppColors.rose,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 205,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderStatusScreen(
                      controller: controller,
                      checkoutMode: true,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'الدفع وإرسال السلة  ←',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _empty() {
    return const Center(
      child: Text(
        'حقيبة التسوق فارغة',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }
}
