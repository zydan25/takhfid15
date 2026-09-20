import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import '../models/chat_message.dart';
import '../state/store_controller.dart';

class ChatScreen extends StatefulWidget {
  final StoreController controller;
  final String sessionId;
  final String title;
  final String? orderId;

  const ChatScreen({
    super.key,
    required this.controller,
    required this.sessionId,
    required this.title,
    this.orderId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final picker = ImagePicker();

  List<ChatMessage> messages = [];
  Timer? poller;
  DateTime? lastMessageAt;
  bool loading = true;
  bool sending = false;
  bool attaching = false;

  @override
  void initState() {
    super.initState();
    _load();
    poller = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    poller?.cancel();
    input.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => loading = true);

    try {
      final raw = await widget.controller.fetchChatMessages(
        widget.sessionId,
        since: silent ? lastMessageAt : null,
      );
      final incoming = raw.map(ChatMessage.fromJson).toList();

      if (silent && lastMessageAt != null) {
        final known = messages.map((item) => item.id).toSet();
        messages.addAll(incoming.where((item) => !known.contains(item.id)));
      } else {
        messages = incoming;
      }

      if (messages.isNotEmpty) {
        lastMessageAt = messages.last.createdAt;
        await widget.controller.markChatRead(widget.sessionId);
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (!silent) _snack(e.toString());
    } finally {
      if (!silent && mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: [
          if (widget.orderId != null)
            IconButton(
              tooltip: 'الطلب المرتبط',
              onPressed: () => _snack(
                'المحادثة مرتبطة بالطلب ' + widget.orderId!,
              ),
              icon: const Icon(Icons.receipt_long_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'ابدأ المحادثة مع خدمة العملاء',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                        itemCount: messages.length,
                        itemBuilder: (_, index) => _bubble(messages[index]),
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.slate200),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: attaching ? null : _pickImage,
                    icon: const Icon(Icons.attach_file_rounded),
                  ),
                  if (widget.orderId != null)
                    IconButton(
                      tooltip: 'إرسال سند الدفع',
                      onPressed: attaching ? null : _pickPayment,
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.rose,
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: sending ? null : _sendText,
                    icon: Icon(
                      Icons.send_rounded,
                      color: sending ? AppColors.slate300 : AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage message) {
    final mine = message.sender == 'customer';
    final media = message.mediaUrl;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: mine ? AppColors.black : AppColors.slate100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (media != null && media.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: CachedNetworkImage(
                  imageUrl: _absoluteUrl(media),
                  width: 250,
                  height: 240,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(
                    height: 80,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            if (message.isPaymentProof)
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 3),
                child: Text(
                  'سند دفع',
                  style: TextStyle(
                    color: mine ? Colors.white : AppColors.rose,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.ink,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _absoluteUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://whats.alattab.site' + value;
  }

  Future<void> _sendText() async {
    final value = input.text.trim();
    if (value.isEmpty || sending) return;

    setState(() => sending = true);
    try {
      await widget.controller.sendChatMessage(
        widget.sessionId,
        text: value,
      );
      input.clear();
      await _load();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _pickImage() async {
    final source = await _source();
    if (source == null) return;
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (file != null) await _upload(file, false);
  }

  Future<void> _pickPayment() async {
    final source = await _source();
    if (source == null) return;
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (file != null) await _upload(file, true);
  }

  Future<ImageSource?> _source() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('المعرض'),
              onTap: () => Navigator.pop(_, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('الكاميرا'),
              onTap: () => Navigator.pop(_, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload(XFile file, bool paymentProof) async {
    setState(() => attaching = true);

    try {
      final uploaded = await widget.controller.uploadChatImage(
        widget.sessionId,
        file,
      );
      final url = uploaded['relativeUrl']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('الخادم لم يُرجع رابط المرفق');
      }

      await widget.controller.sendChatMessage(
        widget.sessionId,
        text: paymentProof ? 'تم إرفاق سند الدفع للطلب.' : '',
        mediaUrl: url,
        mediaType: uploaded['mediaType']?.toString(),
        fileName: uploaded['fileName']?.toString() ?? file.name,
        isPaymentProof: paymentProof,
      );
      await _load();
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => attaching = false);
    }
  }

  void _snack(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }
}
