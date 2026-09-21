import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../state/store_controller.dart';
import 'auth_screen.dart';
import 'order_status_screen.dart';
import 'wishlist_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class AccountScreen extends StatelessWidget {
  final StoreController controller;

  const AccountScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    final name = [
      profile?['firstName'],
      profile?['secondName'],
      profile?['thirdName'],
      profile?['lastName'],
    ]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(' ');
    final displayName = name.isEmpty ? 'مرحباً بك' : name;
    final phone = (profile?['phone'] ?? '').toString();

    final items = <_AccountItem>[
      _AccountItem('طلباتي', Icons.receipt_long_rounded, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OrderStatusScreen(controller: controller),
        ));
      }),
      _AccountItem('الكوبونات', Icons.local_offer_rounded, () {
        _showCoupons(context);
      }),
      _AccountItem('المفضلة', Icons.favorite_rounded, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => WishlistScreen(controller: controller),
        ));
      }),
      _AccountItem('الهدايا', Icons.card_giftcard_rounded, () {
        _showInfo(context, 'الهدايا والمكافآت', 'الهدايا والكوبونات والمكافآت الخاصة بحسابك.');
      }),
      _AccountItem('محفظتي', Icons.account_balance_wallet_rounded, () {
        _showInfo(context, 'المحفظة', 'ستظهر هنا رصيدك ومزايا المحفظة عندما يوفرها الخادم.');
      }),
      _AccountItem('العناوين', Icons.location_on_rounded, () {
        _showInfo(
          context,
          'العناوين',
          'الموقع الحالي: ' + (profile?['governorate'] ?? 'صنعاء').toString(),
        );
      }),
      _AccountItem('الدفع', Icons.credit_card_rounded, () {
        _showInfo(context, 'طرق الدفع', 'خيارات الدفع وسندات التحويل المرتبطة بطلباتك.');
      }),
      _AccountItem('اللغة', Icons.translate_rounded, () {
        _showInfo(context, 'اللغة', 'العربية');
      }),
      _AccountItem('العملة', Icons.currency_exchange_rounded, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SettingsScreen(
            controller: controller,
            openCurrency: true,
          ),
        ));
      }),
      _AccountItem('الإعدادات', Icons.settings_rounded, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SettingsScreen(controller: controller),
        ));
      }),
      _AccountItem('الدعم', Icons.support_agent_rounded, () {
        _openSupportChat(context);
      }),
      _AccountItem('خروج', Icons.logout_rounded, () {
        if (profile != null) {
          controller.logout();
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AuthScreen(controller: controller),
          ));
        }
      }),
    ];

    return Container(
      color: const Color(0xFFF8F8FA),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 22),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile == null
                            ? 'سجّل الدخول للاستفادة من حسابك'
                            : phone,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile == null)
                  SizedBox(
                    width: 64,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AuthScreen(controller: controller),
                      )),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text('دخول'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _summaryRow(),
          const SizedBox(height: 8),
          _accountCouponPreview(context),
          const SizedBox(height: 9),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: .92,
            ),
            itemBuilder: (_, index) => _accountIcon(items[index]),
          ),
          if (profile != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout_rounded, size: 17, color: AppColors.rose),
              label: const Text(
                'تسجيل الخروج من الحساب',
                style: TextStyle(
                  color: AppColors.rose,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Column(
              children: [
                Text(
                  'برمجة وتصميم يمن كود للتقنيات الذكية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '774952665',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    final values = <(String, String, IconData)>[
      ('الطلبات', controller.orders.length.toString(), Icons.receipt_long_outlined),
      ('المفضلة', controller.wishlistIds.length.toString(), Icons.favorite_border_rounded),
      ('الحقيبة', controller.cartCount.toString(), Icons.shopping_bag_outlined),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: values.map((value) {
          return Expanded(
            child: Column(
              children: [
                Icon(value.$3, size: 19, color: AppColors.ink),
                const SizedBox(height: 3),
                Text(
                  value.$2,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                Text(
                  value.$1,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _accountCouponPreview(BuildContext context) {
    final rawScreens = controller.announcements['screens'];
    if (rawScreens is! List) return const SizedBox.shrink();

    final active = rawScreens
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['isActive'] != false)
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();

    final first = active.first;
    final badge = (first['badgeText'] ?? first['badge'] ?? '').toString();
    final coupons = first['coupons'] is List
        ? (first['coupons'] as List).whereType<Map>().toList()
        : const <Map>[];

    return InkWell(
      onTap: () => _showCoupons(context),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF6EE),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: AppColors.rose, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'كوبونات وعروضك',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
                if (badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.rose,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            if (coupons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: coupons.take(2).map((coupon) {
                  final discount =
                      (coupon['discount'] ?? coupon['discountText'] ?? '').toString();
                  final minSpend =
                      (coupon['minSpend'] ?? coupon['minOrder'] ?? '').toString();
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F2),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFF5C2CB)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            discount,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (minSpend.isNotEmpty)
                            Text(
                              minSpend,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.slate500,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accountIcon(_AccountItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.slate200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 21, color: AppColors.ink),
              ),
              const SizedBox(height: 5),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCoupons(BuildContext context) {
    final rawScreens = controller.announcements['screens'];
    final active = rawScreens is List
        ? rawScreens
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['isActive'] != false)
            .toList()
        : const <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final children = <Widget>[
          const Text(
            'الكوبونات والعروض',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (active.isEmpty)
            const Text(
              'لا توجد كوبونات متاحة الآن',
              style: TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
        ];

        for (final screen in active) {
          final coupons = screen['coupons'] is List
              ? (screen['coupons'] as List).whereType<Map>()
              : const <Map>[];
          for (final coupon in coupons) {
            final discount =
                (coupon['discount'] ?? coupon['discountText'] ?? '').toString();
            final minSpend =
                (coupon['minSpend'] ?? coupon['minOrder'] ?? '').toString();
            final code = (coupon['code'] ?? '').toString();

            children.add(
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(11, 9, 7, 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFF3C3CC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, color: AppColors.rose),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            discount,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            [code, minSpend].where((e) => e.isNotEmpty).join(' • '),
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (code.isNotEmpty)
                      IconButton(
                        tooltip: 'نسخ الكود',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ كود القسيمة')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                  ],
                ),
              ),
            );
          }
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        );
      },
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
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

    Future<void> _openSupportChat(BuildContext context) async {
    if (controller.profile == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(controller: controller),
        ),
      );
      return;
    }

    final sessionId = await controller.ensureChat();
    if (!context.mounted) return;
    if (sessionId == null || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح محادثة الدعم')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          controller: controller,
          sessionId: sessionId,
          title: 'التواصل معنا',
        ),
      ),
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

class _AccountItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AccountItem(this.title, this.icon, this.onTap);
}
