import 'package:image_picker/image_picker.dart';

import '../models/content.dart';
import '../models/notification_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'api_client.dart';

String _assetUrl(dynamic value) {
  if (value is Map) {
    value = value['url'] ??
        value['src'] ??
        value['image'] ??
        value['imageUrl'] ??
        value['original'] ??
        value['thumbnail'];
  }

  var url = value?.toString().trim() ?? '';
  if (url.isEmpty || url == 'null') return '';
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('http://') ||
      url.startsWith('https://') ||
      url.startsWith('data:') ||
      url.startsWith('blob:')) {
    return url;
  }
  if (url.startsWith('/')) return 'https://whats.alattab.site$url';
  return 'https://whats.alattab.site/$url';
}

dynamic _normalizeProductMap(dynamic raw) {
  if (raw is! Map) return raw;
  final item = Map<String, dynamic>.from(raw);

  final imageCandidate = item['image'] ??
      item['imageUrl'] ??
      item['mainImage'] ??
      item['coverImage'] ??
      item['cover_image'] ??
      item['thumbnail'] ??
      item['thumbnailUrl'] ??
      item['image_url'];
  if ((item['image'] ?? '').toString().trim().isEmpty && imageCandidate != null) {
    item['image'] = _assetUrl(imageCandidate);
  } else if (item['image'] != null) {
    item['image'] = _assetUrl(item['image']);
  }

  for (final key in const ['images', 'gallery', 'galleryImages', 'imageUrls', 'photos']) {
    final value = item[key];
    if (value is List) {
      item[key] = value.map(_assetUrl).where((x) => x.isNotEmpty).toList();
    }
  }

  final colors = item['colors'];
  if (colors is List) {
    item['colors'] = colors.whereType<Map>().map((rawColor) {
      final color = Map<String, dynamic>.from(rawColor);
      final image = color['image'] ?? color['imageUrl'];
      if (image != null) color['image'] = _assetUrl(image);
      return color;
    }).toList();
  }

  return item;
}

class StoreApi {
  final ApiClient client;

  StoreApi({ApiClient? client}) : client = client ?? ApiClient();

  Future<Map<String, dynamic>> fetchStore() async {
    Map<String, dynamic> store = {};
    Map<String, dynamic> content = {};

    try {
      final raw = await client.get('/store');
      if (raw is Map) {
        store = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    try {
      final raw = await client.get('/content');
      if (raw is Map) {
        final root = Map<String, dynamic>.from(raw);
        content = root['content'] is Map
            ? Map<String, dynamic>.from(root['content'] as Map)
            : root;
      }
    } catch (_) {}

    final merged = <String, dynamic>{...store};

    // Prefer explicit /content values only when /store did not provide them.
    for (final key in const [
      'categories',
      'banners',
      'campaigns',
      'announcements',
      'recommendationTabs',
      'sideCategories',
      'sidebarCategories',
      'homeTopTabs',
      'topTabs',
      'navigationTabs',
      'homeNavigationTabs',
      'homeStyleTabs',
      'styleTabs',
      'looks',
      'homeLooks',
      'categoryTabsConfig',
      'styleTabsConfig',
      'hashtags',
      'trendHashtags',
      'products',
      'pricingSettings',
    ]) {
      final existing = merged[key];
      final missing = existing == null ||
          (existing is List && existing.isEmpty) ||
          (existing is Map && existing.isEmpty);
      if (missing && content[key] != null) {
        merged[key] = content[key];
      }
    }

    final existingNested = merged['content'];
    final nested = existingNested is Map
        ? Map<String, dynamic>.from(existingNested as Map)
        : <String, dynamic>{};
    nested.addAll(content);
    if (nested.isNotEmpty) {
      merged['content'] = nested;
    }

    return merged;
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
      final list = map['products'] is List
          ? map['products'] as List
          : map['data'] is List
              ? map['data'] as List
              : map['items'] is List
                  ? map['items'] as List
                  : const [];

      final page = list.whereType<Map>().map(_normalizeProductMap).whereType<Map>().map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      products.addAll(page);

      final total = map['total'] is num ? (map['total'] as num).toInt() : null;
      final hasMore = map['hasMore'] == true || map['has_next'] == true || map['next'] != null;
      if (page.length < pageSize ||
          (total != null && products.length >= total) ||
          (!hasMore && total == null && page.isEmpty)) {
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

  Future<Map<String, dynamic>> fetchContent() async {
    final raw = await client.get('/content');
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['content'] is Map) {
        return Map<String, dynamic>.from(map['content'] as Map);
      }
      return map;
    }
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final raw = await client.get('/categories');
    final list = raw is Map && raw['categories'] is List
        ? raw['categories'] as List
        : raw is List
            ? raw
            : const [];
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> fetchPricing() async {
    final raw = await client.get('/pricing');
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return map['pricing'] is Map
          ? Map<String, dynamic>.from(map['pricing'] as Map)
          : map;
    }
    return <String, dynamic>{};
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

  Future<Product?> fetchProductById(String productId) async {
    if (productId.trim().isEmpty) return null;
    final raw = await client.get('/products/${Uri.encodeComponent(productId)}');
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final candidate = map['product'] ?? map['data'] ?? raw;
    return candidate is Map
        ? Product.fromJson(
            Map<String, dynamic>.from(_normalizeProductMap(candidate)),
          )
        : null;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    String? secondName,
    String? thirdName,
    String? lastName,
    required String governorate,
  }) async {
    final payload = {
      'firstName': firstName.trim(),
      'secondName': secondName?.trim() ?? '',
      'thirdName': thirdName?.trim() ?? '',
      'lastName': lastName?.trim() ?? '',
      'governorate': governorate.trim(),
    };

    try {
      final raw = await client.send('PATCH', '/auth/me', body: payload);
      return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    } on ApiException {
      final raw = await client.send(
        'POST',
        '/auth/complete-profile',
        body: payload,
      );
      return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    }
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
    final bytes = await file.readAsBytes();
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
