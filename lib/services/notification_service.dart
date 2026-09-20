import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/notification_item.dart';
import 'local_cache.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await NotificationService.handleBackgroundMessage(message);
  } catch (_) {}
}

class NotificationService {
  final LocalCache cache;
  final FutureOr<void> Function(NotificationItem item)? onIncoming;
  final void Function(Map<String, dynamic> data)? onOpened;

  NotificationService({
    LocalCache? cache,
    this.onIncoming,
    this.onOpened,
  }) : cache = cache ?? LocalCache();

  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<String>? _tokenRefresh;

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final cache = LocalCache();
    final item = fromMessage(message);
    final existing = await cache.readJson('notifications');
    final list = existing is List ? List<dynamic>.from(existing) : <dynamic>[];
    list.removeWhere((e) => e is Map && e['id']?.toString() == item.id);
    list.insert(0, item.toJson());
    await cache.writeJson('notifications', list.take(100).toList());
  }

  static NotificationItem fromMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = <String, dynamic>{...message.data};

    return NotificationItem(
      id: message.messageId ??
          'fcm-' + DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? data['title']?.toString() ?? 'التخفيض الصح',
      body: notification?.body ?? data['body']?.toString() ?? '',
      imageUrl:
          notification?.android?.imageUrl ?? data['image']?.toString(),
      createdAt: DateTime.now(),
      data: data,
    );
  }

  Future<String?> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await cache.saveString('fcm_token', token);
      }
    } catch (_) {}

    try {
      await messaging.subscribeToTopic('takhfid_all');
    } catch (_) {}

    await _foreground?.cancel();
    _foreground = FirebaseMessaging.onMessage.listen((message) async {
      final item = fromMessage(message);
      await _save(item);
      await onIncoming?.call(item);
    });

    await _opened?.cancel();
    _opened = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onOpened?.call(Map<String, dynamic>.from(message.data));
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      onOpened?.call(Map<String, dynamic>.from(initial.data));
    }

    await _tokenRefresh?.cancel();
    _tokenRefresh = messaging.onTokenRefresh.listen((token) async {
      await cache.saveString('fcm_token', token);
    });

    return cache.readString('fcm_token');
  }

  Future<void> subscribeGovernorate(String governorate) async {
    final clean = governorate.trim();
    if (clean.isEmpty) return;
    final topic = 'takhfid_gov_' +
        clean.replaceAll(RegExp(r'\s+'), '_').replaceAll('/', '_');
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (_) {}
  }

  Future<List<NotificationItem>> load() async {
    final raw = await cache.readJson('notifications');
    if (raw is! List) return const [];

    return raw.whereType<Map>().map((item) {
      return NotificationItem.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Future<void> _save(NotificationItem item) async {
    final existing = await cache.readJson('notifications');
    final list = existing is List ? List<dynamic>.from(existing) : <dynamic>[];
    list.removeWhere((e) => e is Map && e['id']?.toString() == item.id);
    list.insert(0, item.toJson());
    await cache.writeJson('notifications', list.take(100).toList());
  }

  Future<void> dispose() async {
    await _foreground?.cancel();
    await _opened?.cancel();
    await _tokenRefresh?.cancel();
  }
}
