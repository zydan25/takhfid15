import 'package:flutter/material.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  final StoreController controller;
  const WishlistScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items =
        controller.products.where(controller.isWishlisted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المفضلة',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'لا توجد أصناف محفوظة في المفضلة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(9),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 7,
                mainAxisSpacing: 9,
                childAspectRatio: .53,
              ),
              itemBuilder: (_, index) {
                final product = items[index];
                return ProductCard(
                  product: product,
                  index: index,
                  wishlisted: true,
                  onOpen: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(
                        controller: controller,
                        product: product,
                      ),
                    ),
                  ),
                  onWishlist: () => controller.toggleWishlist(product),
                  onCart: () => controller.addToCart(product),
                );
              },
            ),
    );
  }
}
