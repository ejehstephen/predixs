class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'info', 'success', 'warning', 'error'
  final bool isRead;
  final DateTime date;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.date,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      date: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'created_at': date.toIso8601String(),
    };
  }
}
