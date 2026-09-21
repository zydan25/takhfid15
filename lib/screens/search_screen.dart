import 'package:flutter/material.dart';
import '../state/store_controller.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final StoreController controller;
  const SearchScreen({super.key, required this.controller});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final queryController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final term = query.trim().toLowerCase();
    final items = term.isEmpty
        ? const []
        : widget.controller.products.where((product) {
            return product.name.toLowerCase().contains(term) ||
                product.description.toLowerCase().contains(term) ||
                product.category.toLowerCase().contains(term) ||
                product.brand.toLowerCase().contains(term);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: queryController,
          autofocus: true,
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            hintText: 'ابحث عن ماركة، قميص، فستان، حذاء، عطر...',
            prefixIcon: Icon(Icons.search, size: 18),
            suffixIcon: Icon(Icons.camera_alt_outlined, size: 17),
          ),
        ),
      ),
      body: term.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'عمليات البحث الشائعة اليوم',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    'فساتين سهرة صيفية',
                    'هودي رجالي أوفر سايز',
                    'أحذية سنيكرز رياضية',
                    'عبايات كلوش فاخرة',
                    'ساعات يد كلاسيكية',
                    'حقائب يد جلدية',
                  ].map((value) {
                    return ActionChip(
                      label: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        queryController.text = value;
                        setState(() => query = value);
                      },
                    );
                  }).toList(),
                ),
              ],
            )
          : items.isEmpty
              ? const Center(
                  child: Text(
                    'لم يتم العثور على منتجات تطابق بحثك',
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
      currencyLabel: widget.controller.currency,
      pricing: widget.controller.pricing,
                      index: index,
                      wishlisted:
                          widget.controller.isWishlisted(product),
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(
                            controller: widget.controller,
                            product: product,
                          ),
                        ),
                      ),
                      onWishlist: () =>
                          widget.controller.toggleWishlist(product),
                      onCart: () =>
                          widget.controller.addToCart(product),
                    );
                  },
                ),
    );
  }
}
