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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onWishlist,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.favorite_border,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotifications,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.slate200, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ابحث عن ماركة، فستان، حذاء، عطر...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onVisualSearch,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: AppColors.slate400,
                          ),
                        ),
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
