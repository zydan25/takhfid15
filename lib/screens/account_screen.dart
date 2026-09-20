import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/store_controller.dart';
import 'auth_screen.dart';
import 'order_status_screen.dart';
import 'wishlist_screen.dart';

class AccountScreen extends StatelessWidget {
  final StoreController controller;

  const AccountScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    final name = [
      profile?['firstName'],
      profile?['lastName'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 18),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(15, 18, 15, 11),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.ink,
                child: Text(
                  name.isEmpty ? 'أ' : name.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile == null ? 'مرحباً بك' : (name.isEmpty ? 'حسابي' : name),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      profile == null
                          ? 'سجّل الدخول لإدارة طلباتك'
                          : (profile['phone'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (profile == null)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthScreen(controller: controller),
                    ),
                  ),
                  child: const Text('دخول'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _row(context, 'خيارات الدفع', Icons.credit_card_outlined,
            () => _sheet(context, 'خيارات الدفع', 'الحسابات والمحافظ المعتمدة لإتمام الدفع وإرسال السند.')),
        _row(context, 'إدارة حسابي', Icons.manage_accounts_outlined,
            () => _sheet(context, 'إدارة حسابي', 'بيانات الحساب تحفظ في الخادم وتُعرض محلياً بعد المصادقة.')),
        _row(
          context,
          'موقع • ' + (profile?['governorate'] ?? 'صنعاء').toString(),
          Icons.location_on_outlined,
          () => _sheet(context, 'الموقع والمحافظات', 'المحافظة تؤثر في السعر الإقليمي والشحن.'),
        ),
        _row(context, 'اللغة • العربية', Icons.language_outlined,
            () => _sheet(context, 'اللغة', 'العربية مفعلة مثل النسخة المرجعية.')),
        _row(context, 'عملة • SAR', Icons.currency_exchange_outlined,
            () => _sheet(context, 'عملة الأسعار', 'أسعار التحويل تأتي من إعدادات الخادم.')),
        _row(
          context,
          'المفضلة • ' + controller.wishlistIds.length.toString(),
          Icons.favorite_border,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WishlistScreen(controller: controller),
            ),
          ),
        ),
        _row(
          context,
          'حالة الطلب • ' + controller.orders.length.toString(),
          Icons.local_shipping_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderStatusScreen(controller: controller),
            ),
          ),
        ),
        _row(context, 'الهدايا والبطاقات والمكافآت', Icons.card_giftcard_outlined,
            () => _sheet(context, 'الهدايا والكوبونات', 'المكافآت والكوبونات جزء من تجربة العميل في النسخة المرجعية.')),
        _row(context, 'التواصل معنا', Icons.support_agent_outlined,
            () => _sheet(context, 'التواصل معنا', 'سيتم توصيل شاشة المحادثة بعقد الرسائل بعد تثبيت API النهائي.')),
        if (profile != null)
          Center(
            child: TextButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout, color: AppColors.rose, size: 17),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: AppColors.rose,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        tileColor: Colors.white,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        trailing: const Icon(
          Icons.chevron_left,
          size: 18,
          color: AppColors.slate500,
        ),
      ),
    );
  }

  void _sheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.slate500,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
