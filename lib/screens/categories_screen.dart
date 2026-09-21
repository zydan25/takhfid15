import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/content.dart';
import '../state/store_controller.dart';
import 'search_screen.dart';
import 'showcase_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final StoreController controller;

  const CategoriesScreen({
    super.key,
    required this.controller,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _activeId;

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    if (groups.isEmpty) {
      return RefreshIndicator(
        color: AppColors.black,
        onRefresh: widget.controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text(
                'لا توجد فئات متاحة الآن',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final activeIndex = groups.indexWhere(
      (item) => item.id == (_activeId ?? groups.first.id),
    );
    final safeIndex = activeIndex >= 0 ? activeIndex : 0;
    final active = groups[safeIndex];

    if (_activeId != active.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeId != active.id) {
          setState(() => _activeId = active.id);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 12,
        title: const Row(
          children: [
            Icon(Icons.grid_view_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'جميع الأقسام',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'بحث',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(
                  controller: widget.controller,
                ),
              ),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: widget.controller.refreshing
                ? null
                : widget.controller.refresh,
            icon: widget.controller.refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: widget.controller.refresh,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // RTL: the category rail is intentionally kept on the right,
            // matching the reference browser layout.
            SizedBox(
              width: 112,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F5F7),
                  border: Border(
                    left: BorderSide(color: AppColors.slate200),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 1),
                  itemBuilder: (_, index) {
                    final group = groups[index];
                    final selected = group.id == active.id;
                    return _sideItem(group, selected);
                  },
                ),
              ),
            ),
            Expanded(
              child: _contentPane(active),
            ),
          ],
        ),
      ),
    );
  }

  List<SideCategory> _groups() {
    if (widget.controller.sideCategories.isNotEmpty) {
      return widget.controller.sideCategories;
    }

    // Graceful fallback: build the same sidebar pattern from server
    // categories when the optional sideCategories collection is absent.
    return widget.controller.categories
        .map(
          (category) => SideCategory(
            id: category.id,
            name: category.name,
            iconName: '',
            subCategories: category.subCategories
                .map(
                  (sub) => SideCategoryItem(
                    id: sub.id,
                    name: sub.name,
                    image: sub.image,
                    categoryId: category.id,
                    sideCategoryId: category.id,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  Widget _sideItem(SideCategory group, bool selected) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeId = group.id),
        child: Stack(
          children: [
            if (selected)
              Positioned(
                top: 8,
                bottom: 8,
                right: 0,
                child: Container(
                  width: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 9, 9, 9),
              child: Column(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.black
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.black
                            : AppColors.slate200,
                      ),
                    ),
                    child: Icon(
                      _iconFor(group.iconName),
                      size: 19,
                      color: selected
                          ? Colors.white
                          : AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    group.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.15,
                      color: selected
                          ? AppColors.ink
                          : AppColors.slate500,
                      fontWeight: selected
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                  if (group.badge.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.roseSoft,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        group.badge,
                        style: const TextStyle(
                          color: AppColors.rose,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentPane(SideCategory group) {
    final items = group.subCategories;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  Text(
                    '${items.length} قسم',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'لا توجد أقسام فرعية',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.slate500,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(9, 3, 9, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, index) => _subCard(items[index]),
                childCount: items.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 7,
                mainAxisSpacing: 8,
                mainAxisExtent: 128,
              ),
            ),
          ),
      ],
    );
  }

  Widget _subCard(SideCategoryItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShowcaseScreen(
              controller: widget.controller,
              title: item.name,
              category: item.categoryId.isEmpty ? 'all' : item.categoryId,
              subCategory: item.name,
              image: item.image,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: item.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.image,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.slate400,
                              size: 30,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.category_outlined,
                            color: AppColors.slate400,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String value) {
    final v = value.toLowerCase();
    if (v.contains('spark')) return Icons.auto_awesome_outlined;
    if (v.contains('shirt')) return Icons.checkroom_outlined;
    if (v.contains('home')) return Icons.home_outlined;
    if (v.contains('baby')) return Icons.child_friendly_outlined;
    if (v.contains('user')) return Icons.person_outline;
    if (v.contains('flame')) return Icons.local_fire_department_outlined;
    if (v.contains('gem')) return Icons.diamond_outlined;
    if (v.contains('foot')) return Icons.directions_walk_outlined;
    if (v.contains('heart')) return Icons.favorite_border;
    return Icons.grid_view_rounded;
  }
}
