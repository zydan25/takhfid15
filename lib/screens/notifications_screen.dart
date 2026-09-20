import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/notification_item.dart';
import '../state/store_controller.dart';
import 'chat_screen.dart';
import 'order_status_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final StoreController controller;

  const NotificationsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Timer? poller;

  @override
  void initState() {
    super.initState();
    widget.controller.refreshNotifications();
    poller = Timer.periodic(
      const Duration(seconds: 15),
      (_) => widget.controller.refreshNotifications(),
    );
  }

  @override
  void dispose() {
    poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final items = widget.controller.notifications;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'الإشعارات',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            actions: [
              if (items.any((item) => !item.read))
                TextButton(
                  onPressed: widget.controller.markAllNotificationsRead,
                  child: const Text('قراءة الكل', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
          body: items.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد إشعارات جديدة',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.black,
                  onRefresh: widget.controller.refreshNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: items.length,
                    itemBuilder: (_, index) => _item(context, items[index]),
                  ),
                ),
        );
      },
    );
  }

  Widget _item(BuildContext context, NotificationItem item) {
    return InkWell(
      onTap: () => _open(item),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.read ? Colors.white : AppColors.roseSoft,
          border: Border.all(color: AppColors.slate200),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                _icon(item.type),
                size: 19,
                color: item.read ? AppColors.slate500 : AppColors.rose,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, height: 1.5, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            if (!item.read)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: CircleAvatar(radius: 3.5, backgroundColor: AppColors.rose),
              ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'order':
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'chat':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Future<void> _open(NotificationItem item) async {
    await widget.controller.markNotificationRead(item);
    if (!mounted) return;

    final sessionId =
        item.chatSessionId ?? item.data['sessionId']?.toString();

    if (sessionId != null && sessionId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            controller: widget.controller,
            sessionId: sessionId,
            title: item.orderId == null
                ? 'دعم العملاء'
                : 'محادثة الطلب ' + item.orderId!,
            orderId: item.orderId,
          ),
        ),
      );
      return;
    }

    if (item.orderId != null && item.orderId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(controller: widget.controller),
        ),
      );
    }
  }
}
