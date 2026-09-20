class StoreOrder {
  final String id;
  final String customerName;
  final String governorate;
  final double totalAmount;
  final String status;
  final bool isPaid;

  const StoreOrder({
    required this.id,
    required this.customerName,
    required this.governorate,
    required this.totalAmount,
    required this.status,
    required this.isPaid,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['totalAmount'];
    final total = rawTotal is num
        ? rawTotal.toDouble()
        : double.tryParse(rawTotal?.toString() ?? '') ?? 0;
    return StoreOrder(
      id: (json['id'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      governorate: (json['governorate'] ?? 'صنعاء').toString(),
      totalAmount: total,
      status: (json['status'] ?? 'pending_payment').toString(),
      isPaid: json['isPaid'] == true,
    );
  }
}
