import '../config.dart';

/// Issue types the store accepts when a customer opens a support chat.
const Map<String, String> supportIssueTypes = {
  'item_missing': 'Item missing',
  'item_damaged': 'Item damaged',
  'wrong_item': 'Wrong item',
  'not_delivered': "Didn't receive order",
  'payment_issue': 'Payment issue',
  'other': 'Something else',
};

class SupportMessage {
  final String id;
  final String senderType; // 'user', 'agent' (store staff) or 'system'
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.senderType,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  bool get isUser => senderType == 'user';
  bool get isSystem => senderType == 'system';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    // Store format: { body, is_staff, user_id (null for automatic notes), attachment_url }
    final isStaff = json['is_staff'] == true || json['is_staff'] == 1;
    final sender = json['sender_type'] ??
        (isStaff ? 'agent' : (json.containsKey('user_id') && json['user_id'] == null ? 'system' : 'user'));
    final attachment = json['attachment_url']?.toString();
    return SupportMessage(
      id: json['id']?.toString() ?? '',
      senderType: sender,
      message: (json['body'] ?? json['message'] ?? '').toString(),
      attachmentUrl: attachment == null || attachment.isEmpty ? null : AppConfig.media(attachment),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'])?.toLocal() ?? DateTime.now() : DateTime.now(),
    );
  }
}

class SupportThread {
  final String id;
  final String subject;
  final String status; // 'open', 'resolved', 'closed'
  final String? orderId;
  final String issueType; // 'delivery' = started by the rider
  final String? ratingComment;
  final List<SupportMessage> messages;
  final int messageCount;
  final int? rating; // 1 to 5
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  SupportThread({
    required this.id,
    required this.subject,
    required this.status,
    this.orderId,
    this.issueType = 'other',
    this.ratingComment,
    required this.messages,
    this.messageCount = 0,
    this.rating,
    required this.createdAt,
    this.lastMessageAt,
  });

  bool get isDelivery => issueType == 'delivery';
  bool get hasStaffReply => messages.any((m) => m.senderType == 'agent');

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    final rawMsgs = json['messages'] as List? ?? [];
    final issue = supportIssueTypes[json['issue_type']] ??
        (json['issue_type'] == 'delivery' ? 'Delivery' : json['subject']?.toString() ?? 'Support');
    final orderId = json['order_id']?.toString();
    DateTime? parse(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return SupportThread(
      id: json['id']?.toString() ?? '',
      subject: orderId != null ? '$issue · Order #$orderId' : issue,
      status: json['status']?.toString() ?? 'open',
      orderId: orderId,
      issueType: json['issue_type']?.toString() ?? 'other',
      ratingComment: json['rating_comment']?.toString(),
      messages: rawMsgs.map((m) => SupportMessage.fromJson(Map<String, dynamic>.from(m))).toList(),
      messageCount: (json['messages_count'] as num?)?.toInt() ?? rawMsgs.length,
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: parse(json['created_at']) ?? DateTime.now(),
      lastMessageAt: parse(json['last_message_at']),
    );
  }
}
