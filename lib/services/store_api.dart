import '../models/content.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'api_client.dart';

class StoreApi {
  final ApiClient client;
  StoreApi({ApiClient? client}) : client = client ?? ApiClient();

  Future<List<Product>> fetchProducts() async {
    final data = await client.get('/products?limit=200');
    final raw = data is Map && data['products'] is List
        ? data['products'] as List
        : (data is List ? data : const []);
    return raw.whereType<Map>().map((e) {
      return Product.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  Future<Map<String, dynamic>> fetchContent() async {
    final data = await client.get('/content');
    if (data is Map && data['content'] is Map) {
      return Map<String, dynamic>.from(data['content']);
    }
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<List<StoreOrder>> fetchOrders() async {
    final data = await client.get('/orders');
    final raw = data is Map && data['orders'] is List
        ? data['orders'] as List
        : (data is List ? data : const []);
    return raw.whereType<Map>().map((e) {
      return StoreOrder.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final result = await client.send(
      'POST',
      '/auth/send-otp',
      body: {'phoneNumber': normalizePhone(phone)},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final result = await client.send(
      'POST',
      '/auth/verify-otp',
      body: {'phoneNumber': normalizePhone(phone), 'otp': otp},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> completeProfile({
    required String firstName,
    required String lastName,
    required String governorate,
  }) async {
    final result = await client.send(
      'POST',
      '/auth/complete-profile',
      body: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'governorate': governorate,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> currentUser() async {
    if ((await client.token()) == null) return null;
    try {
      final result = await client.get('/auth/me');
      if (result is Map && result['user'] is Map) {
        return Map<String, dynamic>.from(result['user']);
      }
      return null;
    } catch (_) {
      await client.clearToken();
      return null;
    }
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> payload) async {
    final result = await client.send('POST', '/orders', body: payload);
    return Map<String, dynamic>.from(result as Map);
  }

  static String normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '967' + digits.substring(1);
    if (digits.length == 9 && digits.startsWith('7')) {
      digits = '967' + digits;
    }
    return digits;
  }
}
