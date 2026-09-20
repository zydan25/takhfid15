import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../models/content.dart';
import '../models/notification_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'api_client.dart';

class StoreApi {
  final ApiClient client;

  StoreApi({ApiClient? client}) : client = client ?? ApiClient();

  Future<Map<String, dynamic>> fetchStore() async {
    final raw = await client.get('/store');
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<List<Map<String, dynamic>>> fetchAllProductMaps() async {
    final products = <Map<String, dynamic>>[];
    const pageSize = 100;
    var offset = 0;

    while (true) {
      final raw = await client.get(
        '/products',
        query: {
          'limit': '$pageSize',
          'offset': '$offset',
        },
      );
      final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
      final list = map['products'] is List ? map['products'] as List : const [];

      final page = list.whereType<Map>().map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      products.addAll(page);

      final total =
          map['total'] is num ? (map['total'] as num).toInt() : null;
      if (page.length < pageSize ||
          (total != null && products.length >= total)) {
        break;
      }
      offset += pageSize;
    }

    return products;
  }

  Future<List<Product>> fetchAllProducts() async {
    final maps = await fetchAllProductMaps();
    return maps.map(Product.fromJson).toList();
  }

  Future<Map<String, dynamic>?> currentUser() async {
    if ((await client.token()) == null) return null;
    final raw = await client.get('/auth/me');
    if (raw is Map && raw['user'] is Map) {
      return Map<String, dynamic>.from(raw['user']);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await client.send('POST', '/auth/logout');
    } finally {
      await client.clearToken();
    }
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final raw = await client.send(
      'POST',
      '/auth/send-otp',
      body: {'phoneNumber': normalizePhone(phone)},
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final raw = await client.send(
      'POST',
      '/auth/verify-otp',
      body: {
        'phoneNumber': normalizePhone(phone),
        'otp': otp.trim(),
      },
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<Map<String, dynamic>> completeProfile({
    required String firstName,
    String? secondName,
    String? thirdName,
    String? lastName,
    required String governorate,
  }) async {
    final raw = await client.send(
      'POST',
      '/auth/complete-profile',
      body: {
        'firstName': firstName.trim(),
        'secondName': secondName?.trim() ?? '',
        'thirdName': thirdName?.trim() ?? '',
        'lastName': lastName?.trim() ?? '',
        'governorate': governorate,
      },
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<List<Map<String, dynamic>>> fetchOrderMaps() async {
    final raw = await client.get('/orders');
    final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    final list = map['orders'] is List ? map['orders'] as List : const [];
    return list.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<List<StoreOrder>> fetchOrders() async {
    final maps = await fetchOrderMaps();
    return maps.map(StoreOrder.fromJson).toList();
  }

  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> payload,
  ) async {
    final raw = await client.send('POST', '/orders', body: payload);
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<Map<String, dynamic>> createChatSession({String? orderId}) async {
    final raw = await client.send(
      'POST',
      '/chat/sessions',
      body: {
        if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
      },
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<List<Map<String, dynamic>>> chatMessages(
    String sessionId, {
    DateTime? since,
  }) async {
    final query = <String, String>{'limit': '200'};
    if (since != null) {
      query['since'] = since.toUtc().toIso8601String();
    }

    final raw = await client.get(
      '/chat/sessions/$sessionId/messages',
      query: query,
    );
    final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    final list = map['messages'] is List ? map['messages'] as List : const [];
    return list.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>> sendChatMessage(
    String sessionId, {
    String text = '',
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    bool isPaymentProof = false,
  }) async {
    final raw = await client.send(
      'POST',
      '/chat/sessions/$sessionId/messages',
      body: {
        'text': text.trim(),
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaType != null) 'mediaType': mediaType,
        if (fileName != null) 'fileName': fileName,
        'isPaymentProof': isPaymentProof,
      },
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<Map<String, dynamic>> uploadChatImage(
    String sessionId,
    XFile file,
  ) async {
    final bytes = await File(file.path).readAsBytes();
    final raw = await client.multipart(
      '/chat/sessions/$sessionId/media/upload',
      fieldName: 'file',
      fileName: file.name,
      bytes: bytes,
    );
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> markChatRead(String sessionId) async {
    await client.send('PATCH', '/chat/sessions/$sessionId/read');
  }

  Future<List<NotificationItem>> fetchNotifications() async {
    final raw = await client.get('/notifications');
    final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    final list = map['notifications'] is List
        ? map['notifications'] as List
        : const [];
    return list.whereType<Map>().map((item) {
      return NotificationItem.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<void> markNotificationRead(int id) async {
    await client.send('PATCH', '/notifications/$id/read');
  }

  Future<void> markNotificationsReadAll() async {
    await client.send('POST', '/notifications/read-all');
  }

  static String normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '967' + digits.substring(1);
    if (digits.length == 9 && digits.startsWith('7')) {
      digits = '967$digits';
    }
    return digits;
  }
}
