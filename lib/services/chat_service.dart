import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image/image.dart' as img;

import '../firebase_options.dart';

class ChatService {
  static const databaseId = 'ai-studio-3cbe8e72-8545-44eb-90af-bac8612b6c5c';

  late final FirebaseFirestore db;
  bool initialized = false;

  Future<void> initialize() async {
    if (initialized) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: databaseId,
    );
    initialized = true;
  }

  String customerKey({String? userId, String? phone}) {
    if (userId != null && userId.trim().isNotEmpty) return userId.trim();
    final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 'guest_me' : 'c_' + digits;
  }

  String sessionId({String? userId, String? phone, String? orderId}) {
    final key = customerKey(userId: userId, phone: phone);
    if (orderId == null || orderId.trim().isEmpty) return 'chat_' + key;
    return 'chat_' + key + '_order_' + orderId.trim();
  }

  DocumentReference<Map<String, dynamic>> _session(String id) {
    return db.collection('chats').doc(id);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String id) {
    return _session(id)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(200)
        .snapshots();
  }

  Future<void> markRead(String id) async {
    try {
      await _session(id).set({
        'unreadByUser': 0,
        'lastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> ensureSession({
    required String sessionId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String governorate,
    String? orderId,
    double totalAmount = 0,
    List<Map<String, dynamic>> cartItems = const [],
    String status = 'pending_payment',
  }) async {
    await initialize();
    await _session(sessionId).set({
      'id': sessionId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAvatar': '',
      'governorate': governorate,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByAdmin': 0,
      'unreadByUser': 0,
      'status': status,
      'totalAmount': totalAmount,
      'orderId': orderId,
      'cartItems': cartItems,
      'messages': const [],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createOrderSession({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String governorate,
    required String orderId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final id = sessionId(
      userId: customerId,
      phone: customerPhone,
      orderId: orderId,
    );
    await ensureSession(
      sessionId: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      governorate: governorate,
      orderId: orderId,
      totalAmount: totalAmount,
      cartItems: items,
    );
  }

  Future<void> sendMessage({
    required String sessionId,
    required String customerId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    bool isPaymentProof = false,
    String? orderId,
  }) async {
    await initialize();

    final messageId = 'msg-u-' +
        DateTime.now().millisecondsSinceEpoch.toString() +
        '-' +
        DateTime.now().microsecond.toString();
    final now = FieldValue.serverTimestamp();

    final message = <String, dynamic>{
      'id': messageId,
      'chatId': sessionId,
      'sender': 'user',
      'senderUid': customerId,
      'text': text,
      'timestamp': now,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
      if (fileName != null) 'fileName': fileName,
      'isPaymentProof': isPaymentProof,
      if (orderId != null) 'orderId': orderId,
    };

    await _session(sessionId).collection('messages').doc(messageId).set(message);

    await _session(sessionId).set({
      'lastMessage':
          text.trim().isEmpty ? 'مرفق أو إشعار 📎' : text.trim(),
      'lastMessageTime': now,
      'unreadByAdmin': FieldValue.increment(1),
      if (orderId != null && orderId.trim().isNotEmpty) 'orderId': orderId,
    }, SetOptions(merge: true));
  }

  static Uint8List _encodeImage(Uint8List bytes) {
    var decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('تعذر قراءة الصورة');

    const maxDimension = 900;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        decoded = img.copyResize(decoded, width: maxDimension);
      } else {
        decoded = img.copyResize(decoded, height: maxDimension);
      }
    }

    var jpeg = img.encodeJpg(decoded, quality: 72);

    if (jpeg.length > 700000) {
      if (decoded.width > 700 || decoded.height > 700) {
        if (decoded.width >= decoded.height) {
          decoded = img.copyResize(decoded, width: 700);
        } else {
          decoded = img.copyResize(decoded, height: 700);
        }
      }
      jpeg = img.encodeJpg(decoded, quality: 60);
    }

    return Uint8List.fromList(jpeg);
  }

  static String encodeImageForFirestore(Uint8List bytes) {
    return 'data:image/jpeg;base64,' +
        base64Encode(_encodeImage(bytes));
  }
}
