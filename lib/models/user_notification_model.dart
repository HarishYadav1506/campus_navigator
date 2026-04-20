class UserNotificationModel {
  final String id;
  final String userEmail;
  final String title;
  final String? body;
  final String kind;
  final DateTime? readAt;
  final DateTime createdAt;

  UserNotificationModel({
    required this.id,
    required this.userEmail,
    required this.title,
    this.body,
    required this.kind,
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory UserNotificationModel.fromMap(Map<String, dynamic> m) {
    return UserNotificationModel(
      id: m['id'].toString(),
      userEmail: (m['user_email'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      body: m['body']?.toString(),
      kind: (m['kind'] ?? 'general').toString(),
      readAt: m['read_at'] == null
          ? null
          : DateTime.tryParse(m['read_at'].toString())?.toUtc(),
      createdAt: DateTime.parse(m['created_at'].toString()).toUtc(),
    );
  }
}
