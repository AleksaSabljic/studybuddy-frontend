class ChatMessage {
  final String text;
  final String username;
  final int userId;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.text,
    required this.username,
    required this.userId,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, int myId, {String myUsername = ''}) {
    return ChatMessage(
      text: json['text'] ?? '',
      username: json['username'] ?? 'Unknown',
      userId: json['userId'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isMe: (json['username'] != null && json['username'] == myUsername),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'username': username,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
      };
}
