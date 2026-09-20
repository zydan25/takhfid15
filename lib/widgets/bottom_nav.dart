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
      height: 65,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.slate200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final active = currentIndex == index;
            final item = items[index];
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                splashColor: AppColors.slate100,
                highlightColor: AppColors.slate50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: active ? AppColors.slate100 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.$1,
                            size: 22,
                            color: active ? AppColors.ink : AppColors.slate400,
                          ),
                        ),
                        if (index == 3 && cartCount > 0)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.rose,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.rose.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                cartCount > 99 ? '99+' : cartCount.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                        color: active ? AppColors.ink : AppColors.slate400,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
