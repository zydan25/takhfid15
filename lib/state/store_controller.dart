import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../models/cart.dart';
import '../models/content.dart';
import '../models/notification_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/local_cache.dart';
import '../services/store_api.dart';

class StoreController extends ChangeNotifier {
  final StoreApi api;
  final LocalCache cache;

  bool loading = true;
  bool refreshing = false;
  String? error;

  List<Product> products = [];
  List<Category> categories = [];
  List<BannerItem> banners = [];
  List<TrendCampaign> campaigns = [];
  List<String> hashtags = [];
  List<StoreOrder> orders = [];
  List<NotificationItem> notifications = [];

  Map<String, dynamic>? profile;
  Map<String, dynamic> storeConfig = {};
  Map<String, dynamic> pricing = {};
  Map<String, dynamic> categoryTabsConfig = {'shape': 'circle', 'size': 'medium', 'isSquareRatio': true};
  Map<String, dynamic> styleTabsConfig = {'shape': 'rounded', 'size': 'large'};
  List<StyleTab> homeStyleTabs = [];
  Map<String, dynamic> announcements = {};
  List<RecommendationTab> recommendationTabs = [];
  String currency = 'YER';

  final List<CartItem> cart = [];
  final Set<String> wishlistIds = {};

  int tabIndex = 0;
  bool lastOtpNeedsProfile = false;
  String? lastCreatedOrderId;
  String? lastCreatedChatSessionId;

  Timer? _poller;
  bool _polling = false;

  StoreController(
    this.api, {
    LocalCache? cache,
  }) : cache = cache ?? LocalCache();

  Future<void> bootstrap() async {
    error = null;
    final restored = await Future.wait<bool>([
      _restoreProducts().then((_) => products.isNotEmpty),
      _restoreStore().then((_) => categories.isNotEmpty || banners.isNotEmpty),
      _restoreProfile().then((_) => profile != null),
      _restoreOrders().then((_) => orders.isNotEmpty),
      _restoreNotifications().then((_) => notifications.isNotEmpty),
    ]);
    await _restoreCartAndWishlist();

    final hasCachedContent = products.isNotEmpty || categories.isNotEmpty || banners.isNotEmpty;
    loading = !hasCachedContent;
    notifyListeners();

    _startPoller();
    unawaited(_backgroundRefresh(initial: true));
  }

  Future<void> _backgroundRefresh({bool initial = false}) async {
    if (refreshing && !initial) return;

    refreshing = true;
    notifyListeners();

    try {
      final rawProducts = await api.fetchAllProductMaps();
      if (rawProducts.isNotEmpty) {
        products = rawProducts.map(Product.fromJson).toList();
        await cache.writeJson('products', rawProducts);
      }
    } catch (_) {}

    try {
      final store = await api.fetchStore();
      if (store.isNotEmpty) {
        _applyStore(store);
        await cache.writeJson('store', store);
      }
    } catch (_) {}

    if (profile != null) {
      await _refreshCustomerData();
    }

    refreshing = false;
    if (initial || loading) loading = false;
    notifyListeners();
  }

