class InquiryStatisticsModel {
  final int total;
  final int pending;
  final int completed;

  InquiryStatisticsModel({
    required this.total,
    required this.pending,
    required this.completed,
  });

  factory InquiryStatisticsModel.fromJson(Map<String, dynamic> json) {
    return InquiryStatisticsModel(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "total": total,
      "pending": pending,
      "completed": completed,
    };
  }

  @override
  String toString() {
    return 'InquiryStatisticsModel(total: $total, pending: $pending, completed: $completed)';
  }
}