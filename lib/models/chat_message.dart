class ChatMessage {
  final String id;
  final String sessionId;
  final String sender;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;
  final bool isPaymentProof;
  final String? orderId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.text,
    required this.mediaUrl,
    required this.mediaType,
    required this.fileName,
    required this.isPaymentProof,
    required this.orderId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? '').toString(),
      sender: (json['sender'] ?? 'customer').toString(),
      text: (json['text'] ?? '').toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      mediaType: json['mediaType']?.toString(),
      fileName: json['fileName']?.toString(),
      isPaymentProof: json['isPaymentProof'] == true,
      orderId: json['orderId']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
