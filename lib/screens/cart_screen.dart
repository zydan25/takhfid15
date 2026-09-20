import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/cart.dart';
import '../state/store_controller.dart';
import 'order_status_screen.dart';
import 'product_details_screen.dart';

class CartScreen extends StatelessWidget {
  final StoreController controller;
  const CartScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = controller.cart;
    return Column(
      children: [
        AppBar(
          title: const Text(
            'حقيبة التسوق',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          actions: [
            if (items.isNotEmpty)
              IconButton(
                onPressed: controller.clearCart,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
          ],
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'السلة فارغة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _item(context, items[index]),
                ),
        ),
        if (items.isNotEmpty)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.slate200)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'الإجمالي',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        controller.cartTotal.toStringAsFixed(2) + ' ر.س',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.rose,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
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
                        backgroundColor: AppColors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'متابعة الطلب ←',
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
          ),
      ],
    );
  }

  Widget _item(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.slate200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(
                  controller: controller,
                  product: item.product,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 92,
                child: Image.network(item.product.image, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  item.size + ' • ' + item.color.name,
                  style: const TextStyle(fontSize: 9, color: AppColors.slate500),
                ),
                const SizedBox(height: 5),
                Text(
                  item.product.discountPrice.toStringAsFixed(2) + ' ر.س',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.rose,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.updateQuantity(
                        item,
                        item.quantity - 1,
                      ),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                    ),
                    Text(
                      item.quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.updateQuantity(
                        item,
                        item.quantity + 1,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.removeFromCart(item),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.rose,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
