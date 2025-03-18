class ChatHistory {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;

  ChatHistory({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: json['id'] as String,
      title: json['title'] as String,
      lastMessage: json['last_message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'last_message': lastMessage,
    'timestamp': timestamp.toIso8601String(),
  };
}