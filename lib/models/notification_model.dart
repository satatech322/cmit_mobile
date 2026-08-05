class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? type;
  final int? assessmentId;
  final bool? isMs;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.assessmentId,
    this.isMs,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'assessment_id': assessmentId,
      'is_ms': isMs,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'],
      assessmentId: json['assessment_id'],
      isMs: json['is_ms'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      assessmentId: assessmentId,
      isMs: isMs,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
