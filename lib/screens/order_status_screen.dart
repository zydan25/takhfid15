import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/order.dart';
import '../state/store_controller.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

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
    if (widget.checkoutMode) return _checkout();

    final orders = widget.controller.orders;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text(
          'سجل طلباتي',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'لا توجد طلبات سابقة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            )
          : RefreshIndicator(
              onRefresh: widget.controller.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 25),
                itemCount: orders.length,
                itemBuilder: (_, index) => _orderCard(orders[index]),
              ),
            ),
    );
  }

  Widget _orderCard(StoreOrder order) {
    final orderLabel =
        order.orderNumber.isEmpty ? order.id : order.orderNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E6EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'محادثة الطلب',
                onPressed: () => _openOrderChat(order),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'طلب ' + orderLabel,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (order.createdAt.isNotEmpty)
                      Text(
                        order.createdAt,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.slate500,
                        ),
                      ),
                  ],
                ),
              ),
              _statusBadge(order.status),
            ],
          ),
          const Divider(height: 12),
          if (order.items.isNotEmpty)
            ...order.items.map(_orderItem),
          if (order.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'تفاصيل الأصناف غير متاحة في الاستجابة الحالية',
                style: TextStyle(fontSize: 9, color: AppColors.slate500),
              ),
            ),
          const Divider(height: 14),
          _line('المحافظة', order.governorate),
          if (order.address.isNotEmpty) _line('العنوان', order.address),
          if (order.deliveryNotes.isNotEmpty)
            _line('ملاحظات التسليم', order.deliveryNotes),
          if (order.paymentMethod.isNotEmpty)
            _line('الدفع', order.paymentMethod),
          if (order.trackingNumber.isNotEmpty)
            _line('رقم التتبع', order.trackingNumber),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.isPaid ? 'تم الدفع' : 'الدفع غير مكتمل',
                  style: TextStyle(
                    color: order.isPaid
                        ? AppColors.emerald
                        : AppColors.rose,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                order.totalAmount.toStringAsFixed(2) +
                    ' ' +
                    order.currency,
                style: const TextStyle(
                  color: AppColors.rose,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => _openOrderChat(order),
              icon: const Icon(Icons.support_agent_rounded, size: 17),
              label: const Text(
                'محادثة حول هذا الطلب',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderItem(StoreOrderItem item) {
    final image = item.image;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 54,
              height: 54,
              child: image.isEmpty
                  ? const ColoredBox(
                      color: AppColors.slate100,
                      child: Icon(Icons.image_outlined),
                    )
                  : CachedNetworkImage(
                      imageUrl: _absoluteUrl(image),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: AppColors.slate100,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.productName.isEmpty ? item.productId : item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الكمية: ' + item.quantity.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.slate500,
                  ),
                ),
                if (item.color.isNotEmpty || item.size.isNotEmpty)
                  Text(
                    [
                      if (item.color.isNotEmpty) 'اللون: ' + item.color,
                      if (item.size.isNotEmpty) 'المقاس: ' + item.size,
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.slate500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.price.toStringAsFixed(2) + ' ' + widget.controller.currency,
            style: const TextStyle(
              color: AppColors.rose,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final data = <String, dynamic>{
      'preparing': ('جاري التجهيز بالمستودع', Icons.inventory_2_outlined),
      'in_shipping': ('جاري الشحن والتوصيل', Icons.local_shipping_outlined),
      'delivered': ('تم التوصيل بنجاح', Icons.check_circle_outline_rounded),
      'completed': ('تم الاستلام', Icons.check_circle_outline_rounded),
      'cancelled': ('ملغي', Icons.cancel_outlined),
      'pending_payment': ('بانتظار الدفع', Icons.payments_outlined),
    };
    final value = data[status] ??
        ('تم استلام الطلب', Icons.receipt_long_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value.$2 as IconData,
            size: 13,
            color: AppColors.ink,
          ),
          const SizedBox(width: 4),
          Text(
            value.$1 as String,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOrderChat(StoreOrder order) async {
    if (widget.controller.profile == null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(controller: widget.controller),
        ),
      );
      return;
    }

    String? sessionId = order.chatSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      try {
        sessionId = await widget.controller.ensureChat(orderId: order.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }
    }

    if (!mounted) return;
    if (sessionId == null || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الخادم لم يُرجع معرف محادثة الطلب')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          controller: widget.controller,
          sessionId: sessionId!,
          title: 'محادثة الطلب ' +
              (order.orderNumber.isEmpty ? order.id : order.orderNumber),
          orderId: order.id,
        ),
      ),
    );
  }

  Widget _checkout() {
    final c = widget.controller;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text(
          'تأكيد الطلب',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 25),
        children: [
          _checkoutSummary(c),
          const SizedBox(height: 10),
          _field(address, 'عنوان التوصيل', 'الشارع، الحي، المعلم القريب...'),
          const SizedBox(height: 9),
          _field(notes, 'ملاحظات التسليم', 'أي تفاصيل مهمة للتوصيل'),
          const SizedBox(height: 12),
          if (message != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: message!.startsWith('تم')
                    ? const Color(0xFFE7F5E7)
                    : const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: message!.startsWith('تم')
                      ? AppColors.emerald
                      : AppColors.rose,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: busy ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: Text(
                busy ? 'جارٍ إرسال الطلب...' : 'تأكيد وإرسال الطلب',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkoutSummary(StoreController c) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E6EA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              c.cartCount.toString() + ' أصناف',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            c.cartTotal.toStringAsFixed(2) + ' ' + c.currency,
            style: const TextStyle(
              color: AppColors.rose,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E6EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E6EA)),
        ),
      ),
    );
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
      setState(
        () => message = id == null
            ? 'تعذر إنشاء الطلب'
            : 'تم إنشاء الطلب رقم ' + id + ' بنجاح',
      );
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _absoluteUrl(String value) {
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:')) {
      return value;
    }
    if (value.startsWith('//')) return 'https:' + value;
    return 'https://whats.alattab.site' +
        (value.startsWith('/') ? value : '/' + value);
  }
}
