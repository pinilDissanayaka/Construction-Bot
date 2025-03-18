/// Represents a message in the chat
class Message {
  final String text;
  final bool isUser;
  final List<AttachmentItem>? attachments;

  Message({
    required this.text, 
    required this.isUser, 
    this.attachments,
  });
}

/// Represents a file or image attachment in a message
class AttachmentItem {
  final String url;      // Local file URL
  final String type;     // 'image' or 'document'
  final String name;     // Original filename
  final String? size;    // File size (optional)

  AttachmentItem({
    required this.url,
    required this.type,
    required this.name,
    this.size,
  });

  // Replace the static Future method with a factory constructor
  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      url: json['url'] as String, 
      type: json['type'] as String,
      name: json['name'] as String,
      size: json['size'] as String?,
    );
  }
}