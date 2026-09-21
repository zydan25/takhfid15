import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/store_controller.dart';

class SettingsScreen extends StatefulWidget {
  final StoreController controller;
  final bool openCurrency;

  const SettingsScreen({
    super.key,
    required this.controller,
    this.openCurrency = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController firstName;
  late final TextEditingController secondName;
  late final TextEditingController thirdName;
  late final TextEditingController lastName;
  late String governorate;
  bool saving = false;

  static const governors = <String>[
    'أمانة العاصمة',
    'صنعاء',
    'عدن',
    'تعز',
    'إب',
    'حضرموت',
    'الحديدة',
    'ذمار',
    'عمران',
    'صعدة',
    'حجة',
    'المحويت',
    'ريمة',
    'البيضاء',
    'مأرب',
    'الجوف',
    'شبوة',
    'أبين',
    'لحج',
    'الضالع',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile ?? const <String, dynamic>{};
    firstName = TextEditingController(text: (profile['firstName'] ?? '').toString());
    secondName = TextEditingController(text: (profile['secondName'] ?? '').toString());
    thirdName = TextEditingController(text: (profile['thirdName'] ?? '').toString());
    lastName = TextEditingController(text: (profile['lastName'] ?? '').toString());
    governorate = (profile['governorate'] ?? governors.first).toString();
    if (!governors.contains(governorate)) governorate = governors.first;

    if (widget.openCurrency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCurrencySheet();
      });
    }
  }

  @override
  void dispose() {
    firstName.dispose();
    secondName.dispose();
    thirdName.dispose();
    lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    final phone = (profile?['phone'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إدارة الحساب والإعدادات',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 28),
        children: [
          _section(
            title: 'حسابي',
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: AppColors.black,
                        child: Text(
                          firstName.text.isEmpty ? 'أ' : firstName.text.characters.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName().isEmpty ? 'حسابي' : _fullName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.slate500,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: AppColors.emerald,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _field(firstName, 'الاسم الأول'),
                const SizedBox(height: 7),
                _field(secondName, 'الاسم الثاني'),
                const SizedBox(height: 7),
                _field(thirdName, 'الاسم الثالث'),
                const SizedBox(height: 7),
                _field(lastName, 'اسم العائلة'),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  value: governorate,
                  items: governors
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => governorate = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'المحافظة',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 19),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : _saveProfile,
                    icon: saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      saving ? 'جارٍ الحفظ...' : 'حفظ تحديثات الحساب',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          _section(
            title: 'العملة والأسعار',
            icon: Icons.currency_exchange_rounded,
            child: Column(
              children: [
                _settingTile(
                  icon: Icons.payments_outlined,
                  title: 'عملة العرض',
                  subtitle: _currencyLabel(widget.controller.currency),
                  onTap: _showCurrencySheet,
                ),
                const Divider(height: 1),
                _pricingSummary(),
              ],
            ),
          ),
          const SizedBox(height: 9),
          _section(
            title: 'التفضيلات',
            icon: Icons.tune_rounded,
            child: Column(
              children: [
                _settingTile(
                  icon: Icons.language_outlined,
                  title: 'اللغة',
                  subtitle: 'العربية',
                  onTap: () => _simpleMessage('اللغة العربية مفعّلة حالياً.'),
                ),
                const Divider(height: 1),
                _settingTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'الإشعارات',
                  subtitle: 'إشعارات الطلبات والعروض من الخادم',
                  onTap: () => _simpleMessage('الإشعارات مرتبطة بحسابك وتُحدّث في الخلفية.'),
                ),
                const Divider(height: 1),
                _settingTile(
                  icon: Icons.sync_rounded,
                  title: 'مزامنة المتجر',
                  subtitle: widget.controller.refreshing
                      ? 'جارٍ التحديث الآن...'
                      : 'تحديث المنتجات والمحتوى من الخادم',
                  onTap: widget.controller.refreshing
                      ? null
                      : () async {
                          await widget.controller.refresh();
                          if (mounted) _simpleMessage('تم تحديث بيانات المتجر.');
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          _section(
            title: 'الحساب',
            icon: Icons.security_outlined,
            child: Column(
              children: [
                _settingTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'بياناتي وحسابي',
                  subtitle: 'بيانات الحساب محفوظة محلياً بعد المصادقة',
                  onTap: () => _simpleMessage('لحذف الحساب نهائياً يجب تنفيذ ذلك من إدارة المتجر.'),
                ),
                if (widget.controller.profile != null) ...[
                  const Divider(height: 1),
                  _settingTile(
                    icon: Icons.logout_rounded,
                    title: 'تسجيل الخروج',
                    subtitle: 'إنهاء جلسة الحساب على هذا الجهاز',
                    danger: true,
                    onTap: () async {
                      await widget.controller.logout();
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
            color: AppColors.slate50,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_outline, size: 18),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      enabled: onTap != null,
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: danger ? AppColors.roseSoft : AppColors.slate100,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: danger ? AppColors.rose : AppColors.ink,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: danger ? AppColors.rose : AppColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 8,
          color: AppColors.slate500,
          height: 1.4,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        size: 18,
        color: AppColors.slate400,
      ),
    );
  }

  Widget _pricingSummary() {
    final pricing = widget.controller.pricing;
    if (pricing.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(2, 9, 2, 3),
        child: Text(
          'لا توجد أسعار صرف إضافية محفوظة حالياً.',
          style: TextStyle(fontSize: 9, color: AppColors.slate500),
        ),
      );
    }

    final entries = <MapEntry<String, dynamic>>[];
    pricing.forEach((key, value) {
      if (value is num || value is String) {
        entries.add(MapEntry(key, value));
      }
    });

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(2, 9, 2, 3),
        child: Text(
          'إعدادات التسعير تأتي من الخادم.',
          style: TextStyle(fontSize: 9, color: AppColors.slate500),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: entries.take(8).map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (firstName.text.trim().isEmpty) {
      _simpleMessage('الاسم الأول مطلوب.');
      return;
    }

    setState(() => saving = true);
    try {
      await widget.controller.updateProfile(
        firstName: firstName.text,
        secondName: secondName.text,
        thirdName: thirdName.text,
        lastName: lastName.text,
        governorate: governorate,
      );
      if (!mounted) return;
      _simpleMessage('تم حفظ تحديثات الحساب.');
      setState(() {});
    } catch (e) {
      if (mounted) _simpleMessage('تعذر حفظ الحساب: ${e.toString()}');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _showCurrencySheet() async {
    final currencies = <String>['YER', 'SAR', 'USD'];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'عملة الأسعار',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...currencies.map(
                (currency) => ListTile(
                  onTap: () async {
                    await widget.controller.setCurrency(currency);
                    if (mounted) Navigator.pop(context);
                  },
                  leading: Icon(
                    widget.controller.currency == currency
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: widget.controller.currency == currency
                        ? AppColors.black
                        : AppColors.slate400,
                  ),
                  title: Text(
                    _currencyLabel(currency),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  trailing: Text(
                    currency,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  String _fullName() {
    return [
      firstName.text.trim(),
      secondName.text.trim(),
      thirdName.text.trim(),
      lastName.text.trim(),
    ].where((x) => x.isNotEmpty).join(' ');
  }

  String _currencyLabel(String value) {
    switch (value.toUpperCase()) {
      case 'SAR':
        return 'الريال السعودي';
      case 'USD':
        return 'الدولار الأمريكي';
      default:
        return 'الريال اليمني';
    }
  }

  void _simpleMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
