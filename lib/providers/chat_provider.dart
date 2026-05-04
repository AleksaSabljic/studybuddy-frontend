import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../utils/app_config.dart';

class ChatProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final List<ChatMessage> messages = [];
  int _lastReadIndex = 0;
  bool connected = false;

  int get unreadCount {
    int count = 0;
    for (int i = _lastReadIndex; i < messages.length; i++) {
      if (!messages[i].isMe) count++;
    }
    return count;
  }

  String? _myUsername;
  int? _myUserId;

  void init(String token, String username, int userId) {
    _myUsername = username;
    _myUserId = userId;
    _close();
    _connect(token);
  }

  void _connect(String token) {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConfig.wsUrl}?token=$token'),
      );
      _sub = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            if (json['type'] == 'history') {
              final history = (json['messages'] as List)
                  .map((m) => ChatMessage.fromJson(m, _myUserId ?? 0,
                      myUsername: _myUsername ?? ''))
                  .toList();
              messages
                ..clear()
                ..addAll(history);
              _lastReadIndex = messages.length; // history is pre-read
              notifyListeners();
              return;
            }
            if (json['type'] != 'message') return;
            final msg = ChatMessage.fromJson(json, _myUserId ?? 0,
                myUsername: _myUsername ?? '');
            messages.add(msg);
            notifyListeners();
          } catch (_) {}
        },
        onDone: () {
          connected = false;
          notifyListeners();
        },
        onError: (_) {
          connected = false;
          notifyListeners();
        },
      );
      connected = true;
      notifyListeners();
    } catch (_) {}
  }

  void markAsRead() {
    _lastReadIndex = messages.length;
    notifyListeners();
  }

  void send(String text) {
    try {
      _channel?.sink.add(jsonEncode({'type': 'message', 'text': text}));
    } catch (_) {}
  }

  void disconnect() {
    _close();
    messages.clear();
    _lastReadIndex = 0;
    _myUsername = null;
    _myUserId = null;
    connected = false;
    notifyListeners();
  }

  void _close() {
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }
}