  void _applyStore(Map<String, dynamic> store) {
    storeConfig = Map<String, dynamic>.from(
      store['store'] is Map ? store['store'] : const {},
    );
    pricing = Map<String, dynamic>.from(
      store['pricing'] is Map ? store['pricing'] : const {},
    );

    final content = Map<String, dynamic>.from(
      store['content'] is Map ? store['content'] : const {},
    );

    categoryTabsConfig = content['categoryTabsConfig'] is Map
        ? Map<String, dynamic>.from(content['categoryTabsConfig'])
        : <String, dynamic>{
            'shape': 'circle',
            'size': 'medium',
            'isSquareRatio': true,
          };
    styleTabsConfig = content['styleTabsConfig'] is Map
        ? Map<String, dynamic>.from(content['styleTabsConfig'])
        : <String, dynamic>{'shape': 'rounded', 'size': 'large'};

    final rawHomeStyles = content['homeStyleTabs'] ??
        content['styleTabs'] ??
        content['looks'] ??
        content['homeLooks'];
    if (rawHomeStyles is List) {
      homeStyleTabs = rawHomeStyles.whereType<Map>().map((raw) =>
          StyleTab.fromJson(Map<String, dynamic>.from(raw))).toList();
    } else {
      homeStyleTabs = [];
    }

    announcements = content['announcements'] is Map
        ? Map<String, dynamic>.from(content['announcements'])
        : <String, dynamic>{};
    recommendationTabs = content['recommendationTabs'] is List
        ? content['recommendationTabs'].whereType<Map>().map((raw) =>
            RecommendationTab.fromJson(Map<String, dynamic>.from(raw)))
          .where((x) => x.isActive).toList()
        : <RecommendationTab>[];
    recommendationTabs.sort((a, b) => a.order.compareTo(b.order));

    storeConfig['categoryTabsConfig'] = categoryTabsConfig;
    storeConfig['styleTabsConfig'] = styleTabsConfig;
    storeConfig['homeStyleTabs'] = homeStyleTabs
        .map((x) => {'id': x.id, 'name': x.name, 'image': x.image})
        .toList();
    storeConfig['announcements'] = announcements;
    storeConfig['recommendationTabs'] = recommendationTabs
        .map((x) => {'id': x.id, 'label': x.label})
        .toList();

    currency = (storeConfig['currency'] ?? currency).toString().toUpperCase();

    final rawCategories = content['categories'];
    if (rawCategories is List) {
      categories = rawCategories.whereType<Map>().map((raw) {
        return Category.fromJson(Map<String, dynamic>.from(raw));
      }).toList();
    }

    final rawBanners = content['banners'];
    if (rawBanners is List) {
      banners = rawBanners.whereType<Map>().map((raw) {
        return BannerItem.fromJson(Map<String, dynamic>.from(raw));
      }).where((item) => item.image.isNotEmpty).toList();
    }

    final rawCampaigns = content['campaigns'];
    if (rawCampaigns is List) {
      campaigns = rawCampaigns.whereType<Map>().map((raw) {
        return TrendCampaign.fromJson(Map<String, dynamic>.from(raw));
      }).toList();
    }

    final rawTags = content['hashtags'] ?? content['trendHashtags'];
    if (rawTags is List) {
      hashtags = rawTags.map((e) => e.toString()).toList();
    }
  }

  Future<void> refresh() async {
    if (refreshing) return;
    await _backgroundRefresh();
  }

  Future<void> sendOtp(String phone) => api.sendOtp(phone);

  Future<bool> verifyOtp(String phone, String otp) async {
    final result = await api.verifyOtp(phone, otp);
    final token = (result['accessToken'] ?? '').toString();

    if (token.isEmpty) return false;

    await api.client.saveToken(token);
    lastOtpNeedsProfile = result['needsProfile'] == true;

    profile = result['user'] is Map
        ? Map<String, dynamic>.from(result['user'])
        : await api.currentUser();

    if (profile != null) {
      await cache.writeJson('profile', profile!);
    }

    await _refreshCustomerData();
    _startPoller();
    notifyListeners();

    return true;
  }

  Future<void> completeProfile({
    required String firstName,
    String? secondName,
    String? thirdName,
    String? lastName,
    required String governorate,
  }) async {
    final result = await api.completeProfile(
      firstName: firstName,
      secondName: secondName,
      thirdName: thirdName,
      lastName: lastName,
      governorate: governorate,
    );

    if (result['user'] is Map) {
      profile = Map<String, dynamic>.from(result['user']);
    } else {
      profile = await api.currentUser();
    }

    if (profile != null) {
      await cache.writeJson('profile', profile!);
      await _refreshCustomerData();
    }

    lastOtpNeedsProfile = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();

    profile = null;
    orders = [];
    notifications = [];
    lastOtpNeedsProfile = false;
    lastCreatedOrderId = null;
    lastCreatedChatSessionId = null;

    _poller?.cancel();

    await cache.delete('profile');
    await cache.delete('orders');
    await cache.delete('notifications');

    notifyListeners();
  }

  void selectTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  bool isWishlisted(Product product) => wishlistIds.contains(product.id);

