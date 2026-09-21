class StoreOrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String image;
  final String color;
  final String size;

  const StoreOrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.image = '',
    this.color = '',
    this.size = '',
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

    return StoreOrderItem(
      productId: (json['productId'] ?? json['id'] ?? '').toString(),
      productName: (json['productName'] ?? json['name'] ?? json['title'] ?? '').toString(),
      price: number(json['price'] ?? json['unitPrice'] ?? json['discountPrice']),
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toInt()
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      image: (json['image'] ?? json['imageUrl'] ?? json['thumbnail'] ?? '').toString(),
      color: (json['color'] ?? json['selectedColor'] ?? '').toString(),
      size: (json['size'] ?? json['selectedSize'] ?? '').toString(),
    );
  }
}

class StoreOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String governorate;
  final String address;
  final String deliveryNotes;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double totalAmount;
  final String currency;
  final String status;
  final bool isPaid;
  final String paymentMethod;
  final String trackingNumber;
  final String createdAt;
  final String? chatSessionId;
  final List<StoreOrderItem> items;

  const StoreOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.governorate,
    required this.address,
    required this.deliveryNotes,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.isPaid,
    required this.paymentMethod,
    required this.trackingNumber,
    required this.createdAt,
    required this.chatSessionId,
    required this.items,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    dynamic unwrap(dynamic value) {
      if (value is Map) {
        for (final key in const ['order', 'data', 'result']) {
          final nested = value[key];
          if (nested is Map) return unwrap(nested);
        }
      }
      return value;
    }

    final data = Map<String, dynamic>.from(
      (unwrap(json) is Map ? unwrap(json) : json) as Map,
    );

    double number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

    final rawItems = data['items'] ?? data['orderItems'] ?? data['products'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((item) {
            return StoreOrderItem.fromJson(Map<String, dynamic>.from(item));
          }).toList()
        : <StoreOrderItem>[];

    return StoreOrder(
      id: (data['id'] ?? data['orderId'] ?? '').toString(),
      orderNumber: (data['orderNumber'] ?? data['number'] ?? data['id'] ?? '').toString(),
      customerName: (data['customerName'] ?? data['name'] ?? '').toString(),
      customerPhone: (data['customerPhone'] ?? data['phone'] ?? '').toString(),
      governorate: (data['governorate'] ?? 'أمانة العاصمة').toString(),
      address: (data['address'] ?? data['shippingAddress'] ?? '').toString(),
      deliveryNotes: (data['deliveryNotes'] ?? data['notes'] ?? '').toString(),
      subtotal: number(data['subtotal']),
      shippingFee: number(data['shippingFee'] ?? data['deliveryFee']),
      discount: number(data['discount']),
      totalAmount: number(data['totalAmount'] ?? data['total']),
      currency: (data['currency'] ?? 'SAR').toString(),
      status: (data['status'] ?? 'pending_payment').toString(),
      isPaid: data['isPaid'] == true || data['paid'] == true,
      paymentMethod: (data['paymentMethod'] ?? '').toString(),
      trackingNumber: (data['trackingNumber'] ?? data['tracking'] ?? '').toString(),
      createdAt: (data['createdAt'] ?? data['date'] ?? '').toString(),
      chatSessionId: (data['chatSessionId'] ??
              data['sessionId'] ??
              (data['chatSession'] is Map
                  ? data['chatSession']['id']
                  : null))
          ?.toString(),
      items: items,
    );
  }
}
