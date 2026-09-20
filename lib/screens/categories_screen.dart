import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/store_controller.dart';
import 'product_details_screen.dart';
import 'search_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final StoreController controller;
  const CategoriesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'الفئات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(9, 5, 9, 18),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              controller.categories.map((category) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.slate200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 58,
                              height: 58,
                              child: category.image.isNotEmpty
                                  ? Image.network(category.image, fit: BoxFit.cover)
                                  : const ColoredBox(
                                      color: AppColors.slate100,
                                      child: Icon(Icons.category_outlined),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            category.subCategories.length.toString() + ' فرع',
                            style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (category.styleTabs.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: category.styleTabs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 7),
                            itemBuilder: (_, index) {
                              final style = category.styleTabs[index];
                              return SizedBox(
                                width: 71,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 71,
                                        height: 64,
                                        child: style.image.isNotEmpty
                                            ? Image.network(
                                                style.image,
                                                fit: BoxFit.cover,
                                              )
                                            : const ColoredBox(
                                                color: AppColors.slate100),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      style.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: category.subCategories.map((sub) {
                          return ActionChip(
                            label: Text(
                              sub.name,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () {
                              final items = controller.filtered(
                                category: category.id,
                                subCategory: sub.name,
                              );
                              if (items.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsScreen(
                                      controller: controller,
                                      product: items.first,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
