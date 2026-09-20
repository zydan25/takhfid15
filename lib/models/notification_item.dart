class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final bool read;

  String get type => (data['type'] ?? data['notificationType'] ?? 'default').toString();

  String? get chatSessionId {
    final value = data['chatSessionId'] ?? data['sessionId'];
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  String? get orderId {
    final value = data['orderId'] ?? data['order_id'];
    final text = value?.toString();
    return text == null || text.isEmpty ? null : text;
  }

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.createdAt,
    this.data = const {},
    this.read = false,
  });

  NotificationItem copyWith({bool? read}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      createdAt: createdAt,
      data: data,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
      'read': read,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'إشعار').toString(),
      body: (json['body'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'])
          : const {},
      read: json['read'] == true,
    );
  }
}
