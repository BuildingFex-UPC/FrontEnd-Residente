class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.recipientId,
    required this.role,
    required this.title,
    required this.message,
    required this.type,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String recipientId;
  final String role;
  final String title;
  final String message;
  final String type;
  final String? relatedEntityId;
  final bool isRead;
  final String createdAt;
  final String? readAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id']?.toString() ?? '',
        recipientId: json['recipientId']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        type: json['type']?.toString() ?? 'general',
        relatedEntityId: json['relatedEntityId']?.toString(),
        isRead: json['isRead'] == true,
        createdAt: json['createdAt']?.toString() ?? '',
        readAt: json['readAt']?.toString(),
      );
}

