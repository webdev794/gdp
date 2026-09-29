class SupportMessage {
  final String id;
  final String senderType; // 'user' or 'agent'
  final String message;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  bool get isUser => senderType == 'user';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id']?.toString() ?? '',
      senderType: json['sender_type'] ?? 'user',
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_type': senderType,
    'message': message,
    'created_at': createdAt.toIso8601String(),
  };
}

class SupportThread {
  final String id;
  final String subject;
  final String status; // 'open', 'resolved', 'closed'
  final List<SupportMessage> messages;
  final int? rating; // 1 to 5
  final DateTime createdAt;

  SupportThread({
    required this.id,
    required this.subject,
    required this.status,
    required this.messages,
    this.rating,
    required this.createdAt,
  });

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    var rawMsgs = json['messages'] as List? ?? [];
    return SupportThread(
      id: json['id']?.toString() ?? '',
      subject: json['subject'] ?? 'Support Inquiry',
      status: json['status'] ?? 'open',
      messages: rawMsgs.map((m) => SupportMessage.fromJson(m)).toList(),
      rating: json['rating'] as int?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
