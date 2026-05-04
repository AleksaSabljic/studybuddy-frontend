import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  late ChatProvider _chat;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    _chat.markAsRead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _chat.markAsRead();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    _chat.send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final scheme = Theme.of(context).colorScheme;

    // Scroll to bottom when new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 100) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chat'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chat.connected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!chat.connected)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Disconnected', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),

          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56, color: scheme.primary.withOpacity(.3)),
                        const SizedBox(height: 12),
                        const Text('No messages yet.\nStart the conversation!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) =>
                        _MessageBubble(msg: chat.messages[i]),
                  ),
          ),

          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: chat.connected
                            ? 'Type a message…'
                            : 'Reconnecting…',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                      enabled: chat.connected,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor:
                        chat.connected ? scheme.primary : Colors.grey,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: chat.connected ? _send : null,
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
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
        decoration: BoxDecoration(
          color: msg.isMe ? scheme.primary : scheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment:
              msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!msg.isMe)
              Text(msg.username,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary)),
            Text(
              msg.text,
              style: TextStyle(
                  color:
                      msg.isMe ? Colors.white : scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(timeStr,
                style: TextStyle(
                    fontSize: 10,
                    color: (msg.isMe
                            ? Colors.white
                            : scheme.onSurfaceVariant)
                        .withOpacity(.6))),
          ],
        ),
      ),
    );
  }
}
