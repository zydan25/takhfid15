import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/store_controller.dart';

class NotificationsScreen extends StatelessWidget {
  final StoreController controller;
  const NotificationsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('🚚', 'عرض توصيل مجاني', 'توصيل سريع متوفر لمحافظتك'),
      ('🏷️', 'قسيمة جديدة', 'تحقق من كوبوناتك النشطة'),
      ('✨', 'تشكيلة جديدة', 'استكشف آخر الأصناف المضافة'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.slate200),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
