import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/content.dart';
import '../state/store_controller.dart';
import 'search_screen.dart';
import 'showcase_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final StoreController controller;
  const CategoriesScreen({super.key, required this.controller});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final categories = widget.controller.categories;
    final category = categories.where((item) => item.id == _selectedCategory).toList();
    final selected = category.isEmpty && categories.isNotEmpty ? categories.first : category.firstOrNull;

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: widget.controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  MaterialPageRoute(builder: (_) => SearchScreen(controller: widget.controller)),
                ),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          if (categories.isNotEmpty)
            SliverToBoxAdapter(child: _categorySelector(categories)),
          if (selected != null)
            SliverToBoxAdapter(child: _selectedCategory(selected)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _categorySelector(List<Category> categories) {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = categories[index];
          final active = category.id == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category.id),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? AppColors.black : AppColors.slate200,
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: category.image.isNotEmpty
                        ? CachedNetworkImage(imageUrl: category.image, fit: BoxFit.cover)
                        : const Icon(Icons.category_outlined, color: AppColors.slate400),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                      color: active ? AppColors.ink : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectedCategory(Category category) {
    final shape = (widget.controller.categoryTabsConfig['shape'] ?? 'circle').toString();
    final radius = shape == 'circle'
        ? 100.0
        : shape == 'curved'
            ? 24.0
            : shape == 'rounded'
                ? 14.0
                : 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 4, 11, 5),
          child: Row(
            children: [
              Text(
                category.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (category.subCategories.isNotEmpty)
                Text(
                  category.subCategories.length.toString() + ' قسم',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        if (category.styleTabs.isNotEmpty)
          SizedBox(
            height: 104,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 7),
              scrollDirection: Axis.horizontal,
              itemCount: category.styleTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final style = category.styleTabs[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowcaseScreen(
                        controller: widget.controller,
                        title: style.name,
                        category: category.id,
                        styleTab: style.name,
                        image: style.image,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: 74,
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius: shape == 'circle'
                                ? null
                                : BorderRadius.circular(radius),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: style.image.isNotEmpty
                              ? CachedNetworkImage(imageUrl: style.image, fit: BoxFit.cover)
                              : const Icon(Icons.auto_awesome_outlined),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          style.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 7),
          child: Row(
            children: [
              const Text(
                'استكشف الأقسام',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                'اضغط للعرض',
                style: const TextStyle(fontSize: 8, color: AppColors.slate400, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Wrap(
            spacing: 7,
            runSpacing: 11,
            children: category.subCategories.map((sub) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 39) / 4,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowcaseScreen(
                        controller: widget.controller,
                        title: sub.name,
                        category: category.id,
                        subCategory: sub.id,
                        image: sub.image,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: shape == 'circle' ? null : BorderRadius.circular(radius),
                          border: Border.all(color: AppColors.slate200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: sub.image.isNotEmpty
                            ? CachedNetworkImage(imageUrl: sub.image, fit: BoxFit.cover)
                            : const Icon(Icons.category_outlined),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
