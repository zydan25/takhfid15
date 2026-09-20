import 'package:flutter/material.dart';
import '../core/theme.dart';

class TakhfidBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onChanged;

  const TakhfidBottomNav({
    super.key,
    required this.currentIndex,
    required this.cartCount,
    required this.onChanged,
  });

  static const items = [
    (Icons.storefront_outlined, 'متجر'),
    (Icons.grid_view_rounded, 'الفئات'),
    (Icons.local_fire_department_outlined, 'ترندات'),
    (Icons.shopping_bag_outlined, 'حقيبة التسوق'),
    (Icons.person_outline_rounded, 'أنا'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = currentIndex == index;
          final item = items[index];
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        item.$1,
                        size: 21,
                        color: active ? AppColors.ink : AppColors.slate500,
                      ),
                      if (index == 3 && cartCount > 0)
                        Positioned(
                          top: -8,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.rose,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              cartCount > 99 ? '99+' : cartCount.toString(),
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
                  const SizedBox(height: 2),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                      color: active ? AppColors.ink : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
