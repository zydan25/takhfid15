import 'package:flutter/material.dart';
import '../core/theme.dart';

class StoreTopBar extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onWishlist;
  final VoidCallback onNotifications;
  final VoidCallback onVisualSearch;

  const StoreTopBar({
    super.key,
    required this.onSearch,
    required this.onWishlist,
    required this.onNotifications,
    required this.onVisualSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onWishlist,
            icon: const Icon(Icons.favorite_border, size: 21),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded, size: 21),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: AppColors.page,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 17, color: AppColors.slate500),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'ابحث عن ماركة، فستان، حذاء، عطر...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.slate500,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onVisualSearch,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.camera_alt_outlined, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
