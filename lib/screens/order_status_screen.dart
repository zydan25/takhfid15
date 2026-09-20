import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/store_controller.dart';

class OrderStatusScreen extends StatefulWidget {
  final StoreController controller;
  final bool checkoutMode;

  const OrderStatusScreen({
    super.key,
    required this.controller,
    this.checkoutMode = false,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final address = TextEditingController();
  final notes = TextEditingController();
  bool busy = false;
  String? message;

  @override
  void dispose() {
    address.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.checkoutMode) {
      return _checkout(context);
    }

    final orders = widget.controller.orders;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حالة الطلبات',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'لا توجد طلبات بعد',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: orders.length,
              itemBuilder: (_, index) {
                final order = orders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.slate200),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#' + order.id,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            _status(order.status),
                            style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        order.totalAmount.toStringAsFixed(2) +
                            ' ر.س • ' +
                            order.governorate,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _step('تم الطلب', true),
                      _step('جاري الشحن', order.status == 'in_shipping' || order.status == 'completed'),
                      _step('في الطريق إليكم', order.status == 'completed'),
                      _step('تم الاستلام', order.status == 'completed'),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _checkout(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تأكيد الطلب',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            c.cartCount.toString() +
                ' أصناف • ' +
                c.cartTotal.toStringAsFixed(2) +
                ' ر.س',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: address,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'عنوان التوصيل',
              hintText: 'الشارع، الحي، المعلم القريب...',
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظات التسليم',
            ),
          ),
          const SizedBox(height: 15),
          if (message != null)
            Text(
              message!,
              style: TextStyle(
                color: message!.startsWith('تم')
                    ? AppColors.emerald
                    : AppColors.rose,
                fontSize: 10,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: busy ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
              ),
              child: Text(
                busy ? 'جارٍ إرسال الطلب...' : 'تأكيد وإرسال الطلب',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String text, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: active ? AppColors.black : AppColors.slate300,
          ),
          const SizedBox(width: 7),
          Text(text,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _status(String value) {
    switch (value) {
      case 'in_shipping':
        return 'جاري الشحن';
      case 'completed':
        return 'تم الاستلام';
      case 'cancelled':
        return 'إلغاء الطلب';
      default:
        return 'تم الطلب';
    }
  }

  Future<void> _submitOrder() async {
    final c = widget.controller;
    if (c.profile == null) {
      setState(() => message = 'يرجى تسجيل الدخول أولاً');
      return;
    }
    if (address.text.trim().isEmpty) {
      setState(() => message = 'أدخل عنوان التوصيل أولاً');
      return;
    }

    setState(() {
      busy = true;
      message = null;
    });

    try {
      final id = await c.submitOrder(
        address: address.text,
        notes: notes.text,
      );
      setState(() {
        message = id == null
            ? 'تعذر إنشاء الطلب'
            : 'تم إنشاء الطلب رقم ' + id + ' بنجاح';
      });
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