  Future<void> toggleWishlist(Product product) async {
    if (wishlistIds.contains(product.id)) {
      wishlistIds.remove(product.id);
    } else {
      wishlistIds.add(product.id);
    }

    await _saveCartAndWishlist();
    notifyListeners();
  }

  void addToCart(
    Product product, {
    String? size,
    ProductColor? color,
    int quantity = 1,
  }) {
    final chosenSize =
        size ?? (product.sizes.isNotEmpty ? product.sizes.first : '');
    final chosenColor = color ??
        (product.colors.isNotEmpty
            ? product.colors.first
            : const ProductColor(
                name: 'أساسي',
                hex: '#111827',
              ));

    final index = cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == chosenSize &&
          item.color.hex == chosenColor.hex,
    );

    if (index >= 0) {
      cart[index].quantity =
          (cart[index].quantity + quantity).clamp(1, 99);
    } else {
      cart.add(
        CartItem(
          product: product,
          size: chosenSize,
          color: chosenColor,
          quantity: quantity.clamp(1, 99),
        ),
      );
    }

    unawaited(_saveCartAndWishlist());
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      cart.remove(item);
    } else {
      item.quantity = quantity.clamp(1, 99);
    }

    unawaited(_saveCartAndWishlist());
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    cart.remove(item);
    unawaited(_saveCartAndWishlist());
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    unawaited(_saveCartAndWishlist());
    notifyListeners();
  }

  int get cartCount =>
      cart.fold(0, (sum, item) => sum + item.quantity);
  List<Product> productsByIds(List<String> ids) {
    if (ids.isEmpty) return [];
    final wanted = ids.toSet();
    return products.where((item) => wanted.contains(item.id)).toList();
  }

  List<Product> recommendations(RecommendationTab tab) {
    if (tab.linkedProductIds.isNotEmpty) return productsByIds(tab.linkedProductIds);
    var list = products.toList();
    if (tab.targetCategories.isNotEmpty) {
      list = list.where((item) =>
        tab.targetCategories.contains(item.category) ||
        item.categories.any(tab.targetCategories.contains)
      ).toList();
    }
    if (tab.targetSubCategories.isNotEmpty) {
      list = list.where((item) =>
        tab.targetSubCategories.contains(item.subCategory) ||
        tab.targetSubCategories.any((sub) => item.name.contains(sub))
      ).toList();
    }
    if (tab.keywords.isNotEmpty) {
      list = list.where((item) {
        final haystack = item.name + ' ' + item.description + ' ' + item.category + ' ' + item.subCategory;
        return tab.keywords.any((keyword) =>
            haystack.toLowerCase().contains(keyword.toLowerCase()));
      }).toList();
    }
    return list;
  }


  double get cartTotal => cart.fold(
        0,
        (sum, item) =>
            sum + item.product.discountPrice * item.quantity,
      );

  List<Product> filtered({
    String category = 'all',
    String? subCategory,
    String? styleTab,
    String sort = 'for_you',
    bool saleOnly = false,
    String? trend,
  }) {
    var list = products.toList();

    if (category != 'all') {
      list = list.where((p) {
        return p.category == category ||
            p.categories.contains(category);
      }).toList();
    }

    if (subCategory != null && subCategory.isNotEmpty) {
      final requested = subCategory.toLowerCase();
      final aliases = <String>{requested};

      for (final categoryItem in categories) {
        final matched = categoryItem.subCategories.where(
          (item) =>
              item.id.toLowerCase() == requested ||
              item.name.toLowerCase() == requested,
        );
        for (final item in matched) {
          aliases
            ..add(item.id.toLowerCase())
            ..add(item.name.toLowerCase());
        }
      }

      list = list.where((p) {
        final primary = p.subCategory.toLowerCase();
        final labels = p.subCategories.map((item) => item.toLowerCase());
        return aliases.contains(primary) ||
            labels.any(aliases.contains) ||
            labels.any(
              (item) => aliases.any((alias) => item.contains(alias)),
            ) ||
            aliases.any((alias) => p.name.toLowerCase().contains(alias));
      }).toList();
    }

    if (styleTab != null && styleTab.isNotEmpty) {
      list = list.where((p) {
        return p.styleTabs.contains(styleTab) ||
            p.name.contains(styleTab);
      }).toList();
    }

    if (saleOnly) {
      list = list.where((p) => p.discountPercentage > 0).toList();
    }
    if (trend != null && trend.isNotEmpty) {
      list = list.where((p) => p.trends.contains(trend) || p.name.contains(trend)).toList();
    }

    switch (sort) {
      case 'discount':
        list.sort(
          (a, b) => b.discountPercentage.compareTo(
            a.discountPercentage,
          ),
        );
        break;
      case 'popular':
        list.sort(
          (a, b) => b.soldCount.compareTo(a.soldCount),
        );
        break;
      case 'rating':
        list.sort(
          (a, b) => b.rating.compareTo(a.rating),
        );
        break;
      case 'price-low':
        list.sort(
          (a, b) => a.discountPrice.compareTo(b.discountPrice),
        );
        break;
      case 'price-high':
        list.sort(
          (a, b) => b.discountPrice.compareTo(a.discountPrice),
        );
        break;
    }

    return list;
  }

  Future<String?> submitOrder({
    required String address,
    required String notes,
    String paymentMethod = 'cash_on_delivery',
  }) async {
    if (profile == null || cart.isEmpty) return null;

    final name = [
      profile?['firstName'],
      profile?['secondName'],
      profile?['thirdName'],
      profile?['lastName'],
    ]
        .where(
          (value) =>
              value != null &&
              value.toString().trim().isNotEmpty,
        )
        .join(' ');

    final payload = {
      'customerName': name.isEmpty ? 'عميل المتجر' : name,
      'customerPhone': profile?['phone'] ?? '',
      'governorate':
          profile?['governorate'] ?? 'أمانة العاصمة',
      'address': address.trim(),
      'deliveryNotes': notes.trim(),
      'currency': currency,
      'paymentMethod': paymentMethod,
      'items': cart.map((item) {
        return {
          'productId': item.product.id,
          'quantity': item.quantity,
          'size': item.size,
          'color': item.color.name,
        };
      }).toList(),
    };

    final result = await api.createOrder(payload);

    lastCreatedOrderId =
        result['orderId']?.toString() ??
            (result['order'] is Map
                ? result['order']['id']?.toString()
                : null);
    lastCreatedChatSessionId =
        result['chatSessionId']?.toString();

    cart.clear();
    await _saveCartAndWishlist();
    await _refreshCustomerData();

    notifyListeners();
    return lastCreatedOrderId;
  }

  Future<String?> ensureChat({String? orderId}) async {
    if (profile == null) return null;

    final result =
        await api.createChatSession(orderId: orderId);
    final session = result['session'];

    return session is Map
        ? session['id']?.toString()
        : null;
  }

  Future<List<Map<String, dynamic>>> fetchChatMessages(
    String sessionId, {
    DateTime? since,
  }) {
    return api.chatMessages(
      sessionId,
      since: since,
    );
  }

  Future<Map<String, dynamic>> sendChatMessage(
    String sessionId, {
    String text = '',
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    bool isPaymentProof = false,
  }) {
    return api.sendChatMessage(
      sessionId,
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      fileName: fileName,
      isPaymentProof: isPaymentProof,
    );
  }

  Future<Map<String, dynamic>> uploadChatImage(
    String sessionId,
    dynamic file,
  ) {
    return api.uploadChatImage(sessionId, file);
  }

  Future<void> markChatRead(String sessionId) =>
      api.markChatRead(sessionId);

  Future<void> refreshNotifications() async {
    if (profile == null) return;

    try {
      notifications = await api.fetchNotifications();
      await cache.writeJson(
        'notifications',
        notifications
            .map((item) => item.toJson())
            .toList(),
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationRead(
    NotificationItem item,
  ) async {
    final id = int.tryParse(item.id);
    if (id == null) return;

    await api.markNotificationRead(id);

    final index = notifications.indexWhere(
      (x) => x.id == item.id,
    );

    if (index >= 0) {
      notifications[index] =
          notifications[index].copyWith(read: true);
      await cache.writeJson(
        'notifications',
        notifications
            .map((x) => x.toJson())
            .toList(),
      );
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (profile == null) return;

    await api.markNotificationsReadAll();
    notifications =
        notifications.map((x) => x.copyWith(read: true)).toList();

    await cache.writeJson(
      'notifications',
      notifications.map((x) => x.toJson()).toList(),
    );
    notifyListeners();
  }

  Future<void> _refreshCustomerData() async {
    if (profile == null) return;

    try {
      final rawOrders = await api.fetchOrderMaps();
      orders = rawOrders.map(StoreOrder.fromJson).toList();
      await cache.writeJson('orders', rawOrders);
    } catch (_) {}

    try {
      notifications = await api.fetchNotifications();
      await cache.writeJson(
        'notifications',
        notifications.map((x) => x.toJson()).toList(),
      );
    } catch (_) {}
  }

  Future<void> _restoreProducts() async {
    final raw = await cache.readJson('products');
    if (raw is List) {
      products = raw.whereType<Map>().map((item) {
        return Product.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    }
  }

  Future<void> _restoreStore() async {
    final raw = await cache.readJson('store');
    if (raw is Map) {
      _applyStore(Map<String, dynamic>.from(raw));
    }
  }

  Future<void> _restoreProfile() async {
    final raw = await cache.readJson('profile');
    if (raw is Map) {
      profile = Map<String, dynamic>.from(raw);
    }
  }

  Future<void> _restoreOrders() async {
    final raw = await cache.readJson('orders');
    if (raw is List) {
      orders = raw.whereType<Map>().map((item) {
        return StoreOrder.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    }
  }

  Future<void> _restoreNotifications() async {
    final raw = await cache.readJson('notifications');
    if (raw is List) {
      notifications = raw.whereType<Map>().map((item) {
        return NotificationItem.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    }
  }

  Future<void> _restoreCartAndWishlist() async {
    final rawWishlist = await cache.readJson('wishlist');
    if (rawWishlist is List) {
      wishlistIds
        ..clear()
        ..addAll(rawWishlist.map((e) => e.toString()));
    }

    final rawCart = await cache.readJson('cart');
    if (rawCart is! List) return;

    cart.clear();

    for (final rawItem in rawCart.whereType<Map>()) {
      final productId = rawItem['productId']?.toString();
      if (productId == null) continue;

      final matching =
          products.where((p) => p.id == productId);
      if (matching.isEmpty) continue;

      final product = matching.first;
      final requestedHex =
          rawItem['color']?.toString() ?? '#111827';
      final requestedName =
          rawItem['colorName']?.toString() ?? 'أساسي';

      ProductColor selected =
          product.colors.where((color) {
            return color.hex == requestedHex;
          }).firstOrNull ??
          (product.colors.isNotEmpty
              ? product.colors.first
              : ProductColor(
                  name: requestedName,
                  hex: requestedHex,
                ));

      if (selected.name != requestedName &&
          requestedName.isNotEmpty) {
        selected = ProductColor(
          name: requestedName,
          hex: selected.hex,
        );
      }

      final quantity =
          rawItem['quantity'] is num
              ? (rawItem['quantity'] as num)
                  .toInt()
                  .clamp(1, 99)
              : 1;

      cart.add(
        CartItem(
          product: product,
          size: rawItem['size']?.toString() ?? '',
          color: selected,
          quantity: quantity,
        ),
      );
    }
  }

  Future<void> _saveCartAndWishlist() async {
    await cache.writeJson(
      'wishlist',
      wishlistIds.toList(),
    );

    await cache.writeJson(
      'cart',
      cart.map((item) {
        return {
          'productId': item.product.id,
          'size': item.size,
          'color': item.color.hex,
          'colorName': item.color.name,
          'quantity': item.quantity,
        };
      }).toList(),
    );
  }

  void _startPoller() {
    _poller?.cancel();

    if (profile == null) return;

    _poller = Timer.periodic(
      const Duration(seconds: 15),
      (_) async {
        if (_polling || profile == null) return;
        _polling = true;
        await _refreshCustomerData();
        _polling = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
