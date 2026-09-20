import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/content.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/store_api.dart';

class StoreController extends ChangeNotifier {
  final StoreApi api;

  bool loading = true;
  bool refreshing = false;
  String? error;

  List<Product> products = [];
  List<Category> categories = [];
  List<BannerItem> banners = [];
  List<TrendCampaign> campaigns = [];
  List<String> hashtags = [];
  List<StoreOrder> orders = [];
  Map<String, dynamic>? profile;

  final List<CartItem> cart = [];
  final Set<String> wishlistIds = {};
  int tabIndex = 0;

  StoreController(this.api);

  Future<void> bootstrap() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await Future.wait<dynamic>([
        api.fetchProducts(),
        api.fetchContent(),
        api.currentUser(),
      ]);
      products = data[0] as List<Product>;
      _applyContent(data[1] as Map<String, dynamic>);
      profile = data[2] as Map<String, dynamic>?;
      if (profile != null) {
        try {
          orders = await api.fetchOrders();
        } catch (_) {}
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _applyContent(Map<String, dynamic> content) {
    final rawCategories = content['categories'];
    if (rawCategories is List) {
      categories = rawCategories.whereType<Map>().map((e) {
        return Category.fromJson(Map<String, dynamic>.from(e));
      }).toList();
    }

    final rawBanners = content['banners'];
    if (rawBanners is List) {
      banners = rawBanners.whereType<Map>().map((e) {
        return BannerItem.fromJson(Map<String, dynamic>.from(e));
      }).where((e) => e.image.isNotEmpty).toList();
    }

    final rawCampaigns = content['campaigns'];
    if (rawCampaigns is List) {
      campaigns = rawCampaigns.whereType<Map>().map((e) {
        return TrendCampaign.fromJson(Map<String, dynamic>.from(e));
      }).toList();
    }

    final rawTags = content['hashtags'] ?? content['trendHashtags'];
    if (rawTags is List) {
      hashtags = rawTags.map((e) => e.toString()).toList();
    }
  }

  Future<void> refresh() async {
    if (refreshing) return;
    refreshing = true;
    error = null;
    notifyListeners();
    try {
      products = await api.fetchProducts();
      _applyContent(await api.fetchContent());
      if (profile != null) {
        try {
          orders = await api.fetchOrders();
        } catch (_) {}
      }
    } catch (e) {
      error = e.toString();
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  void selectTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  bool isWishlisted(Product product) => wishlistIds.contains(product.id);

  void toggleWishlist(Product product) {
    if (wishlistIds.contains(product.id)) {
      wishlistIds.remove(product.id);
    } else {
      wishlistIds.add(product.id);
    }
    notifyListeners();
  }

  void addToCart(Product product, {
    String? size,
    ProductColor? color,
    int quantity = 1,
  }) {
    final chosenSize =
        size ?? (product.sizes.isNotEmpty ? product.sizes.first : 'M');
    final chosenColor = color ??
        (product.colors.isNotEmpty
            ? product.colors.first
            : const ProductColor(name: 'أساسي', hex: '#111827'));
    final index = cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == chosenSize &&
          item.color.hex == chosenColor.hex,
    );
    if (index >= 0) {
      cart[index].quantity += quantity;
    } else {
      cart.add(CartItem(
        product: product,
        size: chosenSize,
        color: chosenColor,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      cart.remove(item);
    } else {
      item.quantity = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    cart.remove(item);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  int get cartCount =>
      cart.fold(0, (sum, item) => sum + item.quantity);

  double get cartTotal =>
      cart.fold(0, (sum, item) => sum + item.product.discountPrice * item.quantity);

  List<Product> filtered({
    String category = 'all',
    String? subCategory,
    String sort = 'for_you',
  }) {
    var list = products.toList();
    if (category != 'all') {
      list = list.where((p) {
        return p.category == category || p.categories.contains(category);
      }).toList();
    }
    if (subCategory != null && subCategory.isNotEmpty) {
      list = list.where((p) {
        return p.subCategory == subCategory || p.name.contains(subCategory);
      }).toList();
    }

    if (sort == 'discount') {
      list.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
    } else if (sort == 'popular') {
      list.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    } else if (sort == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (sort == 'price-low') {
      list.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
    } else if (sort == 'price-high') {
      list.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
    }
    return list;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    final result = await api.verifyOtp(phone, otp);
    final token = (result['accessToken'] ?? '').toString();
    if (token.isEmpty) return false;
    await api.client.saveToken(token);
    profile = result['user'] is Map
        ? Map<String, dynamic>.from(result['user'])
        : await api.currentUser();
    notifyListeners();
    return true;
  }

  Future<void> completeProfile({
    required String firstName,
    required String lastName,
    required String governorate,
  }) async {
    await api.completeProfile(
      firstName: firstName,
      lastName: lastName,
      governorate: governorate,
    );
    profile = await api.currentUser();
    notifyListeners();
  }

  Future<void> logout() async {
    await api.client.clearToken();
    profile = null;
    orders = [];
    notifyListeners();
  }

  Future<String?> submitOrder({
    required String address,
    required String notes,
  }) async {
    if (profile == null || cart.isEmpty) return null;
    final name = [
      profile?['firstName'],
      profile?['lastName'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    final payload = {
      'customerId': profile?['uid'] ?? profile?['id'],
      'customerName': name,
      'customerPhone': profile?['phone'] ?? '',
      'governorate': profile?['governorate'] ?? 'صنعاء',
      'shippingAddress': address.trim(),
      'deliveryNotes': notes.trim(),
      'totalAmount': cartTotal,
      'items': cart.map((item) {
        return {
          'productId': item.product.id,
          'name': item.product.name,
          'price': item.product.discountPrice,
          'quantity': item.quantity,
          'selectedColor': item.color.name,
          'selectedSize': item.size,
        };
      }).toList(),
    };

    final result = await api.createOrder(payload);
    final id = result['orderId']?.toString() ??
        (result['order'] is Map
            ? (result['order']['id']?.toString())
            : null);
    if (id != null) {
      cart.clear();
      try {
        orders = await api.fetchOrders();
      } catch (_) {}
      notifyListeners();
    }
    return id;
  }
}
